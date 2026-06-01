Place TCG card inner-art PNG files in this folder.

Vite serves files in `public/` from the site root, so:

- `public/assets/tcg/art/s0_001_20th_ward_civilian.png`
- becomes `/assets/tcg/art/s0_001_20th_ward_civilian.png`

The database `tcg_cards.art_path` values should match the served root path.
Do not put card art in Supabase Storage for the current TCG preview.

Milestone 30C-D adds temporary generated art for all 50 Season 0 cards.

Milestone 30C-C first added smoke-test art for these five cards:

- `s0_001_20th_ward_civilian.png`
- `s0_019_anteiku_server.png`
- `s0_033_young_one_eyed_ghoul.png`
- `s0_042_half_mask_awakening.png`
- `s0_050_anteiku_origin.png`

30C-D then imported the remaining 45 cards using the approved deterministic batch mapping:

- Batch 1 items 1-10 -> S0-001 through S0-010
- Batch 2 items 1-10 -> S0-011 through S0-020
- Batch 3 items 1-10 -> S0-021 through S0-030
- Batch 4 items 1-10 -> S0-031 through S0-040
- Batch 5 items 1-10 -> S0-041 through S0-050

The exact duplicate source file `ChatGPT Image May 31, 2026, 09_32_31 PM.png` was intentionally ignored. Use `ChatGPT Image May 31, 2026, 09_32_27 PM (1).png` as Batch 5 item 1 / S0-041.

These are temporary preview assets and should be replaced later with approved final artwork.
