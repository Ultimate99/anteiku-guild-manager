Place shared TCG card presentation assets in this folder.

Vite serves files in `public/` from the site root, so:

- `public/assets/tcg/cards/tcg_card_back_season0.png`
- becomes `/assets/tcg/cards/tcg_card_back_season0.png`

Milestone 30F-D adds a temporary Season 0 card back for unrevealed cards in the Owner-only `/tcg` pack opening flow.

Card backs in this folder are frontend presentation assets only:

- no Supabase Storage;
- no uploads;
- no client-side drop calculation;
- no inventory authority;
- no CP data.

They may be replaced later with approved final card-back artwork.
