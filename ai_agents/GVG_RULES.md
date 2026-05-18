# GvG Rules

GvG persistence is implemented and live-browser validated as of Milestone 10.

Milestone 12 did not change GvG logic. These rules must be preserved during future production deployment.

## Event Scope

Support both:

- Guild-specific GvG events.
- Global/org-wide GvG events.

The current UI supports guild-scoped event management and member voting flows.

Global GvG events include all approved users with active primary memberships.

## Required Vote Behavior

- One vote per user per GvG event.
- Use a unique constraint like `unique (gvg_event_id, profile_id)`.
- Changing Present to Absent or Absent to Present updates the existing row.
- It must not create duplicate votes.
- Absence reason is optional for members and visible to authorized admins.
- Admin totals must include present count, absent count, reasons, and participation percentage.

## v1 Vote Correction Rule

- Normal members can update only their own vote while the event is active.
- Admins/leaders can view results and absence reasons.
- Admins/leaders must not edit or remove member votes in v1.
- Future correction feature may allow Owner/Leader correction with audit logging.

## Constraints

- `vote_status` allowed values: `present`, `absent`.
- `absence_reason` must have a max length.
- If vote is switched to `present`, the safe RPC should clear `absence_reason`.

## Production Validation

- Event management must use approved GvG RPCs/safe reads.
- Member voting must use `submit_gvg_vote`.
- Vote switching must keep one row per event/profile.
- Direct frontend writes to `gvg_votes` must remain absent.
- GvG validation must confirm no CP table/RPC calls are triggered by GvG actions.
