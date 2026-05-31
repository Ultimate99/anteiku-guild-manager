-- Anteiku Guild Manager - Active profile Wall/Profile Reaction migration
-- Migrates Guild Wall/Global Wall authorship/reactions/own-delete and Public Profile
-- reactions to the selected active profile. Does not read or expose protected CP.

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
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  effective_guild_id uuid := p_guild_id;
  normalized_limit integer := least(greatest(coalesce(p_limit, 20), 1), 50);
  scope_guild_id uuid;
  scope_guild_name text;
  scope_guild_slug text;
  viewer_can_post boolean := false;
  viewer_can_moderate boolean := false;
  posts_payload jsonb := '[]'::jsonb;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if actor_profile_id is null or not private.is_approved(actor_profile_id) then
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

    if not private.has_guild_wall_view_access(actor_profile_id, effective_guild_id) then
      raise exception 'Not authorized to view this guild wall.';
    end if;

    viewer_can_post := private.has_guild_wall_action_access(actor_profile_id, effective_guild_id);
    viewer_can_moderate := private.can_moderate_guild_wall(actor_profile_id, effective_guild_id);
  else
    scope_guild_id := null;
    scope_guild_name := null;
    scope_guild_slug := null;

    if not private.has_guild_wall_view_access(actor_profile_id, null) then
      raise exception 'Not authorized to view the global wall.';
    end if;

    viewer_can_post := private.has_guild_wall_action_access(actor_profile_id, null);
    viewer_can_moderate := private.can_moderate_guild_wall(actor_profile_id, null);
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
        'can_delete', vp.author_profile_id = actor_profile_id,
        'can_moderate', private.can_moderate_guild_wall(actor_profile_id, vp.guild_id),
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
                    and wpr_self.profile_id = actor_profile_id
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
                'can_delete', wc.author_profile_id = actor_profile_id,
                'can_moderate', private.can_moderate_guild_wall(actor_profile_id, wc.guild_id),
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
                            and wcr_self.profile_id = actor_profile_id
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
      'profile_id', actor_profile_id,
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

create or replace function public.create_wall_post(
  p_guild_id uuid,
  p_content text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  normalized_content text;
  new_post_id uuid;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if p_guild_id is not null and not exists (
    select 1 from public.guilds g
    where g.id = p_guild_id
      and g.status = 'active'
      and g.is_core = true
  ) then
    raise exception 'Active guild not found.';
  end if;

  if not private.has_guild_wall_action_access(actor_profile_id, p_guild_id) then
    raise exception 'Not authorized to post on this wall.';
  end if;

  normalized_content := private.validate_wall_content(p_content, 1000);

  insert into public.wall_posts (guild_id, author_profile_id, content)
  values (p_guild_id, actor_profile_id, normalized_content)
  returning id into new_post_id;

  perform private.write_audit_log(
    actor_profile_id,
    actor_profile_id,
    p_guild_id,
    'wall_post_created',
    'wall_posts',
    new_post_id,
    jsonb_build_object(
      'content_length', char_length(normalized_content),
      'scope', case when p_guild_id is null then 'global' else 'guild' end
    )
  );

  return new_post_id;
end;
$$;

create or replace function public.delete_wall_post(p_post_id uuid)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_post public.wall_posts%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if target_post.author_profile_id <> actor_profile_id then
    raise exception 'Only the active post author can delete this post.';
  end if;

  if not private.has_guild_wall_action_access(actor_profile_id, target_post.guild_id) then
    raise exception 'Not authorized to delete this post.';
  end if;

  update public.wall_posts
  set deleted_at = now(),
      deleted_by = actor_profile_id,
      is_pinned = false
  where id = target_post.id;

  perform private.write_audit_log(
    actor_profile_id,
    target_post.author_profile_id,
    target_post.guild_id,
    'wall_post_deleted',
    'wall_posts',
    target_post.id,
    '{}'::jsonb
  );

  return target_post.id;
end;
$$;

create or replace function public.moderate_delete_wall_post(p_post_id uuid)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_post public.wall_posts%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if not private.can_moderate_guild_wall(actor_profile_id, target_post.guild_id) then
    raise exception 'Not authorized to moderate this guild wall.';
  end if;

  update public.wall_posts
  set deleted_at = now(),
      deleted_by = actor_profile_id,
      is_pinned = false
  where id = target_post.id;

  perform private.write_audit_log(
    actor_profile_id,
    target_post.author_profile_id,
    target_post.guild_id,
    'wall_post_moderated_deleted',
    'wall_posts',
    target_post.id,
    '{}'::jsonb
  );

  return target_post.id;
end;
$$;

create or replace function public.pin_wall_post(p_post_id uuid)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_post public.wall_posts%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if not private.can_moderate_guild_wall(actor_profile_id, target_post.guild_id) then
    raise exception 'Not authorized to pin this post.';
  end if;

  update public.wall_posts
  set is_pinned = true
  where id = target_post.id;

  perform private.write_audit_log(
    actor_profile_id,
    target_post.author_profile_id,
    target_post.guild_id,
    'wall_post_pinned',
    'wall_posts',
    target_post.id,
    '{}'::jsonb
  );

  return target_post.id;
end;
$$;

create or replace function public.unpin_wall_post(p_post_id uuid)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_post public.wall_posts%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if not private.can_moderate_guild_wall(actor_profile_id, target_post.guild_id) then
    raise exception 'Not authorized to unpin this post.';
  end if;

  update public.wall_posts
  set is_pinned = false
  where id = target_post.id;

  perform private.write_audit_log(
    actor_profile_id,
    target_post.author_profile_id,
    target_post.guild_id,
    'wall_post_unpinned',
    'wall_posts',
    target_post.id,
    '{}'::jsonb
  );

  return target_post.id;
end;
$$;

create or replace function public.create_wall_comment(
  p_post_id uuid,
  p_content text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_post public.wall_posts%rowtype;
  normalized_content text;
  new_comment_id uuid;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if target_post.is_locked then
    raise exception 'Post comments are locked.';
  end if;

  if not private.has_guild_wall_action_access(actor_profile_id, target_post.guild_id) then
    raise exception 'Not authorized to comment on this guild wall.';
  end if;

  normalized_content := private.validate_wall_content(p_content, 500);

  insert into public.wall_comments (post_id, guild_id, author_profile_id, content)
  values (target_post.id, target_post.guild_id, actor_profile_id, normalized_content)
  returning id into new_comment_id;

  perform private.write_audit_log(
    actor_profile_id,
    target_post.author_profile_id,
    target_post.guild_id,
    'wall_comment_created',
    'wall_comments',
    new_comment_id,
    jsonb_build_object('post_id', target_post.id, 'content_length', char_length(normalized_content))
  );

  return new_comment_id;
end;
$$;

create or replace function public.delete_wall_comment(p_comment_id uuid)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_comment public.wall_comments%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  select * into target_comment
  from public.wall_comments
  where id = p_comment_id
    and deleted_at is null;

  if not found then
    raise exception 'Comment not found.';
  end if;

  if target_comment.author_profile_id <> actor_profile_id then
    raise exception 'Only the active comment author can delete this comment.';
  end if;

  if not private.has_guild_wall_action_access(actor_profile_id, target_comment.guild_id) then
    raise exception 'Not authorized to delete this comment.';
  end if;

  update public.wall_comments
  set deleted_at = now(),
      deleted_by = actor_profile_id
  where id = target_comment.id;

  perform private.write_audit_log(
    actor_profile_id,
    target_comment.author_profile_id,
    target_comment.guild_id,
    'wall_comment_deleted',
    'wall_comments',
    target_comment.id,
    jsonb_build_object('post_id', target_comment.post_id)
  );

  return target_comment.id;
end;
$$;

create or replace function public.moderate_delete_wall_comment(p_comment_id uuid)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_comment public.wall_comments%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  select * into target_comment
  from public.wall_comments
  where id = p_comment_id
    and deleted_at is null;

  if not found then
    raise exception 'Comment not found.';
  end if;

  if not private.can_moderate_guild_wall(actor_profile_id, target_comment.guild_id) then
    raise exception 'Not authorized to moderate this guild wall.';
  end if;

  update public.wall_comments
  set deleted_at = now(),
      deleted_by = actor_profile_id
  where id = target_comment.id;

  perform private.write_audit_log(
    actor_profile_id,
    target_comment.author_profile_id,
    target_comment.guild_id,
    'wall_comment_moderated_deleted',
    'wall_comments',
    target_comment.id,
    jsonb_build_object('post_id', target_comment.post_id)
  );

  return target_comment.id;
end;
$$;

create or replace function public.react_to_wall_post(
  p_post_id uuid,
  p_reaction_type text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_post public.wall_posts%rowtype;
  new_reaction_id uuid;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if not private.is_valid_wall_reaction(p_reaction_type) then
    raise exception 'Unsupported reaction.';
  end if;

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if not private.has_guild_wall_action_access(actor_profile_id, target_post.guild_id) then
    raise exception 'Not authorized to react on this guild wall.';
  end if;

  insert into public.wall_post_reactions (post_id, profile_id, reaction_type)
  values (target_post.id, actor_profile_id, p_reaction_type)
  on conflict (post_id, profile_id, reaction_type) do nothing
  returning id into new_reaction_id;

  if new_reaction_id is null then
    select id into new_reaction_id
    from public.wall_post_reactions
    where post_id = target_post.id
      and profile_id = actor_profile_id
      and reaction_type = p_reaction_type;
  end if;

  return new_reaction_id;
end;
$$;

create or replace function public.remove_wall_post_reaction(
  p_post_id uuid,
  p_reaction_type text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_post public.wall_posts%rowtype;
  removed_reaction_id uuid;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if not private.is_valid_wall_reaction(p_reaction_type) then
    raise exception 'Unsupported reaction.';
  end if;

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if not private.has_guild_wall_action_access(actor_profile_id, target_post.guild_id) then
    raise exception 'Not authorized to react on this guild wall.';
  end if;

  delete from public.wall_post_reactions
  where post_id = target_post.id
    and profile_id = actor_profile_id
    and reaction_type = p_reaction_type
  returning id into removed_reaction_id;

  return removed_reaction_id;
end;
$$;

create or replace function public.react_to_wall_comment(
  p_comment_id uuid,
  p_reaction_type text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_comment public.wall_comments%rowtype;
  new_reaction_id uuid;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if not private.is_valid_wall_reaction(p_reaction_type) then
    raise exception 'Unsupported reaction.';
  end if;

  select wc.* into target_comment
  from public.wall_comments wc
  join public.wall_posts wp on wp.id = wc.post_id
  where wc.id = p_comment_id
    and wc.deleted_at is null
    and wp.deleted_at is null;

  if not found then
    raise exception 'Comment not found.';
  end if;

  if not private.has_guild_wall_action_access(actor_profile_id, target_comment.guild_id) then
    raise exception 'Not authorized to react on this guild wall.';
  end if;

  insert into public.wall_comment_reactions (comment_id, profile_id, reaction_type)
  values (target_comment.id, actor_profile_id, p_reaction_type)
  on conflict (comment_id, profile_id, reaction_type) do nothing
  returning id into new_reaction_id;

  if new_reaction_id is null then
    select id into new_reaction_id
    from public.wall_comment_reactions
    where comment_id = target_comment.id
      and profile_id = actor_profile_id
      and reaction_type = p_reaction_type;
  end if;

  return new_reaction_id;
end;
$$;

create or replace function public.remove_wall_comment_reaction(
  p_comment_id uuid,
  p_reaction_type text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  target_comment public.wall_comments%rowtype;
  removed_reaction_id uuid;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if not private.is_valid_wall_reaction(p_reaction_type) then
    raise exception 'Unsupported reaction.';
  end if;

  select wc.* into target_comment
  from public.wall_comments wc
  join public.wall_posts wp on wp.id = wc.post_id
  where wc.id = p_comment_id
    and wc.deleted_at is null
    and wp.deleted_at is null;

  if not found then
    raise exception 'Comment not found.';
  end if;

  if not private.has_guild_wall_action_access(actor_profile_id, target_comment.guild_id) then
    raise exception 'Not authorized to react on this guild wall.';
  end if;

  delete from public.wall_comment_reactions
  where comment_id = target_comment.id
    and profile_id = actor_profile_id
    and reaction_type = p_reaction_type
  returning id into removed_reaction_id;

  return removed_reaction_id;
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
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  normalized_target_type text := lower(trim(coalesce(p_target_type, '')));
  normalized_reaction_type text := nullif(lower(trim(coalesce(p_reaction_type, ''))), '');
  target_guild_id uuid;
  reactions_payload jsonb := '[]'::jsonb;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

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

    if not private.has_guild_wall_view_access(actor_profile_id, target_guild_id) then
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

    if not private.has_guild_wall_view_access(actor_profile_id, target_guild_id) then
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

create or replace function public.get_public_member_profile(p_profile_slug text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  normalized_slug text := private.normalize_profile_slug(p_profile_slug);
  target_profile record;
  reactions_payload jsonb := '[]'::jsonb;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if not private.has_public_profile_view_access(actor_profile_id) then
    raise exception 'Approved member access required.';
  end if;

  if not private.is_valid_profile_slug(normalized_slug) then
    raise exception 'Public profile not found.';
  end if;

  select
    p.id,
    p.username,
    p.profile_slug,
    p.ign,
    gm.guild_id,
    g.name as guild_name,
    g.slug as guild_slug,
    gm.role,
    gm.roster_status,
    coalesce(avatar.key, default_avatar.key) as avatar_key,
    coalesce(avatar.asset_path, default_avatar.asset_path) as avatar_asset_path,
    coalesce(frame.key, default_frame.key) as frame_key,
    coalesce(frame.asset_path, default_frame.asset_path) as frame_asset_path,
    tvp.combined_cp as three_v_three_combined_cp
  into target_profile
  from public.profiles p
  join public.guild_memberships gm
    on gm.profile_id = p.id
   and gm.membership_status = 'active'
   and gm.is_primary = true
   and gm.roster_status in ('active', 'trial', 'pending_transfer', 'inactive', 'on_break')
  join public.guilds g
    on g.id = gm.guild_id
   and g.status = 'active'
   and g.is_core = true
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
  left join public.three_v_three_player_profiles tvp on tvp.profile_id = p.id
  where p.approval_status = 'approved'
    and (p.profile_slug = normalized_slug or p.username = normalized_slug)
  order by gm.created_at desc
  limit 1;

  if not found then
    raise exception 'Public profile not found.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'type', reaction_types.reaction_type,
        'count', coalesce(reaction_counts.reaction_count, 0),
        'reacted_by_me', exists (
          select 1
          from public.profile_reactions pr_self
          where pr_self.target_profile_id = target_profile.id
            and pr_self.reactor_profile_id = actor_profile_id
            and pr_self.reaction_type = reaction_types.reaction_type
        )
      )
      order by reaction_types.sort_order
    ),
    '[]'::jsonb
  )
  into reactions_payload
  from (
    values
      ('like'::text, 1),
      ('fire'::text, 2),
      ('coffee'::text, 3),
      ('skull'::text, 4),
      ('trophy'::text, 5)
  ) as reaction_types(reaction_type, sort_order)
  left join lateral (
    select count(*)::bigint as reaction_count
    from public.profile_reactions pr
    where pr.target_profile_id = target_profile.id
      and pr.reaction_type = reaction_types.reaction_type
  ) reaction_counts on true;

  return jsonb_build_object(
    'viewer',
    jsonb_build_object(
      'is_self', target_profile.id = actor_profile_id,
      'can_react', target_profile.id <> actor_profile_id
        and private.has_public_profile_reaction_access(actor_profile_id)
    ),
    'profile',
    jsonb_build_object(
      'profile_id', target_profile.id,
      'username', target_profile.username,
      'profile_slug', target_profile.profile_slug,
      'ign', target_profile.ign,
      'guild_id', target_profile.guild_id,
      'guild_name', target_profile.guild_name,
      'guild_slug', target_profile.guild_slug,
      'role_label', case target_profile.role
        when 'owner' then 'Owner'
        when 'leader' then 'Leader'
        when 'vice' then 'Vice'
        when 'admin' then 'Admin'
        else 'Member'
      end,
      'roster_status', target_profile.roster_status,
      'avatar_key', target_profile.avatar_key,
      'avatar_asset_path', target_profile.avatar_asset_path,
      'frame_key', target_profile.frame_key,
      'frame_asset_path', target_profile.frame_asset_path,
      'ghoul_rep', private.get_profile_ghoul_rep(target_profile.id),
      'three_v_three_combined_cp', target_profile.three_v_three_combined_cp,
      'reactions', reactions_payload
    )
  );
end;
$$;

create or replace function public.react_to_public_profile(
  p_target_profile_id uuid,
  p_reaction_type text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  normalized_reaction_type text := private.normalize_public_profile_reaction_type(p_reaction_type);
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if not private.has_public_profile_reaction_access(actor_profile_id) then
    raise exception 'Active member access required to react.';
  end if;

  if not private.is_public_profile_reaction_type(normalized_reaction_type) then
    raise exception 'Unsupported profile reaction type.';
  end if;

  if not private.is_public_profile_viewable(p_target_profile_id) then
    raise exception 'Public profile not found.';
  end if;

  if p_target_profile_id = actor_profile_id then
    raise exception 'Self profile reactions are not allowed.';
  end if;

  insert into public.profile_reactions (
    target_profile_id,
    reactor_profile_id,
    reaction_type
  )
  values (
    p_target_profile_id,
    actor_profile_id,
    normalized_reaction_type
  )
  on conflict (target_profile_id, reactor_profile_id, reaction_type) do nothing;

  return jsonb_build_object(
    'reaction_type', normalized_reaction_type,
    'reacted_by_me', true
  );
end;
$$;

create or replace function public.remove_public_profile_reaction(
  p_target_profile_id uuid,
  p_reaction_type text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  normalized_reaction_type text := private.normalize_public_profile_reaction_type(p_reaction_type);
  deleted_count integer := 0;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if not private.has_public_profile_view_access(actor_profile_id) then
    raise exception 'Approved member access required.';
  end if;

  if not private.is_public_profile_reaction_type(normalized_reaction_type) then
    raise exception 'Unsupported profile reaction type.';
  end if;

  if not private.is_public_profile_viewable(p_target_profile_id) then
    raise exception 'Public profile not found.';
  end if;

  delete from public.profile_reactions
  where target_profile_id = p_target_profile_id
    and reactor_profile_id = actor_profile_id
    and reaction_type = normalized_reaction_type;

  get diagnostics deleted_count = row_count;

  return jsonb_build_object(
    'reaction_type', normalized_reaction_type,
    'removed', deleted_count > 0
  );
end;
$$;

create or replace function public.get_public_profile_reaction_details(
  p_target_profile_id uuid,
  p_reaction_type text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_profile_id uuid;
  normalized_reaction_type text := private.normalize_public_profile_reaction_type(p_reaction_type);
  reactions_payload jsonb := '[]'::jsonb;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_profile_id := private.get_active_profile_id();

  if not private.has_public_profile_view_access(actor_profile_id) then
    raise exception 'Approved member access required.';
  end if;

  if not private.is_public_profile_viewable(p_target_profile_id) then
    raise exception 'Public profile not found.';
  end if;

  if normalized_reaction_type is not null
     and not private.is_public_profile_reaction_type(normalized_reaction_type) then
    raise exception 'Unsupported profile reaction type.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'reaction_type', pr.reaction_type,
        'username', reactor.username,
        'profile_slug', reactor.profile_slug,
        'ign', reactor.ign,
        'guild_name', reactor_guild.guild_name,
        'guild_slug', reactor_guild.guild_slug,
        'avatar_key', coalesce(avatar.key, default_avatar.key),
        'avatar_asset_path', coalesce(avatar.asset_path, default_avatar.asset_path),
        'frame_key', coalesce(frame.key, default_frame.key),
        'frame_asset_path', coalesce(frame.asset_path, default_frame.asset_path),
        'reacted_at', pr.created_at
      )
      order by pr.reaction_type, pr.created_at desc
    ),
    '[]'::jsonb
  )
  into reactions_payload
  from public.profile_reactions pr
  join public.profiles reactor on reactor.id = pr.reactor_profile_id
  join lateral (
    select g.name as guild_name, g.slug as guild_slug
    from public.guild_memberships gm
    join public.guilds g on g.id = gm.guild_id
    where gm.profile_id = reactor.id
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer', 'inactive', 'on_break')
      and g.status = 'active'
      and g.is_core = true
    order by gm.created_at desc
    limit 1
  ) reactor_guild on true
  left join public.profile_equipped_cosmetics pec on pec.profile_id = reactor.id
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
  where pr.target_profile_id = p_target_profile_id
    and reactor.approval_status = 'approved'
    and (normalized_reaction_type is null or pr.reaction_type = normalized_reaction_type);

  return jsonb_build_object(
    'reaction_type', normalized_reaction_type,
    'reactions', reactions_payload
  );
end;
$$;

revoke all on function public.get_guild_wall_feed(uuid, integer, timestamptz) from public, anon;
revoke all on function public.create_wall_post(uuid, text) from public, anon;
revoke all on function public.delete_wall_post(uuid) from public, anon;
revoke all on function public.moderate_delete_wall_post(uuid) from public, anon;
revoke all on function public.pin_wall_post(uuid) from public, anon;
revoke all on function public.unpin_wall_post(uuid) from public, anon;
revoke all on function public.create_wall_comment(uuid, text) from public, anon;
revoke all on function public.delete_wall_comment(uuid) from public, anon;
revoke all on function public.moderate_delete_wall_comment(uuid) from public, anon;
revoke all on function public.react_to_wall_post(uuid, text) from public, anon;
revoke all on function public.remove_wall_post_reaction(uuid, text) from public, anon;
revoke all on function public.react_to_wall_comment(uuid, text) from public, anon;
revoke all on function public.remove_wall_comment_reaction(uuid, text) from public, anon;
revoke all on function public.get_wall_reaction_details(text, uuid, text) from public, anon;
revoke all on function public.get_public_member_profile(text) from public, anon;
revoke all on function public.react_to_public_profile(uuid, text) from public, anon;
revoke all on function public.remove_public_profile_reaction(uuid, text) from public, anon;
revoke all on function public.get_public_profile_reaction_details(uuid, text) from public, anon;

grant execute on function public.get_guild_wall_feed(uuid, integer, timestamptz) to authenticated;
grant execute on function public.create_wall_post(uuid, text) to authenticated;
grant execute on function public.delete_wall_post(uuid) to authenticated;
grant execute on function public.moderate_delete_wall_post(uuid) to authenticated;
grant execute on function public.pin_wall_post(uuid) to authenticated;
grant execute on function public.unpin_wall_post(uuid) to authenticated;
grant execute on function public.create_wall_comment(uuid, text) to authenticated;
grant execute on function public.delete_wall_comment(uuid) to authenticated;
grant execute on function public.moderate_delete_wall_comment(uuid) to authenticated;
grant execute on function public.react_to_wall_post(uuid, text) to authenticated;
grant execute on function public.remove_wall_post_reaction(uuid, text) to authenticated;
grant execute on function public.react_to_wall_comment(uuid, text) to authenticated;
grant execute on function public.remove_wall_comment_reaction(uuid, text) to authenticated;
grant execute on function public.get_wall_reaction_details(text, uuid, text) to authenticated;
grant execute on function public.get_public_member_profile(text) to authenticated;
grant execute on function public.react_to_public_profile(uuid, text) to authenticated;
grant execute on function public.remove_public_profile_reaction(uuid, text) to authenticated;
grant execute on function public.get_public_profile_reaction_details(uuid, text) to authenticated;
