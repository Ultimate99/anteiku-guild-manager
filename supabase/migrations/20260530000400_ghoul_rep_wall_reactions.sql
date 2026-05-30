-- Anteiku Guild Manager - Ghoul Rep backend/RPC foundation
-- Calculates social reputation from visible Wall post/comment reactions.
-- Does not read or expose protected normal CP tables/RPCs.

create or replace function private.get_profile_ghoul_rep(p_profile_id uuid)
returns bigint
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  with post_rep as (
    select count(*)::bigint as points
    from (
      select distinct wpr.post_id, wpr.profile_id
      from public.wall_posts wp
      join public.wall_post_reactions wpr on wpr.post_id = wp.id
      where wp.author_profile_id = p_profile_id
        and wp.deleted_at is null
        and wpr.profile_id <> wp.author_profile_id
    ) distinct_post_reactors
  ),
  comment_rep as (
    select count(*)::bigint as points
    from (
      select distinct wcr.comment_id, wcr.profile_id
      from public.wall_comments wc
      join public.wall_posts wp on wp.id = wc.post_id
      join public.wall_comment_reactions wcr on wcr.comment_id = wc.id
      where wc.author_profile_id = p_profile_id
        and wc.deleted_at is null
        and wp.deleted_at is null
        and wcr.profile_id <> wc.author_profile_id
    ) distinct_comment_reactors
  )
  select coalesce((select points from post_rep), 0)
       + coalesce((select points from comment_rep), 0);
$$;

create or replace function public.get_guild_wall_feed(
  p_guild_id uuid default null,
  p_limit integer default 20,
  p_before timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  effective_guild_id uuid := p_guild_id;
  normalized_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  scope_guild_id uuid;
  scope_guild_name text;
  scope_guild_slug text;
  viewer_can_post boolean := false;
  viewer_can_moderate boolean := false;
  posts_payload jsonb := '[]'::jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_approved(actor_id) then
    raise exception 'Approved profile required.';
  end if;

  if effective_guild_id is not null then
    select g.id, g.name, g.slug
    into scope_guild_id, scope_guild_name, scope_guild_slug
    from public.guilds g
    where g.id = effective_guild_id
      and g.status = 'active'
      and g.is_core = true;

    if scope_guild_id is null then
      raise exception 'Active guild not found.';
    end if;

    if not private.has_guild_wall_view_access(actor_id, effective_guild_id) then
      raise exception 'Not authorized to view this guild wall.';
    end if;

    viewer_can_post := private.has_guild_wall_action_access(actor_id, effective_guild_id);
    viewer_can_moderate := private.can_moderate_guild_wall(actor_id, effective_guild_id);
  else
    scope_guild_id := null;
    scope_guild_name := null;
    scope_guild_slug := null;

    if not private.has_guild_wall_view_access(actor_id, null) then
      raise exception 'Not authorized to view the global wall.';
    end if;

    viewer_can_post := private.has_guild_wall_action_access(actor_id, null);
    viewer_can_moderate := private.can_moderate_guild_wall(actor_id, null);
  end if;

  with visible_posts as (
    select
      wp.*,
      post_guild.name as post_guild_name,
      post_guild.slug as post_guild_slug,
      author_guild.guild_id as author_guild_id,
      author_guild.guild_name as author_guild_name,
      author_guild.guild_slug as author_guild_slug,
      p.username,
      p.profile_slug,
      p.ign,
      private.get_profile_ghoul_rep(wp.author_profile_id) as author_ghoul_rep,
      coalesce(avatar.key, default_avatar.key) as avatar_key,
      coalesce(avatar.asset_path, default_avatar.asset_path) as avatar_asset_path,
      coalesce(frame.key, default_frame.key) as frame_key,
      coalesce(frame.asset_path, default_frame.asset_path) as frame_asset_path
    from public.wall_posts wp
    left join public.guilds post_guild on post_guild.id = wp.guild_id
    join public.profiles p on p.id = wp.author_profile_id
    left join lateral (
      select gm.guild_id, g.name as guild_name, g.slug as guild_slug
      from public.guild_memberships gm
      join public.guilds g on g.id = gm.guild_id
      where gm.profile_id = wp.author_profile_id
        and gm.membership_status = 'active'
        and gm.is_primary = true
        and g.status = 'active'
        and g.is_core = true
      order by gm.created_at desc
      limit 1
    ) author_guild on true
    left join public.profile_equipped_cosmetics pec on pec.profile_id = p.id
    left join public.cosmetic_catalog avatar
      on avatar.key = pec.avatar_key
     and avatar.type = 'avatar'
     and avatar.is_active = true
    left join public.cosmetic_catalog frame
      on frame.key = pec.frame_key
     and frame.type = 'frame'
     and frame.is_active = true
    left join public.cosmetic_catalog default_avatar
      on default_avatar.key = '1079_head'
     and default_avatar.type = 'avatar'
     and default_avatar.is_active = true
    left join public.cosmetic_catalog default_frame
      on default_frame.key = 'TXK_frame_reOpen_EN_FREE'
     and default_frame.type = 'frame'
     and default_frame.is_active = true
    where wp.deleted_at is null
      and (
        (effective_guild_id is null and wp.guild_id is null)
        or (effective_guild_id is not null and wp.guild_id = effective_guild_id)
      )
      and (wp.guild_id is null or (post_guild.status = 'active' and post_guild.is_core = true))
      and (p_before is null or wp.created_at < p_before)
    order by wp.is_pinned desc, wp.created_at desc
    limit normalized_limit
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', vp.id,
        'guild_id', vp.guild_id,
        'guild_name', coalesce(vp.post_guild_name, vp.author_guild_name),
        'guild_slug', coalesce(vp.post_guild_slug, vp.author_guild_slug),
        'author_guild_id', vp.author_guild_id,
        'author_guild_name', vp.author_guild_name,
        'author_guild_slug', vp.author_guild_slug,
        'is_global', vp.guild_id is null,
        'author_profile_id', vp.author_profile_id,
        'author_username', vp.username,
        'author_profile_slug', vp.profile_slug,
        'author_ign', vp.ign,
        'author_ghoul_rep', vp.author_ghoul_rep,
        'avatar_key', vp.avatar_key,
        'avatar_asset_path', vp.avatar_asset_path,
        'frame_key', vp.frame_key,
        'frame_asset_path', vp.frame_asset_path,
        'content', vp.content,
        'is_pinned', vp.is_pinned,
        'is_locked', vp.is_locked,
        'created_at', vp.created_at,
        'updated_at', vp.updated_at,
        'can_delete', vp.author_profile_id = actor_id,
        'can_moderate', private.can_moderate_guild_wall(actor_id, vp.guild_id),
        'reactions', (
          select coalesce(
            jsonb_agg(
              jsonb_build_object(
                'type', reaction_rows.reaction_type,
                'count', reaction_rows.reaction_count,
                'reacted_by_me', exists (
                  select 1
                  from public.wall_post_reactions wpr_self
                  where wpr_self.post_id = vp.id
                    and wpr_self.profile_id = actor_id
                    and wpr_self.reaction_type = reaction_rows.reaction_type
                )
              )
              order by reaction_rows.reaction_type
            ),
            '[]'::jsonb
          )
          from (
            select wpr.reaction_type, count(*) as reaction_count
            from public.wall_post_reactions wpr
            where wpr.post_id = vp.id
            group by wpr.reaction_type
          ) reaction_rows
        ),
        'comments', (
          select coalesce(
            jsonb_agg(
              jsonb_build_object(
                'id', wc.id,
                'post_id', wc.post_id,
                'guild_id', wc.guild_id,
                'author_profile_id', wc.author_profile_id,
                'author_username', cp.username,
                'author_profile_slug', cp.profile_slug,
                'author_ign', cp.ign,
                'author_ghoul_rep', private.get_profile_ghoul_rep(wc.author_profile_id),
                'avatar_key', coalesce(cavatar.key, cdefault_avatar.key),
                'avatar_asset_path', coalesce(cavatar.asset_path, cdefault_avatar.asset_path),
                'frame_key', coalesce(cframe.key, cdefault_frame.key),
                'frame_asset_path', coalesce(cframe.asset_path, cdefault_frame.asset_path),
                'content', wc.content,
                'created_at', wc.created_at,
                'updated_at', wc.updated_at,
                'can_delete', wc.author_profile_id = actor_id,
                'can_moderate', private.can_moderate_guild_wall(actor_id, wc.guild_id),
                'reactions', (
                  select coalesce(
                    jsonb_agg(
                      jsonb_build_object(
                        'type', comment_reaction_rows.reaction_type,
                        'count', comment_reaction_rows.reaction_count,
                        'reacted_by_me', exists (
                          select 1
                          from public.wall_comment_reactions wcr_self
                          where wcr_self.comment_id = wc.id
                            and wcr_self.profile_id = actor_id
                            and wcr_self.reaction_type = comment_reaction_rows.reaction_type
                        )
                      )
                      order by comment_reaction_rows.reaction_type
                    ),
                    '[]'::jsonb
                  )
                  from (
                    select wcr.reaction_type, count(*) as reaction_count
                    from public.wall_comment_reactions wcr
                    where wcr.comment_id = wc.id
                    group by wcr.reaction_type
                  ) comment_reaction_rows
                )
              )
              order by wc.created_at asc
            ),
            '[]'::jsonb
          )
          from public.wall_comments wc
          join public.profiles cp on cp.id = wc.author_profile_id
          left join public.profile_equipped_cosmetics cpec on cpec.profile_id = cp.id
          left join public.cosmetic_catalog cavatar
            on cavatar.key = cpec.avatar_key
           and cavatar.type = 'avatar'
           and cavatar.is_active = true
          left join public.cosmetic_catalog cframe
            on cframe.key = cpec.frame_key
           and cframe.type = 'frame'
           and cframe.is_active = true
          left join public.cosmetic_catalog cdefault_avatar
            on cdefault_avatar.key = '1079_head'
           and cdefault_avatar.type = 'avatar'
           and cdefault_avatar.is_active = true
          left join public.cosmetic_catalog cdefault_frame
            on cdefault_frame.key = 'TXK_frame_reOpen_EN_FREE'
           and cdefault_frame.type = 'frame'
           and cdefault_frame.is_active = true
          where wc.post_id = vp.id
            and wc.deleted_at is null
        )
      )
      order by vp.is_pinned desc, vp.created_at desc
    ),
    '[]'::jsonb
  )
  into posts_payload
  from visible_posts vp;

  return jsonb_build_object(
    'viewer',
    jsonb_build_object(
      'profile_id', actor_id,
      'scope_guild_id', effective_guild_id,
      'scope_guild_name', case when effective_guild_id is null then null else scope_guild_name end,
      'scope_guild_slug', case when effective_guild_id is null then null else scope_guild_slug end,
      'is_global', effective_guild_id is null,
      'can_post', viewer_can_post,
      'can_moderate', viewer_can_moderate
    ),
    'posts',
    posts_payload
  );
end;
$$;

create or replace function public.get_wall_reaction_details(
  p_target_type text,
  p_target_id uuid,
  p_reaction_type text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_target_type text := lower(trim(coalesce(p_target_type, '')));
  normalized_reaction_type text := nullif(lower(trim(coalesce(p_reaction_type, ''))), '');
  target_guild_id uuid;
  reactions_payload jsonb := '[]'::jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if normalized_target_type not in ('post', 'comment') then
    raise exception 'Unsupported wall reaction target type.';
  end if;

  if normalized_reaction_type is not null
     and normalized_reaction_type not in ('like', 'fire', 'coffee', 'skull', 'trophy') then
    raise exception 'Unsupported wall reaction type.';
  end if;

  if normalized_target_type = 'post' then
    select wp.guild_id
    into target_guild_id
    from public.wall_posts wp
    where wp.id = p_target_id
      and wp.deleted_at is null;

    if not found then
      raise exception 'Wall target not found.';
    end if;

    if not private.has_guild_wall_view_access(actor_id, target_guild_id) then
      raise exception 'Not authorized to view wall reactions.';
    end if;

    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'reaction_type', wpr.reaction_type,
          'profile_id', p.id,
          'username', p.username,
          'profile_slug', p.profile_slug,
          'ign', p.ign,
          'guild_id', reactor_guild.guild_id,
          'guild_name', reactor_guild.guild_name,
          'guild_slug', reactor_guild.guild_slug,
          'avatar_key', coalesce(avatar.key, default_avatar.key),
          'avatar_asset_path', coalesce(avatar.asset_path, default_avatar.asset_path),
          'frame_key', coalesce(frame.key, default_frame.key),
          'frame_asset_path', coalesce(frame.asset_path, default_frame.asset_path),
          'reacted_at', wpr.created_at
        )
        order by wpr.reaction_type, wpr.created_at desc
      ),
      '[]'::jsonb
    )
    into reactions_payload
    from public.wall_post_reactions wpr
    join public.profiles p on p.id = wpr.profile_id
    left join lateral (
      select gm.guild_id, g.name as guild_name, g.slug as guild_slug
      from public.guild_memberships gm
      join public.guilds g on g.id = gm.guild_id
      where gm.profile_id = p.id
        and gm.membership_status = 'active'
        and gm.is_primary = true
        and g.status = 'active'
        and g.is_core = true
      order by gm.created_at desc
      limit 1
    ) reactor_guild on true
    left join public.profile_equipped_cosmetics pec on pec.profile_id = p.id
    left join public.cosmetic_catalog avatar
      on avatar.key = pec.avatar_key
     and avatar.type = 'avatar'
     and avatar.is_active = true
    left join public.cosmetic_catalog frame
      on frame.key = pec.frame_key
     and frame.type = 'frame'
     and frame.is_active = true
    left join public.cosmetic_catalog default_avatar
      on default_avatar.key = '1079_head'
     and default_avatar.type = 'avatar'
     and default_avatar.is_active = true
    left join public.cosmetic_catalog default_frame
      on default_frame.key = 'TXK_frame_reOpen_EN_FREE'
     and default_frame.type = 'frame'
     and default_frame.is_active = true
    where wpr.post_id = p_target_id
      and (normalized_reaction_type is null or wpr.reaction_type = normalized_reaction_type);
  else
    select wc.guild_id
    into target_guild_id
    from public.wall_comments wc
    join public.wall_posts wp on wp.id = wc.post_id
    where wc.id = p_target_id
      and wc.deleted_at is null
      and wp.deleted_at is null;

    if not found then
      raise exception 'Wall target not found.';
    end if;

    if not private.has_guild_wall_view_access(actor_id, target_guild_id) then
      raise exception 'Not authorized to view wall reactions.';
    end if;

    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'reaction_type', wcr.reaction_type,
          'profile_id', p.id,
          'username', p.username,
          'profile_slug', p.profile_slug,
          'ign', p.ign,
          'guild_id', reactor_guild.guild_id,
          'guild_name', reactor_guild.guild_name,
          'guild_slug', reactor_guild.guild_slug,
          'avatar_key', coalesce(avatar.key, default_avatar.key),
          'avatar_asset_path', coalesce(avatar.asset_path, default_avatar.asset_path),
          'frame_key', coalesce(frame.key, default_frame.key),
          'frame_asset_path', coalesce(frame.asset_path, default_frame.asset_path),
          'reacted_at', wcr.created_at
        )
        order by wcr.reaction_type, wcr.created_at desc
      ),
      '[]'::jsonb
    )
    into reactions_payload
    from public.wall_comment_reactions wcr
    join public.profiles p on p.id = wcr.profile_id
    left join lateral (
      select gm.guild_id, g.name as guild_name, g.slug as guild_slug
      from public.guild_memberships gm
      join public.guilds g on g.id = gm.guild_id
      where gm.profile_id = p.id
        and gm.membership_status = 'active'
        and gm.is_primary = true
        and g.status = 'active'
        and g.is_core = true
      order by gm.created_at desc
      limit 1
    ) reactor_guild on true
    left join public.profile_equipped_cosmetics pec on pec.profile_id = p.id
    left join public.cosmetic_catalog avatar
      on avatar.key = pec.avatar_key
     and avatar.type = 'avatar'
     and avatar.is_active = true
    left join public.cosmetic_catalog frame
      on frame.key = pec.frame_key
     and frame.type = 'frame'
     and frame.is_active = true
    left join public.cosmetic_catalog default_avatar
      on default_avatar.key = '1079_head'
     and default_avatar.type = 'avatar'
     and default_avatar.is_active = true
    left join public.cosmetic_catalog default_frame
      on default_frame.key = 'TXK_frame_reOpen_EN_FREE'
     and default_frame.type = 'frame'
     and default_frame.is_active = true
    where wcr.comment_id = p_target_id
      and (normalized_reaction_type is null or wcr.reaction_type = normalized_reaction_type);
  end if;

  return jsonb_build_object(
    'target_type', normalized_target_type,
    'target_id', p_target_id,
    'reaction_type', normalized_reaction_type,
    'reactions', reactions_payload
  );
end;
$$;

revoke all on function private.get_profile_ghoul_rep(uuid) from public, anon, authenticated;
revoke all on function public.get_guild_wall_feed(uuid, integer, timestamptz) from public, anon;
revoke all on function public.get_wall_reaction_details(text, uuid, text) from public, anon;

grant execute on function public.get_guild_wall_feed(uuid, integer, timestamptz) to authenticated;
grant execute on function public.get_wall_reaction_details(text, uuid, text) to authenticated;
