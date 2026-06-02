Place shared TCG card presentation assets in this folder.

Vite serves files in `public/` from the site root, so:

- `public/assets/tcg/cards/tcg_card_back_season0.png`
- becomes `/assets/tcg/cards/tcg_card_back_season0.png`

Milestone 30F-D added the initial temporary Season 0 card back for unrevealed cards in the Owner-only `/tcg` pack opening flow.

Milestone 30F-G replaces/wires the canonical card-back asset through commit `332e38f fix: use tcg card back for reveal cards`.

Current canonical asset:

- `tcg_card_back_season0.png`
- 1086x1448 PNG
- used for unrevealed face-down cards in the Owner-only pack reveal stage
- CSS/React card-back styling remains as fallback if this image fails to load

Card backs in this folder are frontend presentation assets only:

- no Supabase Storage;
- no uploads;
- no client-side drop calculation;
- no inventory authority;
- no CP data.

They may be replaced later with approved final card-back artwork.
