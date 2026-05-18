# Decisions

## Milestone 1 Scaffold

- Use React + Vite.
- Use plain CSS.
- Do not add Tailwind yet.
- Include Supabase JS only as an environment-backed placeholder.
- Do not implement real auth, database schema, RLS, CP logic, admin permissions, or GvG persistence.
- Use an original abstract SVG mark instead of copyrighted assets.

## Milestone 2 Schema/RLS Spec

- `profiles.id` references `auth.users(id)` directly.
- Do not use a separate `auth_user_id` column for v1.
- CP is not stored in `profiles`.
- Current CP is stored in `member_cp`.
- CP history/growth is stored in `cp_snapshots`.
- Members cannot directly select CP tables.
- CP access uses permission-checked RPC/views.
- Owner has global CP view/update.
- Leader/Vice have automatic guild-scoped CP view/update.
- Admin has no automatic CP access.
- Only Owner can grant Admin `view_cp` and `update_cp` in v1.
- v1 enforces one active primary guild membership per user.
- GvG supports guild-specific and global events.
- v1 GvG UI can start guild-specific.
- Username and profile slug are identical at registration and normalized lowercase.
- Username/profile slug format is lowercase letters, numbers, underscore, hyphen, length 3-32, starts alphanumeric, does not end with hyphen/underscore.
- Owner can reset any slug; Leader/Vice scoped; Admin requires `reset_profile_slug`.
- Users can edit own IGN; Owner/Leader/Vice scoped; Admin requires `edit_member_ign`.
- Rejected users reapply using the same profile row.
- Core guild names are public during registration.
- Multiple Owners are supported by schema, but initial Owner bootstrap is explicit migration/manual SQL with a known auth user id.
- Manual weekly CP snapshots are v1; scheduled automation can come later.
- Admins/leaders do not edit/remove member GvG votes in v1.
- Avoid hard deletes for important records; use status/archive.
