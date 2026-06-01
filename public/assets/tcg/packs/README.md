Place TCG pack-front preview assets in this folder.

Vite serves files in `public/` from the site root, so:

- `public/assets/tcg/packs/season0_test_pack_front.png`
- becomes `/assets/tcg/packs/season0_test_pack_front.png`

Milestone 30F-D adds a temporary Season 0 test pack front for the Owner-only `/tcg` pack inventory and opening overlay.

These assets are frontend presentation assets only:

- no Supabase Storage;
- no uploads;
- no pack drop logic;
- no pricing or economy authority;
- no CP data.

They may be replaced later with approved final pack artwork.
