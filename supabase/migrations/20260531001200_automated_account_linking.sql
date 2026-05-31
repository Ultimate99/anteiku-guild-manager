-- Anteiku Guild Manager - Automated account linking support.
-- Adds a credential-verified link type so a second auth account can be
-- linked without disabling that account's existing owner self-link.

alter table public.user_profile_links
  drop constraint if exists user_profile_links_type_chk;

alter table public.user_profile_links
  add constraint user_profile_links_type_chk
  check (link_type in ('owner', 'verified'));

create index if not exists user_profile_links_verified_active_idx
  on public.user_profile_links (auth_user_id, profile_id, created_at desc)
  where disabled_at is null and link_type = 'verified';
