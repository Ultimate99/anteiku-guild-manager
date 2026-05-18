-- Anteiku Guild Manager - Seed Core Data
-- Safe migration: inserts core guilds and approved permission keys.
-- Does not create users, memberships, CP records, or an Owner.

insert into public.guilds (id, slug, name, parent_guild_id, is_core, status)
values
  ('00000000-0000-0000-0000-000000000101', 'anteiku', 'Anteiku', null, true, 'active'),
  ('00000000-0000-0000-0000-000000000102', 'anteiku-re', 'Anteiku:Re', null, true, 'active'),
  ('00000000-0000-0000-0000-000000000103', 'anteiku-rose', 'Anteiku:Rose', null, true, 'active'),
  ('00000000-0000-0000-0000-000000000104', 'anteiku-goat', 'Anteiku:Goat', null, true, 'active')
on conflict (slug) do update
set
  name = excluded.name,
  is_core = excluded.is_core,
  status = excluded.status,
  updated_at = now();

insert into public.permission_catalog (key, label, description, is_sensitive)
values
  ('approve_members', 'Approve members', 'Approve or reject pending/reapplying members inside scope.', false),
  ('manage_members', 'Manage members', 'Manage member status and basic member records inside scope.', false),
  ('manage_roles', 'Manage roles', 'Assign allowed roles inside scope.', false),
  ('manage_gvg', 'Manage GvG', 'Create and update GvG events and view scoped results.', false),
  ('view_cp', 'View CP', 'View protected CP values and CP leaderboards inside scope.', true),
  ('update_cp', 'Update CP', 'Update protected CP values and capture CP snapshots inside scope.', true),
  ('manage_guilds', 'Manage guilds', 'Manage guild/subguild records where allowed.', false),
  ('view_audit_logs', 'View audit logs', 'Read scoped audit logs.', false),
  ('reset_profile_slug', 'Reset profile slug', 'Reset username/profile slug for members inside scope.', false),
  ('edit_member_ign', 'Edit member IGN', 'Edit member IGN for members inside scope.', false)
on conflict (key) do update
set
  label = excluded.label,
  description = excluded.description,
  is_sensitive = excluded.is_sensitive;
