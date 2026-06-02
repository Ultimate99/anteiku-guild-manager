# TCG/Card Collection Plan

Milestone 30A planning started this document. Milestone 30B is implemented, locally validated, and production-applied through `20260601000100_tcg_30b_catalog_inventory.sql`. Milestone 30C-A Owner-only Card Collection preview UI is deployed through commit `dbb67da feat: add owner tcg collection preview`; Milestone 30C-A2 Owner-only smoke grant control is deployed through commit `e96a489 feat: add owner tcg smoke grant`; Milestone 30C-B album visual polish and repo-served asset-pipeline notes are implemented; Milestone 30C-C adds temporary art for the five smoke-test cards; Milestone 30C-D adds temporary art for all 50 Season 0 cards; Milestone 30D-A adds Owner-only test pack backend/RPC support through `20260601000200_tcg_owner_pack_backend.sql`; Milestone 30D-B adds the Owner-only `/tcg` pack preview UI through commit `fa50b33 feat: add owner tcg pack preview`; Milestone 30E-A adds the Owner-only shop/economy backend through `20260601000300_tcg_owner_shop_economy.sql`; Milestone 30E-B adds the Owner-only `/tcg` shop/economy preview UI through commit `8e7eb73 feat: add owner tcg shop preview`; Milestone 30E-C polishes the Owner-only shop/wallet/pack UX through commit `053f27d style: polish owner tcg shop ux`; Milestone 30E-D adds the compact `/tcg` hub/window layout through commit `d1f4c4a style: add compact tcg hub layout`; Milestone 30F-A adds Owner-only TCG balance/economy/pack analytics backend support through `20260601000400_tcg_owner_balance_report.sql`; Milestone 30F-B adds Owner-only pack inventory backend support through `20260601000500_tcg_owner_pack_inventory.sql`; Milestone 30F-C adds the Owner-only `/tcg` pack inventory/opening UI through commit `ada2b74 feat: add tcg pack inventory opening ui`; Milestone 30F-D adds temporary pack-front and card-back assets through commit `6bcebab feat: add tcg pack and card back assets`; Milestone 30F-E adds a compact pack UI hotfix through commit `bc3c705 fix: compact tcg pack inventory ui`; Milestone 30F-F adds the pack/reveal UI polish hotfix through commit `e77a385 style: polish tcg pack reveal ui`; Milestone 30F-G wires the replaced pack-front and real card-back assets through commit `332e38f fix: use tcg card back for reveal cards`; Milestone 30F-H polishes the Owner-only `/tcg` UI through commit `3d92c37 style: polish owner tcg ui`; Milestone 30F-I makes the Packs and Shop windows compact/windowed through commit `14219fe style: make tcg pack shop windows compact`; Milestone 30F-J slims the Packs/Shop windows and wallet HUD through commit `7840366 style: slim tcg pack shop wallet ui`; Milestone 30F-K replaces the glowing-square wallet mark with a CSS wallet/currency icon through commit `07d65a9 style: polish tcg wallet hud icon`; Milestone 30F-L centers the Packs and Shop item windows through commit `ff94b1c style: center tcg shop pack windows`; Milestone 30F-M adds the Owner-only Balance tab using `tcg_owner_get_balance_report()` through commit `4c4ebc6 feat: add owner tcg balance report ui`. Member-facing packs, shop, economy UI, and final approved card artwork remain unimplemented.

## Product Goal

The TCG/Card Collection system adds a lightweight collection and progression layer to Anteiku Guild Manager without touching protected CP, GvG, Analytics, 3v3, Wall, cosmetics, roles, permissions, or account-switching behavior.

Players should eventually be able to:

- Browse a public card catalog.
- View their own card inventory and duplicate counts.
- Favorite or showcase selected cards on their authenticated profile.
- Open packs whose results are decided server-side.
- Use a later free economy for duplicate selling or burning.

Owners/admins should eventually be able to:

- Manage card catalog entries through permission-gated tools.
- Grant cards for events or moderation recovery through audited RPCs.
- Configure packs, drop tables, and shop availability after the base inventory is stable.

Delayed until later:

- Member-facing pack opening and final drop-rate balancing.
- Economy, wallets, duplicate burning, shop, and premium currency.
- Payments or real-money purchase flows.
- Battles, card stats, trading, marketplace, or public collection pages.

## Recommended Milestones

- 30B: Card catalog + inventory backend/RPC. Complete and production-applied.
- 30C-A: Owner-only Card Collection preview UI. Complete and deployed.
- 30C-A2: Owner-only smoke grant control. Complete and deployed.
- 30C-B: Album visual polish + art asset pipeline notes. Complete.
- 30C-C: First five temporary smoke-card art assets. Complete.
- 30C-D: Full Season 0 temporary art import. Complete.
- 30C-E: Replace temporary art with approved final artwork when ready.
- 30C-F: Member release planning after Owner acceptance.
- 30D-A: Owner-only test pack backend/RPC. Complete and production-applied.
- 30D-B: Owner-only pack opening UI/animation preview. Complete and deployed.
- 30D-C: Owner pack smoke and balancing feedback.
- 30E-A: Owner-only shop/economy backend/RPC foundation. Complete and production-applied.
- 30E-B: Owner-only shop/economy UI preview. Complete and deployed.
- 30E-C: Owner-only shop/pack UX polish. Complete and deployed.
- 30E-D: Owner-only compact TCG hub/window layout. Complete and deployed.
- 30F-A: Owner-only balance/economy/pack analytics backend. Complete and production-applied.
- 30F-B: Owner-only pack inventory backend. Complete and production-applied.
- 30F-C: Owner-only frontend wire-up for shop buy-to-inventory and Packs open-owned-pack flow. Complete and deployed.
- 30F-D: Import temporary Season 0 pack front and card back assets. Complete and deployed.
- 30F-E: Compact pack inventory UI hotfix. Complete and deployed.
- 30F-F: Pack/reveal UI polish hotfix. Complete and deployed.
- 30F-G: Pack front + real card-back asset wire-up. Complete and deployed.
- 30F-H: Owner-only `/tcg` UI polish pass. Complete and deployed.
- 30F-I: Windowed Packs/Shop layout hotfix. Complete and deployed.
- 30F-J: Slim Packs/Shop windows + wallet HUD polish. Complete and deployed.
- 30F-K: Wallet icon HUD hotfix. Complete and deployed.
- 30F-L: Packs/Shop centering alignment hotfix. Complete and deployed.
- 30F-M: Owner-only TCG Balance Report UI. Complete and deployed.
- 30F-N: Member-facing free shop/economy planning after Owner Balance review and pack-inventory review.
- 30G: Admin TCG tools.
- Later: premium/payment system only after the free economy is stable.

## Data Model Proposal

### 30B Core Tables

`tcg_sets`

- Stores set metadata such as Season 0.
- Suggested fields: `id`, `set_key`, `name`, `description`, `release_status`, `sort_order`, `starts_at`, `ends_at`, `created_at`, `updated_at`.

`tcg_rarities`

- Stores rarity order and styling metadata.
- Suggested fields: `id`, `rarity_key`, `name`, `sort_order`, `display_tier`, `style_summary`, `style_prompt_prefix`, `created_at`, `updated_at`.

`tcg_cards`

- Stores card catalog entries.
- Suggested fields: `id`, `card_key`, `card_no`, `set_id`, `rarity_id`, `name`, `card_type`, `subject_or_character`, `faction`, `collector_value`, `short_description`, `flavor_text`, `art_prompt`, `s1_validation_note`, `art_path`, `image_url`, `thumbnail_url`, `release_status`, `is_collectible`, `sort_order`, `created_at`, `updated_at`.
- `card_type` should be constrained to safe known values such as `Character`, `Organization`, `Scene`, and `Relic`.
- Card keys should be lowercase ASCII-safe snake_case.

`tcg_player_inventory`

- Stores active-profile-owned cards and duplicate counts.
- Suggested fields: `id`, `profile_id`, `card_id`, `quantity`, `first_acquired_at`, `last_acquired_at`, `is_favorite`, `is_locked`, `created_at`, `updated_at`.
- Unique constraint on `(profile_id, card_id)`.

`tcg_inventory_events`

- Audits server-side inventory changes.
- Suggested fields: `id`, `profile_id`, `card_id`, `quantity_delta`, `event_type`, `source_type`, `source_id`, `actor_user_id`, `actor_profile_id`, `reason`, `metadata`, `created_at`.
- 30B should only implement audited admin grants. Pack/shop/economy event types can be added later.

### Later Tables

`tcg_packs`

- Defines pack catalog, availability, set coverage, and status.

`tcg_pack_drop_rates`

- Stores server-side rarity/card drop weights. Never expose client-side as authority.

`tcg_pack_openings`

- Records pack opening transactions and results.

`tcg_currency_wallets`

- Later free economy wallet table. Do not implement before inventory is stable.

`tcg_transactions`

- Later append-only ledger for currency, duplicate sale, shop purchase, and adjustment events.

`tcg_card_showcases`

- Later profile showcase slots for public-safe cards.

## RLS And Security Model

Core principles:

- Backend decides card ownership.
- Backend decides pack results.
- Frontend displays data and calls RPCs only.
- Members cannot directly write inventory, events, pack openings, or currency.
- Active profile must be resolved server-side with existing active-profile helpers.
- No arbitrary `profile_id` may be trusted from the frontend for player actions.
- Admin actions must reuse existing Owner/Leader/Vice/Admin permission patterns.
- No CP data should be joined, returned, inferred, or displayed by TCG features.

Catalog access:

- Approved authenticated members can read active catalog rows.
- Draft/retired catalog rows are admin-only or hidden until a later admin tool exists.

Inventory access:

- Members can read only the selected active profile inventory through an RPC.
- Direct inventory/event table reads can be denied if RPC coverage is complete.
- Direct inventory/event inserts, updates, and deletes must be denied.

Admin access:

- Owner can grant/manage globally.
- Scoped staff can only act within their allowed guild scope if a future scoped TCG admin feature needs it.
- Every inventory mutation should produce an audit/event row.

Pack/economy future:

- Pack opening must be a transactionally safe RPC.
- Currency changes must use an append-only ledger or equivalent server-side authority.
- Client-side drop calculation, client-side currency mutation, or direct wallet writes are forbidden.

## RPC Proposal

30B candidate RPCs:

- `tcg_get_catalog()`
  - Returns active sets, rarities, and cards.
  - No CP or private profile data.

- `tcg_get_my_collection()`
  - Resolves selected active profile server-side.
  - Returns catalog rows plus owned quantity/favorite/locked state for the active profile.

- `tcg_set_card_favorite(p_card_key text, p_is_favorite boolean)`
  - Resolves selected active profile server-side.
  - Allows favorite only for owned cards.

- `tcg_admin_grant_card(p_target_profile_id uuid, p_card_key text, p_quantity integer, p_reason text default null)`
  - Admin-only.
  - Validates target profile, card availability, quantity limits, and actor permission.
  - Upserts inventory and writes `tcg_inventory_events`.

Later RPCs:

- `get_public_profile_card_showcase(p_profile_slug text)`
- `set_my_card_showcase(p_card_keys text[])`
- `tcg_owner_open_test_pack(p_pack_code text default 'season_0_test_pack')` is implemented for Owner-only testing.
- `tcg_owner_get_balance_report()` is implemented for Owner-only read-only balancing analytics.
- `tcg_get_my_packs()` is implemented for Owner-only pack inventory reads.
- `tcg_owner_buy_test_pack_to_inventory(p_shop_item_code text default 'season_0_test_pack_shop')` is implemented for Owner-only shop purchases that add pack quantity without opening.
- `tcg_owner_open_owned_pack(p_pack_code text default 'season_0_test_pack')` is implemented for Owner-only owned-pack consumption and backend card rolls.
- `open_tcg_pack(p_pack_key text)` remains a later member-facing candidate after release planning.
- `admin_create_or_update_card(...)`
- `admin_adjust_pack_availability(...)`
- `sell_duplicate_card(p_card_key text, p_quantity integer)`
- `get_my_tcg_wallet()`

## Frontend Plan

30C Card Collection UI:

- Member-facing Card Collection page.
- Collection summary: owned count, total catalog count, duplicates, favorite count.
- Filters: rarity, type, set, owned/missing, favorites.
- Card grid with locked/missing state.
- Card detail modal with art, rarity frame, description, flavor text, and ownership count.
- Favorite toggle for owned cards.
- Mobile-first dark/crimson Anteiku style with sharp panels and no generic SaaS look.

Later UI:

- Profile showcase section.
- Pack opening page and result modal.
- Shop/free economy page.
- Admin TCG management tools.

## i18n Plan

All player/admin text should be added to EN/FR/DE dictionaries before UI rollout.

Likely key groups:

- `tcg.title`
- `tcg.collection`
- `tcg.catalog`
- `tcg.owned`
- `tcg.missing`
- `tcg.duplicates`
- `tcg.favorite`
- `tcg.rarity`
- `tcg.cardType`
- `tcg.set`
- `tcg.openPack`
- `tcg.packResults`
- `tcg.adminGrant`
- `tcg.permissionDenied`

## Asset Pipeline

AI-generated images must be inner artwork only.

The app should render:

- Frame overlay.
- Rarity badge.
- Card name.
- Ownership count.
- Duplicate count.
- Favorite/showcase state.
- Future coin value.

Generated art should not include:

- Card frame.
- Text.
- Rarity badge.
- Coin value.
- Nameplate.
- UI, borders, or pack labels.

Recommended structure:

- `public/assets/tcg/frames/common_frame.png`
- `public/assets/tcg/frames/uncommon_frame.png`
- `public/assets/tcg/frames/rare_frame.png`
- `public/assets/tcg/frames/epic_frame.png`
- `public/assets/tcg/frames/legendary_frame.png`
- `public/assets/tcg/frames/mythic_frame.png`
- `public/assets/tcg/art/s0_001_20th_ward_civilian.png`
- `public/assets/tcg/art/s0_019_anteiku_server.png`
- `public/assets/tcg/art/s0_033_young_one_eyed_ghoul.png`
- `public/assets/tcg/art/s0_042_half_mask_awakening.png`
- `public/assets/tcg/art/s0_050_anteiku_origin.png`

Milestone 30C-C temporary smoke assets:

- The five files above are present as temporary generated smoke-test art.
- They are intended only for Owner preview testing and should be replaced later with approved final artwork.

Milestone 30C-D temporary full-set import:

- All 50 Season 0 target files are now present under `public/assets/tcg/art/`.
- The remaining 45 files were imported from the approved deterministic batch mapping.
- The exact duplicate source file `ChatGPT Image May 31, 2026, 09_32_31 PM.png` was ignored; `ChatGPT Image May 31, 2026, 09_32_27 PM (1).png` is the source for S0-041.
- These assets are temporary and should be replaced later with approved final artwork.

Vite/Vercel asset rule:

- Files placed in `public/assets/tcg/art/` are served at `/assets/tcg/art/...`.
- Example repo path `public/assets/tcg/art/s0_001_20th_ward_civilian.png` maps to served path `/assets/tcg/art/s0_001_20th_ward_civilian.png`.
- The database `tcg_cards.art_path` should store the served root path (`/assets/tcg/art/...`), which is already the current Season 0 convention.
- Do not use Supabase Storage or upload flows for the current Owner preview.

Art guidance:

- 3:4 vertical composition.
- Safe margins for frame overlay.
- No generated text.
- Rarity mood can influence lighting, but the reusable app frame owns the final rarity presentation.

## Phase 30B Seed Guidance

30B uses the supplied canonical `Season 0: Anteiku Origins` catalog v0.1 as the source of truth.

Production status:

- Migration `20260601000100_tcg_30b_catalog_inventory.sql` is applied and verified in production.
- Dry-run showed only the 30B migration before apply.
- Production DB verification confirmed TCG tables/RLS/RPCs, Season 0 counts, no broad direct table grants, no CP references, and active Owner count `1`.
- Rollback-wrapped production smoke confirmed approved-member catalog/collection reads and blocked direct inventory/admin-grant paths for a normal member.
- No real production inventory grant/card ownership mutation was performed.

## Phase 30C-A Owner Preview

Implemented:

- Owner-only `/tcg` route and nav entry.
- RPC-only frontend service for catalog, collection, and favorite toggle.
- Season 0 album grid with owned/missing/favorite states.
- Collection progress cards.
- All/Owned/Missing/Favorites filters and rarity filter.
- Card detail sheet with rarity, type, faction, collector value, quantity, and favorite action when owned.
- Missing-art placeholder for catalog cards whose image assets are not present yet.

Validation:

- `npm.cmd run build` passed.
- Source checks found no direct table reads/writes, no normal CP paths, no uploads/Storage, and no frontend admin-grant call.
- Production bundle verification confirmed the deployed frontend contains the owner TCG preview and read/favorite RPC calls.

Security:

- The preview remains Owner-only through the existing active admin context.
- Non-Owner direct URL access should render the blocked preview state.
- Backend/RPC remains the authority for card ownership and favorites.

## Phase 30C-A2 Owner Smoke Grant

Implemented:

- Owner-only smoke grant button on `/tcg`.
- Uses existing RPC `tcg_admin_grant_card`.
- Targets only the current active Owner profile from active admin context.
- Grants exactly:
  - `s0_001_20th_ward_civilian` quantity `3`
  - `s0_019_anteiku_server` quantity `2`
  - `s0_033_young_one_eyed_ghoul` quantity `1`
  - `s0_042_half_mask_awakening` quantity `1`
  - `s0_050_anteiku_origin` quantity `1`
- Uses reason `30C-A owner visual smoke`.
- Refetches collection and switches to Owned after success.
- Disables once the active Owner profile has at least the requested quantities.

Validation:

- `npm.cmd run build` passed.
- Source checks found no direct inventory/event writes and no normal CP paths in the TCG page/service.
- Production bundle verification passed.

Expected smoke result:

- Unique owned: `5 / 50`
- Total owned quantity: `8`
- Owned filter: `5` cards
- Missing filter: `45` cards

Codex did not click the production button during implementation.

## Phase 30C-B Album Visual Polish + Asset Pipeline

Implemented:

- Premium CSS-only card presentation for `/tcg`.
- Distinct rarity accents for Common, Uncommon, Rare, Epic, Legendary, and Mythic.
- Improved missing-art placeholder with card number, rarity, card name, crimson texture, and locked-state treatment.
- Tighter owned quantity pill and favorite state styling.
- More polished progress stat cards.
- Detail sheet rarity styling and stronger metadata layout.
- Smoke grant panel remains visually marked as testing-only.
- Added:
  - `public/assets/tcg/art/README.md`
  - `public/assets/tcg/frames/README.md`

Validation:

- `npm.cmd run build` passed.
- Source checks found no direct TCG table reads/writes, no normal CP paths, no service-role path, and no upload/Storage behavior in the TCG page/service path.

Security:

- Owner-only guard unchanged.
- RPC-only frontend path unchanged.
- No backend/RPC/SQL changes.
- No packs, shop, economy, currency, wallet, drop rates, payments, uploads, Storage, or generated images.

## Phase 30C-C First Smoke-Card Art Assets

Implemented:

- Added only the five temporary smoke-test inner-art PNG files from the supplied `S0` source set.
- Copied/renamed them to the canonical public asset filenames already used by the Season 0 catalog.
- Kept the other 45 cards on polished placeholders.
- Made no CSS/frontend adjustments because the images are `1086x1448`, matching the expected 3:4 card-art composition.

Added files:

- `public/assets/tcg/art/s0_001_20th_ward_civilian.png`
- `public/assets/tcg/art/s0_019_anteiku_server.png`
- `public/assets/tcg/art/s0_033_young_one_eyed_ghoul.png`
- `public/assets/tcg/art/s0_042_half_mask_awakening.png`
- `public/assets/tcg/art/s0_050_anteiku_origin.png`

Validation:

- `npm.cmd run build` passed.
- Asset dimensions verified at `1086x1448`.
- No SQL, RPC, service, catalog seed, Storage/upload, pack, shop, economy, or CP changes.

## Phase 30C-D Full Season 0 Temporary Art Import

Implemented:

- Added the remaining 45 temporary generated inner-art PNG files.
- All 50 Season 0 catalog `art_path` filenames now exist under `public/assets/tcg/art/`.
- Kept the five 30C-C smoke-card assets aligned with the same mapping and verified their hashes.
- Used the approved deterministic source mapping:
  - Batch 1 items 1-10 -> S0-001 through S0-010
  - Batch 2 items 1-10 -> S0-011 through S0-020
  - Batch 3 items 1-10 -> S0-021 through S0-030
  - Batch 4 items 1-10 -> S0-031 through S0-040
  - Batch 5 items 1-10 -> S0-041 through S0-050
- Ignored the exact duplicate unsuffixed Batch 5 item 1 source.
- No UI/CSS adjustment was needed because all target images are `1086x1448`.

Validation:

- All 50 local target files exist.
- All 50 are valid PNGs at `1086x1448`.
- `npm.cmd run build` passed.
- No SQL, RPC, service, catalog seed, Storage/upload, pack, shop, economy, member visibility, or CP changes.

## Phase 30D-A Owner-Only Test Pack Backend/RPC

Implemented:

- `tcg_packs`
- `tcg_pack_drop_rates`
- `tcg_pack_openings`
- New pack-opening event/source values in `tcg_inventory_events`.
- Seeded `season_0_test_pack`, Owner-test-only, 5 cards per pack.
- Seeded integer drop weights:
  - Common `6000`
  - Uncommon `2500`
  - Rare `1000`
  - Epic `400`
  - Legendary `90`
  - Mythic `10`
- RPC `tcg_owner_open_test_pack(p_pack_code text default 'season_0_test_pack')`.

RPC rules:

- Owner-only.
- Active approved Owner profile is resolved server-side.
- Backend calculates drops; frontend must never calculate pack results.
- Duplicates are allowed.
- Inventory is updated transactionally by the RPC.
- One inventory event is written per card.
- One pack opening history row is written per opening.
- No currency or pack cost exists yet.
- No member-facing pack access exists yet.

Validation:

- Local Supabase reset passed.
- `tcg_30d_pack_validation.sql` passed `18 PASS / 0 FAIL / 0 SKIP`.
- Existing `tcg_30b_validation.sql` passed `19 PASS / 0 FAIL / 0 SKIP`.
- Broad `local_validation_anteiku.sql` regression suite passed.
- `npm.cmd run build` passed.

Production:

- Dry-run showed only `20260601000200_tcg_owner_pack_backend.sql` pending.
- Migration applied to production.
- Production DB verification confirmed new tables/RLS, no broad direct grants, RPC existence/authenticated execute grant, seeded pack/rates, and active Owner count `1`.
- No production pack-opening mutation smoke was performed without explicit approval.

## Phase 30D-B Owner-Only Pack Preview UI

Implemented:

- Owner-only `Season 0 Test Pack` preview panel on `/tcg`.
- Frontend RPC wrapper `tcgOwnerOpenTestPack()` for `tcg_owner_open_test_pack`.
- One button: `Open Test Pack`.
- The backend remains the sole authority for card drops, duplicate stacking, inventory events, and opening history.
- Result display shows the returned five cards with art, name, card number, rarity, new/duplicate state, quantity delta, and resulting owned quantity.
- The collection refetches after a successful pack opening.
- Added EN/FR/DE copy and CSS-only reveal styling.

Validation:

- `npm.cmd run build` passed.
- Source checks found no direct TCG table reads/writes, no pack/drop table reads, no client-side drop calculation, no normal CP paths, no service-role path, and no uploads/Storage in the TCG page/service path.
- Production bundle verification confirmed the pack UI and `tcg_owner_open_test_pack` wrapper are deployed.

Production status:

- Codex did not click `Open Test Pack` in production.
- No production pack-opening/inventory mutation was created by the rollout.
- Owner can now manually test pack opening from `/tcg`.

## Phase 30E-A Owner-Only Shop/Economy Backend

Implemented backend/RPC only:

- `tcg_wallets`
- `tcg_wallet_ledger`
- `tcg_shop_items`
- RLS enabled and direct anon/authenticated table grants revoked for the new economy tables.
- Currency code constrained to `anteiku_coins`.
- Seeded Owner-test-only shop item:
  - `season_0_test_pack_shop`
  - `Season 0 Test Pack`
  - `price = 100`
  - linked to `season_0_test_pack`
- Refactored the Owner test pack opening internals into private helper `private.tcg_open_owner_test_pack_for_profile(...)` so the existing free Owner test pack RPC and the new shop purchase RPC share the same backend-authoritative roll/inventory/event/history flow.
- Preserved existing `tcg_owner_open_test_pack(p_pack_code text default 'season_0_test_pack')` behavior.
- Added Owner-only RPCs:
  - `tcg_owner_grant_test_coins(p_amount integer default 1000)`
  - `tcg_get_my_wallet()`
  - `tcg_owner_get_test_shop()`
  - `tcg_owner_buy_test_pack(p_shop_item_code text default 'season_0_test_pack_shop')`

RPC behavior:

- Owner-only through the existing active-profile/admin context.
- No arbitrary frontend `profile_id` is accepted.
- Coin grants are test-only and write wallet ledger rows.
- Shop purchases lock the wallet row, reject insufficient balance, deduct `anteiku_coins`, write a ledger spend row, open the pack server-side, write pack opening/inventory history, and return safe pack result metadata.
- Frontend/client code still does not calculate drops or mutate inventory.
- No member-facing shop UI, payments, premium currency, storage/uploads, or economy release was added.

Validation:

- Local `npx.cmd supabase db reset` passed through `20260601000300_tcg_owner_shop_economy.sql`.
- `supabase/tests/tcg_30e_shop_validation.sql` passed `32 PASS / 0 FAIL / 0 SKIP`.
- Existing `supabase/tests/tcg_30d_pack_validation.sql` passed `18 PASS / 0 FAIL / 0 SKIP`.
- Existing `supabase/tests/tcg_30b_validation.sql` passed `19 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed.

Production:

- Production dry-run showed exactly one pending migration: `20260601000300_tcg_owner_shop_economy.sql`.
- Migration was applied to production and migration list shows `20260601000300` applied remotely.
- Read-only production verification confirmed:
  - `tcg_wallets`, `tcg_wallet_ledger`, and `tcg_shop_items` exist with RLS enabled.
  - No direct anon/authenticated client grants exist on the new economy tables.
  - `season_0_test_pack_shop` is seeded as active Owner-test-only, priced at `100 anteiku_coins`.
  - New public RPCs exist and authenticated execute grants are present.
  - Anon execute is denied for checked Owner mutation RPCs.
  - The private pack-opening helper is not executable by authenticated clients.
  - New TCG economy RPC definitions contain no CP table/RPC references.
  - Simulated authenticated direct reads of `member_cp` and `cp_snapshots` returned zero visible rows.
  - Active Owner count remains `1`.
- No production Owner coin grant, shop purchase, wallet mutation, or pack purchase smoke was performed without explicit approval.

## Phase 30E-B Owner-Only Shop/Economy UI Preview

Implemented frontend-only:

- Owner-only `TCG Shop Test` panel on `/tcg`.
- Frontend RPC wrappers:
  - `tcgGetMyWallet()` -> `tcg_get_my_wallet`
  - `tcgOwnerGetTestShop()` -> `tcg_owner_get_test_shop`
  - `tcgOwnerGrantTestCoins(amount = 1000)` -> `tcg_owner_grant_test_coins`
  - `tcgOwnerBuyTestPack(shopItemCode = 'season_0_test_pack_shop')` -> `tcg_owner_buy_test_pack`
- Wallet balance display for `Anteiku Coins`.
- Owner test/dev action `Grant 1000 test coins`.
- Owner shop item display for `Season 0 Test Pack`, price `100 Anteiku Coins`, and backend-drop note.
- `Buy Test Pack` action that displays backend-returned pack results and refetches wallet plus collection after success.
- Reused the existing pack result card reveal UI for shop purchase results.
- Added EN/FR/DE copy and dark/crimson mobile-first shop styling.

Validation:

- `npm.cmd run build` passed.
- Source checks found no SQL/migration changes, no direct TCG table reads/writes, no client-side pack drop generation, no `member_cp`/`cp_snapshots` paths in the touched TCG page/service, no service-role path, no payments, and no uploads/Storage.
- Owner-only guard remains the existing `/tcg` active Owner check; non-Owner direct `/tcg` remains blocked by the page guard.

Production:

- Commit `8e7eb73 feat: add owner tcg shop preview` was pushed to `main`.
- Vercel deployed bundle `assets/index-Dh0VeSsd.js`.
- Non-mutating production smoke confirmed `/tcg` returns HTTP `200` and the deployed bundle contains the shop UI plus all four 30E-A shop/economy RPC wrapper names.
- Codex did not click `Grant 1000 test coins` or `Buy Test Pack` in production.
- Owner can now perform controlled manual shop-loop smoke: grant test coins, buy the test pack, verify wallet decreases by `100`, verify five backend-returned cards display, and verify collection quantity increases by `+5`.

## Phase 30E-C Owner-Only Shop/Pack UX Polish

Implemented frontend/style-only:

- Polished the Owner-only `TCG Shop Test` panel so it reads more like a dark game shop and less like an admin/debug box.
- Wallet balance now has a stronger currency-HUD treatment.
- Shop item card has stronger crimson/gold accents and a clearer price/action area.
- Free Owner test pack panel remains visually distinct with dashed testing treatment.
- Pack result stage now has a darker reveal surface, crimson texture, rarity glow, and stronger Epic/Legendary/Mythic impact.
- Added card reveal index markers and refined CSS-only reveal timing.
- Added reduced-motion coverage for the new shop loading accent.
- Added ref-based double-submit guards for favorite, smoke grant, free test pack, test coin grant, and shop purchase actions.
- Kept current test values unchanged:
  - grant amount `1000`
  - test pack price `100 Anteiku Coins`
  - test pack size `5`
  - drop weights unchanged

Validation:

- `npm.cmd run build` passed.
- Source checks found only `src/pages/TcgCollection.jsx` and `src/styles/app.css` changed.
- No SQL/migrations/backend/RPC/RLS/package/service-worker changes were made.
- No direct TCG table reads/writes were added; the only `.from` match was JavaScript `Array.from`.
- No `member_cp`, `cp_snapshots`, CP RPC, service-role, payment, upload, or Storage path was added in the touched TCG files.

Production:

- Commit `053f27d style: polish owner tcg shop ux` was pushed to `main`.
- Vercel deployed bundle assets `index-CqwRGfAC.js` and `index-BsBoxApK.css`.
- Non-mutating production smoke confirmed `/tcg` returns HTTP `200` and the deployed bundle contains the new polish markers.
- Codex did not click `Grant smoke cards`, `Open Test Pack`, `Grant 1000 test coins`, `Buy Test Pack`, or favorite toggle in production.
- Owner manual mutation smoke remains the next validation step.

## Phase 30E-D Compact TCG Hub / Windowed UI Polish

Implemented frontend/style-only:

- Refactored the Owner-only `/tcg` preview into a compact game-style hub.
- Added a compact header with Season 0 title, Owner preview badge, Refresh, and quick stats for unique owned, total owned quantity, favorites, and Anteiku Coins.
- Added frontend-only window tabs:
  - Album
  - Packs
  - Shop
  - Owner Lab
- Kept Album as the default window with progress, filters, rarity filter, compact card grid, detail sheet, and favorite behavior.
- Moved free test pack opening into the Packs window.
- Moved test shop purchase into the Shop window.
- Moved `Grant smoke cards` and `Grant 1000 test coins` into Owner Lab so mutation controls are clearly separated from the normal album/shop preview.
- Kept current test values unchanged:
  - grant amount `1000`
  - test pack price `100 Anteiku Coins`
  - pack size `5`
  - drop weights unchanged

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks found only `src/pages/TcgCollection.jsx`, `src/styles/app.css`, and EN/FR/DE i18n files changed.
- No SQL/migrations/backend/RPC/RLS/package/service-worker changes were made.
- No direct TCG table reads/writes were added; the only `.from` match in the touched TCG path was JavaScript `Array.from`.
- No `member_cp`, `cp_snapshots`, CP RPC, service-role, payment, upload, or Storage path was added in the touched TCG files.

Production:

- Commit `d1f4c4a style: add compact tcg hub layout` was pushed to `main`.
- Vercel deployed bundle assets `index-B1zvnfTg.js` and `index-E_s9esTL.css`.
- Non-mutating production smoke confirmed `/tcg` returns HTTP `200` and the deployed bundle contains the new hub/window/Owner Lab markers.
- Codex did not click `Grant smoke cards`, `Open Test Pack`, `Grant 1000 test coins`, `Buy Test Pack`, or favorite toggle in production.
- Owner manual shop-loop smoke remains the next validation step.

## Phase 30F-A Owner-Only Balance Report Backend

Implemented backend/RPC only:

- New migration `20260601000400_tcg_owner_balance_report.sql`.
- New read-only RPC `tcg_owner_get_balance_report()`.
- Resolves the active Owner profile server-side through the existing active admin context.
- Rejects non-Owner active profiles.
- Returns structured JSONB for TCG balancing review:
  - collection summary;
  - rarity ownership summary;
  - pack opening summary;
  - rarity pull summary;
  - economy summary;
  - duplicate/card pressure summary;
  - balance hints with raw computed values.
- Uses existing TCG tables only.
- Does not mutate inventory, wallet, ledger, pack openings, prices, drop rates, or pack size.
- Does not expose the report to members and does not add a frontend analytics UI yet.

Security:

- Owner-only through backend `private.active_admin_profile_id()` and `private.is_owner(...)`.
- RPC has no arbitrary profile id parameter.
- Execute is granted to authenticated clients only, with Owner checks inside the function.
- No direct member access, service-role path, payment/premium path, uploads, Storage, CP joins, or CP payload fields were added.

Validation:

- Local `npx.cmd supabase db reset` passed.
- `supabase/tests/tcg_30f_balance_report_validation.sql` passed `20 PASS / 0 FAIL / 0 SKIP`.
- Regression validation passed:
  - `supabase/tests/tcg_30b_validation.sql`: `19 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30d_pack_validation.sql`: `18 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30e_shop_validation.sql`: `32 PASS / 0 FAIL / 0 SKIP`
- Broad `supabase/tests/local_validation_anteiku.sql` passed.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.

Production:

- Production dry-run showed exactly one pending migration: `20260601000400_tcg_owner_balance_report.sql`.
- Migration was applied to production and migration list shows `20260601000400` applied remotely.
- Read-only production verification confirmed:
  - RPC exists.
  - Authenticated execute grant exists and anon execute is not granted.
  - Function definition contains no CP table references.
  - Simulated active Owner report call returned the expected report sections.
  - Normal member call was denied.
  - Report payload check found no CP/private token exposure.
  - Active Owner count remains `1`.
- No production wallet, inventory, ledger, opening, price, drop-rate, or pack-size mutation was performed.

## Phase 30F-B Owner-Only Pack Inventory Backend

Implemented backend/RPC only:

- New migration `20260601000500_tcg_owner_pack_inventory.sql`.
- New tables:
  - `tcg_player_packs`
  - `tcg_pack_inventory_events`
- New Owner-only RPCs:
  - `tcg_get_my_packs()`
  - `tcg_owner_buy_test_pack_to_inventory(p_shop_item_code text default 'season_0_test_pack_shop')`
  - `tcg_owner_open_owned_pack(p_pack_code text default 'season_0_test_pack')`
- Shop-to-inventory purchase flow now exists for future UI:
  - deducts `100 anteiku_coins`;
  - writes a wallet ledger spend row;
  - increments owned `Season 0 Test Pack` quantity by `+1`;
  - writes a pack inventory event;
  - does not roll cards;
  - does not update card inventory;
  - does not write pack opening history.
- Owned-pack opening flow now exists for future UI:
  - checks owned pack quantity;
  - consumes `-1` pack quantity;
  - writes a pack inventory event;
  - rolls cards backend-side through the existing private pack helper;
  - adds five card quantities;
  - writes card inventory events and pack opening history;
  - returns backend-generated pack results and remaining pack quantity.

Backward compatibility:

- Existing `tcg_owner_buy_test_pack(...)` is preserved and still buys-and-opens immediately for the currently deployed frontend.
- Existing free Owner `tcg_owner_open_test_pack(...)` is preserved.
- Future frontend should move to the new inventory-based purchase/opening RPCs.

Security:

- Owner-only through existing active-profile/admin authority.
- No arbitrary profile id is accepted.
- RLS is enabled on the new pack inventory tables.
- Direct anon/authenticated table grants are revoked.
- Frontend must use RPCs only and must never calculate drops or mutate pack inventory directly.
- No member-facing TCG release, CP joins, CP payload fields, payment/premium path, uploads, Storage, price changes, drop-rate changes, or pack-size changes were added.

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

- Production dry-run initially hit a transient Supabase pooler auth/circuit-breaker error before SQL execution; after cooldown, rerun succeeded.
- Clean dry-run showed exactly one pending migration: `20260601000500_tcg_owner_pack_inventory.sql`.
- Migration was applied to production and migration list shows `20260601000500` applied remotely.
- Read-only production verification confirmed:
  - new tables exist;
  - RLS is enabled on both;
  - no direct anon/authenticated table grants exist;
  - all three new RPCs exist;
  - authenticated execute grants exist and anon execute is not granted;
  - new RPC definitions contain no CP table references;
  - Owner can read pack inventory through RPC;
  - normal member is denied pack inventory RPC access;
  - normal member direct `member_cp` read remains empty/blocked;
  - active Owner count remains `1`.
- Codex did not perform production pack buy, owned-pack open, wallet mutation, inventory mutation, or pack-opening smoke.

## Phase 30F-C Owner-Only Pack Inventory UI

Status: complete and deployed through commit `ada2b74 feat: add tcg pack inventory opening ui`.

Implemented:

- Shop `Buy Test Pack` now calls `tcg_owner_buy_test_pack_to_inventory(...)`.
- Shop purchases add a pack to inventory and do not reveal card results in the Shop.
- Packs now calls `tcg_get_my_packs()` and displays owned Season 0 Test Pack quantity.
- Packs uses a CSS-only 4:3 pack sprite/card treatment for the Owner test pack.
- Opening from Packs calls `tcg_owner_open_owned_pack(...)`; the backend consumes one owned pack and rolls five card results.
- The opening UI uses a dimmed/blurred overlay, swipe-left/right rip gesture, fallback `Rip Open` button, card-by-card reveal, and `Reveal all`.
- Pack animations are local UI state, default enabled, and can be disabled without changing backend behavior.
- The older free Owner `Open Test Pack` path remains available only in Owner Lab.
- EN/FR/DE copy and dark/crimson mobile styling were added.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed no SQL/migration, Supabase/RLS/RPC, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend TCG checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `ada2b74` was pushed to `main` and Vercel served the updated production bundle.
- Non-mutating production smoke passed: `/tcg?tcg-pack-inventory-smoke=1` returned HTTP 200 and the deployed bundle contained `tcg_get_my_packs`, `tcg_owner_buy_test_pack_to_inventory`, `tcg_owner_open_owned_pack`, `packInventory`, `swipeToRip`, and `packAnimations`.
- Codex did not click production Buy, Open, Rip, Grant, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-D Temporary Pack Front + Card Back Assets

Status: complete and deployed through commit `6bcebab feat: add tcg pack and card back assets`.

Assets:

- Pack front: `public/assets/tcg/packs/season0_test_pack_front.png`
- Card back: `public/assets/tcg/cards/tcg_card_back_season0.png`
- Added asset READMEs under `public/assets/tcg/packs/` and `public/assets/tcg/cards/`.

Implemented:

- Packs window uses the temporary Season 0 pack-front asset.
- Pack opening overlay uses the same pack-front asset.
- Unrevealed pack result cards use the temporary Season 0 card-back asset.
- If either asset fails to load, the existing CSS/text placeholder fallback remains available.
- Revealed cards still use backend-returned card art/details.
- Swipe/rip, `Rip Open`, `Reveal all`, and pack animation setting behavior were preserved.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Build output contains the pack-front and card-back files under `dist/assets/tcg/packs/` and `dist/assets/tcg/cards/`.
- Source validation confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `6bcebab` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg?tcg-assets-smoke=1` returned HTTP 200.
  - `/assets/tcg/packs/season0_test_pack_front.png` returned HTTP 200 image/png.
  - `/assets/tcg/cards/tcg_card_back_season0.png` returned HTTP 200 image/png.
  - Deployed bundle `assets/index-DW84VTFX.js` references both new asset paths and still contains `tcg_get_my_packs` / `tcg_owner_open_owned_pack`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-E Pack UI Compact Hotfix

Status: complete and deployed through commit `bc3c705 fix: compact tcg pack inventory ui`.

Implemented:

- Removed the hard app-side rectangular box/background around the pack-front image.
- Kept the pack visual floating on the dark panel with subtler glow/shadow.
- Kept a compact `xN` quantity badge near the pack.
- Moved `Open Pack` directly under the pack and made it a smaller compact action.
- Disabled `Open Pack` at quantity `0` remains readable.
- Shop no longer auto-switches to Packs after `tcg_owner_buy_test_pack_to_inventory(...)` succeeds.
- Shop success stays inline with pack-added / current pack quantity copy.
- Added a small `Go to Packs` secondary action for manual navigation.
- Added EN/FR/DE `tcg.goToPacks` copy.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.
- The temporary pack/card-back PNGs are `Format24bppRgb`, so they do not have alpha transparency. CSS can remove the app wrapper box, but cannot remove opaque black pixels baked into the artwork.

Production:

- Commit `bc3c705` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg?tcg-pack-compact-smoke=1` returned HTTP 200.
  - Deployed bundle `assets/index-DLnPnWpl.js` contains `tcg-owned-open-button`, `tcg-shop-success-actions`, `Go to Packs`, `tcg_owner_buy_test_pack_to_inventory`, and `tcg_owner_open_owned_pack`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-F Pack/Reveal UI Polish Hotfix

Status: complete and deployed through commit `e77a385 style: polish tcg pack reveal ui`.

Implemented:

- Added a local, safe canvas cleanup pass for the pack-front image that turns near-black edge-connected background pixels transparent when possible.
- Canvas cleanup is frontend-only, pack-image-only, cached per asset path, and falls back to the original image if processing fails.
- Tightened the Packs window into a collectible-style display with the pack as the hero.
- Kept compact quantity badge and compact `Open Pack` action.
- Simplified reveal overlay so the pack name/status appears once in the top bar.
- Added compact reveal toolbar with revealed-card count and `Reveal all`.
- Improved reveal grid spacing and alignment for unrevealed/revealed mixed states.
- Reduced unrevealed card clutter while keeping the temporary Season 0 card-back asset.
- Preserved Shop stay-in-Shop behavior, swipe/rip, `Rip Open`, tap-to-reveal, `Reveal all`, pack animation setting, and refresh after opening.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `e77a385` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg?tcg-reveal-polish-smoke=1` returned HTTP 200.
  - Deployed bundle `assets/index-BPcKi_cv.js` contains `tcg-reveal-toolbar`, `tcg-owned-pack-stage`, `tcg_owner_open_owned_pack`, and `tcg_owner_buy_test_pack_to_inventory`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-G Pack Front + Real Card Back Asset Wire-Up

Status: complete and deployed through commit `332e38f fix: use tcg card back for reveal cards`.

Implemented:

- Kept the canonical pack front at `/assets/tcg/packs/season0_test_pack_front.png`.
- Pack front remains limited to pack inventory and pack opening/rip overlay presentation.
- Wired unrevealed pack result cards to the canonical real card-back asset at `/assets/tcg/cards/tcg_card_back_season0.png`.
- Kept the CSS/React card-back design as fallback if the card-back image fails.
- Kept the `Tap to Reveal` label small and overlaid.
- Preserved Shop/Packs behavior: Shop purchases stay in Shop, `Go to Packs` remains manual, pack count stays in Packs, and `Open Pack` remains compact.
- Preserved Open Pack, swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, pack animation toggle, collection refetch, and pack quantity refetch behavior.

Asset verification:

- Pack front: `public/assets/tcg/packs/season0_test_pack_front.png`, 1086x1448 PNG, 1,799,800 bytes.
- Card back: `public/assets/tcg/cards/tcg_card_back_season0.png`, 1086x1448 PNG, 2,185,757 bytes.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `332e38f` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg` app shell returned HTTP 200.
  - Deployed bundle `assets/index-DZ6Xj5gs.js` and CSS `assets/index-D5PKDyGy.css` contain the real card-back image wire-up/styling.
  - `/assets/tcg/packs/season0_test_pack_front.png` returned HTTP 200 and 1,799,800 bytes.
  - `/assets/tcg/cards/tcg_card_back_season0.png` returned HTTP 200 and 2,185,757 bytes.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-H Owner-Only TCG UI Polish Pass

Status: complete and deployed through commit `3d92c37 style: polish owner tcg ui`.

Implemented:

- Polished the overall `/tcg` page into a compact Owner-only game hub.
- Tightened top header hierarchy, refresh action, and HUD stat cards.
- Improved Album filter density, rarity selector, card grid density, owned/missing/favorite states, hover/focus treatment, and detail sheet sizing.
- Improved Packs composition while keeping the pack front as the hero and `Open Pack` compact.
- Added an existing pack-front preview to Shop items and tightened wallet, price, purchase, success, and `Go to Packs` presentation.
- Reworked Owner Lab into a separated test-only section for smoke grants and test coins.
- Polished reveal overlay spacing, toolbar, hidden/revealed card grid sizing, and mobile safety.

Preserved behavior:

- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- Packs open owned packs through backend RPC.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `3d92c37` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg?tcg-ui-polish-smoke=2` returned HTTP 200.
  - Deployed bundle `assets/index-C9n3v1dY.js` contains `tcg-shop-pack-preview` and `tcg-owner-lab-section`.
  - Deployed CSS `assets/index-DSO3TEr-.css` contains `tcg-shop-pack-preview`, `tcg-owner-lab-section`, and `tcg-hub-hero`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-I Windowed Pack/Shop Layout Hotfix

Status: complete and deployed through commit `14219fe style: make tcg pack shop windows compact`.

Implemented:

- Converted the owned Packs item from a full-width row into a compact centered pack window/card.
- Kept the pack front as the hero with quantity badge and compact `Open Pack` action under/near the pack.
- Centered compact metadata chips and no-pack state around the pack card.
- Converted Shop items from full-width dashboard rows into compact 3:4-style shelf cards.
- Kept the pack image as Shop item art, with pack name, price, and `Buy Test Pack` in the compact card.
- Kept wallet in the Shop header/HUD area.
- Kept purchase success inline and compact, with `Go to Packs` as a secondary action.
- Added responsive CSS so compact items center on desktop and stack without horizontal overflow on mobile.

Preserved behavior:

- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- Packs open owned packs through backend RPC.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed only `src/styles/app.css` changed for the source hotfix.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.
- Owner-only `/tcg` source guard remains based on `activeAdminContext?.isOwner`.

Production:

- Commit `14219fe` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg?tcg-windowed-pack-shop-smoke=1` returned HTTP 200.
  - Deployed CSS `assets/index-lRpgZHRE.css` contains the compact pack/shop layout rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-J Slim Windows + Wallet HUD Polish

Status: complete and deployed through commit `7840366 style: slim tcg pack shop wallet ui`.

Implemented:

- Slimmed the owned Packs card into a tighter centered pack window.
- Reduced the pack preview size, metadata chip weight, copy density, and `Open Pack` button size while keeping the control tappable.
- Slimmed Shop item cards with smaller pack previews, tighter product copy, compact price areas, and smaller `Buy Test Pack` controls.
- Reworked the Shop wallet display into a compact gold/crimson game-currency HUD.
- Added matching gold/crimson styling to the top Anteiku Coins HUD stat.
- Added responsive CSS so Packs, Shop cards, and wallet HUD stay compact on desktop and safe on mobile.

Preserved behavior:

- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- Packs open owned packs through backend RPC.
- Wallet values remain backend-derived.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed only `src/styles/app.css` changed for the source patch.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, no service-role path, and no client-side wallet authority.
- Owner-only `/tcg` source guard remains based on `activeAdminContext?.isOwner`.

Production:

- Commit `7840366` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg?tcg-slim-wallet-smoke=1` returned the production app shell.
  - Deployed CSS `assets/index-Bzxq0oc_.css` contains the slim pack, slim shop, and wallet HUD rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-K Wallet Icon HUD Hotfix

Status: complete and deployed through commit `07d65a9 style: polish tcg wallet hud icon`.

Implemented:

- Replaced the wallet HUD glowing-square mark with a compact CSS wallet/currency object.
- Added a wallet body, flap, and clasp using pseudo-elements.
- Used restrained dark gold, black, and crimson styling so the icon reads as a wallet/token without becoming too bright.
- Added the same visual language to the top Anteiku Coins HUD stat.

Preserved behavior:

- Wallet balance remains backend-derived.
- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- Packs open owned packs through backend RPC.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed only `src/styles/app.css` changed for the source patch.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, no service-role path, and no client-side wallet authority.

Production:

- Commit `07d65a9` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg?tcg-wallet-icon-smoke=1` returned the production app shell.
  - Deployed CSS `assets/index-CIvARjRw.css` contains the wallet body, flap, clasp, and Anteiku Coins HUD icon rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-L Centering / Alignment Hotfix

Status: complete and deployed through commit `ff94b1c style: center tcg shop pack windows`.

Implemented:

- Centered the owned Packs card inside the Packs window while keeping the panel header full-width.
- Aligned the pack image, quantity badge, metadata, and `Open Pack` action on one cleaner visual axis.
- Centered the compact Shop item card/list inside the Shop window on a dedicated content rail.
- Kept the wallet HUD in the Shop header while preventing it from visually pulling the main card off-center.
- Added mobile rules so the Shop card stays centered with safe margins and no horizontal overflow.

Preserved behavior:

- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- `Go to Packs` remains manual.
- Packs open owned packs through backend RPC.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed only `src/styles/app.css` changed for the source patch.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, no service-role path, and no client-side wallet authority.

Production:

- Commit `ff94b1c` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg?tcg-centering-smoke=1` returned the production app shell.
  - Deployed CSS `assets/index-Cm2PILN7.css` contains the centering content rail, pack card centering, wallet alignment, and mobile width rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## Phase 30F-M Owner-Only Balance Report UI

Status: complete and deployed through commit `4c4ebc6 feat: add owner tcg balance report ui`.

Implemented:

- Added a `Balance` tab/window to the Owner-only `/tcg` hub.
- Added frontend service wrapper `tcgOwnerGetBalanceReport()` for the existing production RPC `tcg_owner_get_balance_report()`.
- Displayed collection summary, rarity ownership, pack summary, rarity pulls, economy summary, duplicate pressure, and balance hints.
- Added loading, empty, error, and `Refresh Report` states.
- Added EN/FR/DE labels and mobile-safe report styling.

Preserved behavior:

- TCG remains Owner-only.
- Album, Packs, Shop, Owner Lab, pack opening/reveal, wallet, pack inventory, favorite toggle, smoke grant, and test coin controls remain unchanged.
- Balance report is read-only and does not apply price, drop-rate, pack-size, wallet, or economy changes.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed frontend-only changes in `src/pages/TcgCollection.jsx`, `src/services/tcgService.js`, `src/styles/app.css`, and EN/FR/DE i18n.
- Frontend checks confirmed no direct TCG table access, no `member_cp` or `cp_snapshots` in the TCG page/service path, no CP analytics RPCs, no client-side drops, no payments/uploads/storage additions, no service-role path, and no client-side wallet authority.

Production:

- Commit `4c4ebc6` was pushed to `main`.
- Non-mutating production smoke passed:
  - `/tcg?tcg-balance-ui-smoke=1` returned the production app shell.
  - Deployed bundle `assets/index-BQrXiP8d.js` contains `tcg_owner_get_balance_report` and Balance UI text.
  - Deployed CSS `assets/index-D23BkU1w.css` contains the Balance report panel/table rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

Canonical v0.1 rules:

- Exactly 50 cards.
- Common 18, Uncommon 14, Rare 9, Epic 5, Legendary 3, Mythic 1.
- Character 24, Scene 16, Relic 10, Organization 0.
- No pack/drop/economy/combat stats.
- Collector values are display values only, not spendable currency.
- `art_path` stores the canonical inner-art asset path.
- `image_url` and `thumbnail_url` remain `NULL` until/unless a later asset pipeline needs them.
- Normal CP must not be referenced.

## Risks

- CP privacy regression if TCG joins or displays protected CP data.
- Inventory write abuse if direct table writes are accidentally granted.
- Client-side pack manipulation if drop logic is exposed to the browser.
- Currency duplication if wallet changes are not append-only and transactional.
- Active-profile identity bugs if RPCs use legacy `auth.uid()` profile assumptions.
- Bloated first implementation if pack/shop/economy are mixed into the catalog milestone.
- Inconsistent card assets if generated art includes text or baked frames.
- Production-direct migration mistakes if dry-run gating is skipped.

## Validation Plan

30B backend validation:

- Local migration/reset applies cleanly.
- RLS enabled on new tables.
- Approved member can read active catalog through RPC.
- Pending/restricted users denied where appropriate.
- Active profile can read only its own inventory.
- Direct inventory writes are blocked.
- Admin grant RPC validates actor permission and target profile.
- Admin grant creates inventory and audit/event row.
- Favorite toggle only works for owned cards.
- No `member_cp`, `cp_snapshots`, normal CP RPCs, or CP payload fields are used.
- Active Owner count remains `1`.

30C frontend validation:

- `npm.cmd run build`.
- No direct inventory writes from frontend.
- No client-side pack/economy logic.
- Card Collection page works on mobile.
- EN/FR/DE labels render.
- No raw translation keys.
- No CP values visible.

Production-direct gate for future SQL:

- Confirm git status and latest commit.
- Link production deliberately.
- Run `npx.cmd supabase migration list`.
- Run `npx.cmd supabase db push --dry-run`.
- Proceed only if exactly the expected TCG migration is pending.
- Verify schema/RLS/RPCs after apply.
- Deploy frontend only after target DB has the needed migration.
