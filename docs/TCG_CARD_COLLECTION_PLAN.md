# TCG/Card Collection Plan

Milestone 30A planning started this document. Milestone 30B is implemented, locally validated, and production-applied through `20260601000100_tcg_30b_catalog_inventory.sql`. Milestone 30C-A Owner-only Card Collection preview UI is deployed through commit `dbb67da feat: add owner tcg collection preview`; Milestone 30C-A2 Owner-only smoke grant control is deployed through commit `e96a489 feat: add owner tcg smoke grant`; Milestone 30C-B album visual polish and repo-served asset-pipeline notes are implemented. Pack opening, shop, economy, and generated/real card artwork remain unimplemented.

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

- Pack opening and drop-rate logic.
- Economy, wallets, duplicate burning, shop, and premium currency.
- Payments or real-money purchase flows.
- Battles, card stats, trading, marketplace, or public collection pages.

## Recommended Milestones

- 30B: Card catalog + inventory backend/RPC. Complete and production-applied.
- 30C-A: Owner-only Card Collection preview UI. Complete and deployed.
- 30C-A2: Owner-only smoke grant control. Complete and deployed.
- 30C-B: Album visual polish + art asset pipeline notes. Complete.
- 30C-C: Real art asset add/import after approved artwork exists.
- 30C-D: Member release planning after Owner acceptance.
- 30D: Pack opening backend/RPC.
- 30E: Pack opening animation/UI.
- 30F: Free shop/economy.
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
- `open_tcg_pack(p_pack_key text)`
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
