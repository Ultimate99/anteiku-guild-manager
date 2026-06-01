Place TCG card inner-art PNG files in this folder.

Vite serves files in `public/` from the site root, so:

- `public/assets/tcg/art/s0_001_20th_ward_civilian.png`
- becomes `/assets/tcg/art/s0_001_20th_ward_civilian.png`

The database `tcg_cards.art_path` values should match the served root path.
Do not put card art in Supabase Storage for the current TCG preview.

Milestone 30C-C adds temporary smoke-test art for only these five cards:

- `s0_001_20th_ward_civilian.png`
- `s0_019_anteiku_server.png`
- `s0_033_young_one_eyed_ghoul.png`
- `s0_042_half_mask_awakening.png`
- `s0_050_anteiku_origin.png`

The remaining Season 0 cards intentionally keep the polished placeholder until their final approved art is ready.
