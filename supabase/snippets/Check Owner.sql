select id, username, ign, approval_status, approved_at
from public.profiles
where id = '7d1d78c6-3545-4522-9861-62ee979a32e6';

select gm.profile_id, g.name as guild_name, gm.role, gm.membership_status, gm.is_primary
from public.guild_memberships gm
join public.guilds g on g.id = gm.guild_id
where gm.profile_id = '7d1d78c6-3545-4522-9861-62ee979a32e6';
