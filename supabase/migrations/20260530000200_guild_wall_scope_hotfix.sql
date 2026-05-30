-- Anteiku Guild Manager - Guild Wall scope hotfix
-- Fixes Owner/global feed loads by assigning the scope_guild record before
-- returning viewer metadata. No CP tables/RPCs are used.

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
  actor_is_owner boolean;
  scope_guild record;
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

  actor_is_owner := private.is_owner(actor_id);

  if effective_guild_id is null and not actor_is_owner then
    effective_guild_id := private.guild_wall_primary_guild_id(actor_id);
  end if;

  if effective_guild_id is not null then
    select g.id, g.name, g.slug into scope_guild
    from public.guilds g
    where g.id = effective_guild_id
      and g.status = 'active'
      and g.is_core = true;

    if scope_guild.id is null then
      raise exception 'Active guild not found.';
    end if;

    if not private.has_guild_wall_view_access(actor_id, effective_guild_id) then
      raise exception 'Not authorized to view this guild wall.';
    end if;

    viewer_can_post := private.has_guild_wall_action_access(actor_id, effective_guild_id);
    viewer_can_moderate := private.can_moderate_guild_wall(actor_id, effective_guild_id);
  elsif not actor_is_owner then
    raise exception 'Guild scope is required.';
  else
    select null::uuid as id, null::text as name, null::text as slug into scope_guild;
    viewer_can_moderate := true;
  end if;

  with visible_posts as (
    select
      wp.*,
      g.name as guild_name,
      g.slug as guild_slug,
      p.username,
      p.profile_slug,
      p.ign,
      coalesce(avatar.key, default_avatar.key) as avatar_key,
      coalesce(avatar.asset_path, default_avatar.asset_path) as avatar_asset_path,
      coalesce(frame.key, default_frame.key) as frame_key,
      coalesce(frame.asset_path, default_frame.asset_path) as frame_asset_path
    from public.wall_posts wp
    join public.guilds g on g.id = wp.guild_id
    join public.profiles p on p.id = wp.author_profile_id
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
      and g.status = 'active'
      and g.is_core = true
      and (effective_guild_id is null or wp.guild_id = effective_guild_id)
      and (p_before is null or wp.created_at < p_before)
    order by wp.is_pinned desc, wp.created_at desc
    limit normalized_limit
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', vp.id,
        'guild_id', vp.guild_id,
        'guild_name', vp.guild_name,
        'guild_slug', vp.guild_slug,
        'author_profile_id', vp.author_profile_id,
        'author_username', vp.username,
        'author_profile_slug', vp.profile_slug,
        'author_ign', vp.ign,
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
      'scope_guild_name', case when effective_guild_id is null then null else scope_guild.name end,
      'scope_guild_slug', case when effective_guild_id is null then null else scope_guild.slug end,
      'is_global', effective_guild_id is null,
      'can_post', viewer_can_post,
      'can_moderate', viewer_can_moderate
    ),
    'posts',
    posts_payload
  );
end;
$$;

revoke all on function public.get_guild_wall_feed(uuid, integer, timestamptz) from public, anon;
grant execute on function public.get_guild_wall_feed(uuid, integer, timestamptz) to authenticated;
