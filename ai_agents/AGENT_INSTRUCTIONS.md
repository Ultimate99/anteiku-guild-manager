# Agent Instructions

- Keep CP private.
- Do not expose CP values to members in UI, queries, public views, cached state, or docs examples.
- Do not treat frontend hiding as security.
- Pending users must not access member or admin areas after real auth is implemented.
- Username/profile slug is locked after registration for normal users.
- IGN can be changed by the player or an authorized admin.
- GvG voting must use one vote per user per event.
- Vote switching must update the existing vote.
- Absence reasons must be visible to authorized admins.
- Ask before schema, RLS, role model, dependency, or major architecture changes.
- Update `ai_agents/` after meaningful changes.
