-- Anteiku Guild Manager - Guild Wall MVP
-- Safe migration: adds text-only, guild-scoped social feed tables and
-- RPC-only post/comment/reaction/moderation flows. Normal protected CP in
-- member_cp/cp_snapshots is not read or exposed.

create table if not exists public.wall_posts (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references public.guilds(id) on delete restrict,
  author_profile_id uuid not null references public.profiles(id) on delete restrict,
  content text not null,
  is_pinned boolean not null default false,
  is_locked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid references public.profiles(id) on delete set null,
  constraint wall_posts_content_length_chk check (
    char_length(btrim(content)) between 1 and 1000
  )
);

create table if not exists public.wall_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.wall_posts(id) on delete cascade,
  guild_id uuid not null references public.guilds(id) on delete restrict,
  author_profile_id uuid not null references public.profiles(id) on delete restrict,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid references public.profiles(id) on delete set null,
  constraint wall_comments_content_length_chk check (
    char_length(btrim(content)) between 1 and 500
  )
);

create table if not exists public.wall_post_reactions (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.wall_posts(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  reaction_type text not null,
  created_at timestamptz not null default now(),
  constraint wall_post_reactions_type_chk check (
    reaction_type in ('like', 'fire', 'coffee', 'skull', 'trophy')
  )
);

create table if not exists public.wall_comment_reactions (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.wall_comments(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  reaction_type text not null,
  created_at timestamptz not null default now(),
  constraint wall_comment_reactions_type_chk check (
    reaction_type in ('like', 'fire', 'coffee', 'skull', 'trophy')
  )
);

create index if not exists wall_posts_guild_feed_idx
  on public.wall_posts (guild_id, is_pinned desc, created_at desc)
  where deleted_at is null;

create index if not exists wall_posts_author_idx
  on public.wall_posts (author_profile_id, created_at desc);

create index if not exists wall_comments_post_created_idx
  on public.wall_comments (post_id, created_at asc)
  where deleted_at is null;

create index if not exists wall_comments_author_idx
  on public.wall_comments (author_profile_id, created_at desc);

create unique index if not exists wall_post_reactions_one_per_type_uidx
  on public.wall_post_reactions (post_id, profile_id, reaction_type);

create unique index if not exists wall_comment_reactions_one_per_type_uidx
  on public.wall_comment_reactions (comment_id, profile_id, reaction_type);

drop trigger if exists set_wall_posts_updated_at on public.wall_posts;
create trigger set_wall_posts_updated_at
before update on public.wall_posts
for each row
execute function public.set_updated_at();

drop trigger if exists set_wall_comments_updated_at on public.wall_comments;
create trigger set_wall_comments_updated_at
before update on public.wall_comments
for each row
execute function public.set_updated_at();

alter table public.wall_posts enable row level security;
alter table public.wall_comments enable row level security;
alter table public.wall_post_reactions enable row level security;
alter table public.wall_comment_reactions enable row level security;

revoke all on public.wall_posts from public, anon, authenticated;
revoke all on public.wall_comments from public, anon, authenticated;
revoke all on public.wall_post_reactions from public, anon, authenticated;
revoke all on public.wall_comment_reactions from public, anon, authenticated;

create or replace function private.guild_wall_primary_guild_id(p_profile_id uuid)
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select gm.guild_id
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.profile_id = p_profile_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
    and gm.roster_status in ('active', 'trial', 'pending_transfer', 'inactive', 'on_break')
    and p.approval_status = 'approved'
  limit 1;
$$;

create or replace function private.has_guild_wall_view_access(p_profile_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_profile_id)
    or exists (
      select 1
      from public.guild_memberships gm
      join public.profiles p on p.id = gm.profile_id
      where gm.profile_id = p_profile_id
        and gm.guild_id = p_guild_id
        and gm.membership_status = 'active'
        and gm.roster_status in ('active', 'trial', 'pending_transfer', 'inactive', 'on_break')
        and p.approval_status = 'approved'
    );
$$;

create or replace function private.has_guild_wall_action_access(p_profile_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_profile_id)
    or exists (
      select 1
      from public.guild_memberships gm
      join public.profiles p on p.id = gm.profile_id
      where gm.profile_id = p_profile_id
        and gm.guild_id = p_guild_id
        and gm.membership_status = 'active'
        and gm.roster_status in ('active', 'trial', 'pending_transfer')
        and p.approval_status = 'approved'
    );
$$;

create or replace function private.can_moderate_guild_wall(p_profile_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_profile_id)
    or (
      p_guild_id is not null
      and (
        private.has_role(p_profile_id, p_guild_id, array['leader', 'vice'])
        or private.has_permission(p_profile_id, p_guild_id, 'manage_members')
      )
    );
$$;

create or replace function private.is_valid_wall_reaction(p_reaction_type text)
returns boolean
language sql
immutable
set search_path = pg_catalog
as $$
  select p_reaction_type in ('like', 'fire', 'coffee', 'skull', 'trophy');
$$;

create or replace function private.validate_wall_content(
  p_content text,
  p_max_length integer
)
returns text
language plpgsql
immutable
set search_path = pg_catalog
as $$
declare
  normalized_content text := btrim(coalesce(p_content, ''));
begin
  if char_length(normalized_content) < 1 then
    raise exception 'Content is required.';
  end if;

  if char_length(normalized_content) > p_max_length then
    raise exception 'Content is too long.';
  end if;

  return normalized_content;
end;
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
  actor_id uuid := auth.uid();
  normalized_content text;
  new_post_id uuid;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_guild_id is null then
    raise exception 'Guild is required.';
  end if;

  if not exists (
    select 1 from public.guilds g
    where g.id = p_guild_id
      and g.status = 'active'
      and g.is_core = true
  ) then
    raise exception 'Active guild not found.';
  end if;

  if not private.has_guild_wall_action_access(actor_id, p_guild_id) then
    raise exception 'Not authorized to post on this guild wall.';
  end if;

  normalized_content := private.validate_wall_content(p_content, 1000);

  insert into public.wall_posts (guild_id, author_profile_id, content)
  values (p_guild_id, actor_id, normalized_content)
  returning id into new_post_id;

  perform private.write_audit_log(
    actor_id,
    actor_id,
    p_guild_id,
    'wall_post_created',
    'wall_posts',
    new_post_id,
    jsonb_build_object('content_length', char_length(normalized_content))
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
  actor_id uuid := auth.uid();
  target_post public.wall_posts%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if target_post.author_profile_id <> actor_id then
    raise exception 'Only the post author can delete this post.';
  end if;

  if not private.has_guild_wall_action_access(actor_id, target_post.guild_id) then
    raise exception 'Not authorized to delete this post.';
  end if;

  update public.wall_posts
  set deleted_at = now(),
      deleted_by = actor_id,
      is_pinned = false
  where id = target_post.id;

  perform private.write_audit_log(
    actor_id,
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
  actor_id uuid := auth.uid();
  target_post public.wall_posts%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if not private.can_moderate_guild_wall(actor_id, target_post.guild_id) then
    raise exception 'Not authorized to moderate this guild wall.';
  end if;

  update public.wall_posts
  set deleted_at = now(),
      deleted_by = actor_id,
      is_pinned = false
  where id = target_post.id;

  perform private.write_audit_log(
    actor_id,
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
  actor_id uuid := auth.uid();
  target_post public.wall_posts%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if not private.can_moderate_guild_wall(actor_id, target_post.guild_id) then
    raise exception 'Not authorized to pin this post.';
  end if;

  update public.wall_posts
  set is_pinned = true
  where id = target_post.id;

  perform private.write_audit_log(
    actor_id,
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
  actor_id uuid := auth.uid();
  target_post public.wall_posts%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_post
  from public.wall_posts
  where id = p_post_id
    and deleted_at is null;

  if not found then
    raise exception 'Post not found.';
  end if;

  if not private.can_moderate_guild_wall(actor_id, target_post.guild_id) then
    raise exception 'Not authorized to unpin this post.';
  end if;

  update public.wall_posts
  set is_pinned = false
  where id = target_post.id;

  perform private.write_audit_log(
    actor_id,
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
  actor_id uuid := auth.uid();
  target_post public.wall_posts%rowtype;
  normalized_content text;
  new_comment_id uuid;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

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

  if not private.has_guild_wall_action_access(actor_id, target_post.guild_id) then
    raise exception 'Not authorized to comment on this guild wall.';
  end if;

  normalized_content := private.validate_wall_content(p_content, 500);

  insert into public.wall_comments (post_id, guild_id, author_profile_id, content)
  values (target_post.id, target_post.guild_id, actor_id, normalized_content)
  returning id into new_comment_id;

  perform private.write_audit_log(
    actor_id,
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
  actor_id uuid := auth.uid();
  target_comment public.wall_comments%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_comment
  from public.wall_comments
  where id = p_comment_id
    and deleted_at is null;

  if not found then
    raise exception 'Comment not found.';
  end if;

  if target_comment.author_profile_id <> actor_id then
    raise exception 'Only the comment author can delete this comment.';
  end if;

  if not private.has_guild_wall_action_access(actor_id, target_comment.guild_id) then
    raise exception 'Not authorized to delete this comment.';
  end if;

  update public.wall_comments
  set deleted_at = now(),
      deleted_by = actor_id
  where id = target_comment.id;

  perform private.write_audit_log(
    actor_id,
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
  actor_id uuid := auth.uid();
  target_comment public.wall_comments%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_comment
  from public.wall_comments
  where id = p_comment_id
    and deleted_at is null;

  if not found then
    raise exception 'Comment not found.';
  end if;

  if not private.can_moderate_guild_wall(actor_id, target_comment.guild_id) then
    raise exception 'Not authorized to moderate this guild wall.';
  end if;

  update public.wall_comments
  set deleted_at = now(),
      deleted_by = actor_id
  where id = target_comment.id;

  perform private.write_audit_log(
    actor_id,
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
  actor_id uuid := auth.uid();
  target_post public.wall_posts%rowtype;
  new_reaction_id uuid;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

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

  if not private.has_guild_wall_action_access(actor_id, target_post.guild_id) then
    raise exception 'Not authorized to react on this guild wall.';
  end if;

  insert into public.wall_post_reactions (post_id, profile_id, reaction_type)
  values (target_post.id, actor_id, p_reaction_type)
  on conflict (post_id, profile_id, reaction_type) do nothing
  returning id into new_reaction_id;

  if new_reaction_id is null then
    select id into new_reaction_id
    from public.wall_post_reactions
    where post_id = target_post.id
      and profile_id = actor_id
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
  actor_id uuid := auth.uid();
  target_post public.wall_posts%rowtype;
  removed_reaction_id uuid;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

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

  if not private.has_guild_wall_action_access(actor_id, target_post.guild_id) then
    raise exception 'Not authorized to react on this guild wall.';
  end if;

  delete from public.wall_post_reactions
  where post_id = target_post.id
    and profile_id = actor_id
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
  actor_id uuid := auth.uid();
  target_comment public.wall_comments%rowtype;
  new_reaction_id uuid;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

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

  if not private.has_guild_wall_action_access(actor_id, target_comment.guild_id) then
    raise exception 'Not authorized to react on this guild wall.';
  end if;

  insert into public.wall_comment_reactions (comment_id, profile_id, reaction_type)
  values (target_comment.id, actor_id, p_reaction_type)
  on conflict (comment_id, profile_id, reaction_type) do nothing
  returning id into new_reaction_id;

  if new_reaction_id is null then
    select id into new_reaction_id
    from public.wall_comment_reactions
    where comment_id = target_comment.id
      and profile_id = actor_id
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
  actor_id uuid := auth.uid();
  target_comment public.wall_comments%rowtype;
  removed_reaction_id uuid;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

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

  if not private.has_guild_wall_action_access(actor_id, target_comment.guild_id) then
    raise exception 'Not authorized to react on this guild wall.';
  end if;

  delete from public.wall_comment_reactions
  where comment_id = target_comment.id
    and profile_id = actor_id
    and reaction_type = p_reaction_type
  returning id into removed_reaction_id;

  return removed_reaction_id;
end;
$$;

revoke all on function private.guild_wall_primary_guild_id(uuid) from public, anon, authenticated;
revoke all on function private.has_guild_wall_view_access(uuid, uuid) from public, anon, authenticated;
revoke all on function private.has_guild_wall_action_access(uuid, uuid) from public, anon, authenticated;
revoke all on function private.can_moderate_guild_wall(uuid, uuid) from public, anon, authenticated;
revoke all on function private.is_valid_wall_reaction(text) from public, anon, authenticated;
revoke all on function private.validate_wall_content(text, integer) from public, anon, authenticated;

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
