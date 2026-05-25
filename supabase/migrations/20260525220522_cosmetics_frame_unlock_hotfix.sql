-- Anteiku Guild Manager - Cosmetics frame unlock hotfix
-- Only Arena and KOF frame families are manual locked frames.
-- All other frame rows are free/unlocked, with cosmetic_catalog.unlock_type
-- remaining the runtime source of truth.

update public.cosmetic_catalog
set
  unlock_type = case
    when key like 'TXK_Arena%' then 'manual'
    when key like 'TXK_KOF%' then 'manual'
    else 'free'
  end,
  updated_at = now()
where type = 'frame'
  and unlock_type is distinct from case
    when key like 'TXK_Arena%' then 'manual'
    when key like 'TXK_KOF%' then 'manual'
    else 'free'
  end;
