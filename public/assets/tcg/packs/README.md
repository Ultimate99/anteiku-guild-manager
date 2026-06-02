Place TCG pack-front preview assets in this folder.

Vite serves files in `public/` from the site root, so:

- `public/assets/tcg/packs/season0_test_pack_front.png`
- becomes `/assets/tcg/packs/season0_test_pack_front.png`

Milestone 30F-D added the initial temporary Season 0 test pack front for the Owner-only `/tcg` pack inventory and opening overlay.

Milestone 30F-G replaces/wires the canonical pack-front asset through commit `332e38f fix: use tcg card back for reveal cards`.

Current canonical asset:

- `season0_test_pack_front.png`
- 1086x1448 PNG
- used only for pack inventory and pack opening/rip overlay presentation

These assets are frontend presentation assets only:

- no Supabase Storage;
- no uploads;
- no pack drop logic;
- no pricing or economy authority;
- no CP data.

They may be replaced later with approved final pack artwork.
