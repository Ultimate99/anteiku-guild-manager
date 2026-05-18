# GvG System

GvG persistence is implemented and live-browser validated as of Milestone 10.

Milestone 12 did not change GvG logic. This document records the implemented security expectations that must be preserved during production deployment.

## Event Scope

The schema should support:

- guild-specific GvG events
- global/org-wide GvG events

The current UI supports guild-scoped event management and voting flows validated in local browser testing.

Global GvG events include all approved users with active primary memberships.

## Implemented Flow

1. Admin, Vice, Leader, or Owner creates or enables a GvG event according to approved permissions.
2. Approved members select `I participate` or `Absent`.
3. If absent, members may add a reason.
4. Admin panel shows present list, absent list, reasons, totals, and participation percentage.

Required database rule, implemented through the unique index:

```sql
unique (gvg_event_id, profile_id)
```

Switching between present and absent must update the existing row.

## v1 Vote Correction Rule

- Members can update only their own vote while the event is active.
- Admins/leaders can view results and absence reasons.
- Admins/leaders cannot edit or remove member votes in v1.
- Future Owner/Leader vote correction would require audit logging.

## Production Validation

- GvG event management must use approved RPCs/safe reads.
- Member voting must use `submit_gvg_vote`.
- Vote switching must keep one row per event/profile.
- Direct frontend writes to `gvg_votes` must remain absent.
- GvG actions must not trigger CP RPC/table calls.

## Constraints

- `vote_status` must be `present` or `absent`.
- `absence_reason` must have a max length.
- Switching to `present` should clear absence reason in the safe submit/update function.
