# Role Permissions

## Milestone 19B CP Update Window Permissions

Milestone 19B reuses the existing CP update authority model for CP Update Window management.

Can open/close CP Update Windows:
- Owner globally.
- Leader/Vice in their guild scope.
- Admin only with scoped `update_cp`.

Cannot open/close CP Update Windows:
- Admin without scoped `update_cp`.
- Members.
- Pending/rejected users.
- Hard-blocked roster/membership states.

Member CP self-submit eligibility:
- `active`, `trial`, and `pending_transfer` members can submit their own CP during an applicable open window.
- `inactive` and `on_break` members cannot submit CP by default.
- `suspended`, `left`, and `kicked` users remain blocked.

Important boundary:
- These permissions do not grant members CP roster, leaderboard, snapshot, or other-member CP visibility.

## Milestone 15A Member Status Rules

Roster status is live in production as of Milestone 15E. It is a lifecycle concept, not a replacement for approval or hard membership security.

Status meanings:
- `active`: normal access, reliable participant.
- `trial`: normal access, marked as trial.
- `pending_transfer`: normal access, flagged for staff review.
- `inactive`: can log in and view own profile; excluded from GvG expectation/eligibility.
- `on_break`: can log in and view own profile; excluded from GvG expectation/eligibility.
- `suspended`: blocked from member/admin areas; shows suspension notice in future frontend work.
- `left`: blocked from member/admin areas; preserved for history.
- `kicked`: blocked from member/admin areas; preserved for history.

Status-changing authority:
- Owner can set all statuses globally, with last-active-Owner protection.
- Leader/Vice can set scoped non-Owner statuses.
- Admin with `manage_members` can set only `active`, `trial`, `inactive`, `on_break`, and `pending_transfer`.
- Admin cannot set `suspended`, `left`, or `kicked`.
- Admin cannot affect Owners or change their own status.
- Members cannot change roster status.

Hard-block mapping:
- `suspended` sets `membership_status = 'suspended'`.
- `left` sets `membership_status = 'left'`.
- `kicked` sets `membership_status = 'left'`; `rejected` remains for registration/reapply.

## Milestone 7 Role And Transfer Rules

Normal app role assignment:

- Owner can assign `member`, `admin`, `vice`, and `leader`.
- Owner cannot assign `owner` through normal app RPC.
- Leader/Vice can assign `member` and `admin` inside their guild scope.
- Admin with `manage_roles` can assign `member` and `admin` inside their guild scope.
- Admin without `manage_roles` cannot assign roles.
- Member cannot assign roles.

Guild transfer:

- Owner-only in v1.
- Leader/Vice cannot transfer members between guilds in v1.
- Admin cannot transfer members between guilds in v1, even with `manage_members`.
- Transferred member role resets to `member`.
- Owner assignment remains manual-only.

Milestone 2 role direction was later implemented through Supabase migrations, RLS, and RPCs.

## Roles

- Owner
- Leader
- Vice
- Admin
- Member

## Role Defaults

### Owner

- Global organization control.
- Can assign Owner, Leader, Vice, Admin, and Member roles.
- Can grant all Admin permissions.
- Only Owner can grant Admin `view_cp` and `update_cp` in v1.
- Global CP visibility and CP update access.
- Can reset any username/profile slug.
- Can edit any member IGN.
- Can read all audit logs.

Schema supports multiple Owners, but initial Owner creation must use migration-controlled explicit bootstrap with a known auth user id. There is no public/self-service Owner creation.

### Leader

- Broad control inside assigned guild.
- Automatic `view_cp` and `update_cp` inside assigned guild.
- Can promote members up to Admin only inside assigned guild.
- Cannot assign Vice, Leader, or Owner.
- Can reset username/profile slug for members inside assigned guild.
- Can edit member IGN inside assigned guild.
- Can read scoped guild audit logs by default.
- Cannot grant Admin `view_cp` or `update_cp` in v1.

### Vice

- Near-Leader control inside assigned guild.
- Automatic `view_cp` and `update_cp` inside assigned guild.
- Can promote members up to Admin only inside assigned guild.
- Cannot assign Vice, Leader, or Owner.
- Can reset username/profile slug for members inside assigned guild.
- Can edit member IGN inside assigned guild.
- Can read scoped guild audit logs by default.
- Cannot grant Admin `view_cp` or `update_cp` in v1.

### Admin

- No automatic CP access.
- Uses explicit checkbox permissions.
- Can reset username/profile slug only with `reset_profile_slug`.
- Can edit member IGN only with `edit_member_ign`.
- Can read scoped audit logs only with `view_audit_logs`.
- Cannot grant permissions.

### Member

- Approved normal user.
- Can edit own IGN.
- Can vote on active GvG events in scope.
- No CP access.
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

## Promotion Limits

- Owner can assign any role.
- Leader/Vice can promote members up to Admin only inside assigned guild.
- Admin cannot promote users.
- Member cannot promote users.
