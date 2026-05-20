# Roles And Permissions

Role, guild, and permission behavior is implemented through Supabase RLS/RPCs and frontend UX gating. Sensitive enforcement must remain database-side; frontend conditionals are only presentation.

Production deployment is live at `https://anteiku-guild-manager.vercel.app`. Role and permission enforcement remains database-side through Supabase RLS/RPCs.

Roles:

- Owner
- Leader
- Vice
- Admin
- Member

## Role Defaults

Owner:

- Global control.
- Can assign Owner, Leader, Vice, Admin, and Member roles.
- Global CP view/update.
- Can grant Admin CP permissions.
- Can reset any username/profile slug.
- Can edit any member IGN.
- Can read all audit logs.

Leader:

- Guild-scoped control.
- Automatic `view_cp` and `update_cp` inside assigned guild.
- Can promote members up to Admin only.
- Cannot assign Vice, Leader, or Owner.
- Can reset username/profile slug inside assigned guild.
- Can edit member IGN inside assigned guild.
- Can read scoped audit logs.
- Cannot grant Admin CP permissions in v1.

Vice:

- Near-Leader guild-scoped control.
- Automatic `view_cp` and `update_cp` inside assigned guild.
- Can promote members up to Admin only.
- Cannot assign Vice, Leader, or Owner.
- Can reset username/profile slug inside assigned guild.
- Can edit member IGN inside assigned guild.
- Can read scoped audit logs.
- Cannot grant Admin CP permissions in v1.

Admin:

- Explicit checkbox permissions only.
- No automatic CP access.
- CP access requires `view_cp` and/or `update_cp`.
- Owner only can grant Admin CP permissions in v1.
- Slug reset requires `reset_profile_slug`.
- Member IGN edit requires `edit_member_ign`.
- Audit log access requires `view_audit_logs`.

Member:

- Approved normal user.
- Can edit own IGN.
- Can vote on active GvG events in scope.
- Cannot access CP.
- Cannot change username/profile slug.

## Permission Keys

- `approve_members`
- `manage_members`
- `manage_roles`
- `manage_gvg`
- `view_cp`
- `update_cp`
- `manage_guilds`
- `view_audit_logs`
- `reset_profile_slug`
- `edit_member_ign`

Initial Owner bootstrap must be manual-controlled with a known Supabase Auth user id. It must not be exposed through frontend UI or normal public RPCs.
## Milestone 7 Role And Transfer Rules

Normal app role assignment:
- Owner can assign `member`, `admin`, `vice`, and `leader`.
- Owner cannot assign `owner` through normal app RPC.
- Leader/Vice can assign `member` and `admin` only inside assigned guild scope.
- Admin with `manage_roles` can assign `member` and `admin` only inside assigned guild scope.
- Admin without `manage_roles` cannot assign roles.
- Member cannot assign roles.

Owner assignment:
- Owner assignment remains manual-only.
- No frontend UI or normal public app RPC should expose Owner assignment.

Guild transfer:
- Owner-only in v1.
- Leader/Vice/Admin cannot transfer members between guilds in v1.
- Transferred member role resets to `member`.
