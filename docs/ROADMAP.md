# Roadmap

## Complete

- Milestone 1: React + Vite scaffold and documentation base.
- Milestone 2: Supabase schema/RLS plan, migrations, and local validation.
- Milestone 3: Supabase auth, registration, and pending/rejected/suspended gates.
- Milestone 4: Owner bootstrap validation and registration approval/rejection flow.
- Milestone 5: member own-profile IGN editing.
- Milestone 6: Admin member management for active approved members.
- Milestone 7: role/guild management with Owner-only guild transfer.
- Milestone 8: protected Admin CP management and leaderboard.
- Milestone 9: Admin permission checkbox management.
- Milestone 10: GvG event management and one-vote-per-event/member voting.
- Milestone 11A: backend audit-log read hardening and CP metadata redaction.
- Milestone 11B: frontend read-only Audit Log Viewer using `get_audit_logs`.
- Milestone 12: docs-only production readiness runbook/checklist.

## Recommended Next

Milestone 13 should be production Supabase + Vercel setup only after explicit approval.

Milestone 13 should follow:

- [DEPLOYMENT.md](DEPLOYMENT.md)
- [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md)

## Later Candidates

- Reapply UI/RPC integration.
- Weekly CP snapshot/growth report UI.
- Suspended/left/rejected member management.
- Guild/subguild management UI.
- Avatar editing.

Each future feature should receive a dedicated plan and security review before implementation.
