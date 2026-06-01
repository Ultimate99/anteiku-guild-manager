# TCG/Card Collection Handoff

Milestone 30A planning is complete. No backend, frontend, SQL, Supabase, or production behavior was changed.

## Current Status

- Milestone 30C-A Owner-only Card Collection preview UI is implemented and deployed in production through commit `dbb67da feat: add owner tcg collection preview`.
- Milestone 30C-A2 Owner-only smoke grant control is implemented and deployed in production through commit `e96a489 feat: add owner tcg smoke grant`.
- Milestone 30C-B TCG album visual polish and repo-served asset-pipeline notes are implemented.
- Milestone 30C-C adds temporary generated art assets for only the five Owner smoke-test cards.
- Milestone 30C-D adds temporary generated art assets for all 50 Season 0 cards.
- Milestone 30D-A adds Owner-only test pack backend/RPC support and is production-applied through `20260601000200_tcg_owner_pack_backend.sql`.
- Milestone 30B backend/RPC foundation is implemented, locally validated, and production-applied through `20260601000100_tcg_30b_catalog_inventory.sql`.
- No member-facing packs, shop, economy, currency, routes beyond `/tcg`, uploads, or Storage have been implemented.
- No member-facing TCG release exists yet. The next step is Owner-only pack UI/testing; frontend must call the backend RPC and never calculate drops client-side.

## Product Direction

TCG should add a fun collection layer without touching protected app systems.

Initial player value:

- Browse a card catalog.
- View own active-profile card inventory.
- Track duplicates and favorites.
- Later showcase selected cards.

Initial staff value:

- Audited card grants for events or corrections.
- Later catalog/pack/admin management tools.

Delayed:

- Member-facing pack opening.
- Member-facing drop rates/balancing.
- Shop/economy.
- Wallets/currency.
- Premium/payment flows.
- Trading/marketplace/battles.

## Security Rules

- Do not expose normal CP.
- Do not use `member_cp`.
- Do not use `cp_snapshots`.
- Do not use normal CP RPCs.
- Do not put service-role keys in frontend.
- Do not trust frontend-selected `profile_id` for player actions.
- Use server-side active-profile helpers for player RPCs.
- Use existing admin permission patterns for admin RPCs.
- Backend decides ownership, pack results, inventory mutation, and future currency changes.
- Frontend displays and calls RPCs only.

## 30B Scope

Implemented backend only:

- `tcg_sets`
- `tcg_rarities`
- `tcg_cards`
- `tcg_player_inventory`
- `tcg_inventory_events`
- RLS policies
- RPC-only inventory mutation
- Catalog/inventory read RPCs
- Admin card grant RPC
- Local validation SQL/checklist

Do not implement:

- UI.
- Member-facing pack opening UI.
- Drop rates.
- Shop.
- Economy.
- Currency/wallets.
- Premium/payments.
- Trading.
- Public collection pages.

## 30C-A Owner Preview UI

Implemented frontend only:

- `/tcg` page.
- Owner-only nav entry.
- Owner-only page guard using the existing active admin context.
- `src/services/tcgService.js` RPC wrappers:
  - `tcgGetCatalog()`
  - `tcgGetMyCollection()`
  - `tcgSetCardFavorite(cardKey, isFavorite)`
- Mobile-first album grid and detail sheet.
- Catalog progress: unique owned, total owned quantity, and favorites.
- Filters: All, Owned, Missing, Favorites, and rarity.
- Missing art placeholder.
- EN/FR/DE i18n keys.

Validation:

- `npm.cmd run build` passed.
- Source checks confirmed no direct TCG table reads/writes, no `member_cp`, no `cp_snapshots`, no normal CP RPCs, no uploads/Storage, and no frontend `tcg_admin_grant_card` call.
- Production bundle verification confirmed `/tcg` serves the app shell and the deployed bundle contains the TCG preview plus read/favorite RPC calls.

Manual smoke still recommended:

- Owner sees Cards nav and can open `/tcg`.
- Non-Owner does not see Cards nav and direct `/tcg` shows the Owner-only blocked state.
- Catalog and collection load for Owner.
- Favorite toggle works only on owned cards.
- Missing art placeholders render cleanly.

## 30C-A2 Owner Smoke Grant Control

Implemented frontend-only:

- Compact Owner-only smoke panel on `/tcg`.
- Fixed smoke grant set:
  - `s0_001_20th_ward_civilian` quantity `3`
  - `s0_019_anteiku_server` quantity `2`
  - `s0_033_young_one_eyed_ghoul` quantity `1`
  - `s0_042_half_mask_awakening` quantity `1`
  - `s0_050_anteiku_origin` quantity `1`
- Fixed reason: `30C-A owner visual smoke`.
- Target profile: current selected active Owner profile from active admin context.
- RPC: `tcg_admin_grant_card`.
- After grant, `/tcg` refetches catalog/collection and switches to Owned filter.
- Button disables as `Smoke cards ready` once the active Owner profile has at least the requested quantities.

Validation:

- `npm.cmd run build` passed.
- Source checks confirmed no direct `tcg_player_inventory` / `tcg_inventory_events` writes, no normal CP paths, no service-role path, and no uploads/Storage.
- Production bundle verification confirmed the button/RPC path is deployed.

Production smoke status:

- The button is ready for controlled Owner click.
- Codex did not perform the production grant mutation during implementation.
- Expected visual-smoke state after one successful click: Unique owned `5 / 50`, total owned quantity `8`, Owned filter `5`, Missing filter `45`.

## 30C-B Album Visual Polish + Asset Pipeline

Implemented frontend-only:

- Premium collectible-card styling for `/tcg`.
- Rarity visual accents for Common, Uncommon, Rare, Epic, Legendary, and Mythic through CSS borders/glow/accent lines.
- Intentional dark missing-art placeholder with card number, rarity, card name, crimson texture, and diagonal locked-state overlay.
- Owned cards receive stronger border/shadow and compact quantity pill.
- Missing cards are dimmed but still readable.
- Favorite action remains compact and accessible.
- Detail sheet inherits rarity styling and has stronger metadata cards.
- Progress cards are more game-stat-like.
- Smoke grant panel remains dashed/testing-only.

Asset location decision:

- Vite/Vercel serves files from `public/` at the site root.
- Real card inner art should be placed in `public/assets/tcg/art/`.
- Example repo path: `public/assets/tcg/art/s0_001_20th_ward_civilian.png`.
- Example served path / database `art_path`: `/assets/tcg/art/s0_001_20th_ward_civilian.png`.
- Reserved future frame overlays can live in `public/assets/tcg/frames/`.
- Added README notes in both folders.
- Do not use Supabase Storage or uploads for the current TCG preview.

Validation:

- `npm.cmd run build` passed.
- Source checks confirmed no direct TCG table reads/writes, no normal CP paths, no service-role path, and no upload/Storage behavior in the TCG page/service path.

## 30C-C First Smoke-Card Art Assets

Implemented asset-only:

- Added five temporary PNG inner-art files from the provided `S0` source set.
- Assets were copied to canonical Vite public paths that already match the Season 0 `tcg_cards.art_path` values.
- No catalog seed, SQL, RPC, service, or frontend behavior changes were needed.
- Other 45 Season 0 cards intentionally continue using the polished placeholder treatment.

Added files:

- `public/assets/tcg/art/s0_001_20th_ward_civilian.png`
- `public/assets/tcg/art/s0_019_anteiku_server.png`
- `public/assets/tcg/art/s0_033_young_one_eyed_ghoul.png`
- `public/assets/tcg/art/s0_042_half_mask_awakening.png`
- `public/assets/tcg/art/s0_050_anteiku_origin.png`

Validation:

- Source files are `1086x1448` PNGs, matching the 3:4 card-art ratio.
- `npm.cmd run build` passed.
- No Supabase Storage, uploads, generated-new-art step, packs, shop, economy, or CP paths were added.

## 30C-D Full Season 0 Temporary Art Import

Implemented asset-only:

- Added the remaining 45 temporary generated PNG inner-art files so all 50 Season 0 catalog cards have repo-served artwork.
- Kept the five 30C-C smoke-card files aligned with the same source-to-target mapping and verified their hashes did not change.
- Used the approved deterministic source mapping:
  - Batch 1 items 1-10 -> S0-001 through S0-010
  - Batch 2 items 1-10 -> S0-011 through S0-020
  - Batch 3 items 1-10 -> S0-021 through S0-030
  - Batch 4 items 1-10 -> S0-031 through S0-040
  - Batch 5 items 1-10 -> S0-041 through S0-050
- Ignored exact duplicate source `ChatGPT Image May 31, 2026, 09_32_31 PM.png`; used `ChatGPT Image May 31, 2026, 09_32_27 PM (1).png` for Batch 5 item 1 / S0-041.
- No catalog seed, SQL, RPC, service, UI, or CSS changes were needed.

Validation:

- All 50 local target files exist.
- All 50 are valid PNGs at `1086x1448`.
- `npm.cmd run build` passed.
- No Supabase Storage, uploads, generated-new-art step, packs, shop, economy, member visibility, or CP paths were added.

## 30D-A Owner-Only Test Pack Backend/RPC

Implemented backend/RPC only:

- Added `tcg_packs`.
- Added `tcg_pack_drop_rates`.
- Added `tcg_pack_openings`.
- Extended `tcg_inventory_events` allowed event/source values for pack openings.
- Seeded one active Owner-test pack:
  - code `season_0_test_pack`
  - name `Season 0 Test Pack`
  - cards per pack `5`
  - owner-test-only `true`
- Seeded temporary integer drop weights:
  - Common `6000`
  - Uncommon `2500`
  - Rare `1000`
  - Epic `400`
  - Legendary `90`
  - Mythic `10`
- Added `tcg_owner_open_test_pack(p_pack_code text default 'season_0_test_pack')`.

RPC behavior:

- Resolves active profile server-side through existing TCG active-profile helper.
- Requires active approved Owner profile.
- Rolls all cards in the backend.
- Updates `tcg_player_inventory`.
- Writes one `tcg_inventory_events` row per card.
- Writes one `tcg_pack_openings` history row.
- Returns a five-card result payload with safe card metadata for later UI.
- Duplicates are allowed and stack inventory quantity.
- No currency, wallet, shop, payment, member access, or frontend UI was added.

Validation:

- Local `npx.cmd supabase db reset` passed through `20260601000200_tcg_owner_pack_backend.sql`.
- `supabase/tests/tcg_30d_pack_validation.sql` passed `18 PASS / 0 FAIL / 0 SKIP`.
- Existing `supabase/tests/tcg_30b_validation.sql` passed `19 PASS / 0 FAIL / 0 SKIP`.
- Broad `supabase/tests/local_validation_anteiku.sql` passed its regression suite with no failures.
- `npm.cmd run build` passed.

Production:

- Production dry-run showed exactly one pending migration: `20260601000200_tcg_owner_pack_backend.sql`.
- Production migration apply/list verification passed.
- Read-only production verification confirmed:
  - `tcg_packs`, `tcg_pack_drop_rates`, and `tcg_pack_openings` exist with RLS enabled.
  - No direct anon/authenticated table grants exist for the new pack tables.
  - `tcg_owner_open_test_pack(p_pack_code text default 'season_0_test_pack')` exists.
  - Authenticated execute grant exists for the RPC; anon execute was not present.
  - `season_0_test_pack` is active, Owner-test-only, has 5 cards per pack, 6 drop rates, and total weight 10000.
  - Active Owner count remains `1`.
- No production Owner pack opening smoke was performed; user approval is required before creating production pack-opening/inventory mutations.

## 30B RPC Candidates

- `tcg_get_catalog()`
- `tcg_get_my_collection()`
- `tcg_set_card_favorite(p_card_key text, p_is_favorite boolean)`
- `tcg_admin_grant_card(p_target_profile_id uuid, p_card_key text, p_quantity integer, p_reason text default null)`

## 30B Local Validation

- `npm.cmd run build` passed.
- Local `npx.cmd supabase db reset` passed through `20260601000100_tcg_30b_catalog_inventory.sql`.
- `supabase/tests/tcg_30b_validation.sql` passed `19 PASS / 0 FAIL / 0 SKIP`.
- The full existing local validation suite passed after the TCG migration.

## 30B Production Verification

- Production dry-run showed exactly one pending migration: `20260601000100_tcg_30b_catalog_inventory.sql`.
- Production migration apply/list verification passed.
- Production DB verification confirmed `tcg_sets`, `tcg_rarities`, `tcg_cards`, `tcg_player_inventory`, and `tcg_inventory_events` exist with RLS enabled.
- Production verification confirmed Season 0 has exactly 50 cards with Common 18, Uncommon 14, Rare 9, Epic 5, Legendary 3, Mythic 1; Character 24, Scene 16, Relic 10, Organization 0.
- Production verification found no broad anon/authenticated direct table grants and no TCG RPC references to `member_cp`, `cp_snapshots`, normal CP RPCs, or Analytics CP paths.
- Rollback-wrapped production smoke confirmed approved-member catalog/collection reads work, direct inventory insert is blocked, and normal member admin grant is denied.
- No real production inventory grant or card ownership mutation was performed.

## Season 0 Catalog

The canonical "Season 0: Anteiku Origins" catalog v0.1 is available in the thread and supersedes earlier placeholder distribution notes.

Catalog shape:

- Exactly 50 cards.
- Common 18, Uncommon 14, Rare 9, Epic 5, Legendary 3, Mythic 1.
- Character 24, Scene 16, Relic 10, Organization 0.
- No invented cards.
- No pack/drop/economy/combat fields.
- Collector values are display values only, not spendable currency.
- `art_path` stores canonical inner-art asset paths.
- `image_url` and `thumbnail_url` remain `NULL` until approved rendered assets need those fields.

## Asset Pipeline

AI-generated card images are inner art only.

The app owns:

- Frame overlay.
- Rarity badge.
- Card name.
- Duplicate/ownership state.
- Future coin value.

Generated art must not bake in frames, text, badges, borders, nameplates, UI, or coin values.

## 30C UI Direction

- Mobile-first Card Collection page.
- Card grid with owned/missing/favorite states.
- Rarity/type/set filters.
- Card detail modal.
- Dark/crimson Anteiku styling.
- EN/FR/DE i18n.
- No CP display.

## Validation Focus

Backend:

- Local reset/migration passes.
- RLS enabled.
- Catalog read is safe.
- Inventory is active-profile scoped.
- Direct inventory/event writes blocked.
- Admin grant permission-gated and audited.
- No CP table/RPC references.
- Active Owner count remains `1`.

Frontend:

- `npm.cmd run build`.
- RPC-only service.
- No direct inventory writes.
- No client-side pack/drop/currency logic.
- No CP values.

Production-direct gate:

- Dry-run must show exactly the intended TCG migration.
- Apply only after clean migration list/dry-run.
- Deploy UI only after target DB has required TCG backend migration.

## References

- Planning document: `docs/TCG_CARD_COLLECTION_PLAN.md`
- Current project state: `ai_agents/PROJECT_STATE.md`
- Security rules: `ai_agents/SECURITY_RULES.md`
- RLS notes: `ai_agents/SUPABASE_RLS.md`
