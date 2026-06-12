# Roadmap

## Complete

- Milestone 30B: TCG/Card Collection catalog + inventory backend implemented, locally validated, and production-applied.
- Milestone 30C-A: Owner-only TCG Card Collection preview UI deployed.
- Milestone 30C-A2: Owner-only TCG smoke grant control deployed.
- Milestone 30C-B: TCG album visual polish and repo-served art asset pipeline notes.
- Milestone 30C-C: First five temporary smoke-card art assets added for Owner preview testing.
- Milestone 30C-D: Full Season 0 temporary art import for all 50 catalog cards.
- Milestone 30D-A: Owner-only TCG test pack backend/RPC production-applied.
- Milestone 30D-B: Owner-only TCG pack preview UI deployed.
- Milestone 30E-A: Owner-only TCG shop/economy backend/RPC production-applied.
- Milestone 30E-B: Owner-only TCG shop/economy UI preview deployed.
- Milestone 30E-C: Owner-only TCG shop/pack UX polish deployed.
- Milestone 30E-D: Owner-only compact TCG hub/window layout deployed.
- Milestone 30F-A: Owner-only TCG balance/economy/pack analytics backend production-applied.
- Milestone 30F-B: Owner-only TCG pack inventory backend production-applied.
- Milestone 30F-C: Owner-only TCG pack inventory/open-owned-pack UI deployed.
- Milestone 30F-D: Temporary TCG pack-front and card-back assets deployed.
- Milestone 30F-E: Compact TCG pack inventory UI hotfix deployed.
- Milestone 30F-F: TCG pack/reveal UI polish hotfix deployed.
- Milestone 30F-G: TCG pack front + real card-back asset wire-up deployed.
- Milestone 30F-H: Owner-only TCG UI polish pass deployed.
- Milestone 30F-I: TCG windowed Packs/Shop layout hotfix deployed.
- Milestone 30F-J: TCG slim Packs/Shop windows + wallet HUD polish deployed.
- Milestone 30F-K: TCG wallet icon HUD hotfix deployed.
- Milestone 30F-L: TCG Packs/Shop centering alignment hotfix deployed.
- Milestone 30F-M: Owner-only TCG Balance Report UI deployed.
- Milestone 30G-A: TCG Economy / Drop Balance Planning completed with Current Low-Rate Baseline as the primary simulation model.
- Milestone 30G-B: TCG Balance Simulation for Current Low-Rate Baseline completed.
- Milestone 30G-C: TCG Duplicate Sell / Burn / Pity Simulation completed.
- Milestone 30G-D: TCG Duplicate Economy Design Specification completed.
- Milestone 30G-E: TCG Duplicate Economy Backend/RPC/RLS Implementation Plan completed.
- Milestone 30G-F1: TCG Fragments / Duplicate Burn / Crafting backend implemented, locally validated, and production-applied.
- Milestone 30G-F2: TCG Soft Pity backend counters and owned-pack integration implemented, locally validated, and production-applied.
- Milestone 30G-F3: Owner-only TCG Craft UI for fragments, duplicate burn, missing-card crafting, and pity status implemented.
- Milestone 30A: TCG/Card Collection planning.
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
- Milestone 13A: production Supabase migrations, schema/RLS/seed verification, and manual Owner bootstrap.
- Milestone 13B: Vercel deployment, Supabase Auth URL configuration, and production smoke/security validation.
- Milestone 14A: docs-only production hardening and cleanup policy.

## Recommended Next

Milestone 30C-A Owner-only Card Collection preview is live, Milestone 30C-A2 adds a controlled Owner-only smoke grant button, Milestone 30C-B improves the album visuals, Milestone 30C-C/30C-D add temporary art coverage, Milestone 30D-A adds the Owner-only backend/RPC foundation for test pack opening, Milestone 30D-B adds the Owner-only pack preview UI, Milestone 30E-A adds the Owner-only backend/RPC foundation for test coins, wallet ledger, Owner test shop listing, and Owner test pack purchase, Milestone 30E-B adds the Owner-only shop/economy UI preview, Milestone 30E-C polishes the Owner shop/wallet/pack reveal UX, Milestone 30E-D refactors `/tcg` into a compact Album/Packs/Shop/Owner Lab hub, Milestone 30F-A adds the Owner-only read-only balance/economy/pack analytics RPC, Milestone 30F-B adds Owner-only pack inventory backend support, Milestone 30F-C deploys the Owner-only frontend flow where Shop buys packs into inventory and Packs opens owned packs later, Milestone 30F-D deploys temporary pack-front/card-back assets for that flow, Milestone 30F-E deploys the compact pack UI hotfix, Milestone 30F-F deploys the pack/reveal UI polish hotfix, Milestone 30F-G deploys the replaced pack-front and real card-back asset wire-up, Milestone 30F-H deploys the Owner-only `/tcg` UI polish pass, Milestone 30F-I deploys compact windowed Packs/Shop cards, Milestone 30F-J deploys slimmer Packs/Shop windows plus a wallet HUD polish, Milestone 30F-K replaces the wallet HUD glowing square with a CSS wallet/currency icon, Milestone 30F-L centers the Packs and Shop item windows inside their active panels, Milestone 30F-M deploys the Owner-only Balance tab using `tcg_owner_get_balance_report()`, Milestone 30G-A documents balance planning around the current low-rate production baseline, Milestone 30G-B completes the local simulation for that baseline, Milestone 30G-C completes duplicate sell/burn/pity simulation, Milestone 30G-D specifies the future duplicate economy design, Milestone 30G-E plans the backend/RPC/RLS implementation, Milestone 30G-F1 implements, local-validates, and production-applies Anteiku Fragments, duplicate burn, duplicate summary, and missing-card crafting backend support, Milestone 30G-F2 implements, local-validates, and production-applies backend-only Soft Pity counters for owned-pack openings, and Milestone 30G-F3 adds the Owner-only Craft window for fragments, duplicate burn, missing-card crafting, and pity review. Member-facing shop/economy release, payments, trading, marketplace, and battles remain out of scope until separately planned.

Strong candidates:

- Owner manual mutation smoke for the 30G-F3 Craft window.
- Member-safe TCG release planning after Owner review and test-control hiding.
- Owner visual review of the Balance tab, centered Packs/Shop item windows, and wallet icon HUD.
- Controlled Owner click-through smoke for the deployed pack inventory loop when mutation testing is approved.
- Optional Owner hub/album/shop UX polish after manual smoke feedback.
- Replace temporary smoke art with approved final card art under `public/assets/tcg/art/`.
- Plan member-release gating separately after Owner acceptance.
- Manual Vercel GitHub App restriction to only `Ultimate99/anteiku-guild-manager`.
- Controlled production test member cleanup planning.
- Staging Supabase + Vercel Preview environment planning.

Production operations should follow:

- [DEPLOYMENT.md](DEPLOYMENT.md)
- [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md)

## Later Candidates

- Reapply UI/RPC integration.
- Weekly CP snapshot/growth report UI.
- Suspended/left/rejected member management.
- Guild/subguild management UI.
- Avatar editing.

Each future feature should receive a dedicated plan and security review before implementation.
