# TCG/Card Collection Handoff

Milestone 30A planning is complete. No backend, frontend, SQL, Supabase, or production behavior was changed.

## Current Status

- Milestone 30C-A Owner-only Card Collection preview UI is implemented and deployed in production through commit `dbb67da feat: add owner tcg collection preview`.
- Milestone 30C-A2 Owner-only smoke grant control is implemented and deployed in production through commit `e96a489 feat: add owner tcg smoke grant`.
- Milestone 30C-B TCG album visual polish and repo-served asset-pipeline notes are implemented.
- Milestone 30C-C adds temporary generated art assets for only the five Owner smoke-test cards.
- Milestone 30C-D adds temporary generated art assets for all 50 Season 0 cards.
- Milestone 30D-A adds Owner-only test pack backend/RPC support and is production-applied through `20260601000200_tcg_owner_pack_backend.sql`.
- Milestone 30D-B adds the Owner-only `/tcg` pack preview/opening UI and is deployed through commit `fa50b33 feat: add owner tcg pack preview`.
- Milestone 30E-A adds the Owner-only shop/economy backend/RPC foundation and is production-applied through `20260601000300_tcg_owner_shop_economy.sql`.
- Milestone 30E-B adds the Owner-only `/tcg` shop/economy preview UI and is deployed through commit `8e7eb73 feat: add owner tcg shop preview`.
- Milestone 30E-C polishes the Owner-only `/tcg` shop, wallet, and pack reveal UX and is deployed through commit `053f27d style: polish owner tcg shop ux`.
- Milestone 30E-D refactors the Owner-only `/tcg` preview into a compact Album/Packs/Shop/Owner Lab hub and is deployed through commit `d1f4c4a style: add compact tcg hub layout`.
- Milestone 30F-A adds Owner-only TCG balance/economy/pack analytics backend support and is production-applied through `20260601000400_tcg_owner_balance_report.sql`.
- Milestone 30F-B adds Owner-only TCG pack inventory backend support and is production-applied through `20260601000500_tcg_owner_pack_inventory.sql`.
- Milestone 30F-C adds the Owner-only `/tcg` pack inventory/opening UI and is deployed through commit `ada2b74 feat: add tcg pack inventory opening ui`.
- Milestone 30F-D adds temporary Season 0 pack-front and card-back assets and is deployed through commit `6bcebab feat: add tcg pack and card back assets`.
- Milestone 30F-E adds the compact TCG pack inventory UI hotfix and is deployed through commit `bc3c705 fix: compact tcg pack inventory ui`.
- Milestone 30F-F adds the TCG pack/reveal UI polish hotfix and is deployed through commit `e77a385 style: polish tcg pack reveal ui`.
- Milestone 30F-G wires the replaced pack-front and real card-back assets into the Owner-only pack/reveal flow and is deployed through commit `332e38f fix: use tcg card back for reveal cards`.
- Milestone 30F-H polishes the Owner-only `/tcg` UI across Album, Packs, Shop, Owner Lab, and reveal overlay and is deployed through commit `3d92c37 style: polish owner tcg ui`.
- Milestone 30B backend/RPC foundation is implemented, locally validated, and production-applied through `20260601000100_tcg_30b_catalog_inventory.sql`.
- No member-facing packs, shop, economy UI, routes beyond `/tcg`, uploads, or Storage have been implemented.
- No member-facing TCG release exists yet. The next step is controlled Owner manual mutation smoke for the deployed pack loop; frontend calls backend RPCs and never calculates drops or mutates wallets/inventory client-side.

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
- Owner-only balance analytics must remain backend-gated and read-only.
- Pack inventory is backend/RPC authority only; the frontend must not write pack quantities or calculate drops.
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

## 30D-B Owner-Only Pack Preview UI

Implemented frontend-only:

- Added an Owner-only `Season 0 Test Pack` panel on `/tcg`.
- Added `tcgOwnerOpenTestPack()` in `src/services/tcgService.js`.
- The button calls only `tcg_owner_open_test_pack(p_pack_code => season_0_test_pack)`.
- No profile id is sent from the frontend; the backend resolves the active Owner profile.
- Result cards render directly from the backend payload: art, card name/no, rarity, new/duplicate state, quantity delta, and resulting owned quantity.
- After success the page refetches `tcg_get_my_collection`, switches to Owned, and keeps existing favorite/detail/smoke-grant behavior.
- Added EN/FR/DE i18n and CSS-only staggered reveal styling with reduced-motion fallback.

Validation:

- `npm.cmd run build` passed.
- Source checks confirmed no direct TCG table reads/writes, no pack/drop table reads, no client-side drop calculation, no normal CP paths, no service-role path, and no uploads/Storage in the TCG page/service path.
- Production bundle verification confirmed `/tcg` serves the app shell and the deployed bundle contains the pack UI plus `tcg_owner_open_test_pack`.

Production smoke status:

- Codex did not click `Open Test Pack` in production.
- No production pack-opening or inventory mutation was created during deployment.
- Owner can now manually open a controlled test pack from `/tcg`.

## 30E-A Owner-Only Shop/Economy Backend

Implemented backend/RPC only:

- New migration `20260601000300_tcg_owner_shop_economy.sql`.
- New tables:
  - `tcg_wallets`
  - `tcg_wallet_ledger`
  - `tcg_shop_items`
- New currency code: `anteiku_coins`.
- New seeded Owner-test shop item:
  - code `season_0_test_pack_shop`
  - name `Season 0 Test Pack`
  - price `100`
  - linked to existing `season_0_test_pack`
- Private helper `private.tcg_open_owner_test_pack_for_profile(...)` now owns the shared backend pack-opening flow for existing free Owner test packs and future Owner shop purchases.
- Existing RPC `tcg_owner_open_test_pack(p_pack_code text default 'season_0_test_pack')` is preserved.
- New Owner-only public RPCs:
  - `tcg_owner_grant_test_coins(p_amount integer default 1000)`
  - `tcg_get_my_wallet()`
  - `tcg_owner_get_test_shop()`
  - `tcg_owner_buy_test_pack(p_shop_item_code text default 'season_0_test_pack_shop')`

Security:

- Owner-only through existing active-profile/admin authority.
- No arbitrary target profile id is accepted for player/economy actions.
- Wallet balance changes are server-side and ledger-backed.
- Shop purchase locks the wallet row, rejects insufficient balance, deducts coins, records ledger history, opens the pack server-side, and writes inventory/opening history.
- RLS is enabled on all new tables and direct anon/authenticated table grants are revoked.
- No member-facing shop access, payments, premium currency, uploads, Storage, frontend shop UI, CP references, or normal CP exposure was added.

Validation:

- Local `npx.cmd supabase db reset` passed.
- `supabase/tests/tcg_30e_shop_validation.sql` passed `32 PASS / 0 FAIL / 0 SKIP`.
- Regression validation passed:
  - `supabase/tests/tcg_30d_pack_validation.sql`: `18 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30b_validation.sql`: `19 PASS / 0 FAIL / 0 SKIP`
- `npm.cmd run build` passed.

Production:

- Dry-run showed exactly one pending migration: `20260601000300_tcg_owner_shop_economy.sql`.
- Migration apply/list verification passed.
- Read-only DB verification confirmed:
  - new economy tables exist and have RLS enabled;
  - no direct anon/authenticated client grants exist on the new tables;
  - Owner test shop item is seeded;
  - new public RPCs exist with authenticated execute grants;
  - checked anon execute grants are denied;
  - the private pack helper is not executable by authenticated clients;
  - new economy RPCs contain no CP references;
  - simulated authenticated direct reads of `member_cp` and `cp_snapshots` returned zero rows;
  - active Owner count remains `1`.
- No production Owner coin grant, wallet mutation, shop purchase, or pack purchase smoke was performed. User approval is required before creating those production economy/inventory mutations.

## 30E-B Owner-Only Shop/Economy UI Preview

Implemented frontend-only:

- Owner-only `TCG Shop Test` panel on `/tcg`.
- Wallet card showing `Anteiku Coins` balance from `tcg_get_my_wallet`.
- Owner test/dev button `Grant 1000 test coins` using `tcg_owner_grant_test_coins`.
- Owner shop item card for `Season 0 Test Pack`, price `100 Anteiku Coins`, using `tcg_owner_get_test_shop`.
- `Buy Test Pack` action using `tcg_owner_buy_test_pack`.
- Purchase result display reuses the existing backend-returned pack result/reveal card UI.
- After successful purchase, the UI refetches wallet and collection and switches to Owned.
- Added EN/FR/DE copy and dark/crimson mobile-first shop styling.

Validation:

- `npm.cmd run build` passed.
- Source checks found no SQL/migration/backend changes, no direct `.from('tcg_*')` table access in the TCG page/service, no client-side drop calculation, no `member_cp`/`cp_snapshots` paths in touched TCG page/service files, no service-role path, no payments, and no uploads/Storage.
- Non-Owner direct `/tcg` remains blocked by the existing active Owner page guard.

Production:

- Commit `8e7eb73 feat: add owner tcg shop preview` was pushed to `main`.
- Production serves the deployed bundle containing `TCG Shop Test`, wallet text, and RPC wrapper names for `tcg_get_my_wallet`, `tcg_owner_get_test_shop`, `tcg_owner_grant_test_coins`, and `tcg_owner_buy_test_pack`.
- Non-mutating production smoke confirmed `/tcg` returns HTTP `200`.
- Codex did not click production `Grant 1000 test coins` or `Buy Test Pack`.
- Manual Owner mutation smoke is ready: grant test coins, buy the test pack, confirm wallet decreases by `100`, confirm five backend-returned cards reveal, and confirm collection quantity increases by `+5`.

## 30E-C Owner-Only Shop/Pack UX Polish

Implemented frontend/style-only:

- Polished the Owner-only shop panel into a darker game-shop presentation.
- Improved wallet HUD styling for `Anteiku Coins`.
- Improved shop item/price/buy-button visual hierarchy.
- Kept the free Owner test pack visually separate from the shop purchase flow.
- Improved pack result stage, rarity glow, card reveal timing, and Epic/Legendary/Mythic impact.
- Added small card reveal index markers.
- Added ref-based double-submit guards for mutation actions:
  - favorite toggle
  - smoke grant
  - free Owner test pack
  - test coin grant
  - test pack purchase
- Current test values remain unchanged:
  - grant amount `1000`
  - test pack price `100 Anteiku Coins`
  - pack size `5`
  - drop weights unchanged

Validation:

- `npm.cmd run build` passed.
- Source checks found only `src/pages/TcgCollection.jsx` and `src/styles/app.css` changed.
- No SQL/migrations/backend/RPC/RLS/package/service-worker changes were made.
- No direct TCG table reads/writes were added.
- No client-side drop calculation, client-side wallet authority, CP path, service-role path, payments, uploads, or Storage was added.

Production:

- Commit `053f27d style: polish owner tcg shop ux` was pushed to `main`.
- Production serves the updated JS/CSS bundle with the shop polish markers.
- Non-mutating production smoke confirmed `/tcg` returns HTTP `200`.
- Codex did not click any production mutation controls.
- Owner manual shop-loop smoke remains next: grant coins, buy pack, verify wallet decrease, reveal five cards, verify collection quantity increase.

## 30E-D Compact TCG Hub / Windowed UI Polish

Implemented frontend/style-only:

- Reworked Owner-only `/tcg` into a compact hub instead of one long stacked preview page.
- Added top header stats for unique owned, total owned quantity, favorites, and Anteiku Coins.
- Added frontend-only window tabs:
  - Album
  - Packs
  - Shop
  - Owner Lab
- Album remains the default window and keeps collection progress, filters, rarity filter, card grid, detail sheet, and favorite behavior.
- Packs contains the free Owner test pack opening preview.
- Shop contains wallet, shop item, and `Buy Test Pack`.
- Owner Lab contains the controlled mutation tools:
  - `Grant smoke cards`
  - `Grant 1000 test coins`
- Preserved existing ref-based double-submit guards for favorite toggle, smoke grant, free test pack, test coin grant, and shop purchase.
- Current test values remain unchanged:
  - grant amount `1000`
  - test pack price `100 Anteiku Coins`
  - pack size `5`
  - drop weights unchanged

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks found only `src/pages/TcgCollection.jsx`, `src/styles/app.css`, and EN/FR/DE i18n files changed.
- No SQL/migrations/backend/RPC/RLS/package/service-worker changes were made.
- No direct TCG table reads/writes were added.
- No client-side drop calculation, client-side wallet authority, CP path, service-role path, payments, uploads, or Storage was added.

Production:

- Commit `d1f4c4a style: add compact tcg hub layout` was pushed to `main`.
- Production serves the updated hub bundle with JS/CSS markers for the tabbed TCG hub and Owner Lab.
- Non-mutating production smoke confirmed `/tcg` returns HTTP `200`.
- Codex did not click `Grant smoke cards`, `Open Test Pack`, `Grant 1000 test coins`, `Buy Test Pack`, or favorite toggle in production.
- Owner manual shop-loop smoke remains next.

## 30F-A Owner-Only Balance Report Backend

Implemented backend/RPC only:

- New migration `20260601000400_tcg_owner_balance_report.sql`.
- New read-only RPC `tcg_owner_get_balance_report()`.
- The RPC resolves the active Owner profile server-side through the existing active admin context.
- The RPC rejects non-Owner active profiles.
- Execute is granted to authenticated clients only; the function performs the Owner check internally.
- The report returns structured JSONB sections:
  - `collection_summary`
  - `rarity_ownership_summary`
  - `pack_opening_summary`
  - `rarity_pull_summary`
  - `economy_summary`
  - `duplicate_pressure_summary`
  - `balance_hints`

Behavior:

- Uses existing TCG catalog, inventory, pack opening, wallet, ledger, and shop tables.
- Does not accept arbitrary player/profile ids.
- Does not mutate inventory, wallets, ledger rows, pack openings, prices, drop rates, or pack size.
- Does not expose analytics to members.
- Does not add frontend analytics UI yet.

Validation:

- Local `npx.cmd supabase db reset` passed.
- `supabase/tests/tcg_30f_balance_report_validation.sql` passed `20 PASS / 0 FAIL / 0 SKIP`.
- TCG regression tests passed:
  - `supabase/tests/tcg_30b_validation.sql`: `19 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30d_pack_validation.sql`: `18 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30e_shop_validation.sql`: `32 PASS / 0 FAIL / 0 SKIP`
- Broad `supabase/tests/local_validation_anteiku.sql` passed.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.

Production:

- Production dry-run showed exactly one pending migration: `20260601000400_tcg_owner_balance_report.sql`.
- Migration apply/list verification passed and remote now shows `20260601000400`.
- Read-only production verification confirmed:
  - `tcg_owner_get_balance_report()` exists.
  - Authenticated execute is granted and anon execute is not granted.
  - Function definition has no CP table references.
  - Simulated active Owner call returned the expected sections.
  - Normal member call was denied.
  - Payload check found no CP/private token exposure.
  - Active Owner count remains `1`.
- No production wallet, inventory, ledger, opening, price, drop-rate, or pack-size mutation was performed.

Next:

- Plan or implement an Owner-only TCG balance report UI inside `/tcg` Owner Lab after explicit approval.
- Keep member TCG release blocked until Owner analytics review and member-release gates are separately planned.

## 30F-B Owner-Only Pack Inventory Backend

Implemented backend/RPC only:

- New migration `20260601000500_tcg_owner_pack_inventory.sql`.
- New tables:
  - `tcg_player_packs`
  - `tcg_pack_inventory_events`
- New Owner-only RPCs:
  - `tcg_get_my_packs()`
  - `tcg_owner_buy_test_pack_to_inventory(p_shop_item_code text default 'season_0_test_pack_shop')`
  - `tcg_owner_open_owned_pack(p_pack_code text default 'season_0_test_pack')`

New behavior:

- `tcg_owner_buy_test_pack_to_inventory(...)` deducts the shop price and adds owned pack quantity.
- Buying to inventory does not roll cards, update card inventory, or write pack opening history.
- `tcg_owner_open_owned_pack(...)` consumes one owned pack and then rolls five cards backend-side through the existing private pack helper.
- Opening an owned pack writes pack inventory event history, card inventory events, and pack opening history.

Backward compatibility:

- Existing `tcg_owner_buy_test_pack(...)` is preserved and still buys-and-opens immediately for the currently deployed frontend.
- Existing free Owner `tcg_owner_open_test_pack(...)` is preserved.
- Future frontend should use the new inventory-based flow.

Validation:

- Local `npx.cmd supabase db reset` passed.
- `supabase/tests/tcg_30f_pack_inventory_validation.sql` passed `31 PASS / 0 FAIL / 0 SKIP`.
- TCG regression tests passed:
  - `supabase/tests/tcg_30b_validation.sql`: `19 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30d_pack_validation.sql`: `18 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30e_shop_validation.sql`: `32 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30f_balance_report_validation.sql`: `20 PASS / 0 FAIL / 0 SKIP`
- Broad `supabase/tests/local_validation_anteiku.sql` passed.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.

Production:

- Production dry-run initially hit a transient Supabase pooler auth/circuit-breaker error before SQL execution; rerun after cooldown succeeded.
- Clean dry-run showed exactly one pending migration: `20260601000500_tcg_owner_pack_inventory.sql`.
- Migration apply/list verification passed and remote now shows `20260601000500`.
- Read-only production verification confirmed:
  - `tcg_player_packs` and `tcg_pack_inventory_events` exist.
  - RLS is enabled on both new tables.
  - No direct anon/authenticated table grants exist.
  - All three new RPCs exist.
  - Authenticated execute is granted and anon execute is not granted.
  - New RPC definitions contain no CP table references.
  - Owner can read pack inventory through RPC.
  - Normal member is denied pack inventory RPC access.
  - Normal member direct `member_cp` read remains empty/blocked.
  - Active Owner count remains `1`.
- No production pack buy, owned-pack open, wallet mutation, inventory mutation, or pack-opening smoke was performed by Codex.

## 30F-C Owner-Only Pack Inventory UI

Status: complete and deployed through commit `ada2b74 feat: add tcg pack inventory opening ui`.

Implemented:

- Shop `Buy Test Pack` calls `tcg_owner_buy_test_pack_to_inventory(...)`.
- Shop purchases add a Season 0 Test Pack to pack inventory and do not reveal cards in the Shop.
- Packs calls `tcg_get_my_packs()` and displays owned Season 0 Test Pack quantity.
- Packs uses a CSS-only 4:3 pack sprite/card treatment for the Owner test pack.
- Opening from Packs calls `tcg_owner_open_owned_pack(...)`.
- The backend remains authority for consuming one pack and rolling five card results.
- Opening UI uses a dimmed/blurred overlay, swipe-left/right rip gesture, fallback `Rip Open` button, card-by-card reveal, and `Reveal all`.
- Pack animations are local UI state, default enabled, and can be disabled without changing backend behavior.
- The older free Owner `Open Test Pack` path remains only in Owner Lab.
- EN/FR/DE i18n and dark/crimson mobile styling were added.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed no SQL/migration, Supabase/RLS/RPC, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `ada2b74` was pushed to `main` and production served the updated bundle.
- Non-mutating smoke passed: `/tcg?tcg-pack-inventory-smoke=1` returned HTTP 200 and the bundle contained `tcg_get_my_packs`, `tcg_owner_buy_test_pack_to_inventory`, `tcg_owner_open_owned_pack`, `packInventory`, `swipeToRip`, and `packAnimations`.
- Codex did not click production Buy, Open, Rip, Grant, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-D Temporary Pack Front + Card Back Assets

Status: complete and deployed through commit `6bcebab feat: add tcg pack and card back assets`.

Assets:

- Pack front: `public/assets/tcg/packs/season0_test_pack_front.png`
- Card back: `public/assets/tcg/cards/tcg_card_back_season0.png`
- Added `public/assets/tcg/packs/README.md`.
- Added `public/assets/tcg/cards/README.md`.

Implemented:

- Packs window and pack opening overlay use the temporary Season 0 pack-front image.
- Unrevealed pack result cards use the temporary Season 0 card-back image.
- Existing CSS/text placeholder fallback remains if either image fails to load.
- Revealed cards still use backend-returned card art/details.
- Swipe/rip, `Rip Open`, `Reveal all`, and pack animation setting behavior were preserved.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Build output contains both image assets in `dist/assets/tcg/packs/` and `dist/assets/tcg/cards/`.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `6bcebab` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-assets-smoke=1` returned HTTP 200.
  - `/assets/tcg/packs/season0_test_pack_front.png` returned HTTP 200 image/png.
  - `/assets/tcg/cards/tcg_card_back_season0.png` returned HTTP 200 image/png.
  - Deployed bundle `assets/index-DW84VTFX.js` references both new asset paths and still contains `tcg_get_my_packs` / `tcg_owner_open_owned_pack`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-E Pack UI Compact Hotfix

Status: complete and deployed through commit `bc3c705 fix: compact tcg pack inventory ui`.

Implemented:

- Removed the app-side hard rectangular box/background around the pack image.
- Kept the pack floating on the dark panel with subtler glow/shadow.
- Kept a compact `xN` quantity badge near the pack.
- Moved `Open Pack` directly under the pack as a smaller compact action.
- Disabled `Open Pack` at quantity `0` remains readable.
- Shop purchases remain on the Shop window after `tcg_owner_buy_test_pack_to_inventory(...)` succeeds.
- Shop success stays inline and shows pack-added / current pack quantity copy.
- Added a small `Go to Packs` secondary action for manual navigation.
- Added EN/FR/DE `tcg.goToPacks` copy.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.
- The temporary pack/card-back PNGs are `Format24bppRgb`, so CSS can remove the app wrapper box but cannot remove opaque black pixels baked into the artwork.

Production:

- Commit `bc3c705` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-pack-compact-smoke=1` returned HTTP 200.
  - Deployed bundle `assets/index-DLnPnWpl.js` contains `tcg-owned-open-button`, `tcg-shop-success-actions`, `Go to Packs`, `tcg_owner_buy_test_pack_to_inventory`, and `tcg_owner_open_owned_pack`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-F Pack/Reveal UI Polish Hotfix

Status: complete and deployed through commit `e77a385 style: polish tcg pack reveal ui`.

Implemented:

- Added a local canvas cleanup pass for the pack-front image that turns near-black edge-connected background pixels transparent when possible.
- Canvas cleanup is frontend-only, pack-image-only, cached by asset path, and falls back to the original image if processing fails.
- Tightened the Packs window into a collectible-style display with the pack as the hero.
- Kept compact quantity badge and compact `Open Pack` action.
- Simplified reveal overlay so the pack name/status appears once in the top bar.
- Added compact reveal toolbar with revealed-card count and `Reveal all`.
- Improved reveal grid spacing and alignment for unrevealed/revealed mixed states.
- Reduced unrevealed card clutter while keeping the temporary Season 0 card-back asset.
- Preserved Shop stay-in-Shop behavior, swipe/rip, `Rip Open`, tap-to-reveal, `Reveal all`, pack animation setting, and refresh after opening.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `e77a385` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-reveal-polish-smoke=1` returned HTTP 200.
  - Deployed bundle `assets/index-BPcKi_cv.js` contains `tcg-reveal-toolbar`, `tcg-owned-pack-stage`, `tcg_owner_open_owned_pack`, and `tcg_owner_buy_test_pack_to_inventory`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-G Pack Front + Real Card Back Asset Wire-Up

Status: complete and deployed through commit `332e38f fix: use tcg card back for reveal cards`.

Implemented:

- Kept the pack front on `/assets/tcg/packs/season0_test_pack_front.png` for pack inventory and pack opening/rip overlay.
- Wired unrevealed pack result cards to `/assets/tcg/cards/tcg_card_back_season0.png`.
- Kept the CSS/React card-back design as fallback if the real card-back image fails to load.
- Kept the small `Tap to Reveal` overlay label.
- Preserved Shop/Packs behavior: buying stays in Shop, `Go to Packs` remains manual, pack count stays in Packs, and `Open Pack` remains compact.
- Preserved Open Pack, swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, pack animation toggle, collection refetch, and pack quantity refetch behavior.

Asset verification:

- Pack front: `public/assets/tcg/packs/season0_test_pack_front.png`, 1086x1448 PNG, 1,799,800 bytes.
- Card back: `public/assets/tcg/cards/tcg_card_back_season0.png`, 1086x1448 PNG, 2,185,757 bytes.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `332e38f` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg` app shell returned HTTP 200.
  - Deployed bundle `assets/index-DZ6Xj5gs.js` and CSS `assets/index-D5PKDyGy.css` contain the card-back image wire-up/styling.
  - `/assets/tcg/packs/season0_test_pack_front.png` returned HTTP 200 and 1,799,800 bytes.
  - `/assets/tcg/cards/tcg_card_back_season0.png` returned HTTP 200 and 2,185,757 bytes.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-H Owner-Only TCG UI Polish Pass

Status: complete and deployed through commit `3d92c37 style: polish owner tcg ui`.

Implemented:

- Tightened the overall `/tcg` page into a more polished game-hub presentation.
- Improved top header hierarchy, compact refresh action, and HUD stat cards.
- Improved Album filter density, rarity selector, card grid density, owned/missing/favorite states, and detail sheet sizing.
- Kept card art readable while reducing excessive spacing and button weight.
- Improved Packs composition while preserving the pack front as the hero and compact `Open Pack` placement.
- Added an existing pack-front preview to Shop items and tightened wallet, price, purchase, success, and `Go to Packs` presentation.
- Reworked Owner Lab into a clearly separated test-only section for smoke grants and test coins.
- Improved reveal overlay spacing, toolbar, hidden/revealed card grid sizing, and mobile safety.

Preserved behavior:

- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- Packs open owned packs through backend RPC.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `3d92c37` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-ui-polish-smoke=2` returned HTTP 200.
  - Deployed bundle `assets/index-C9n3v1dY.js` contains `tcg-shop-pack-preview` and `tcg-owner-lab-section`.
  - Deployed CSS `assets/index-DSO3TEr-.css` contains `tcg-shop-pack-preview`, `tcg-owner-lab-section`, and `tcg-hub-hero`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

Next:

- Run controlled Owner manual mutation smoke for the pack loop when approved:
  - grant test coins if needed;
  - buy a test pack into inventory from Shop;
  - open it from Packs;
  - reveal cards;
  - verify wallet decrease, pack quantity decrease, collection count update, and favorites still work.
- Keep member TCG release blocked until this flow is accepted and release gates are planned.

## 30B RPC Candidates

- `tcg_get_catalog()`
- `tcg_get_my_collection()`
- `tcg_set_card_favorite(p_card_key text, p_is_favorite boolean)`
- `tcg_admin_grant_card(p_target_profile_id uuid, p_card_key text, p_quantity integer, p_reason text default null)`
- `tcg_owner_get_balance_report()`
- `tcg_get_my_packs()`
- `tcg_owner_buy_test_pack_to_inventory(p_shop_item_code text default 'season_0_test_pack_shop')`
- `tcg_owner_open_owned_pack(p_pack_code text default 'season_0_test_pack')`

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
