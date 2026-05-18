-- Anteiku Guild Manager - Owner Bootstrap TEMPLATE
-- MANUAL TEMPLATE ONLY. This file is intentionally stored under supabase/templates/, not supabase/migrations/.
-- It is NOT applied automatically by Supabase migrations.
-- It requires a real Supabase Auth user id supplied by the project owner before use.
-- Do not run this file as-is.

do $$
begin
  raise exception 'Manual template only. Replace placeholders with a real Supabase Auth user id and remove this guard before running intentionally.';
end;
$$;

/*
Manual owner bootstrap plan:

1. Create the first user through Supabase Auth.
2. Copy that real auth.users.id.
3. Replace the placeholders below.
4. Review the selected initial guild id.
5. Run manually in a controlled SQL editor/session.
6. Never expose public/self-service Owner creation.

Placeholders:
- __OWNER_AUTH_USER_ID__
- __OWNER_USERNAME_AND_SLUG__
- __OWNER_IGN__
- __INITIAL_OWNER_GUILD_ID__

Suggested initial guild id, if Owner should start in Anteiku:
- 00000000-0000-0000-0000-000000000101

Example template, intentionally commented out:

begin;

insert into public.profiles (
  id,
  username,
  profile_slug,
  ign,
  approval_status,
  approved_at,
  approved_by
)
values (
  '__OWNER_AUTH_USER_ID__'::uuid,
  '__OWNER_USERNAME_AND_SLUG__',
  '__OWNER_USERNAME_AND_SLUG__',
  '__OWNER_IGN__',
  'approved',
  now(),
  null
)
on conflict (id) do update
set
  username = excluded.username,
  profile_slug = excluded.profile_slug,
  ign = excluded.ign,
  approval_status = 'approved',
  approved_at = coalesce(public.profiles.approved_at, now()),
  updated_at = now();

insert into public.guild_memberships (
  profile_id,
  guild_id,
  role,
  membership_status,
  is_primary,
  assigned_by
)
values (
  '__OWNER_AUTH_USER_ID__'::uuid,
  '__INITIAL_OWNER_GUILD_ID__'::uuid,
  'owner',
  'active',
  true,
  '__OWNER_AUTH_USER_ID__'::uuid
)
on conflict (profile_id, guild_id) do update
set
  role = 'owner',
  membership_status = 'active',
  is_primary = true,
  assigned_by = excluded.assigned_by,
  updated_at = now();

insert into public.audit_logs (
  actor_profile_id,
  target_profile_id,
  guild_id,
  action,
  entity_table,
  entity_id,
  metadata
)
values (
  '__OWNER_AUTH_USER_ID__'::uuid,
  '__OWNER_AUTH_USER_ID__'::uuid,
  '__INITIAL_OWNER_GUILD_ID__'::uuid,
  'owner_bootstrapped',
  'guild_memberships',
  '__OWNER_AUTH_USER_ID__'::uuid,
  jsonb_build_object('manual_bootstrap', true)
);

commit;
*/
