Place final TCG card inner-art PNG files in this folder.

Vite serves files in `public/` from the site root, so:

- `public/assets/tcg/art/s0_001_20th_ward_civilian.png`
- becomes `/assets/tcg/art/s0_001_20th_ward_civilian.png`

The database `tcg_cards.art_path` values should match the served root path.
Do not put card art in Supabase Storage for the current TCG preview.
