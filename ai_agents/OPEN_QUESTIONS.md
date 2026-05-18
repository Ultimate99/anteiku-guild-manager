# Open Questions

Milestone 2 schema/RLS planning questions resolved on 2026-05-14:

- CP lives outside `profiles` in `member_cp` and `cp_snapshots`.
- `profiles.id` directly references `auth.users(id)`.
- Owner only can grant Admin `view_cp` and `update_cp`.
- Leader/Vice can promote members up to Admin only inside assigned guild.
- Username/profile slug format and lowercase normalization are decided.
- Username and profile slug are identical at v1 registration.
- Owner bootstrap uses migration-controlled explicit known auth user id.
- Rejected users reapply using the same profile row.
- Global GvG includes all approved users with active primary memberships.
- Audit log visibility is Owner all, Leader/Vice scoped by default, Admin explicit `view_audit_logs`.

Remaining open questions:

- What known Supabase Auth user id should be used for the initial Owner bootstrap?
- Should React Router be approved for real routing?
- Which test framework should be approved for frontend and policy testing?
- Should local Supabase CLI/policy tests be used for RLS validation?
- What exact max length should be used for `absence_reason` and `reapply_note`?
