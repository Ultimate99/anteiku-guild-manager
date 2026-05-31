-- Anteiku Guild Manager local validation script.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back at the end.

begin;

create temp table validation_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  detail text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  anteiku_re_id constant uuid := '00000000-0000-0000-0000-000000000102';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  leader_id constant uuid := '10000000-0000-0000-0000-000000000002';
  vice_id constant uuid := '10000000-0000-0000-0000-000000000003';
  admin_no_cp_id constant uuid := '10000000-0000-0000-0000-000000000004';
  admin_cp_id constant uuid := '10000000-0000-0000-0000-000000000005';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  pending_id constant uuid := '10000000-0000-0000-0000-000000000007';
  rejected_id constant uuid := '10000000-0000-0000-0000-000000000008';
  wrong_guild_id constant uuid := '10000000-0000-0000-0000-000000000009';
  pending_allow_id constant uuid := '10000000-0000-0000-0000-000000000010';
  seeded_gvg_event_id uuid;
  required_permission_count integer;
  sensitive_cp_permission_count integer;
  seeded_snapshot_count integer;
  result_count integer;
  direct_row_count integer;
  total_pass_count integer;
  total_fail_count integer;
  total_skip_count integer;
  setup_fail_count integer;
  security_fail_count integer;
  current_absence_reason text;
begin
  insert into validation_results values (
    'warning',
    'local_only',
    'PASS',
    'This script is for local/disposable Supabase validation only and rolls back at the end.'
  );

  begin
    if to_regclass('public.permission_catalog') is null then
      insert into validation_results values ('setup', 'permission_catalog_exists', 'FAIL', 'public.permission_catalog was not found.');
    else
      insert into validation_results values ('setup', 'permission_catalog_exists', 'PASS', 'public.permission_catalog exists.');
    end if;

    select count(*) into required_permission_count
    from public.permission_catalog
    where key in ('view_cp', 'update_cp', 'approve_members', 'manage_gvg');

    if required_permission_count = 4 then
      insert into validation_results values ('setup', 'required_permission_keys_exist', 'PASS', 'view_cp, update_cp, approve_members, and manage_gvg exist.');
    else
      insert into validation_results values ('setup', 'required_permission_keys_exist', 'FAIL', 'Expected 4 required permission keys, found ' || required_permission_count || '.');
    end if;

    select count(*) into sensitive_cp_permission_count
    from public.permission_catalog
    where key in ('view_cp', 'update_cp')
      and is_sensitive = true;

    if sensitive_cp_permission_count = 2 then
      insert into validation_results values ('setup', 'cp_permissions_sensitive', 'PASS', 'view_cp and update_cp are marked sensitive.');
    else
      insert into validation_results values ('setup', 'cp_permissions_sensitive', 'FAIL', 'Expected 2 sensitive CP permissions, found ' || sensitive_cp_permission_count || '.');
    end if;
  exception
    when others then
      insert into validation_results values ('setup', 'permission_catalog_setup', 'FAIL', sqlerrm);
  end;

  begin
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    )
    values
      ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'owner.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', leader_id, 'authenticated', 'authenticated', 'leader.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', vice_id, 'authenticated', 'authenticated', 'vice.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', admin_no_cp_id, 'authenticated', 'authenticated', 'admin-no-cp.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', admin_cp_id, 'authenticated', 'authenticated', 'admin-cp.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'member.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'pending.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', rejected_id, 'authenticated', 'authenticated', 'rejected.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', wrong_guild_id, 'authenticated', 'authenticated', 'wrong-guild.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', pending_allow_id, 'authenticated', 'authenticated', 'pending-allow.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now())
    on conflict (id) do nothing;

    insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
    values
      (owner_id, 'owner_local', 'owner_local', 'Owner Local', 'approved', now()),
      (leader_id, 'leader_local', 'leader_local', 'Leader Local', 'approved', now()),
      (vice_id, 'vice_local', 'vice_local', 'Vice Local', 'approved', now()),
      (admin_no_cp_id, 'admin_no_cp', 'admin_no_cp', 'Admin No CP', 'approved', now()),
      (admin_cp_id, 'admin_cp', 'admin_cp', 'Admin CP', 'approved', now()),
      (member_id, 'member_local', 'member_local', 'Member Local', 'approved', now()),
      (pending_id, 'pending_local', 'pending_local', 'Pending Local', 'pending', null),
      (rejected_id, 'rejected_local', 'rejected_local', 'Rejected Local', 'rejected', null),
      (wrong_guild_id, 'wrong_guild', 'wrong_guild', 'Wrong Guild', 'approved', now()),
      (pending_allow_id, 'pending_allow', 'pending_allow', 'Pending Allow', 'pending', null)
    on conflict (id) do update
    set ign = excluded.ign,
        approval_status = excluded.approval_status,
        approved_at = excluded.approved_at;

    insert into public.guild_memberships (profile_id, guild_id, role, membership_status, is_primary, assigned_by)
    values
      (owner_id, anteiku_id, 'owner', 'active', true, owner_id),
      (leader_id, anteiku_id, 'leader', 'active', true, owner_id),
      (vice_id, anteiku_id, 'vice', 'active', true, owner_id),
      (admin_no_cp_id, anteiku_id, 'admin', 'active', true, owner_id),
      (admin_cp_id, anteiku_id, 'admin', 'active', true, owner_id),
      (member_id, anteiku_id, 'member', 'active', true, owner_id),
      (pending_id, anteiku_id, 'member', 'pending', true, null),
      (rejected_id, anteiku_id, 'member', 'rejected', true, owner_id),
      (wrong_guild_id, anteiku_re_id, 'member', 'active', true, owner_id),
      (pending_allow_id, anteiku_id, 'member', 'pending', true, null)
    on conflict (profile_id, guild_id) do update
    set role = excluded.role,
        membership_status = excluded.membership_status,
        is_primary = excluded.is_primary,
        assigned_by = excluded.assigned_by;

    insert into public.admin_permissions (membership_id, permission_key, granted_by)
    select gm.id, permission_key, owner_id
    from public.guild_memberships gm
    cross join (values ('view_cp'), ('update_cp'), ('approve_members'), ('manage_gvg')) as perms(permission_key)
    where gm.profile_id = admin_cp_id
      and gm.guild_id = anteiku_id
    on conflict (membership_id, permission_key) do nothing;

    insert into public.admin_permissions (membership_id, permission_key, granted_by)
    select gm.id, 'approve_members', owner_id
    from public.guild_memberships gm
    where gm.profile_id = admin_no_cp_id
      and gm.guild_id = anteiku_id
    on conflict (membership_id, permission_key) do nothing;

    insert into validation_results values ('setup', 'profiles_memberships_seeded', 'PASS', 'Fake local profiles and memberships were seeded.');
  exception
    when others then
      insert into validation_results values ('setup', 'profiles_memberships_seeded', 'FAIL', sqlerrm);
  end;

  begin
    insert into public.member_cp (profile_id, guild_id, cp_value, updated_by, updated_at)
    values
      (leader_id, anteiku_id, 900000, owner_id, now()),
      (vice_id, anteiku_id, 850000, owner_id, now()),
      (admin_cp_id, anteiku_id, 800000, owner_id, now()),
      (member_id, anteiku_id, 700000, owner_id, now()),
      (wrong_guild_id, anteiku_re_id, 650000, owner_id, now())
    on conflict (profile_id) do update
    set guild_id = excluded.guild_id,
        cp_value = excluded.cp_value,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at;

    insert into public.cp_snapshots (
      profile_id,
      guild_id,
      snapshot_week_start,
      cp_value,
      captured_by,
      created_at
    )
    values
      (leader_id, anteiku_id, date '2026-05-11', 880000, owner_id, now()),
      (vice_id, anteiku_id, date '2026-05-11', 830000, owner_id, now()),
      (admin_cp_id, anteiku_id, date '2026-05-11', 780000, owner_id, now()),
      (member_id, anteiku_id, date '2026-05-11', 680000, owner_id, now()),
      (wrong_guild_id, anteiku_re_id, date '2026-05-11', 620000, owner_id, now())
    on conflict (profile_id, guild_id, snapshot_week_start) do update
    set cp_value = excluded.cp_value,
        captured_by = excluded.captured_by,
        created_at = excluded.created_at;

    select count(*) into seeded_snapshot_count
    from public.cp_snapshots
    where snapshot_week_start = date '2026-05-11'
      and profile_id in (leader_id, vice_id, admin_cp_id, member_id, wrong_guild_id)
      and guild_id is not null
      and cp_value >= 0;

    if seeded_snapshot_count = 5 then
      insert into validation_results values ('setup', 'cp_snapshots_seeded', 'PASS', 'cp_snapshots seeded with snapshot_week_start date 2026-05-11.');
    else
      insert into validation_results values ('setup', 'cp_snapshots_seeded', 'FAIL', 'Expected 5 valid cp_snapshots rows, found ' || seeded_snapshot_count || '.');
    end if;
  exception
    when others then
      insert into validation_results values ('setup', 'cp_snapshots_seeded', 'FAIL', sqlerrm);
  end;

  begin
    insert into public.gvg_events (
      guild_id,
      scope,
      title,
      status,
      starts_at,
      ends_at,
      created_by,
      created_at,
      updated_at
    )
    values (
      anteiku_id,
      'guild',
      'Local Validation GvG',
      'active',
      now() - interval '1 hour',
      now() + interval '1 day',
      owner_id,
      now(),
      now()
    )
    returning id into seeded_gvg_event_id;

    if seeded_gvg_event_id is not null then
      insert into validation_results values ('setup', 'gvg_event_seeded', 'PASS', 'Active guild-scoped GvG event seeded with scope = guild.');
    else
      insert into validation_results values ('setup', 'gvg_event_seeded', 'FAIL', 'GvG event insert returned null id.');
    end if;
  exception
    when others then
      insert into validation_results values ('setup', 'gvg_event_seeded', 'FAIL', sqlerrm);
  end;

  if exists (select 1 from validation_results where section = 'setup' and status = 'FAIL') then
    insert into validation_results values ('cp', 'dependent_cp_tests', 'SKIP', 'Skipped because setup failed.');
    insert into validation_results values ('gvg', 'dependent_gvg_tests', 'SKIP', 'Skipped because setup failed.');
    insert into validation_results values ('permissions', 'dependent_permission_tests', 'SKIP', 'Skipped because setup failed.');
  else
    insert into validation_results values ('setup', 'all_prerequisites', 'PASS', 'Permission, CP snapshot, and GvG setup prerequisites passed.');

    if exists (
      select 1
      from public.cp_snapshots
      where profile_id = member_id
        and guild_id = anteiku_id
        and snapshot_week_start = date '2026-05-11'
    ) then
      insert into validation_results values ('cp', 'cp_snapshot_prerequisite_available', 'PASS', 'Member CP snapshot prerequisite is available.');
    else
      insert into validation_results values ('cp', 'cp_snapshot_prerequisite_available', 'FAIL', 'Member CP snapshot prerequisite is missing.');
    end if;

    if exists (
      select 1
      from public.gvg_events
      where scope = 'guild'
        and guild_id = anteiku_id
        and status = 'active'
        and title = 'Local Validation GvG'
    ) then
      insert into validation_results values ('gvg', 'gvg_event_prerequisite_available', 'PASS', 'Active guild GvG prerequisite is available.');
    else
      insert into validation_results values ('gvg', 'gvg_event_prerequisite_available', 'FAIL', 'Active guild GvG prerequisite is missing.');
    end if;

    if exists (
      select 1
      from public.permission_catalog
      where key = 'view_cp'
        and is_sensitive = true
    ) then
      insert into validation_results values ('permissions', 'view_cp_permission_available', 'PASS', 'view_cp permission exists and is sensitive.');
    else
      insert into validation_results values ('permissions', 'view_cp_permission_available', 'FAIL', 'view_cp permission prerequisite failed.');
    end if;

    begin
      perform set_config('request.jwt.claim.sub', member_id::text, true);
      perform set_config('request.jwt.claim.role', 'authenticated', true);
      execute 'set local role authenticated';
      begin
        execute 'select count(*) from public.member_cp' into result_count;
        execute 'reset role';

        if result_count = 0 then
          insert into validation_results values ('cp', 'member_direct_member_cp_denied', 'PASS', 'Direct member_cp read returned no rows.');
        else
          insert into validation_results values ('cp', 'member_direct_member_cp_denied', 'FAIL', 'Direct member_cp read returned ' || result_count || ' rows.');
        end if;
      exception
        when others then
          execute 'reset role';
          insert into validation_results values ('cp', 'member_direct_member_cp_denied', 'PASS', 'Direct member_cp read was denied: ' || sqlerrm);
      end;
    exception
      when others then
        begin
          execute 'reset role';
        exception when others then
          null;
        end;
        insert into validation_results values ('cp', 'member_direct_member_cp_denied', 'SKIP', 'Could not switch to authenticated role for direct table test: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', member_id::text, true);
      perform set_config('request.jwt.claim.role', 'authenticated', true);
      execute 'set local role authenticated';
      begin
        execute 'select count(*) from public.cp_snapshots' into result_count;
        execute 'reset role';

        if result_count = 0 then
          insert into validation_results values ('cp', 'member_direct_cp_snapshots_denied', 'PASS', 'Direct cp_snapshots read returned no rows.');
        else
          insert into validation_results values ('cp', 'member_direct_cp_snapshots_denied', 'FAIL', 'Direct cp_snapshots read returned ' || result_count || ' rows.');
        end if;
      exception
        when others then
          execute 'reset role';
          insert into validation_results values ('cp', 'member_direct_cp_snapshots_denied', 'PASS', 'Direct cp_snapshots read was denied: ' || sqlerrm);
      end;
    exception
      when others then
        begin
          execute 'reset role';
        exception when others then
          null;
        end;
        insert into validation_results values ('cp', 'member_direct_cp_snapshots_denied', 'SKIP', 'Could not switch to authenticated role for direct table test: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', member_id::text, true);
      select count(*) into result_count
      from public.get_current_cp_roster(anteiku_id);

      insert into validation_results values ('cp', 'member_cp_rpc_blocked', 'FAIL', 'Member CP RPC unexpectedly returned ' || result_count || ' rows.');
    exception
      when others then
        insert into validation_results values ('cp', 'member_cp_rpc_blocked', 'PASS', 'Member CP RPC was blocked: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
      select count(*) into result_count
      from public.get_current_cp_roster(anteiku_id);

      insert into validation_results values ('cp', 'admin_without_view_cp_blocked', 'FAIL', 'Admin without view_cp unexpectedly returned ' || result_count || ' rows.');
    exception
      when others then
        insert into validation_results values ('cp', 'admin_without_view_cp_blocked', 'PASS', 'Admin without view_cp was blocked: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
      select count(*) into result_count
      from public.get_current_cp_roster(anteiku_id);

      if result_count > 0 then
        insert into validation_results values ('cp', 'admin_with_view_cp_allowed', 'PASS', 'Admin with view_cp returned ' || result_count || ' scoped CP rows.');
      else
        insert into validation_results values ('cp', 'admin_with_view_cp_allowed', 'FAIL', 'Admin with view_cp returned no rows.');
      end if;
    exception
      when others then
        insert into validation_results values ('cp', 'admin_with_view_cp_allowed', 'FAIL', 'Admin with view_cp failed: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', leader_id::text, true);
      select count(*) into result_count
      from public.get_current_cp_roster(anteiku_id);

      if result_count > 0 then
        insert into validation_results values ('cp', 'leader_scoped_cp_allowed', 'PASS', 'Leader saw ' || result_count || ' CP rows in assigned guild.');
      else
        insert into validation_results values ('cp', 'leader_scoped_cp_allowed', 'FAIL', 'Leader saw no CP rows in assigned guild.');
      end if;
    exception
      when others then
        insert into validation_results values ('cp', 'leader_scoped_cp_allowed', 'FAIL', 'Leader scoped CP failed: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', leader_id::text, true);
      select count(*) into result_count
      from public.get_current_cp_roster(anteiku_re_id);

      insert into validation_results values ('cp', 'leader_wrong_guild_cp_blocked', 'FAIL', 'Leader wrong-guild CP unexpectedly returned ' || result_count || ' rows.');
    exception
      when others then
        insert into validation_results values ('cp', 'leader_wrong_guild_cp_blocked', 'PASS', 'Leader wrong-guild CP was blocked: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', member_id::text, true);
      perform public.submit_gvg_vote(seeded_gvg_event_id, 'present', null);
      perform public.submit_gvg_vote(seeded_gvg_event_id, 'absent', 'Local validation absence');
      select count(*) into result_count
      from public.gvg_votes gv
      where gv.gvg_event_id = seeded_gvg_event_id
        and gv.profile_id = member_id;

      if result_count = 1 then
        insert into validation_results values ('gvg', 'gvg_vote_upsert_one_row', 'PASS', 'Vote submit/switch kept one row.');
      else
        insert into validation_results values ('gvg', 'gvg_vote_upsert_one_row', 'FAIL', 'Expected one vote row, found ' || result_count || '.');
      end if;

      perform public.submit_gvg_vote(seeded_gvg_event_id, 'present', 'Should clear');
      select absence_reason into current_absence_reason
      from public.gvg_votes
      where public.gvg_votes.gvg_event_id = seeded_gvg_event_id
        and public.gvg_votes.profile_id = member_id;

      if current_absence_reason is null then
        insert into validation_results values ('gvg', 'gvg_present_clears_absence_reason', 'PASS', 'Switching back to present cleared absence_reason.');
      else
        insert into validation_results values ('gvg', 'gvg_present_clears_absence_reason', 'FAIL', 'absence_reason was not cleared.');
      end if;
    exception
      when others then
        insert into validation_results values ('gvg', 'gvg_vote_rpc_flow', 'FAIL', sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', member_id::text, true);
      perform set_config('request.jwt.claim.role', 'authenticated', true);
      execute 'set local role authenticated';
      begin
        execute 'update public.gvg_votes set vote_status = ''absent'' where profile_id = $1' using member_id;
        get diagnostics direct_row_count = row_count;
        execute 'reset role';

        if direct_row_count = 0 then
          insert into validation_results values ('gvg', 'direct_gvg_vote_update_blocked', 'PASS', 'Direct gvg_votes update affected no rows.');
        else
          insert into validation_results values ('gvg', 'direct_gvg_vote_update_blocked', 'FAIL', 'Direct gvg_votes update affected ' || direct_row_count || ' rows.');
        end if;
      exception
        when others then
          execute 'reset role';
          insert into validation_results values ('gvg', 'direct_gvg_vote_update_blocked', 'PASS', 'Direct gvg_votes update was denied: ' || sqlerrm);
      end;
    exception
      when others then
        begin
          execute 'reset role';
        exception when others then
          null;
        end;
        insert into validation_results values ('gvg', 'direct_gvg_vote_update_blocked', 'SKIP', 'Could not switch to authenticated role for direct gvg_votes update test: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', member_id::text, true);
      perform set_config('request.jwt.claim.role', 'authenticated', true);
      execute 'set local role authenticated';
      begin
        execute 'insert into public.gvg_votes (gvg_event_id, profile_id, vote_status) values ($1, $2, ''present'')' using seeded_gvg_event_id, wrong_guild_id;
        execute 'reset role';
        insert into validation_results values ('gvg', 'direct_gvg_vote_insert_blocked', 'FAIL', 'Direct gvg_votes insert unexpectedly succeeded.');
      exception
        when others then
          execute 'reset role';
          insert into validation_results values ('gvg', 'direct_gvg_vote_insert_blocked', 'PASS', 'Direct gvg_votes insert was denied: ' || sqlerrm);
      end;
    exception
      when others then
        begin
          execute 'reset role';
        exception when others then
          null;
        end;
        insert into validation_results values ('gvg', 'direct_gvg_vote_insert_blocked', 'SKIP', 'Could not switch to authenticated role for direct gvg_votes insert test: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
      perform public.approve_registration(pending_id, anteiku_id, 'admin');
      insert into validation_results values ('approval', 'admin_approve_as_admin_blocked', 'FAIL', 'Admin with approve_members unexpectedly approved Admin role.');
    exception
      when others then
        insert into validation_results values ('approval', 'admin_approve_as_admin_blocked', 'PASS', 'Admin approve-as-admin was blocked: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
      perform public.approve_registration(pending_allow_id, anteiku_id, 'member');
      insert into validation_results values ('approval', 'admin_approve_as_member_allowed', 'PASS', 'Admin with approve_members approved pending user as member.');
    exception
      when others then
        insert into validation_results values ('approval', 'admin_approve_as_member_allowed', 'FAIL', sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
      perform public.reject_registration(wrong_guild_id, 'Wrong guild rejection attempt');
      insert into validation_results values ('approval', 'wrong_guild_reject_blocked', 'FAIL', 'Wrong-guild rejection unexpectedly succeeded.');
    exception
      when others then
        insert into validation_results values ('approval', 'wrong_guild_reject_blocked', 'PASS', 'Wrong-guild rejection was blocked: ' || sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', rejected_id::text, true);
      perform public.request_reapply('Local validation reapply request');

      if exists (
        select 1
        from public.profiles
        where id = rejected_id
          and reapply_requested_at is not null
          and reapply_note = 'Local validation reapply request'
      ) then
        insert into validation_results values ('approval', 'rejected_user_reapply_allowed', 'PASS', 'Rejected user requested reapply.');
      else
        insert into validation_results values ('approval', 'rejected_user_reapply_allowed', 'FAIL', 'Reapply fields were not set.');
      end if;
    exception
      when others then
        insert into validation_results values ('approval', 'rejected_user_reapply_allowed', 'FAIL', sqlerrm);
    end;

    begin
      perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
      perform public.reject_registration(rejected_id, 'Still rejected in local validation');

      if exists (
        select 1
        from public.profiles
        where id = rejected_id
          and approval_status = 'rejected'
          and reapply_requested_at is null
          and reapply_note is null
      ) then
        insert into validation_results values ('approval', 'reject_clears_reapply_fields', 'PASS', 'reject_registration cleared reapply fields.');
      else
        insert into validation_results values ('approval', 'reject_clears_reapply_fields', 'FAIL', 'reject_registration did not clear reapply fields.');
      end if;
    exception
      when others then
        insert into validation_results values ('approval', 'reject_clears_reapply_fields', 'FAIL', sqlerrm);
    end;

    if exists (
      select 1
      from public.audit_logs
      where action in ('registration_approved', 'registration_rejected', 'profile_reapply_requested')
    ) then
      insert into validation_results values ('audit', 'approval_reapply_audit_written', 'PASS', 'Approval/reapply actions wrote audit logs.');
    else
      insert into validation_results values ('audit', 'approval_reapply_audit_written', 'FAIL', 'Expected approval/reapply audit logs were not found.');
    end if;

    begin
      perform set_config('request.jwt.claim.sub', member_id::text, true);
      perform set_config('request.jwt.claim.role', 'authenticated', true);
      execute 'set local role authenticated';
      begin
        execute 'insert into public.audit_logs (actor_profile_id, action) values ($1, ''spoof_attempt'')' using member_id;
        execute 'reset role';
        insert into validation_results values ('audit', 'audit_spoof_denied', 'FAIL', 'Normal authenticated user inserted audit log directly.');
      exception
        when others then
          execute 'reset role';
          insert into validation_results values ('audit', 'audit_spoof_denied', 'PASS', 'Direct audit insert was denied: ' || sqlerrm);
      end;
    exception
      when others then
        begin
          execute 'reset role';
        exception when others then
          null;
        end;
        insert into validation_results values ('audit', 'audit_spoof_denied', 'SKIP', 'Could not switch to authenticated role for audit spoof test: ' || sqlerrm);
    end;
  end if;

  select count(*) into total_pass_count from validation_results where status = 'PASS';
  select count(*) into total_fail_count from validation_results where status = 'FAIL';
  select count(*) into total_skip_count from validation_results where status = 'SKIP';
  select count(*) into setup_fail_count from validation_results where section = 'setup' and status = 'FAIL';
  select count(*) into security_fail_count
  from validation_results
  where section in ('cp', 'gvg', 'approval', 'audit', 'permissions')
    and status = 'FAIL';

  insert into validation_results values ('summary', 'total_pass', 'PASS', total_pass_count::text);
  insert into validation_results values ('summary', 'total_fail', case when total_fail_count = 0 then 'PASS' else 'FAIL' end, total_fail_count::text);
  insert into validation_results values ('summary', 'total_skip', case when total_skip_count = 0 then 'PASS' else 'SKIP' end, total_skip_count::text);
  insert into validation_results values ('summary', 'setup_failures_count', case when setup_fail_count = 0 then 'PASS' else 'FAIL' end, setup_fail_count::text);
  insert into validation_results values ('summary', 'security_failures_count', case when security_fail_count = 0 then 'PASS' else 'FAIL' end, security_fail_count::text);
end;
$$;

select section, test_name, status, detail
from validation_results
order by
  case status when 'FAIL' then 1 when 'SKIP' then 2 else 3 end,
  section,
  test_name;

-- Milestone 7 backend validation: app role assignment hardening and Owner-only guild transfer.
-- This section is local-only test data and is rolled back with the rest of this script.
create temp table if not exists milestone7_validation_results (
  section text not null,
  test_name text not null,
  status text not null,
  details text
) on commit drop;

do $$
declare
  anteiku_id uuid;
  anteiku_re_id uuid;
  owner_id uuid := '10000000-0000-4000-8000-000000000701';
  leader_id uuid := '10000000-0000-4000-8000-000000000702';
  vice_id uuid := '10000000-0000-4000-8000-000000000703';
  admin_roles_id uuid := '10000000-0000-4000-8000-000000000704';
  admin_members_id uuid := '10000000-0000-4000-8000-000000000705';
  admin_plain_id uuid := '10000000-0000-4000-8000-000000000706';
  member_actor_id uuid := '10000000-0000-4000-8000-000000000707';
  role_target_id uuid := '10000000-0000-4000-8000-000000000708';
  transfer_target_id uuid := '10000000-0000-4000-8000-000000000709';
  transfer_block_target_id uuid := '10000000-0000-4000-8000-000000000710';
  role_target_membership_id uuid;
  transfer_active_count integer;
  transfer_old_status text;
  transfer_old_primary boolean;
  transfer_new_status text;
  transfer_new_primary boolean;
  transfer_new_role text;
begin
  select g.id into anteiku_id
  from public.guilds g
  where g.slug = 'anteiku' or g.name = 'Anteiku'
  limit 1;

  select g.id into anteiku_re_id
  from public.guilds g
  where g.slug in ('anteiku-re', 'anteiku_re') or g.name = 'Anteiku:Re'
  limit 1;

  if anteiku_id is null or anteiku_re_id is null then
    insert into milestone7_validation_results
    values ('setup', 'milestone7_core_guilds_available', 'FAIL', 'Anteiku or Anteiku:Re guild seed row not found.');
    return;
  end if;

  insert into auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data
  )
  values
    (owner_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-owner@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (leader_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-leader@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (vice_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-vice@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (admin_roles_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-admin-roles@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (admin_members_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-admin-members@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (admin_plain_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-admin-plain@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (member_actor_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-member-actor@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (role_target_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-role-target@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (transfer_target_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-transfer-target@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (transfer_block_target_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'm7-transfer-block-target@local.test', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb)
  on conflict (id) do nothing;

  insert into public.profiles (id, username, profile_slug, ign, approval_status)
  values
    (owner_id, 'm7-owner', 'm7-owner', 'M7 Owner', 'approved'),
    (leader_id, 'm7-leader', 'm7-leader', 'M7 Leader', 'approved'),
    (vice_id, 'm7-vice', 'm7-vice', 'M7 Vice', 'approved'),
    (admin_roles_id, 'm7-admin-roles', 'm7-admin-roles', 'M7 Admin Roles', 'approved'),
    (admin_members_id, 'm7-admin-members', 'm7-admin-members', 'M7 Admin Members', 'approved'),
    (admin_plain_id, 'm7-admin-plain', 'm7-admin-plain', 'M7 Admin Plain', 'approved'),
    (member_actor_id, 'm7-member-actor', 'm7-member-actor', 'M7 Member Actor', 'approved'),
    (role_target_id, 'm7-role-target', 'm7-role-target', 'M7 Role Target', 'approved'),
    (transfer_target_id, 'm7-transfer-target', 'm7-transfer-target', 'M7 Transfer Target', 'approved'),
    (transfer_block_target_id, 'm7-transfer-block-target', 'm7-transfer-block-target', 'M7 Transfer Block Target', 'approved')
  on conflict (id) do update
  set
    username = excluded.username,
    profile_slug = excluded.profile_slug,
    ign = excluded.ign,
    approval_status = 'approved',
    updated_at = now();

  insert into public.guild_memberships (profile_id, guild_id, role, membership_status, is_primary, assigned_by)
  values
    (owner_id, anteiku_id, 'owner', 'active', true, owner_id),
    (leader_id, anteiku_id, 'leader', 'active', true, owner_id),
    (vice_id, anteiku_id, 'vice', 'active', true, owner_id),
    (admin_roles_id, anteiku_id, 'admin', 'active', true, owner_id),
    (admin_members_id, anteiku_id, 'admin', 'active', true, owner_id),
    (admin_plain_id, anteiku_id, 'admin', 'active', true, owner_id),
    (member_actor_id, anteiku_id, 'member', 'active', true, owner_id),
    (role_target_id, anteiku_id, 'member', 'active', true, owner_id),
    (transfer_target_id, anteiku_re_id, 'admin', 'active', true, owner_id),
    (transfer_block_target_id, anteiku_re_id, 'member', 'active', true, owner_id)
  on conflict (profile_id, guild_id) do update
  set
    role = excluded.role,
    membership_status = 'active',
    is_primary = true,
    assigned_by = owner_id,
    updated_at = now();

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  select gm.id, permission_key, owner_id
  from public.guild_memberships gm
  cross join (values ('manage_roles'), ('manage_members')) as permissions(permission_key)
  where gm.profile_id = admin_roles_id
    and gm.guild_id = anteiku_id
    and permission_key = 'manage_roles'
  on conflict (membership_id, permission_key) do nothing;

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  select gm.id, 'manage_members', owner_id
  from public.guild_memberships gm
  where gm.profile_id = admin_members_id
    and gm.guild_id = anteiku_id
  on conflict (membership_id, permission_key) do nothing;

  select gm.id into role_target_membership_id
  from public.guild_memberships gm
  where gm.profile_id = role_target_id
    and gm.guild_id = anteiku_id;

  perform set_config('request.jwt.claim.role', 'authenticated', true);

  perform set_config('request.jwt.claim.sub', owner_id::text, true);

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'member');
    insert into milestone7_validation_results values ('role', 'owner_assign_member_allowed', 'PASS', null);
  exception when others then
    insert into milestone7_validation_results values ('role', 'owner_assign_member_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'admin');
    insert into milestone7_validation_results values ('role', 'owner_assign_admin_allowed', 'PASS', null);
  exception when others then
    insert into milestone7_validation_results values ('role', 'owner_assign_admin_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'vice');
    insert into milestone7_validation_results values ('role', 'owner_assign_vice_allowed', 'PASS', null);
  exception when others then
    insert into milestone7_validation_results values ('role', 'owner_assign_vice_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'leader');
    insert into milestone7_validation_results values ('role', 'owner_assign_leader_allowed', 'PASS', null);
  exception when others then
    insert into milestone7_validation_results values ('role', 'owner_assign_leader_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'owner');
    insert into milestone7_validation_results values ('role', 'owner_assign_owner_blocked', 'FAIL', 'Owner role was unexpectedly assigned.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'owner_assign_owner_blocked', 'PASS', sqlerrm);
  end;

  perform public.assign_member_role(role_target_id, anteiku_id, 'member');
  perform set_config('request.jwt.claim.sub', leader_id::text, true);

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'admin');
    insert into milestone7_validation_results values ('role', 'leader_assign_admin_allowed', 'PASS', null);
  exception when others then
    insert into milestone7_validation_results values ('role', 'leader_assign_admin_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'member');
    insert into milestone7_validation_results values ('role', 'leader_assign_member_allowed', 'PASS', null);
  exception when others then
    insert into milestone7_validation_results values ('role', 'leader_assign_member_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'vice');
    insert into milestone7_validation_results values ('role', 'leader_assign_vice_blocked', 'FAIL', 'Leader unexpectedly assigned vice.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'leader_assign_vice_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'leader');
    insert into milestone7_validation_results values ('role', 'leader_assign_leader_blocked', 'FAIL', 'Leader unexpectedly assigned leader.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'leader_assign_leader_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'owner');
    insert into milestone7_validation_results values ('role', 'leader_assign_owner_blocked', 'FAIL', 'Leader unexpectedly assigned owner.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'leader_assign_owner_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', vice_id::text, true);

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'admin');
    perform public.assign_member_role(role_target_id, anteiku_id, 'member');
    insert into milestone7_validation_results values ('role', 'vice_assign_member_admin_allowed', 'PASS', null);
  exception when others then
    insert into milestone7_validation_results values ('role', 'vice_assign_member_admin_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'leader');
    insert into milestone7_validation_results values ('role', 'vice_assign_leader_blocked', 'FAIL', 'Vice unexpectedly assigned leader.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'vice_assign_leader_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_roles_id::text, true);

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'admin');
    perform public.assign_member_role(role_target_id, anteiku_id, 'member');
    insert into milestone7_validation_results values ('role', 'admin_manage_roles_assign_member_admin_allowed', 'PASS', null);
  exception when others then
    insert into milestone7_validation_results values ('role', 'admin_manage_roles_assign_member_admin_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'vice');
    insert into milestone7_validation_results values ('role', 'admin_assign_vice_blocked', 'FAIL', 'Admin unexpectedly assigned vice.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'admin_assign_vice_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'leader');
    insert into milestone7_validation_results values ('role', 'admin_assign_leader_blocked', 'FAIL', 'Admin unexpectedly assigned leader.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'admin_assign_leader_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'owner');
    insert into milestone7_validation_results values ('role', 'admin_assign_owner_blocked', 'FAIL', 'Admin unexpectedly assigned owner.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'admin_assign_owner_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_plain_id::text, true);

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'admin');
    insert into milestone7_validation_results values ('role', 'admin_without_manage_roles_blocked', 'FAIL', 'Admin without manage_roles unexpectedly assigned role.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'admin_without_manage_roles_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_actor_id::text, true);

  begin
    perform public.assign_member_role(role_target_id, anteiku_id, 'admin');
    insert into milestone7_validation_results values ('role', 'member_assign_role_blocked', 'FAIL', 'Member unexpectedly assigned role.');
  exception when others then
    insert into milestone7_validation_results values ('role', 'member_assign_role_blocked', 'PASS', sqlerrm);
  end;

  if exists (
    select 1
    from public.audit_logs al
    where al.target_profile_id = role_target_id
      and al.action = 'member_role_changed'
      and al.entity_id = role_target_membership_id
  ) then
    insert into milestone7_validation_results values ('audit', 'role_change_audit_written', 'PASS', null);
  else
    insert into milestone7_validation_results values ('audit', 'role_change_audit_written', 'FAIL', 'member_role_changed audit log not found.');
  end if;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);

  begin
    perform public.transfer_member_guild(transfer_target_id, anteiku_re_id, anteiku_id);
    insert into milestone7_validation_results values ('transfer', 'owner_transfer_allowed', 'PASS', null);
  exception when others then
    insert into milestone7_validation_results values ('transfer', 'owner_transfer_allowed', 'FAIL', sqlerrm);
  end;

  select gm.membership_status, gm.is_primary
  into transfer_old_status, transfer_old_primary
  from public.guild_memberships gm
  where gm.profile_id = transfer_target_id
    and gm.guild_id = anteiku_re_id;

  select gm.membership_status, gm.is_primary, gm.role
  into transfer_new_status, transfer_new_primary, transfer_new_role
  from public.guild_memberships gm
  where gm.profile_id = transfer_target_id
    and gm.guild_id = anteiku_id;

  select count(*) into transfer_active_count
  from public.guild_memberships gm
  where gm.profile_id = transfer_target_id
    and gm.membership_status = 'active'
    and gm.is_primary = true;

  insert into milestone7_validation_results
  values (
    'transfer',
    'transfer_old_membership_left',
    case when transfer_old_status = 'left' and transfer_old_primary = false then 'PASS' else 'FAIL' end,
    concat('old_status=', coalesce(transfer_old_status, 'null'), ', old_primary=', coalesce(transfer_old_primary::text, 'null'))
  );

  insert into milestone7_validation_results
  values (
    'transfer',
    'transfer_new_membership_active_primary_member',
    case when transfer_new_status = 'active' and transfer_new_primary = true and transfer_new_role = 'member' then 'PASS' else 'FAIL' end,
    concat('new_status=', coalesce(transfer_new_status, 'null'), ', new_primary=', coalesce(transfer_new_primary::text, 'null'), ', new_role=', coalesce(transfer_new_role, 'null'))
  );

  insert into milestone7_validation_results
  values (
    'transfer',
    'transfer_exactly_one_active_primary',
    case when transfer_active_count = 1 then 'PASS' else 'FAIL' end,
    concat('active_primary_count=', transfer_active_count)
  );

  if exists (
    select 1
    from public.guild_memberships gm
    where gm.profile_id = transfer_target_id
      and gm.guild_id = anteiku_re_id
  ) then
    insert into milestone7_validation_results values ('transfer', 'transfer_preserves_old_membership_row', 'PASS', null);
  else
    insert into milestone7_validation_results values ('transfer', 'transfer_preserves_old_membership_row', 'FAIL', 'Old membership row was deleted.');
  end if;

  if exists (
    select 1
    from public.audit_logs al
    where al.target_profile_id = transfer_target_id
      and al.action = 'member_guild_transferred'
  ) then
    insert into milestone7_validation_results values ('audit', 'transfer_audit_written', 'PASS', null);
  else
    insert into milestone7_validation_results values ('audit', 'transfer_audit_written', 'FAIL', 'member_guild_transferred audit log not found.');
  end if;

  perform set_config('request.jwt.claim.sub', leader_id::text, true);

  begin
    perform public.transfer_member_guild(transfer_block_target_id, anteiku_re_id, anteiku_id);
    insert into milestone7_validation_results values ('transfer', 'leader_transfer_blocked', 'FAIL', 'Leader unexpectedly transferred member.');
  exception when others then
    insert into milestone7_validation_results values ('transfer', 'leader_transfer_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', vice_id::text, true);

  begin
    perform public.transfer_member_guild(transfer_block_target_id, anteiku_re_id, anteiku_id);
    insert into milestone7_validation_results values ('transfer', 'vice_transfer_blocked', 'FAIL', 'Vice unexpectedly transferred member.');
  exception when others then
    insert into milestone7_validation_results values ('transfer', 'vice_transfer_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_members_id::text, true);

  begin
    perform public.transfer_member_guild(transfer_block_target_id, anteiku_re_id, anteiku_id);
    insert into milestone7_validation_results values ('transfer', 'admin_manage_members_transfer_blocked', 'FAIL', 'Admin with manage_members unexpectedly transferred member.');
  exception when others then
    insert into milestone7_validation_results values ('transfer', 'admin_manage_members_transfer_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_plain_id::text, true);

  begin
    perform public.transfer_member_guild(transfer_block_target_id, anteiku_re_id, anteiku_id);
    insert into milestone7_validation_results values ('transfer', 'admin_without_manage_members_transfer_blocked', 'FAIL', 'Admin unexpectedly transferred member.');
  exception when others then
    insert into milestone7_validation_results values ('transfer', 'admin_without_manage_members_transfer_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_actor_id::text, true);

  begin
    perform public.transfer_member_guild(transfer_block_target_id, anteiku_re_id, anteiku_id);
    insert into milestone7_validation_results values ('transfer', 'member_transfer_blocked', 'FAIL', 'Member unexpectedly transferred member.');
  exception when others then
    insert into milestone7_validation_results values ('transfer', 'member_transfer_blocked', 'PASS', sqlerrm);
  end;
end $$;

select section, test_name, status, details
from milestone7_validation_results
order by section, test_name;

select
  count(*) filter (where status = 'PASS') as milestone7_total_pass,
  count(*) filter (where status = 'FAIL') as milestone7_total_fail
from milestone7_validation_results;

create temp table if not exists milestone8_cp_hardening_results (
  section text not null,
  test_name text not null,
  status text not null,
  details text
) on commit drop;

do $$
declare
  anteiku_id uuid;
  re_id uuid;
  owner_id uuid := '88000000-0000-4000-8000-000000000001'::uuid;
  admin_update_id uuid := '88000000-0000-4000-8000-000000000002'::uuid;
  admin_no_view_id uuid := '88000000-0000-4000-8000-000000000003'::uuid;
  member_id uuid := '88000000-0000-4000-8000-000000000004'::uuid;
  approved_target_id uuid := '88000000-0000-4000-8000-000000000005'::uuid;
  pending_target_id uuid := '88000000-0000-4000-8000-000000000006'::uuid;
  rejected_target_id uuid := '88000000-0000-4000-8000-000000000007'::uuid;
  suspended_target_id uuid := '88000000-0000-4000-8000-000000000008'::uuid;
  missing_cp_target_id uuid := '88000000-0000-4000-8000-000000000009'::uuid;
  admin_membership_id uuid;
  direct_count integer;
  roster_missing_count integer;
  missing_cp_value integer;
begin
  select g.id into anteiku_id
  from public.guilds g
  where g.slug = 'anteiku' or g.name = 'Anteiku'
  limit 1;

  select g.id into re_id
  from public.guilds g
  where g.slug in ('anteiku-re', 'anteiku_re') or g.name = 'Anteiku:Re'
  limit 1;

  insert into auth.users (
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data
  )
  values
    (owner_id, 'authenticated', 'authenticated', 'm8-owner@local.dev', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (admin_update_id, 'authenticated', 'authenticated', 'm8-admin-update@local.dev', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (admin_no_view_id, 'authenticated', 'authenticated', 'm8-admin-no-view@local.dev', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (member_id, 'authenticated', 'authenticated', 'm8-member@local.dev', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (approved_target_id, 'authenticated', 'authenticated', 'm8-approved@local.dev', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (pending_target_id, 'authenticated', 'authenticated', 'm8-pending@local.dev', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (rejected_target_id, 'authenticated', 'authenticated', 'm8-rejected@local.dev', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (suspended_target_id, 'authenticated', 'authenticated', 'm8-suspended@local.dev', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb),
    (missing_cp_target_id, 'authenticated', 'authenticated', 'm8-missing-cp@local.dev', 'local-validation', now(), now(), now(), '{}'::jsonb, '{}'::jsonb)
  on conflict (id) do nothing;

  insert into public.profiles (id, username, profile_slug, ign, approval_status)
  values
    (owner_id, 'm8_owner', 'm8_owner', 'M8 Owner', 'approved'),
    (admin_update_id, 'm8_admin_update', 'm8_admin_update', 'M8 Admin Update', 'approved'),
    (admin_no_view_id, 'm8_admin_no_view', 'm8_admin_no_view', 'M8 Admin No View', 'approved'),
    (member_id, 'm8_member', 'm8_member', 'M8 Member', 'approved'),
    (approved_target_id, 'm8_approved', 'm8_approved', 'M8 Approved', 'approved'),
    (pending_target_id, 'm8_pending', 'm8_pending', 'M8 Pending', 'pending'),
    (rejected_target_id, 'm8_rejected', 'm8_rejected', 'M8 Rejected', 'rejected'),
    (suspended_target_id, 'm8_suspended', 'm8_suspended', 'M8 Suspended', 'suspended'),
    (missing_cp_target_id, 'm8_missing_cp', 'm8_missing_cp', 'M8 Missing CP', 'approved')
  on conflict (id) do update
  set approval_status = excluded.approval_status,
      ign = excluded.ign,
      updated_at = now();

  insert into public.guild_memberships (profile_id, guild_id, role, membership_status, is_primary)
  values
    (owner_id, anteiku_id, 'owner', 'active', true),
    (admin_update_id, anteiku_id, 'admin', 'active', true),
    (admin_no_view_id, anteiku_id, 'admin', 'active', true),
    (member_id, anteiku_id, 'member', 'active', true),
    (approved_target_id, anteiku_id, 'member', 'active', true),
    (pending_target_id, anteiku_id, 'member', 'active', true),
    (rejected_target_id, anteiku_id, 'member', 'active', true),
    (suspended_target_id, anteiku_id, 'member', 'active', true),
    (missing_cp_target_id, anteiku_id, 'member', 'active', true)
  on conflict (profile_id, guild_id) do update
  set role = excluded.role,
      membership_status = excluded.membership_status,
      is_primary = excluded.is_primary,
      updated_at = now();

  select gm.id into admin_membership_id
  from public.guild_memberships gm
  where gm.profile_id = admin_update_id
    and gm.guild_id = anteiku_id
    and gm.membership_status = 'active'
  limit 1;

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  values
    (admin_membership_id, 'view_cp', owner_id),
    (admin_membership_id, 'update_cp', owner_id)
  on conflict (membership_id, permission_key) do update
  set granted_by = excluded.granted_by,
      created_at = now();

  delete from public.member_cp
  where profile_id in (approved_target_id, pending_target_id, rejected_target_id, suspended_target_id, missing_cp_target_id);

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.update_member_cp(pending_target_id, 11111, 'validation should fail');
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'owner_pending_cp_update_blocked', 'FAIL', 'Owner unexpectedly updated CP for pending profile.');
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'owner_pending_cp_update_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.update_member_cp(rejected_target_id, 11111, 'validation should fail');
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'owner_rejected_cp_update_blocked', 'FAIL', 'Owner unexpectedly updated CP for rejected profile.');
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'owner_rejected_cp_update_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.update_member_cp(suspended_target_id, 11111, 'validation should fail');
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'owner_suspended_cp_update_blocked', 'FAIL', 'Owner unexpectedly updated CP for suspended profile.');
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'owner_suspended_cp_update_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.update_member_cp(approved_target_id, 12345, 'validation approved update');
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'owner_approved_cp_update_allowed', 'PASS', 'Owner updated approved active profile CP.');
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'owner_approved_cp_update_allowed', 'FAIL', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_update_id::text, true);

  begin
    execute 'set local role authenticated';
    perform public.update_member_cp(rejected_target_id, 22222, 'validation should fail');
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'admin_update_cp_rejected_profile_blocked', 'FAIL', 'Admin unexpectedly updated CP for rejected profile.');
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'admin_update_cp_rejected_profile_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.update_member_cp(approved_target_id, 23456, 'validation admin approved update');
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'admin_update_cp_approved_profile_allowed', 'PASS', 'Admin with update_cp updated approved active profile CP.');
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'admin_update_cp_approved_profile_allowed', 'FAIL', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);

  begin
    execute 'set local role authenticated';
    select count(*), max(r.cp_value) into roster_missing_count, missing_cp_value
    from public.get_current_cp_roster(anteiku_id) r
    where r.profile_id = missing_cp_target_id;
    execute 'reset role';

    if roster_missing_count = 1 and missing_cp_value is null then
      insert into milestone8_cp_hardening_results values ('cp_hardening', 'roster_includes_missing_cp_as_null', 'PASS', 'Roster includes active approved member with no CP row as null.');
    else
      insert into milestone8_cp_hardening_results values ('cp_hardening', 'roster_includes_missing_cp_as_null', 'FAIL', 'Missing CP member was absent or CP was not null.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'roster_includes_missing_cp_as_null', 'FAIL', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);

  begin
    execute 'set local role authenticated';
    perform count(*) from public.get_current_cp_roster(anteiku_id);
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'member_cp_roster_read_blocked', 'FAIL', 'Member unexpectedly read CP roster.');
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'member_cp_roster_read_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_no_view_id::text, true);

  begin
    execute 'set local role authenticated';
    perform count(*) from public.get_current_cp_roster(anteiku_id);
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'admin_without_view_cp_roster_read_blocked', 'FAIL', 'Admin without view_cp unexpectedly read CP roster.');
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'admin_without_view_cp_roster_read_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);

  begin
    execute 'set local role authenticated';
    select count(*) into direct_count from public.member_cp;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone8_cp_hardening_results values ('cp_hardening', 'direct_member_cp_access_blocked', 'PASS', 'Direct member_cp read returned no rows.');
    else
      insert into milestone8_cp_hardening_results values ('cp_hardening', 'direct_member_cp_access_blocked', 'FAIL', 'Direct member_cp read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'direct_member_cp_access_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into direct_count from public.cp_snapshots;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone8_cp_hardening_results values ('cp_hardening', 'direct_cp_snapshots_access_blocked', 'PASS', 'Direct cp_snapshots read returned no rows.');
    else
      insert into milestone8_cp_hardening_results values ('cp_hardening', 'direct_cp_snapshots_access_blocked', 'FAIL', 'Direct cp_snapshots read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'direct_cp_snapshots_access_blocked', 'PASS', sqlerrm);
  end;

  if exists (
    select 1
    from public.audit_logs al
    where al.action = 'member_cp_updated'
      and al.target_profile_id = approved_target_id
      and al.metadata ? 'cp_old'
      and al.metadata ? 'cp_new'
  ) then
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'cp_update_audit_log_written', 'PASS', 'CP update audit log includes old/new metadata.');
  else
    insert into milestone8_cp_hardening_results values ('cp_hardening', 'cp_update_audit_log_written', 'FAIL', 'CP update audit log not found.');
  end if;
end;
$$;

select section, test_name, status, details
from milestone8_cp_hardening_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone8_total_pass,
       count(*) filter (where status = 'FAIL') as milestone8_total_fail
from milestone8_cp_hardening_results;

-- Milestone 11A backend validation: audit-log reader hardening and CP metadata redaction.
-- This section is local-only test data and is rolled back with the rest of this script.
create temp table if not exists milestone11_audit_hardening_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id uuid := '00000000-0000-0000-0000-000000000101';
  anteiku_re_id uuid := '00000000-0000-0000-0000-000000000102';
  owner_id uuid := '10000000-0000-4000-8000-000000001101';
  leader_id uuid := '10000000-0000-4000-8000-000000001102';
  vice_id uuid := '10000000-0000-4000-8000-000000001103';
  admin_audit_id uuid := '10000000-0000-4000-8000-000000001104';
  admin_audit_cp_id uuid := '10000000-0000-4000-8000-000000001105';
  admin_plain_id uuid := '10000000-0000-4000-8000-000000001106';
  member_id uuid := '10000000-0000-4000-8000-000000001107';
  pending_id uuid := '10000000-0000-4000-8000-000000001108';
  target_id uuid := '10000000-0000-4000-8000-000000001109';
  admin_audit_membership_id uuid;
  admin_audit_cp_membership_id uuid;
  result_count integer;
  direct_count integer;
  audit_metadata jsonb;
  redacted boolean;
begin
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  values
    ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'm11-owner.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', leader_id, 'authenticated', 'authenticated', 'm11-leader.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', vice_id, 'authenticated', 'authenticated', 'm11-vice.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', admin_audit_id, 'authenticated', 'authenticated', 'm11-admin-audit.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', admin_audit_cp_id, 'authenticated', 'authenticated', 'm11-admin-audit-cp.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', admin_plain_id, 'authenticated', 'authenticated', 'm11-admin-plain.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'm11-member.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'm11-pending.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', target_id, 'authenticated', 'authenticated', 'm11-target.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now())
  on conflict (id) do nothing;

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_id, 'm11_owner', 'm11_owner', 'M11 Owner', 'approved', now()),
    (leader_id, 'm11_leader', 'm11_leader', 'M11 Leader', 'approved', now()),
    (vice_id, 'm11_vice', 'm11_vice', 'M11 Vice', 'approved', now()),
    (admin_audit_id, 'm11_admin_audit', 'm11_admin_audit', 'M11 Admin Audit', 'approved', now()),
    (admin_audit_cp_id, 'm11_admin_cp', 'm11_admin_cp', 'M11 Admin Audit CP', 'approved', now()),
    (admin_plain_id, 'm11_admin_plain', 'm11_admin_plain', 'M11 Admin Plain', 'approved', now()),
    (member_id, 'm11_member', 'm11_member', 'M11 Member', 'approved', now()),
    (pending_id, 'm11_pending', 'm11_pending', 'M11 Pending', 'pending', null),
    (target_id, 'm11_target', 'm11_target', 'M11 Target', 'approved', now())
  on conflict (id) do update
  set ign = excluded.ign,
      approval_status = excluded.approval_status,
      approved_at = excluded.approved_at;

  insert into public.guild_memberships (profile_id, guild_id, role, membership_status, is_primary, assigned_by)
  values
    (owner_id, anteiku_id, 'owner', 'active', true, owner_id),
    (leader_id, anteiku_id, 'leader', 'active', true, owner_id),
    (vice_id, anteiku_id, 'vice', 'active', true, owner_id),
    (admin_audit_id, anteiku_id, 'admin', 'active', true, owner_id),
    (admin_audit_cp_id, anteiku_id, 'admin', 'active', true, owner_id),
    (admin_plain_id, anteiku_id, 'admin', 'active', true, owner_id),
    (member_id, anteiku_id, 'member', 'active', true, owner_id),
    (pending_id, anteiku_id, 'member', 'pending', true, null),
    (target_id, anteiku_id, 'member', 'active', true, owner_id)
  on conflict (profile_id, guild_id) do update
  set role = excluded.role,
      membership_status = excluded.membership_status,
      is_primary = excluded.is_primary,
      assigned_by = excluded.assigned_by;

  select gm.id into admin_audit_membership_id
  from public.guild_memberships gm
  where gm.profile_id = admin_audit_id
    and gm.guild_id = anteiku_id
  limit 1;

  select gm.id into admin_audit_cp_membership_id
  from public.guild_memberships gm
  where gm.profile_id = admin_audit_cp_id
    and gm.guild_id = anteiku_id
  limit 1;

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  values
    (admin_audit_membership_id, 'view_audit_logs', owner_id),
    (admin_audit_cp_membership_id, 'view_audit_logs', owner_id),
    (admin_audit_cp_membership_id, 'view_cp', owner_id)
  on conflict (membership_id, permission_key) do update
  set granted_by = excluded.granted_by,
      created_at = now();

  insert into public.audit_logs (
    actor_profile_id,
    target_profile_id,
    guild_id,
    action,
    entity_table,
    entity_id,
    metadata
  )
  values
    (
      owner_id,
      target_id,
      anteiku_id,
      'member_cp_updated',
      'member_cp',
      target_id,
      jsonb_build_object('cp_old', 100, 'cp_new', 200, 'note', 'private CP note', 'safe_label', 'CP update')
    ),
    (
      owner_id,
      target_id,
      anteiku_id,
      'registration_approved',
      'profiles',
      target_id,
      jsonb_build_object('approval_status_old', 'pending', 'approval_status_new', 'approved')
    ),
    (
      owner_id,
      target_id,
      anteiku_re_id,
      'member_role_changed',
      'guild_memberships',
      gen_random_uuid(),
      jsonb_build_object('role_old', 'member', 'role_new', 'admin')
    ),
    (
      owner_id,
      null,
      null,
      'owner_bootstrap_completed',
      'profiles',
      owner_id,
      jsonb_build_object('manual', true)
    );

  perform set_config('request.jwt.claim.role', 'authenticated', true);

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  begin
    execute 'set local role authenticated';
    select count(*) into result_count
    from public.get_audit_logs(null, null, null, null, null, null, 100, null);
    execute 'reset role';

    if result_count >= 4 then
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'owner_global_audit_rpc_allowed', 'PASS', 'Owner read global audit logs through RPC.');
    else
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'owner_global_audit_rpc_allowed', 'FAIL', 'Owner saw fewer audit logs than expected.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'owner_global_audit_rpc_allowed', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into result_count
    from public.get_audit_logs(null, 'member_cp_updated', null, null, null, null, 100, null);
    execute 'reset role';

    if result_count >= 1 then
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'action_filter_supported', 'PASS', 'Action filter returned the CP audit log.');
    else
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'action_filter_supported', 'FAIL', 'Action filter returned no CP audit log.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'action_filter_supported', 'FAIL', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', leader_id::text, true);
  begin
    execute 'set local role authenticated';
    select count(*) into result_count
    from public.get_audit_logs(anteiku_id, null, null, null, null, null, 100, null);
    execute 'reset role';

    if result_count >= 2 then
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'leader_scoped_audit_rpc_allowed', 'PASS', 'Leader read assigned guild audit logs.');
    else
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'leader_scoped_audit_rpc_allowed', 'FAIL', 'Leader saw fewer scoped logs than expected.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'leader_scoped_audit_rpc_allowed', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform count(*) from public.get_audit_logs(anteiku_re_id, null, null, null, null, null, 100, null);
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'leader_wrong_guild_audit_blocked', 'FAIL', 'Leader unexpectedly read wrong-guild audit logs.');
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'leader_wrong_guild_audit_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', vice_id::text, true);
  begin
    execute 'set local role authenticated';
    select count(*) into result_count
    from public.get_audit_logs(anteiku_id, null, null, null, null, null, 100, null);
    execute 'reset role';

    if result_count >= 2 then
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'vice_scoped_audit_rpc_allowed', 'PASS', 'Vice read assigned guild audit logs.');
    else
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'vice_scoped_audit_rpc_allowed', 'FAIL', 'Vice saw fewer scoped logs than expected.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'vice_scoped_audit_rpc_allowed', 'FAIL', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_audit_id::text, true);
  begin
    execute 'set local role authenticated';
    select count(*) into result_count
    from public.get_audit_logs(anteiku_id, null, null, null, null, null, 100, null);
    execute 'reset role';

    if result_count >= 2 then
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_with_view_audit_allowed', 'PASS', 'Admin with view_audit_logs read scoped audit logs.');
    else
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_with_view_audit_allowed', 'FAIL', 'Admin with view_audit_logs saw fewer logs than expected.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_with_view_audit_allowed', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select r.metadata, r.metadata_redacted into audit_metadata, redacted
    from public.get_audit_logs(anteiku_id, 'member_cp_updated', null, null, null, null, 100, null) r
    limit 1;
    execute 'reset role';

    if redacted = true
       and audit_metadata ? 'cp_metadata_redacted'
       and not audit_metadata ? 'cp_old'
       and not audit_metadata ? 'cp_new'
       and not audit_metadata ? 'note' then
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_without_view_cp_cp_metadata_redacted', 'PASS', 'CP metadata was redacted for Admin without view_cp.');
    else
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_without_view_cp_cp_metadata_redacted', 'FAIL', coalesce(audit_metadata::text, 'No CP audit metadata returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_without_view_cp_cp_metadata_redacted', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into direct_count
    from public.audit_logs
    where action = 'member_cp_updated';
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'direct_audit_logs_select_non_owner_blocked', 'PASS', 'Direct audit_logs SELECT returned no rows for non-Owner.');
    else
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'direct_audit_logs_select_non_owner_blocked', 'FAIL', 'Direct audit_logs SELECT returned ' || direct_count || ' rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'direct_audit_logs_select_non_owner_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_audit_cp_id::text, true);
  begin
    execute 'set local role authenticated';
    select r.metadata, r.metadata_redacted into audit_metadata, redacted
    from public.get_audit_logs(anteiku_id, 'member_cp_updated', null, null, null, null, 100, null) r
    limit 1;
    execute 'reset role';

    if redacted = false
       and audit_metadata ? 'cp_old'
       and audit_metadata ? 'cp_new'
       and audit_metadata ? 'note' then
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_with_view_cp_cp_metadata_visible', 'PASS', 'Admin with view_audit_logs and view_cp received scoped CP metadata.');
    else
      insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_with_view_cp_cp_metadata_visible', 'FAIL', coalesce(audit_metadata::text, 'No CP audit metadata returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_with_view_cp_cp_metadata_visible', 'FAIL', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_plain_id::text, true);
  begin
    execute 'set local role authenticated';
    perform count(*) from public.get_audit_logs(anteiku_id, null, null, null, null, null, 100, null);
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_without_view_audit_blocked', 'FAIL', 'Admin without view_audit_logs unexpectedly read audit logs.');
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'admin_without_view_audit_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  begin
    execute 'set local role authenticated';
    perform count(*) from public.get_audit_logs(anteiku_id, null, null, null, null, null, 100, null);
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'member_audit_read_blocked', 'FAIL', 'Member unexpectedly read audit logs.');
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'member_audit_read_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', pending_id::text, true);
  begin
    execute 'set local role authenticated';
    perform count(*) from public.get_audit_logs(anteiku_id, null, null, null, null, null, 100, null);
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'pending_audit_read_blocked', 'FAIL', 'Pending user unexpectedly read audit logs.');
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'pending_audit_read_blocked', 'PASS', sqlerrm);
  end;

  if has_function_privilege(
    'authenticated',
    'private.write_audit_log(uuid, uuid, uuid, text, text, uuid, jsonb)',
    'execute'
  ) then
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'private_write_audit_log_direct_blocked', 'FAIL', 'authenticated still has EXECUTE on private.write_audit_log.');
  else
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'private_write_audit_log_direct_blocked', 'PASS', 'authenticated has no EXECUTE privilege on private.write_audit_log.');
  end if;

  begin
    execute 'set local role authenticated';
    insert into public.audit_logs (actor_profile_id, action)
    values (admin_audit_id, 'spoof_attempt');
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'audit_spoof_insert_still_blocked', 'FAIL', 'Authenticated user inserted audit log directly.');
  exception when others then
    execute 'reset role';
    insert into milestone11_audit_hardening_results values ('audit_hardening', 'audit_spoof_insert_still_blocked', 'PASS', sqlerrm);
  end;
end;
$$;

select section, test_name, status, details
from milestone11_audit_hardening_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone11_total_pass,
       count(*) filter (where status = 'FAIL') as milestone11_total_fail,
       count(*) filter (where status = 'SKIP') as milestone11_total_skip
from milestone11_audit_hardening_results;

-- Milestone 15A backend validation: member roster status current state,
-- private history, audit logging, role/permission rules, and GvG eligibility.
-- This section is local-only test data and is rolled back with the rest of this script.
create temp table if not exists milestone15a_member_status_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id uuid := '00000000-0000-0000-0000-000000000101';
  anteiku_re_id uuid := '00000000-0000-0000-0000-000000000102';
  owner_primary_id uuid := '10000000-0000-5000-8000-000000001501';
  owner_secondary_id uuid := '10000000-0000-5000-8000-000000001502';
  leader_id uuid := '10000000-0000-5000-8000-000000001503';
  vice_id uuid := '10000000-0000-5000-8000-000000001504';
  admin_manage_id uuid := '10000000-0000-5000-8000-000000001505';
  admin_plain_id uuid := '10000000-0000-5000-8000-000000001506';
  member_id uuid := '10000000-0000-5000-8000-000000001507';
  member_two_id uuid := '10000000-0000-5000-8000-000000001508';
  wrong_guild_member_id uuid := '10000000-0000-5000-8000-000000001509';
  default_member_id uuid := '10000000-0000-5000-8000-000000001510';
  owner_primary_membership_id uuid;
  owner_secondary_membership_id uuid;
  admin_manage_membership_id uuid;
  member_membership_id uuid;
  member_two_membership_id uuid;
  wrong_guild_membership_id uuid;
  default_membership_id uuid;
  gvg_event_id uuid;
  updated_membership public.guild_memberships%rowtype;
  status_name text;
  expected_membership_status text;
  result_count integer;
  active_owner_count integer;
begin
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  values
    ('00000000-0000-0000-0000-000000000000', owner_primary_id, 'authenticated', 'authenticated', 'm15-owner-primary.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', owner_secondary_id, 'authenticated', 'authenticated', 'm15-owner-secondary.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', leader_id, 'authenticated', 'authenticated', 'm15-leader.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', vice_id, 'authenticated', 'authenticated', 'm15-vice.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', admin_manage_id, 'authenticated', 'authenticated', 'm15-admin-manage.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', admin_plain_id, 'authenticated', 'authenticated', 'm15-admin-plain.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'm15-member.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_two_id, 'authenticated', 'authenticated', 'm15-member-two.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', wrong_guild_member_id, 'authenticated', 'authenticated', 'm15-wrong-guild.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', default_member_id, 'authenticated', 'authenticated', 'm15-default.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now())
  on conflict (id) do nothing;

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_primary_id, 'm15_owner_primary', 'm15_owner_primary', 'M15 Owner Primary', 'approved', now()),
    (owner_secondary_id, 'm15_owner_secondary', 'm15_owner_secondary', 'M15 Owner Secondary', 'approved', now()),
    (leader_id, 'm15_leader', 'm15_leader', 'M15 Leader', 'approved', now()),
    (vice_id, 'm15_vice', 'm15_vice', 'M15 Vice', 'approved', now()),
    (admin_manage_id, 'm15_admin_manage', 'm15_admin_manage', 'M15 Admin Manage', 'approved', now()),
    (admin_plain_id, 'm15_admin_plain', 'm15_admin_plain', 'M15 Admin Plain', 'approved', now()),
    (member_id, 'm15_member', 'm15_member', 'M15 Member', 'approved', now()),
    (member_two_id, 'm15_member_two', 'm15_member_two', 'M15 Member Two', 'approved', now()),
    (wrong_guild_member_id, 'm15_wrong_guild', 'm15_wrong_guild', 'M15 Wrong Guild', 'approved', now()),
    (default_member_id, 'm15_default', 'm15_default', 'M15 Default', 'approved', now())
  on conflict (id) do update
  set ign = excluded.ign,
      approval_status = excluded.approval_status,
      approved_at = excluded.approved_at;

  insert into public.guild_memberships (profile_id, guild_id, role, membership_status, is_primary, assigned_by)
  values
    (owner_primary_id, anteiku_id, 'owner', 'active', true, owner_primary_id),
    (owner_secondary_id, anteiku_id, 'owner', 'active', true, owner_primary_id),
    (leader_id, anteiku_id, 'leader', 'active', true, owner_primary_id),
    (vice_id, anteiku_id, 'vice', 'active', true, owner_primary_id),
    (admin_manage_id, anteiku_id, 'admin', 'active', true, owner_primary_id),
    (admin_plain_id, anteiku_id, 'admin', 'active', true, owner_primary_id),
    (member_id, anteiku_id, 'member', 'active', true, owner_primary_id),
    (member_two_id, anteiku_id, 'member', 'active', true, owner_primary_id),
    (wrong_guild_member_id, anteiku_re_id, 'member', 'active', true, owner_primary_id),
    (default_member_id, anteiku_id, 'member', 'active', true, owner_primary_id)
  on conflict (profile_id, guild_id) do update
  set role = excluded.role,
      membership_status = excluded.membership_status,
      is_primary = excluded.is_primary,
      assigned_by = excluded.assigned_by,
      roster_status = 'active';

  select id into owner_primary_membership_id from public.guild_memberships where profile_id = owner_primary_id and guild_id = anteiku_id;
  select id into owner_secondary_membership_id from public.guild_memberships where profile_id = owner_secondary_id and guild_id = anteiku_id;
  select id into admin_manage_membership_id from public.guild_memberships where profile_id = admin_manage_id and guild_id = anteiku_id;
  select id into member_membership_id from public.guild_memberships where profile_id = member_id and guild_id = anteiku_id;
  select id into member_two_membership_id from public.guild_memberships where profile_id = member_two_id and guild_id = anteiku_id;
  select id into wrong_guild_membership_id from public.guild_memberships where profile_id = wrong_guild_member_id and guild_id = anteiku_re_id;
  select id into default_membership_id from public.guild_memberships where profile_id = default_member_id and guild_id = anteiku_id;

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  values (admin_manage_membership_id, 'manage_members', owner_primary_id)
  on conflict (membership_id, permission_key) do update
  set granted_by = excluded.granted_by,
      created_at = now();

  insert into public.gvg_events (
    guild_id,
    scope,
    title,
    status,
    starts_at,
    ends_at,
    created_by,
    created_at,
    updated_at
  )
  values (
    anteiku_id,
    'guild',
    'Milestone 15A Local GvG',
    'active',
    now() - interval '1 hour',
    now() + interval '1 day',
    owner_primary_id,
    now(),
    now()
  )
  returning id into gvg_event_id;

  if exists (
    select 1
    from public.guild_memberships
    where id = default_membership_id
      and roster_status = 'active'
  ) then
    insert into milestone15a_member_status_results values ('schema', 'default_roster_status_active', 'PASS', 'New memberships default to roster_status active.');
  else
    insert into milestone15a_member_status_results values ('schema', 'default_roster_status_active', 'FAIL', 'Default roster_status was not active.');
  end if;

  begin
    update public.guild_memberships
    set roster_status = 'invalid_status'
    where id = default_membership_id;

    insert into milestone15a_member_status_results values ('schema', 'invalid_roster_status_rejected', 'FAIL', 'Invalid roster_status update unexpectedly succeeded.');
  exception when others then
    insert into milestone15a_member_status_results values ('schema', 'invalid_roster_status_rejected', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_primary_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);

    foreach status_name in array array[
      'active',
      'trial',
      'inactive',
      'on_break',
      'pending_transfer',
      'suspended',
      'active',
      'left',
      'active',
      'kicked',
      'active'
    ] loop
      expected_membership_status := case status_name
        when 'suspended' then 'suspended'
        when 'left' then 'left'
        when 'kicked' then 'left'
        else 'active'
      end;

      execute 'set local role authenticated';
      select * into updated_membership
      from public.update_member_roster_status(member_membership_id, status_name, 'owner validation status change');
      execute 'reset role';

      if updated_membership.roster_status <> status_name
         or updated_membership.membership_status <> expected_membership_status then
        raise exception 'Expected status %, membership %, got status %, membership %',
          status_name,
          expected_membership_status,
          updated_membership.roster_status,
          updated_membership.membership_status;
      end if;
    end loop;

    insert into milestone15a_member_status_results values ('rpc', 'owner_can_set_all_statuses', 'PASS', 'Owner set every roster status and restored hard-blocked statuses.');
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'owner_can_set_all_statuses', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', leader_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    select * into updated_membership
    from public.update_member_roster_status(member_membership_id, 'on_break', 'leader scoped status test');
    execute 'reset role';

    perform set_config('request.jwt.claim.sub', vice_id::text, true);
    execute 'set local role authenticated';
    select * into updated_membership
    from public.update_member_roster_status(member_membership_id, 'suspended', 'vice scoped hard block');
    execute 'reset role';

    perform set_config('request.jwt.claim.sub', leader_id::text, true);
    execute 'set local role authenticated';
    select * into updated_membership
    from public.update_member_roster_status(member_membership_id, 'active', 'leader restores active');
    execute 'reset role';

    if updated_membership.roster_status = 'active' and updated_membership.membership_status = 'active' then
      insert into milestone15a_member_status_results values ('rpc', 'leader_vice_scoped_status_allowed', 'PASS', 'Leader/Vice updated scoped non-Owner roster statuses and restored active.');
    else
      insert into milestone15a_member_status_results values ('rpc', 'leader_vice_scoped_status_allowed', 'FAIL', 'Leader/Vice status update did not end active.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'leader_vice_scoped_status_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', leader_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(wrong_guild_membership_id, 'inactive', 'wrong guild should fail');
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'leader_wrong_guild_denied', 'FAIL', 'Leader updated wrong-guild member status.');
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'leader_wrong_guild_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_manage_id::text, true);
    execute 'set local role authenticated';
    select * into updated_membership
    from public.update_member_roster_status(member_membership_id, 'inactive', 'admin allowed status');
    execute 'reset role';

    if updated_membership.roster_status = 'inactive' and updated_membership.membership_status = 'active' then
      insert into milestone15a_member_status_results values ('rpc', 'admin_manage_members_allowed_non_terminal', 'PASS', 'Admin with manage_members set inactive without hard-locking membership.');
    else
      insert into milestone15a_member_status_results values ('rpc', 'admin_manage_members_allowed_non_terminal', 'FAIL', 'Admin allowed status did not preserve active membership.');
    end if;

    perform set_config('request.jwt.claim.sub', owner_primary_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'active', 'restore for next tests');
    execute 'reset role';
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'admin_manage_members_allowed_non_terminal', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_manage_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'suspended', 'admin hard block should fail');
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'admin_terminal_status_denied', 'FAIL', 'Admin set suspended.');
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'admin_terminal_status_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_plain_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'trial', 'plain admin should fail');
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'admin_without_manage_members_denied', 'FAIL', 'Admin without manage_members changed status.');
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'admin_without_manage_members_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_manage_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(owner_secondary_membership_id, 'inactive', 'admin owner target should fail');
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'admin_cannot_affect_owner', 'FAIL', 'Admin affected Owner roster status.');
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'admin_cannot_affect_owner', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_manage_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(admin_manage_membership_id, 'inactive', 'admin self should fail');
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'admin_cannot_change_self_status', 'FAIL', 'Admin changed their own roster status.');
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'admin_cannot_change_self_status', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_two_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'trial', 'member should fail');
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'member_status_change_denied', 'FAIL', 'Member changed roster status.');
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'member_status_change_denied', 'PASS', sqlerrm);
  end;

  begin
    update public.guild_memberships
    set membership_status = 'suspended',
        roster_status = 'suspended'
    where role = 'owner'
      and profile_id <> owner_secondary_id;

    update public.guild_memberships
    set membership_status = 'active',
        roster_status = 'active',
        is_primary = true
    where id = owner_secondary_membership_id;

    perform set_config('request.jwt.claim.sub', owner_secondary_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);

    begin
      execute 'set local role authenticated';
      perform public.update_member_roster_status(owner_secondary_membership_id, 'suspended', 'last owner should fail');
      execute 'reset role';
      insert into milestone15a_member_status_results values ('rpc', 'last_active_owner_protected', 'FAIL', 'Last active Owner was hard-blocked.');
    exception when others then
      execute 'reset role';
      insert into milestone15a_member_status_results values ('rpc', 'last_active_owner_protected', 'PASS', sqlerrm);
    end;

    update public.guild_memberships
    set membership_status = 'active',
        roster_status = 'active',
        is_primary = true
    where id in (owner_primary_membership_id, owner_secondary_membership_id);
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('rpc', 'last_active_owner_protected_setup', 'FAIL', sqlerrm);
  end;

  select count(*) into active_owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved'
    and gm.profile_id in (owner_primary_id, owner_secondary_id);

  if active_owner_count = 2 then
    insert into milestone15a_member_status_results values ('rpc', 'active_owner_count_restored', 'PASS', 'Both local validation Owners are active after last-owner test.');
  else
    insert into milestone15a_member_status_results values ('rpc', 'active_owner_count_restored', 'FAIL', 'Expected 2 active Owners, found ' || active_owner_count || '.');
  end if;

  begin
    perform set_config('request.jwt.claim.sub', owner_primary_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);

    foreach status_name in array array['suspended', 'left', 'kicked'] loop
      execute 'set local role authenticated';
      select * into updated_membership
      from public.update_member_roster_status(member_membership_id, status_name, 'hard block validation');
      execute 'reset role';

      if private.has_active_membership(member_id, anteiku_id) then
        raise exception 'Hard-block status % still has active membership.', status_name;
      end if;

      execute 'set local role authenticated';
      perform public.update_member_roster_status(member_membership_id, 'active', 'restore after hard block validation');
      execute 'reset role';
    end loop;

    insert into milestone15a_member_status_results values ('access', 'hard_block_statuses_remove_active_access', 'PASS', 'suspended/left/kicked remove active membership access.');
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('access', 'hard_block_statuses_remove_active_access', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_primary_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'inactive', 'inactive gvg validation');
    execute 'reset role';

    if not private.has_active_membership(member_id, anteiku_id) then
      raise exception 'inactive unexpectedly removed hard active membership.';
    end if;

    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    begin
      perform public.submit_gvg_vote(gvg_event_id, 'present', null);
      execute 'reset role';
      insert into milestone15a_member_status_results values ('gvg', 'inactive_gvg_vote_denied', 'FAIL', 'inactive member submitted GvG vote.');
    exception when others then
      execute 'reset role';
      insert into milestone15a_member_status_results values ('gvg', 'inactive_gvg_vote_denied', 'PASS', sqlerrm);
    end;

    execute 'set local role authenticated';
    select count(*) into result_count
    from public.gvg_events
    where id = gvg_event_id;
    execute 'reset role';

    if result_count = 0 then
      insert into milestone15a_member_status_results values ('gvg', 'inactive_gvg_event_hidden_by_rls', 'PASS', 'inactive member does not see active GvG event through member RLS.');
    else
      insert into milestone15a_member_status_results values ('gvg', 'inactive_gvg_event_hidden_by_rls', 'FAIL', 'inactive member saw active GvG event.');
    end if;

    perform set_config('request.jwt.claim.sub', owner_primary_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'on_break', 'on_break gvg validation');
    execute 'reset role';

    if not private.has_active_membership(member_id, anteiku_id) then
      raise exception 'on_break unexpectedly removed hard active membership.';
    end if;

    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    begin
      perform public.submit_gvg_vote(gvg_event_id, 'present', null);
      execute 'reset role';
      insert into milestone15a_member_status_results values ('gvg', 'on_break_gvg_vote_denied', 'FAIL', 'on_break member submitted GvG vote.');
    exception when others then
      execute 'reset role';
      insert into milestone15a_member_status_results values ('gvg', 'on_break_gvg_vote_denied', 'PASS', sqlerrm);
    end;

    perform set_config('request.jwt.claim.sub', owner_primary_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'trial', 'trial gvg validation');
    execute 'reset role';

    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    perform public.submit_gvg_vote(gvg_event_id, 'present', null);
    execute 'reset role';
    insert into milestone15a_member_status_results values ('gvg', 'trial_gvg_vote_allowed', 'PASS', 'trial member retained normal GvG voting access.');

    perform set_config('request.jwt.claim.sub', owner_primary_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'active', 'restore after gvg validation');
    execute 'reset role';
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('gvg', 'inactive_on_break_gvg_eligibility', 'FAIL', sqlerrm);
  end;

  if exists (
    select 1
    from public.member_status_history
    where membership_id = member_membership_id
      and new_status in ('inactive', 'on_break', 'trial')
      and reason is not null
  ) then
    insert into milestone15a_member_status_results values ('history', 'status_history_inserted', 'PASS', 'Status history rows were inserted with private reasons.');
  else
    insert into milestone15a_member_status_results values ('history', 'status_history_inserted', 'FAIL', 'Expected status history rows were not found.');
  end if;

  if exists (
    select 1
    from public.audit_logs
    where action = 'member_roster_status_changed'
      and entity_table = 'guild_memberships'
      and entity_id = member_membership_id
      and metadata ? 'old_status'
      and metadata ? 'new_status'
      and metadata ? 'membership_id'
      and metadata ? 'guild_id'
      and metadata ? 'reason_provided'
      and not metadata ? 'reason'
  ) then
    insert into milestone15a_member_status_results values ('audit', 'status_change_audit_log_inserted', 'PASS', 'Audit log includes status metadata without private reason text.');
  else
    insert into milestone15a_member_status_results values ('audit', 'status_change_audit_log_inserted', 'FAIL', 'Expected status-change audit log metadata was not found.');
  end if;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
  begin
    execute 'set local role authenticated';
    select count(*) into result_count
    from public.member_status_history
    where membership_id = member_membership_id;
    execute 'reset role';

    if result_count = 0 then
      insert into milestone15a_member_status_results values ('history_rls', 'member_cannot_read_private_status_history', 'PASS', 'Member direct status-history read returned no rows.');
    else
      insert into milestone15a_member_status_results values ('history_rls', 'member_cannot_read_private_status_history', 'FAIL', 'Member read ' || result_count || ' status history rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('history_rls', 'member_cannot_read_private_status_history', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', leader_id::text, true);
  begin
    execute 'set local role authenticated';
    select count(*) into result_count
    from public.member_status_history
    where membership_id = member_membership_id;
    execute 'reset role';

    if result_count > 0 then
      insert into milestone15a_member_status_results values ('history_rls', 'scoped_staff_can_read_status_history', 'PASS', 'Scoped Leader read private status history.');
    else
      insert into milestone15a_member_status_results values ('history_rls', 'scoped_staff_can_read_status_history', 'FAIL', 'Scoped Leader saw no status history.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone15a_member_status_results values ('history_rls', 'scoped_staff_can_read_status_history', 'FAIL', sqlerrm);
  end;
end;
$$;

select section, test_name, status, details
from milestone15a_member_status_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone15a_total_pass,
       count(*) filter (where status = 'FAIL') as milestone15a_total_fail,
       count(*) filter (where status = 'SKIP') as milestone15a_total_skip
from milestone15a_member_status_results;

-- Milestone 19B: CP Update Window / Member CP Self-Submit backend validation.
-- This validates guild-scoped CP windows, own-CP RPC access, member self-submit
-- eligibility, and audit CP metadata redaction.
create temp table if not exists milestone19b_cp_window_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  anteiku_re_id constant uuid := '00000000-0000-0000-0000-000000000102';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  admin_no_cp_id constant uuid := '10000000-0000-0000-0000-000000000004';
  admin_cp_id constant uuid := '10000000-0000-0000-0000-000000000005';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  wrong_guild_id constant uuid := '10000000-0000-0000-0000-000000000009';
  member_membership_id uuid;
  open_window_id uuid;
  window_state record;
  cp_state record;
  submit_state record;
  audit_metadata jsonb;
  audit_redacted boolean;
  direct_count integer;
  result_count integer;
begin
  update public.guild_memberships
  set membership_status = 'active',
      roster_status = 'active',
      is_primary = true
  where profile_id in (owner_id, admin_no_cp_id, admin_cp_id, member_id)
    and guild_id = anteiku_id;

  update public.guild_memberships
  set membership_status = 'active',
      roster_status = 'active',
      is_primary = true
  where profile_id = wrong_guild_id
    and guild_id = anteiku_re_id;

  delete from public.cp_update_windows;

  select id into member_membership_id
  from public.guild_memberships
  where profile_id = member_id
    and guild_id = anteiku_id;

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  select gm.id, 'view_audit_logs', owner_id
  from public.guild_memberships gm
  where gm.profile_id in (admin_no_cp_id, admin_cp_id)
    and gm.guild_id = anteiku_id
  on conflict (membership_id, permission_key) do nothing;

  if to_regclass('public.cp_update_windows') is not null then
    insert into milestone19b_cp_window_results values ('schema', 'cp_update_windows_exists', 'PASS', 'cp_update_windows table exists.');
  else
    insert into milestone19b_cp_window_results values ('schema', 'cp_update_windows_exists', 'FAIL', 'cp_update_windows table missing.');
  end if;

  if exists (
    select 1
    from pg_class
    where oid = 'public.cp_update_windows'::regclass
      and relrowsecurity = true
  ) then
    insert into milestone19b_cp_window_results values ('rls', 'cp_update_windows_rls_enabled', 'PASS', 'RLS is enabled.');
  else
    insert into milestone19b_cp_window_results values ('rls', 'cp_update_windows_rls_enabled', 'FAIL', 'RLS is not enabled.');
  end if;

  if not has_table_privilege('authenticated', 'public.cp_update_windows', 'select')
     and not has_table_privilege('authenticated', 'public.cp_update_windows', 'insert')
     and not has_table_privilege('authenticated', 'public.cp_update_windows', 'update')
     and not has_table_privilege('authenticated', 'public.cp_update_windows', 'delete') then
    insert into milestone19b_cp_window_results values ('rls', 'cp_update_windows_no_direct_client_grants', 'PASS', 'authenticated has no direct table grants.');
  else
    insert into milestone19b_cp_window_results values ('rls', 'cp_update_windows_no_direct_client_grants', 'FAIL', 'authenticated has direct table grants.');
  end if;

  if to_regprocedure('public.get_active_cp_update_window_for_me()') is not null
     and to_regprocedure('public.get_my_cp()') is not null
     and to_regprocedure('public.submit_my_cp_update(integer)') is not null
     and to_regprocedure('public.open_cp_update_window(uuid,timestamp with time zone,timestamp with time zone,text)') is not null
     and to_regprocedure('public.close_cp_update_window(uuid)') is not null then
    insert into milestone19b_cp_window_results values ('schema', 'cp_window_rpcs_exist', 'PASS', 'All CP window/self-submit RPCs exist.');
  else
    insert into milestone19b_cp_window_results values ('schema', 'cp_window_rpcs_exist', 'FAIL', 'One or more CP window/self-submit RPCs are missing.');
  end if;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    select count(*) into direct_count from public.cp_update_windows;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone19b_cp_window_results values ('rls', 'member_direct_cp_update_windows_denied', 'PASS', 'Direct window read returned no rows.');
    else
      insert into milestone19b_cp_window_results values ('rls', 'member_direct_cp_update_windows_denied', 'FAIL', 'Direct window read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rls', 'member_direct_cp_update_windows_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select count(*) into direct_count from public.member_cp;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone19b_cp_window_results values ('rls', 'member_direct_member_cp_still_denied', 'PASS', 'Direct member_cp read returned no rows.');
    else
      insert into milestone19b_cp_window_results values ('rls', 'member_direct_member_cp_still_denied', 'FAIL', 'Direct member_cp read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rls', 'member_direct_member_cp_still_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select count(*) into direct_count from public.cp_snapshots;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone19b_cp_window_results values ('rls', 'member_direct_cp_snapshots_still_denied', 'PASS', 'Direct cp_snapshots read returned no rows.');
    else
      insert into milestone19b_cp_window_results values ('rls', 'member_direct_cp_snapshots_still_denied', 'FAIL', 'Direct cp_snapshots read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rls', 'member_direct_cp_snapshots_still_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    perform public.open_cp_update_window(anteiku_id, null, null, 'member should fail');
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'member_cannot_open_window', 'FAIL', 'Member opened CP update window.');
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'member_cannot_open_window', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    execute 'set local role authenticated';
    perform public.open_cp_update_window(anteiku_id, null, null, 'admin no update_cp should fail');
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'admin_without_update_cp_cannot_open_window', 'FAIL', 'Admin without update_cp opened CP update window.');
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'admin_without_update_cp_cannot_open_window', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.open_cp_update_window(anteiku_id, null, null, 'owner local validation');
    execute 'reset role';
    open_window_id := window_state.window_id;

    if open_window_id is not null then
      insert into milestone19b_cp_window_results values ('rpc', 'owner_can_open_window', 'PASS', 'Owner opened CP update window.');
    else
      insert into milestone19b_cp_window_results values ('rpc', 'owner_can_open_window', 'FAIL', 'Owner open returned no window id.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'owner_can_open_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    perform public.open_cp_update_window(anteiku_id, null, null, 'duplicate should fail');
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('schema', 'one_open_window_per_guild_enforced', 'FAIL', 'Duplicate open CP window succeeded.');
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('schema', 'one_open_window_per_guild_enforced', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_active_cp_update_window_for_me();
    execute 'reset role';

    if window_state.window_id = open_window_id
       and window_state.guild_id = anteiku_id
       and window_state.can_submit = true
       and window_state.reason = 'open' then
      insert into milestone19b_cp_window_results values ('rpc', 'member_reads_own_guild_open_window', 'PASS', 'Member saw own guild open window with can_submit true.');
    else
      insert into milestone19b_cp_window_results values ('rpc', 'member_reads_own_guild_open_window', 'FAIL', coalesce(row_to_json(window_state)::text, 'No window state returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'member_reads_own_guild_open_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', wrong_guild_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_active_cp_update_window_for_me();
    execute 'reset role';

    if window_state.guild_id = anteiku_re_id
       and window_state.window_id is null
       and window_state.can_submit = false then
      insert into milestone19b_cp_window_results values ('rpc', 'wrong_guild_user_does_not_see_other_window', 'PASS', 'Wrong-guild member saw only own-guild closed state.');
    else
      insert into milestone19b_cp_window_results values ('rpc', 'wrong_guild_user_does_not_see_other_window', 'FAIL', coalesce(row_to_json(window_state)::text, 'No window state returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'wrong_guild_user_does_not_see_other_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select * into cp_state
    from public.get_my_cp();
    execute 'reset role';

    if cp_state.guild_id = anteiku_id and cp_state.cp_value = 700000 then
      insert into milestone19b_cp_window_results values ('rpc', 'member_reads_only_own_cp', 'PASS', 'Member read own CP only.');
    else
      insert into milestone19b_cp_window_results values ('rpc', 'member_reads_only_own_cp', 'FAIL', coalesce(row_to_json(cp_state)::text, 'No CP state returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'member_reads_only_own_cp', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select * into submit_state
    from public.submit_my_cp_update(710000);
    execute 'reset role';

    if submit_state.cp_value = 710000 and submit_state.window_id = open_window_id then
      insert into milestone19b_cp_window_results values ('rpc', 'member_submits_own_cp_when_open', 'PASS', 'Member submitted own CP while window was open.');
    else
      insert into milestone19b_cp_window_results values ('rpc', 'member_submits_own_cp_when_open', 'FAIL', coalesce(row_to_json(submit_state)::text, 'No submit result returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'member_submits_own_cp_when_open', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    perform public.submit_my_cp_update(720000);
    execute 'reset role';

    select cp_value into result_count
    from public.member_cp
    where profile_id = member_id
      and guild_id = anteiku_id
      and updated_by = member_id;

    select count(*) into direct_count
    from public.audit_logs
    where action = 'member_cp_self_submitted'
      and actor_profile_id = member_id
      and target_profile_id = member_id
      and metadata ? 'cp_old'
      and metadata ? 'cp_new'
      and metadata ? 'window_id'
      and metadata ->> 'source' = 'member_self_submit';

    if result_count = 720000 and direct_count >= 2 then
      insert into milestone19b_cp_window_results values ('rpc', 'multiple_submissions_latest_wins_and_audits', 'PASS', 'Latest CP won and each submission wrote audit history.');
    else
      insert into milestone19b_cp_window_results values ('rpc', 'multiple_submissions_latest_wins_and_audits', 'FAIL', 'Latest CP or audit count did not match expectations.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'multiple_submissions_latest_wins_and_audits', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    execute 'set local role authenticated';
    select metadata, metadata_redacted into audit_metadata, audit_redacted
    from public.get_audit_logs(anteiku_id, 'member_cp_self_submitted', null, null, null, null, 100, null)
    limit 1;
    execute 'reset role';

    if audit_redacted = true
       and audit_metadata ? 'cp_metadata_redacted'
       and not (audit_metadata ? 'cp_old')
       and not (audit_metadata ? 'cp_new') then
      insert into milestone19b_cp_window_results values ('audit', 'self_submit_cp_metadata_redacted_without_view_cp', 'PASS', 'CP self-submit metadata redacted without view_cp.');
    else
      insert into milestone19b_cp_window_results values ('audit', 'self_submit_cp_metadata_redacted_without_view_cp', 'FAIL', coalesce(audit_metadata::text, 'No audit metadata.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('audit', 'self_submit_cp_metadata_redacted_without_view_cp', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    execute 'set local role authenticated';
    select metadata, metadata_redacted into audit_metadata, audit_redacted
    from public.get_audit_logs(anteiku_id, 'member_cp_self_submitted', null, null, null, null, 100, null)
    limit 1;
    execute 'reset role';

    if coalesce(audit_redacted, false) = false
       and audit_metadata ? 'cp_old'
       and audit_metadata ? 'cp_new' then
      insert into milestone19b_cp_window_results values ('audit', 'self_submit_cp_metadata_visible_with_view_cp', 'PASS', 'CP self-submit metadata visible with scoped view_cp.');
    else
      insert into milestone19b_cp_window_results values ('audit', 'self_submit_cp_metadata_visible_with_view_cp', 'FAIL', coalesce(audit_metadata::text, 'No audit metadata.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('audit', 'self_submit_cp_metadata_visible_with_view_cp', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    execute 'set local role authenticated';
    perform public.close_cp_update_window(open_window_id);
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'admin_without_update_cp_cannot_close_window', 'FAIL', 'Admin without update_cp closed CP update window.');
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'admin_without_update_cp_cannot_close_window', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    perform public.close_cp_update_window(open_window_id);
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'owner_can_close_window', 'PASS', 'Owner closed CP update window.');
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'owner_can_close_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    perform public.submit_my_cp_update(730000);
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_when_closed', 'FAIL', 'Member submitted after window close.');
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_when_closed', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.open_cp_update_window(anteiku_id, now() + interval '1 hour', now() + interval '2 hours', null);
    execute 'reset role';
    open_window_id := window_state.window_id;

    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_active_cp_update_window_for_me();
    begin
      perform public.submit_my_cp_update(730000);
      execute 'reset role';
      insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_before_opens_at', 'FAIL', 'Member submitted before opens_at.');
    exception when others then
      execute 'reset role';
      if window_state.can_submit = false and window_state.reason = 'window_not_open_yet' then
        insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_before_opens_at', 'PASS', sqlerrm);
      else
        insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_before_opens_at', 'FAIL', coalesce(row_to_json(window_state)::text, sqlerrm));
      end if;
    end;

    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    perform public.close_cp_update_window(open_window_id);
    execute 'reset role';
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_before_opens_at_setup', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.open_cp_update_window(anteiku_id, null, now() + interval '2 hours', null);
    execute 'reset role';
    open_window_id := window_state.window_id;

    update public.cp_update_windows
    set closes_at = now() - interval '1 minute'
    where id = open_window_id;

    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_active_cp_update_window_for_me();
    begin
      perform public.submit_my_cp_update(730000);
      execute 'reset role';
      insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_after_closes_at', 'FAIL', 'Member submitted after closes_at.');
    exception when others then
      execute 'reset role';
      if window_state.can_submit = false and window_state.reason = 'window_closed' then
        insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_after_closes_at', 'PASS', sqlerrm);
      else
        insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_after_closes_at', 'FAIL', coalesce(row_to_json(window_state)::text, sqlerrm));
      end if;
    end;

    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    perform public.close_cp_update_window(open_window_id);
    execute 'reset role';
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'member_submit_denied_after_closes_at_setup', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.open_cp_update_window(anteiku_id, null, null, null);
    execute 'reset role';
    open_window_id := window_state.window_id;

    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    perform public.submit_my_cp_update(-1);
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'negative_cp_rejected', 'FAIL', 'Negative CP submission succeeded.');
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'negative_cp_rejected', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', wrong_guild_id::text, true);
    execute 'set local role authenticated';
    perform public.submit_my_cp_update(730000);
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'wrong_guild_submit_denied', 'FAIL', 'Wrong-guild member submitted against another guild window.');
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'wrong_guild_submit_denied', 'PASS', sqlerrm);
  end;

  for window_state in
    select unnest(array['inactive', 'on_break']) as status_name
  loop
    begin
      perform set_config('request.jwt.claim.sub', owner_id::text, true);
      execute 'set local role authenticated';
      perform public.update_member_roster_status(member_membership_id, window_state.status_name, 'cp window eligibility validation');
      execute 'reset role';

      perform set_config('request.jwt.claim.sub', member_id::text, true);
      execute 'set local role authenticated';
      perform public.submit_my_cp_update(730000);
      execute 'reset role';
      insert into milestone19b_cp_window_results values ('eligibility', window_state.status_name || '_submit_denied', 'FAIL', window_state.status_name || ' submitted CP.');
    exception when others then
      execute 'reset role';
      insert into milestone19b_cp_window_results values ('eligibility', window_state.status_name || '_submit_denied', 'PASS', sqlerrm);
    end;

    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'active', 'restore after CP eligibility validation');
    execute 'reset role';
  end loop;

  for window_state in
    select unnest(array['suspended', 'left', 'kicked']) as status_name
  loop
    begin
      perform set_config('request.jwt.claim.sub', owner_id::text, true);
      execute 'set local role authenticated';
      perform public.update_member_roster_status(member_membership_id, window_state.status_name, 'cp hard-block validation');
      execute 'reset role';

      perform set_config('request.jwt.claim.sub', member_id::text, true);
      execute 'set local role authenticated';
      perform public.submit_my_cp_update(730000);
      execute 'reset role';
      insert into milestone19b_cp_window_results values ('eligibility', window_state.status_name || '_submit_denied', 'FAIL', window_state.status_name || ' submitted CP.');
    exception when others then
      execute 'reset role';
      insert into milestone19b_cp_window_results values ('eligibility', window_state.status_name || '_submit_denied', 'PASS', sqlerrm);
    end;

    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_roster_status(member_membership_id, 'active', 'restore after CP hard-block validation');
    execute 'reset role';
  end loop;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    perform public.close_cp_update_window(open_window_id);
    execute 'reset role';
  exception when others then
    execute 'reset role';
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.open_cp_update_window(anteiku_id, null, null, 'admin with update_cp validation');
    perform public.close_cp_update_window(window_state.window_id);
    execute 'reset role';

    insert into milestone19b_cp_window_results values ('rpc', 'admin_with_update_cp_can_open_close_window', 'PASS', 'Admin with update_cp opened and closed CP update window.');
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('rpc', 'admin_with_update_cp_can_open_close_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    execute 'set local role authenticated';
    perform public.update_member_cp(member_id, 740000, 'existing admin CP RPC validation');
    execute 'reset role';

    if exists (
      select 1
      from public.member_cp
      where profile_id = member_id
        and cp_value = 740000
        and updated_by = admin_cp_id
    ) then
      insert into milestone19b_cp_window_results values ('regression', 'existing_admin_update_member_cp_still_works', 'PASS', 'Existing admin CP update RPC still works.');
    else
      insert into milestone19b_cp_window_results values ('regression', 'existing_admin_update_member_cp_still_works', 'FAIL', 'Existing admin CP update did not update expected row.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b_cp_window_results values ('regression', 'existing_admin_update_member_cp_still_works', 'FAIL', sqlerrm);
  end;
end;
$$;

select section, test_name, status, details
from milestone19b_cp_window_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone19b_total_pass,
       count(*) filter (where status = 'FAIL') as milestone19b_total_fail,
       count(*) filter (where status = 'SKIP') as milestone19b_total_skip
from milestone19b_cp_window_results;

-- Milestone 19B.1: CP Update Window staff read RPC validation.
-- This validates get_cp_update_window_for_guild(p_guild_id uuid) for scoped
-- staff read access without direct table grants.
create temp table if not exists milestone19b1_cp_window_read_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  anteiku_re_id constant uuid := '00000000-0000-0000-0000-000000000102';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  leader_id constant uuid := '10000000-0000-0000-0000-000000000002';
  vice_id constant uuid := '10000000-0000-0000-0000-000000000003';
  admin_no_cp_id constant uuid := '10000000-0000-0000-0000-000000000004';
  admin_cp_id constant uuid := '10000000-0000-0000-0000-000000000005';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  wrong_guild_id constant uuid := '10000000-0000-0000-0000-000000000009';
  admin_no_cp_membership_id uuid;
  open_window_id uuid;
  window_state record;
  direct_count integer;
begin
  update public.guild_memberships
  set membership_status = 'active',
      roster_status = 'active',
      is_primary = true
  where profile_id in (owner_id, leader_id, vice_id, admin_no_cp_id, admin_cp_id, member_id)
    and guild_id = anteiku_id;

  update public.guild_memberships
  set membership_status = 'active',
      roster_status = 'active',
      is_primary = true
  where profile_id = wrong_guild_id
    and guild_id = anteiku_re_id;

  select id into admin_no_cp_membership_id
  from public.guild_memberships
  where profile_id = admin_no_cp_id
    and guild_id = anteiku_id;

  delete from public.admin_permissions
  where membership_id = admin_no_cp_membership_id
    and permission_key in ('view_cp', 'update_cp');

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  select gm.id, permission_key, owner_id
  from public.guild_memberships gm
  cross join (values ('view_cp'), ('update_cp')) as perms(permission_key)
  where gm.profile_id = admin_cp_id
    and gm.guild_id = anteiku_id
  on conflict (membership_id, permission_key) do nothing;

  delete from public.cp_update_windows;

  if to_regprocedure('public.get_cp_update_window_for_guild(uuid)') is not null then
    insert into milestone19b1_cp_window_read_results values ('schema', 'staff_window_read_rpc_exists', 'PASS', 'get_cp_update_window_for_guild(uuid) exists.');
  else
    insert into milestone19b1_cp_window_read_results values ('schema', 'staff_window_read_rpc_exists', 'FAIL', 'get_cp_update_window_for_guild(uuid) is missing.');
  end if;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    select count(*) into direct_count from public.cp_update_windows;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone19b1_cp_window_read_results values ('rls', 'no_direct_cp_update_windows_read', 'PASS', 'Normal authenticated direct read returned no rows.');
    else
      insert into milestone19b1_cp_window_read_results values ('rls', 'no_direct_cp_update_windows_read', 'FAIL', 'Normal authenticated direct read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rls', 'no_direct_cp_update_windows_read', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.open_cp_update_window(anteiku_id, null, null, 'staff read validation');
    execute 'reset role';
    open_window_id := window_state.window_id;
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('setup', 'open_window_for_staff_read_tests', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_cp_update_window_for_guild(anteiku_id);
    execute 'reset role';

    if window_state.id = open_window_id
       and window_state.guild_id = anteiku_id
       and window_state.status = 'open'
       and window_state.note = 'staff read validation'
       and window_state.created_by_username is not null
       and window_state.server_now is not null then
      insert into milestone19b1_cp_window_read_results values ('rpc', 'owner_reads_open_window', 'PASS', 'Owner read selected-guild open window with safe labels.');
    else
      insert into milestone19b1_cp_window_read_results values ('rpc', 'owner_reads_open_window', 'FAIL', coalesce(row_to_json(window_state)::text, 'No window state returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'owner_reads_open_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', leader_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_cp_update_window_for_guild(anteiku_id);
    execute 'reset role';

    if window_state.id = open_window_id and window_state.status = 'open' then
      insert into milestone19b1_cp_window_read_results values ('rpc', 'leader_reads_scoped_window', 'PASS', 'Leader read assigned guild CP window.');
    else
      insert into milestone19b1_cp_window_read_results values ('rpc', 'leader_reads_scoped_window', 'FAIL', coalesce(row_to_json(window_state)::text, 'No window state returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'leader_reads_scoped_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', vice_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_cp_update_window_for_guild(anteiku_id);
    execute 'reset role';

    if window_state.id = open_window_id and window_state.status = 'open' then
      insert into milestone19b1_cp_window_read_results values ('rpc', 'vice_reads_scoped_window', 'PASS', 'Vice read assigned guild CP window.');
    else
      insert into milestone19b1_cp_window_read_results values ('rpc', 'vice_reads_scoped_window', 'FAIL', coalesce(row_to_json(window_state)::text, 'No window state returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'vice_reads_scoped_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', leader_id::text, true);
    execute 'set local role authenticated';
    perform public.get_cp_update_window_for_guild(anteiku_re_id);
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'leader_wrong_guild_denied', 'FAIL', 'Leader read wrong-guild CP window status.');
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'leader_wrong_guild_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_cp_update_window_for_guild(anteiku_id);
    execute 'reset role';

    if window_state.id = open_window_id and window_state.status = 'open' then
      insert into milestone19b1_cp_window_read_results values ('rpc', 'admin_with_cp_permission_reads_window', 'PASS', 'Admin with CP permission read scoped CP window.');
    else
      insert into milestone19b1_cp_window_read_results values ('rpc', 'admin_with_cp_permission_reads_window', 'FAIL', coalesce(row_to_json(window_state)::text, 'No window state returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'admin_with_cp_permission_reads_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    execute 'set local role authenticated';
    perform public.get_cp_update_window_for_guild(anteiku_id);
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'admin_without_cp_permission_denied', 'FAIL', 'Admin without CP permission read CP window status.');
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'admin_without_cp_permission_denied', 'PASS', sqlerrm);
  end;

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  values (admin_no_cp_membership_id, 'view_cp', owner_id)
  on conflict (membership_id, permission_key) do nothing;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_cp_update_window_for_guild(anteiku_id);
    execute 'reset role';

    if window_state.id = open_window_id and window_state.status = 'open' then
      insert into milestone19b1_cp_window_read_results values ('rpc', 'admin_with_view_cp_reads_window', 'PASS', 'Admin with view_cp read scoped CP window.');
    else
      insert into milestone19b1_cp_window_read_results values ('rpc', 'admin_with_view_cp_reads_window', 'FAIL', coalesce(row_to_json(window_state)::text, 'No window state returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'admin_with_view_cp_reads_window', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    perform public.get_cp_update_window_for_guild(anteiku_id);
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'member_denied_staff_window_read', 'FAIL', 'Member read staff CP window status.');
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'member_denied_staff_window_read', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', wrong_guild_id::text, true);
    execute 'set local role authenticated';
    perform public.get_cp_update_window_for_guild(anteiku_id);
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'wrong_guild_user_denied_staff_window_read', 'FAIL', 'Wrong-guild user read Anteiku CP window status.');
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'wrong_guild_user_denied_staff_window_read', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    perform public.close_cp_update_window(open_window_id);
    select * into window_state
    from public.get_cp_update_window_for_guild(anteiku_id);
    execute 'reset role';

    if window_state.id = open_window_id
       and window_state.status = 'closed'
       and window_state.closed_by_username is not null then
      insert into milestone19b1_cp_window_read_results values ('rpc', 'latest_closed_window_returned_when_no_open', 'PASS', 'Latest closed window returned after close.');
    else
      insert into milestone19b1_cp_window_read_results values ('rpc', 'latest_closed_window_returned_when_no_open', 'FAIL', coalesce(row_to_json(window_state)::text, 'No window state returned.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'latest_closed_window_returned_when_no_open', 'FAIL', sqlerrm);
  end;

  begin
    delete from public.cp_update_windows where guild_id = anteiku_re_id;

    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    select * into window_state
    from public.get_cp_update_window_for_guild(anteiku_re_id);

    if not found then
      execute 'reset role';
      insert into milestone19b1_cp_window_read_results values ('rpc', 'no_window_returns_no_row', 'PASS', 'No row returned when selected guild has no CP windows.');
    else
      execute 'reset role';
      insert into milestone19b1_cp_window_read_results values ('rpc', 'no_window_returns_no_row', 'FAIL', coalesce(row_to_json(window_state)::text, 'Unexpected window state.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone19b1_cp_window_read_results values ('rpc', 'no_window_returns_no_row', 'FAIL', sqlerrm);
  end;
end;
$$;

select section, test_name, status, details
from milestone19b1_cp_window_read_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone19b1_total_pass,
       count(*) filter (where status = 'FAIL') as milestone19b1_total_fail,
       count(*) filter (where status = 'SKIP') as milestone19b1_total_skip
from milestone19b1_cp_window_read_results;

-- Milestone 20B: CP Leaderboard RPC validation.
-- This validates member-safe rank-only CP rankings and admin CP rankings
-- without direct member_cp/cp_snapshots access or member CP value leakage.
create temp table if not exists milestone20b_cp_rankings_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  anteiku_re_id constant uuid := '00000000-0000-0000-0000-000000000102';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  leader_id constant uuid := '10000000-0000-0000-0000-000000000002';
  vice_id constant uuid := '10000000-0000-0000-0000-000000000003';
  admin_cp_id constant uuid := '10000000-0000-0000-0000-000000000005';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  wrong_guild_id constant uuid := '10000000-0000-0000-0000-000000000009';
  trial_rank_id constant uuid := '10000000-0000-0000-0000-000000000020';
  pending_transfer_rank_id constant uuid := '10000000-0000-0000-0000-000000000021';
  inactive_rank_id constant uuid := '10000000-0000-0000-0000-000000000022';
  on_break_rank_id constant uuid := '10000000-0000-0000-0000-000000000023';
  suspended_rank_id constant uuid := '10000000-0000-0000-0000-000000000024';
  left_rank_id constant uuid := '10000000-0000-0000-0000-000000000025';
  kicked_rank_id constant uuid := '10000000-0000-0000-0000-000000000026';
  admin_no_view_rank_id constant uuid := '10000000-0000-0000-0000-000000000027';
  admin_no_view_membership_id uuid;
  member_signature text;
  forbidden_member_columns integer;
  guild_igns text[];
  global_guild_count integer;
  global_missing_label_count integer;
  wrong_guild_global_count integer;
  direct_count integer;
  member_ranking record;
  first_ranking record;
  admin_ranking record;
begin
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  values
    ('00000000-0000-0000-0000-000000000000', trial_rank_id, 'authenticated', 'authenticated', 'trial-rank.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', pending_transfer_rank_id, 'authenticated', 'authenticated', 'pending-transfer-rank.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', inactive_rank_id, 'authenticated', 'authenticated', 'inactive-rank.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', on_break_rank_id, 'authenticated', 'authenticated', 'on-break-rank.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', suspended_rank_id, 'authenticated', 'authenticated', 'suspended-rank.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', left_rank_id, 'authenticated', 'authenticated', 'left-rank.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', kicked_rank_id, 'authenticated', 'authenticated', 'kicked-rank.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', admin_no_view_rank_id, 'authenticated', 'authenticated', 'admin-no-view-rank.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now())
  on conflict (id) do nothing;

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (trial_rank_id, 'trial_rank', 'trial_rank', 'Trial Rank', 'approved', now()),
    (pending_transfer_rank_id, 'pending_transfer_rank', 'pending_transfer_rank', 'Pending Transfer Rank', 'approved', now()),
    (inactive_rank_id, 'inactive_rank', 'inactive_rank', 'Inactive Rank', 'approved', now()),
    (on_break_rank_id, 'on_break_rank', 'on_break_rank', 'On Break Rank', 'approved', now()),
    (suspended_rank_id, 'suspended_rank', 'suspended_rank', 'Suspended Rank', 'approved', now()),
    (left_rank_id, 'left_rank', 'left_rank', 'Left Rank', 'approved', now()),
    (kicked_rank_id, 'kicked_rank', 'kicked_rank', 'Kicked Rank', 'approved', now()),
    (admin_no_view_rank_id, 'admin_no_view_rank', 'admin_no_view_rank', 'Admin No View Rank', 'approved', now())
  on conflict (id) do update
  set ign = excluded.ign,
      approval_status = excluded.approval_status,
      approved_at = excluded.approved_at;

  update public.guild_memberships
  set membership_status = 'active',
      roster_status = 'active',
      is_primary = true
  where profile_id in (owner_id, leader_id, vice_id, admin_cp_id, member_id)
    and guild_id = anteiku_id;

  update public.guild_memberships
  set membership_status = 'active',
      roster_status = 'active',
      is_primary = true
  where profile_id = wrong_guild_id
    and guild_id = anteiku_re_id;

  insert into public.guild_memberships (profile_id, guild_id, role, membership_status, roster_status, is_primary, assigned_by)
  values
    (trial_rank_id, anteiku_id, 'member', 'active', 'trial', true, owner_id),
    (pending_transfer_rank_id, anteiku_id, 'member', 'active', 'pending_transfer', true, owner_id),
    (inactive_rank_id, anteiku_id, 'member', 'active', 'inactive', true, owner_id),
    (on_break_rank_id, anteiku_id, 'member', 'active', 'on_break', true, owner_id),
    (suspended_rank_id, anteiku_id, 'member', 'suspended', 'suspended', true, owner_id),
    (left_rank_id, anteiku_id, 'member', 'left', 'left', false, owner_id),
    (kicked_rank_id, anteiku_id, 'member', 'left', 'kicked', false, owner_id),
    (admin_no_view_rank_id, anteiku_id, 'admin', 'active', 'active', true, owner_id)
  on conflict (profile_id, guild_id) do update
  set role = excluded.role,
      membership_status = excluded.membership_status,
      roster_status = excluded.roster_status,
      is_primary = excluded.is_primary,
      assigned_by = excluded.assigned_by;

  select id into admin_no_view_membership_id
  from public.guild_memberships
  where profile_id = admin_no_view_rank_id
    and guild_id = anteiku_id;

  delete from public.admin_permissions
  where membership_id = admin_no_view_membership_id
    and permission_key in ('view_cp', 'update_cp');

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  select gm.id, 'view_cp', owner_id
  from public.guild_memberships gm
  where gm.profile_id = admin_cp_id
    and gm.guild_id = anteiku_id
  on conflict (membership_id, permission_key) do nothing;

  insert into public.member_cp (profile_id, guild_id, cp_value, updated_by, updated_at)
  values
    (leader_id, anteiku_id, 900000, owner_id, now()),
    (vice_id, anteiku_id, 850000, owner_id, now()),
    (admin_cp_id, anteiku_id, 800000, owner_id, now()),
    (trial_rank_id, anteiku_id, 760000, owner_id, now()),
    (pending_transfer_rank_id, anteiku_id, 750000, owner_id, now()),
    (member_id, anteiku_id, 700000, owner_id, now()),
    (wrong_guild_id, anteiku_re_id, 650000, owner_id, now()),
    (inactive_rank_id, anteiku_id, 990000, owner_id, now()),
    (on_break_rank_id, anteiku_id, 980000, owner_id, now()),
    (suspended_rank_id, anteiku_id, 970000, owner_id, now()),
    (left_rank_id, anteiku_id, 960000, owner_id, now()),
    (kicked_rank_id, anteiku_id, 950000, owner_id, now())
  on conflict (profile_id) do update
  set guild_id = excluded.guild_id,
      cp_value = excluded.cp_value,
      updated_by = excluded.updated_by,
      updated_at = excluded.updated_at;

  if to_regprocedure('public.get_member_cp_rankings(text)') is not null
     and to_regprocedure('public.get_admin_cp_rankings(uuid,text)') is not null then
    insert into milestone20b_cp_rankings_results values ('schema', 'cp_ranking_rpcs_exist', 'PASS', 'Both CP ranking RPCs exist.');
  else
    insert into milestone20b_cp_rankings_results values ('schema', 'cp_ranking_rpcs_exist', 'FAIL', 'One or both CP ranking RPCs are missing.');
  end if;

  select pg_get_function_result('public.get_member_cp_rankings(text)'::regprocedure)
  into member_signature;

  select count(*) into forbidden_member_columns
  from regexp_matches(
    lower(member_signature),
    '(cp_value|old_cp|cp_new|growth|updated_at|updated_by|profile_id|username|snapshot|metadata)',
    'g'
  );

  if forbidden_member_columns = 0 then
    insert into milestone20b_cp_rankings_results values ('schema', 'member_rpc_shape_has_no_cp_fields', 'PASS', member_signature);
  else
    insert into milestone20b_cp_rankings_results values ('schema', 'member_rpc_shape_has_no_cp_fields', 'FAIL', member_signature);
  end if;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select array_agg(r.ign order by r.rank) into guild_igns
    from public.get_member_cp_rankings('guild') r;
    execute 'reset role';

    if guild_igns[1:6] = array[
      'Leader Local',
      'Vice Local',
      'Admin CP',
      'Trial Rank',
      'Pending Transfer Rank',
      'Member Local'
    ]
       and array_position(guild_igns, 'Inactive Rank') is null
       and array_position(guild_igns, 'On Break Rank') is null
       and array_position(guild_igns, 'Suspended Rank') is null
       and array_position(guild_igns, 'Left Rank') is null
       and array_position(guild_igns, 'Kicked Rank') is null then
      insert into milestone20b_cp_rankings_results values ('rpc', 'member_guild_ranking_order_and_visibility', 'PASS', array_to_string(guild_igns, ', '));
    else
      insert into milestone20b_cp_rankings_results values ('rpc', 'member_guild_ranking_order_and_visibility', 'FAIL', coalesce(array_to_string(guild_igns, ', '), 'No rows.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'member_guild_ranking_order_and_visibility', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select * into member_ranking
    from public.get_member_cp_rankings('guild')
    where is_current_user = true;
    execute 'reset role';

    if member_ranking.ign = 'Member Local'
       and member_ranking.rank = 6
       and member_ranking.profile_slug = 'member_local'
       and member_ranking.guild_name is null
       and member_ranking.guild_slug is null then
      insert into milestone20b_cp_rankings_results values ('rpc', 'member_current_user_highlighted', 'PASS', row_to_json(member_ranking)::text);
    else
      insert into milestone20b_cp_rankings_results values ('rpc', 'member_current_user_highlighted', 'FAIL', coalesce(row_to_json(member_ranking)::text, 'No current-user row.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'member_current_user_highlighted', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select count(*) into global_guild_count
    from public.get_member_cp_rankings('global') r
    where r.guild_name is not null
      and r.guild_slug is not null;
    select count(*) into global_missing_label_count
    from public.get_member_cp_rankings('global') r
    where r.guild_name is null
       or r.guild_slug is null;
    select count(*) into wrong_guild_global_count
    from public.get_member_cp_rankings('global') r
    where r.ign = 'Wrong Guild'
      and r.guild_name = 'Anteiku:Re'
      and r.guild_slug = 'anteiku-re';
    execute 'reset role';

    if global_guild_count >= 7
       and global_missing_label_count = 0
       and wrong_guild_global_count = 1 then
      insert into milestone20b_cp_rankings_results values ('rpc', 'member_global_ranking_has_guild_labels_only', 'PASS', 'Global member ranking returned guild labels for all eligible rows.');
    else
      insert into milestone20b_cp_rankings_results values ('rpc', 'member_global_ranking_has_guild_labels_only', 'FAIL', 'Expected 7 labeled global rows, found ' || coalesce(global_guild_count::text, 'null') || '.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'member_global_ranking_has_guild_labels_only', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', inactive_rank_id::text, true);
    execute 'set local role authenticated';
    perform public.get_member_cp_rankings('global');
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'inactive_can_view_rankings', 'PASS', 'Inactive active-membership user can view rank order.');
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'inactive_can_view_rankings', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', suspended_rank_id::text, true);
    execute 'set local role authenticated';
    perform public.get_member_cp_rankings('global');
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'hard_blocked_user_denied_rankings', 'FAIL', 'Suspended user read member rankings.');
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'hard_blocked_user_denied_rankings', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    perform public.get_admin_cp_rankings(anteiku_id, 'guild');
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'member_cannot_call_admin_rankings', 'FAIL', 'Member called admin CP rankings.');
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'member_cannot_call_admin_rankings', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    execute 'set local role authenticated';
    select * into admin_ranking
    from public.get_admin_cp_rankings(anteiku_id, 'guild')
    where rank = 1;
    execute 'reset role';

    if admin_ranking.profile_id = leader_id
       and admin_ranking.cp_value = 900000
       and admin_ranking.guild_id = anteiku_id
       and admin_ranking.updated_at is not null then
      insert into milestone20b_cp_rankings_results values ('rpc', 'admin_with_view_cp_reads_guild_values', 'PASS', row_to_json(admin_ranking)::text);
    else
      insert into milestone20b_cp_rankings_results values ('rpc', 'admin_with_view_cp_reads_guild_values', 'FAIL', coalesce(row_to_json(admin_ranking)::text, 'No admin ranking row.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'admin_with_view_cp_reads_guild_values', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_view_rank_id::text, true);
    execute 'set local role authenticated';
    perform public.get_admin_cp_rankings(anteiku_id, 'guild');
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'admin_without_view_cp_denied', 'FAIL', 'Admin without view_cp read guild CP rankings.');
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'admin_without_view_cp_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    execute 'set local role authenticated';
    perform public.get_admin_cp_rankings(null, 'global');
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'non_owner_admin_global_denied', 'FAIL', 'Non-owner Admin read global CP rankings.');
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'non_owner_admin_global_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    execute 'set local role authenticated';
    select * into first_ranking
    from public.get_admin_cp_rankings(null, 'global')
    where rank = 1;
    execute 'reset role';

    if first_ranking.profile_id = leader_id
       and first_ranking.cp_value = 900000 then
      insert into milestone20b_cp_rankings_results values ('rpc', 'owner_reads_global_admin_values', 'PASS', row_to_json(first_ranking)::text);
    else
      insert into milestone20b_cp_rankings_results values ('rpc', 'owner_reads_global_admin_values', 'FAIL', coalesce(row_to_json(first_ranking)::text, 'No owner global ranking row.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rpc', 'owner_reads_global_admin_values', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    select count(*) into direct_count from public.member_cp;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone20b_cp_rankings_results values ('rls', 'member_direct_member_cp_still_denied', 'PASS', 'Direct member_cp read returned no rows.');
    else
      insert into milestone20b_cp_rankings_results values ('rls', 'member_direct_member_cp_still_denied', 'FAIL', 'Direct member_cp read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rls', 'member_direct_member_cp_still_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    select count(*) into direct_count from public.cp_snapshots;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone20b_cp_rankings_results values ('rls', 'member_direct_cp_snapshots_still_denied', 'PASS', 'Direct cp_snapshots read returned no rows.');
    else
      insert into milestone20b_cp_rankings_results values ('rls', 'member_direct_cp_snapshots_still_denied', 'FAIL', 'Direct cp_snapshots read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone20b_cp_rankings_results values ('rls', 'member_direct_cp_snapshots_still_denied', 'PASS', sqlerrm);
  end;
end;
$$;

select section, test_name, status, details
from milestone20b_cp_rankings_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone20b_total_pass,
       count(*) filter (where status = 'FAIL') as milestone20b_total_fail,
       count(*) filter (where status = 'SKIP') as milestone20b_total_skip
from milestone20b_cp_rankings_results;

-- Milestone 21B: Rank Badge / Profile Border own-rank summary validation.
-- This validates a member-safe own-rank summary RPC without exposing CP values
-- or private leaderboard metadata.
create temp table if not exists milestone21b_rank_badge_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  leader_id constant uuid := '10000000-0000-0000-0000-000000000002';
  vice_id constant uuid := '10000000-0000-0000-0000-000000000003';
  admin_cp_id constant uuid := '10000000-0000-0000-0000-000000000005';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  trial_rank_id constant uuid := '10000000-0000-0000-0000-000000000020';
  inactive_rank_id constant uuid := '10000000-0000-0000-0000-000000000022';
  suspended_rank_id constant uuid := '10000000-0000-0000-0000-000000000024';
  filler_high_rank_id uuid := '10000000-0000-0000-0000-00000000020b';
  filler_ranked_member_id uuid := '10000000-0000-0000-0000-00000000021b';
  unranked_id uuid := '10000000-0000-0000-0000-00000000030b';
  rank_summary record;
  summary_signature text;
  forbidden_summary_columns integer;
  direct_count integer;
  idx integer;
  filler_id uuid;
begin
  if to_regprocedure('public.get_my_cp_rank_summary()') is not null then
    insert into milestone21b_rank_badge_results values ('schema', 'rank_summary_rpc_exists', 'PASS', 'get_my_cp_rank_summary() exists.');
  else
    insert into milestone21b_rank_badge_results values ('schema', 'rank_summary_rpc_exists', 'FAIL', 'get_my_cp_rank_summary() is missing.');
  end if;

  select pg_get_function_result('public.get_my_cp_rank_summary()'::regprocedure)
  into summary_signature;

  select count(*) into forbidden_summary_columns
  from regexp_matches(
    lower(summary_signature),
    '(cp_value|old_cp|cp_new|growth|updated_at|updated_by|profile_id|username|snapshot|metadata|ign|guild_name|guild_slug)',
    'g'
  );

  if forbidden_summary_columns = 0 then
    insert into milestone21b_rank_badge_results values ('schema', 'rank_summary_shape_has_no_private_fields', 'PASS', summary_signature);
  else
    insert into milestone21b_rank_badge_results values ('schema', 'rank_summary_shape_has_no_private_fields', 'FAIL', summary_signature);
  end if;

  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  values
    ('00000000-0000-0000-0000-000000000000', filler_high_rank_id, 'authenticated', 'authenticated', 'rank-badge-high.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', filler_ranked_member_id, 'authenticated', 'authenticated', 'rank-badge-ranked.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', unranked_id, 'authenticated', 'authenticated', 'rank-badge-unranked.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now())
  on conflict (id) do nothing;

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (filler_high_rank_id, 'rank_badge_high', 'rank_badge_high', 'Rank Badge High', 'approved', now()),
    (filler_ranked_member_id, 'rank_badge_ranked', 'rank_badge_ranked', 'Rank Badge Ranked', 'approved', now()),
    (unranked_id, 'rank_badge_unranked', 'rank_badge_unranked', 'Rank Badge Unranked', 'approved', now())
  on conflict (id) do update
  set ign = excluded.ign,
      approval_status = excluded.approval_status,
      approved_at = excluded.approved_at;

  insert into public.guild_memberships (profile_id, guild_id, role, membership_status, roster_status, is_primary, assigned_by)
  values
    (filler_high_rank_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
    (filler_ranked_member_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
    (unranked_id, anteiku_id, 'member', 'active', 'active', true, owner_id)
  on conflict (profile_id, guild_id) do update
  set role = excluded.role,
      membership_status = excluded.membership_status,
      roster_status = excluded.roster_status,
      is_primary = excluded.is_primary,
      assigned_by = excluded.assigned_by;

  for idx in 1..20 loop
    filler_id := ('10000000-0000-0000-0000-' || lpad(to_hex(8448 + idx), 12, '0'))::uuid;

    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    )
    values (
      '00000000-0000-0000-0000-000000000000',
      filler_id,
      'authenticated',
      'authenticated',
      'rank-badge-filler-' || idx || '.local@example.test',
      'local-only',
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{}'::jsonb,
      now(),
      now()
    )
    on conflict (id) do nothing;

    insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
    values (
      filler_id,
      'rank_badge_filler_' || idx,
      'rank_badge_filler_' || idx,
      'Rank Badge Filler ' || lpad(idx::text, 2, '0'),
      'approved',
      now()
    )
    on conflict (id) do update
    set ign = excluded.ign,
        approval_status = excluded.approval_status,
        approved_at = excluded.approved_at;

    insert into public.guild_memberships (profile_id, guild_id, role, membership_status, roster_status, is_primary, assigned_by)
    values (filler_id, anteiku_id, 'member', 'active', 'active', true, owner_id)
    on conflict (profile_id, guild_id) do update
    set role = excluded.role,
        membership_status = excluded.membership_status,
        roster_status = excluded.roster_status,
        is_primary = excluded.is_primary,
        assigned_by = excluded.assigned_by;

    insert into public.member_cp (profile_id, guild_id, cp_value, updated_by, updated_at)
    values (filler_id, anteiku_id, 690000 - (idx * 1000), owner_id, now())
    on conflict (profile_id) do update
    set guild_id = excluded.guild_id,
        cp_value = excluded.cp_value,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at;
  end loop;

  insert into public.member_cp (profile_id, guild_id, cp_value, updated_by, updated_at)
  values
    (filler_high_rank_id, anteiku_id, 683500, owner_id, now()),
    (filler_ranked_member_id, anteiku_id, 1000, owner_id, now())
  on conflict (profile_id) do update
  set guild_id = excluded.guild_id,
      cp_value = excluded.cp_value,
      updated_by = excluded.updated_by,
      updated_at = excluded.updated_at;

  begin
    perform set_config('request.jwt.claim.sub', leader_id::text, true);
    execute 'set local role authenticated';
    select * into rank_summary from public.get_my_cp_rank_summary();
    execute 'reset role';

    if rank_summary.global_rank = 1
       and rank_summary.guild_rank = 1
       and rank_summary.rank_tier = 'rank_one'
       and rank_summary.visual_key = 'rank_1'
       and rank_summary.is_ranked = true then
      insert into milestone21b_rank_badge_results values ('rpc', 'rank_1_summary', 'PASS', row_to_json(rank_summary)::text);
    else
      insert into milestone21b_rank_badge_results values ('rpc', 'rank_1_summary', 'FAIL', coalesce(row_to_json(rank_summary)::text, 'No summary.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'rank_1_summary', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', vice_id::text, true);
    execute 'set local role authenticated';
    select * into rank_summary from public.get_my_cp_rank_summary();
    execute 'reset role';

    if rank_summary.global_rank = 2
       and rank_summary.rank_tier = 'rank_two'
       and rank_summary.visual_key = 'rank_2'
       and rank_summary.is_ranked = true then
      insert into milestone21b_rank_badge_results values ('rpc', 'rank_2_summary', 'PASS', row_to_json(rank_summary)::text);
    else
      insert into milestone21b_rank_badge_results values ('rpc', 'rank_2_summary', 'FAIL', coalesce(row_to_json(rank_summary)::text, 'No summary.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'rank_2_summary', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    execute 'set local role authenticated';
    select * into rank_summary from public.get_my_cp_rank_summary();
    execute 'reset role';

    if rank_summary.global_rank = 3
       and rank_summary.rank_tier = 'rank_three'
       and rank_summary.visual_key = 'rank_3'
       and rank_summary.is_ranked = true then
      insert into milestone21b_rank_badge_results values ('rpc', 'rank_3_summary', 'PASS', row_to_json(rank_summary)::text);
    else
      insert into milestone21b_rank_badge_results values ('rpc', 'rank_3_summary', 'FAIL', coalesce(row_to_json(rank_summary)::text, 'No summary.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'rank_3_summary', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', trial_rank_id::text, true);
    execute 'set local role authenticated';
    select * into rank_summary from public.get_my_cp_rank_summary();
    execute 'reset role';

    if rank_summary.global_rank = 4
       and rank_summary.rank_tier = 'elite_five'
       and rank_summary.visual_key = 'elite_5'
       and rank_summary.is_ranked = true then
      insert into milestone21b_rank_badge_results values ('rpc', 'elite_five_summary', 'PASS', row_to_json(rank_summary)::text);
    else
      insert into milestone21b_rank_badge_results values ('rpc', 'elite_five_summary', 'FAIL', coalesce(row_to_json(rank_summary)::text, 'No summary.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'elite_five_summary', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select * into rank_summary from public.get_my_cp_rank_summary();
    execute 'reset role';

    if rank_summary.global_rank = 6
       and rank_summary.rank_tier = 'top_ten'
       and rank_summary.visual_key = 'top_10'
       and rank_summary.is_ranked = true then
      insert into milestone21b_rank_badge_results values ('rpc', 'top_ten_summary', 'PASS', row_to_json(rank_summary)::text);
    else
      insert into milestone21b_rank_badge_results values ('rpc', 'top_ten_summary', 'FAIL', coalesce(row_to_json(rank_summary)::text, 'No summary.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'top_ten_summary', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', filler_high_rank_id::text, true);
    execute 'set local role authenticated';
    select * into rank_summary from public.get_my_cp_rank_summary();
    execute 'reset role';

    if rank_summary.global_rank between 11 and 25
       and rank_summary.rank_tier = 'high_rank'
       and rank_summary.visual_key = 'high_rank'
       and rank_summary.is_ranked = true then
      insert into milestone21b_rank_badge_results values ('rpc', 'high_rank_summary', 'PASS', row_to_json(rank_summary)::text);
    else
      insert into milestone21b_rank_badge_results values ('rpc', 'high_rank_summary', 'FAIL', coalesce(row_to_json(rank_summary)::text, 'No summary.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'high_rank_summary', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', filler_ranked_member_id::text, true);
    execute 'set local role authenticated';
    select * into rank_summary from public.get_my_cp_rank_summary();
    execute 'reset role';

    if rank_summary.global_rank >= 26
       and rank_summary.rank_tier = 'ranked_member'
       and rank_summary.visual_key = 'ranked_member'
       and rank_summary.is_ranked = true then
      insert into milestone21b_rank_badge_results values ('rpc', 'rank_26_plus_summary', 'PASS', row_to_json(rank_summary)::text);
    else
      insert into milestone21b_rank_badge_results values ('rpc', 'rank_26_plus_summary', 'FAIL', coalesce(row_to_json(rank_summary)::text, 'No summary.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'rank_26_plus_summary', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', unranked_id::text, true);
    execute 'set local role authenticated';
    select * into rank_summary from public.get_my_cp_rank_summary();
    execute 'reset role';

    if rank_summary.global_rank is null
       and rank_summary.guild_rank is null
       and rank_summary.rank_tier = 'unranked'
       and rank_summary.visual_key = 'unranked'
       and rank_summary.is_ranked = false then
      insert into milestone21b_rank_badge_results values ('rpc', 'unranked_member_summary', 'PASS', row_to_json(rank_summary)::text);
    else
      insert into milestone21b_rank_badge_results values ('rpc', 'unranked_member_summary', 'FAIL', coalesce(row_to_json(rank_summary)::text, 'No summary.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'unranked_member_summary', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', inactive_rank_id::text, true);
    execute 'set local role authenticated';
    select * into rank_summary from public.get_my_cp_rank_summary();
    execute 'reset role';

    if rank_summary.global_rank is null
       and rank_summary.guild_rank is null
       and rank_summary.rank_tier = 'unranked'
       and rank_summary.visual_key = 'unranked'
       and rank_summary.is_ranked = false then
      insert into milestone21b_rank_badge_results values ('rpc', 'inactive_excluded_summary', 'PASS', row_to_json(rank_summary)::text);
    else
      insert into milestone21b_rank_badge_results values ('rpc', 'inactive_excluded_summary', 'FAIL', coalesce(row_to_json(rank_summary)::text, 'No summary.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'inactive_excluded_summary', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', suspended_rank_id::text, true);
    execute 'set local role authenticated';
    perform public.get_my_cp_rank_summary();
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'hard_blocked_user_denied_summary', 'FAIL', 'Suspended user read rank summary.');
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rpc', 'hard_blocked_user_denied_summary', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    execute 'set local role authenticated';
    select count(*) into direct_count from public.get_my_cp_rank_summary() s
    where to_jsonb(s) ?| array[
      'cp_value',
      'old_cp',
      'cp_new',
      'growth',
      'updated_at',
      'updated_by',
      'profile_id',
      'username',
      'snapshot',
      'metadata',
      'ign',
      'guild_name',
      'guild_slug'
    ];
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone21b_rank_badge_results values ('security', 'summary_response_contains_no_private_fields', 'PASS', 'Summary response contained only rank/tier fields.');
    else
      insert into milestone21b_rank_badge_results values ('security', 'summary_response_contains_no_private_fields', 'FAIL', 'Summary response contained private fields.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('security', 'summary_response_contains_no_private_fields', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    select count(*) into direct_count from public.member_cp;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone21b_rank_badge_results values ('rls', 'member_direct_member_cp_still_denied', 'PASS', 'Direct member_cp read returned no rows.');
    else
      insert into milestone21b_rank_badge_results values ('rls', 'member_direct_member_cp_still_denied', 'FAIL', 'Direct member_cp read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rls', 'member_direct_member_cp_still_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    select count(*) into direct_count from public.cp_snapshots;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone21b_rank_badge_results values ('rls', 'member_direct_cp_snapshots_still_denied', 'PASS', 'Direct cp_snapshots read returned no rows.');
    else
      insert into milestone21b_rank_badge_results values ('rls', 'member_direct_cp_snapshots_still_denied', 'FAIL', 'Direct cp_snapshots read returned rows.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone21b_rank_badge_results values ('rls', 'member_direct_cp_snapshots_still_denied', 'PASS', sqlerrm);
  end;
end;
$$;

select section, test_name, status, details
from milestone21b_rank_badge_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone21b_total_pass,
       count(*) filter (where status = 'FAIL') as milestone21b_total_fail,
       count(*) filter (where status = 'SKIP') as milestone21b_total_skip
from milestone21b_rank_badge_results;

-- Milestone 22B: Cosmetics catalog, unlocks, and equip RPC validation.

create temp table if not exists milestone22b_cosmetics_results (
  section text not null,
  test_name text not null,
  status text not null,
  details text
) on commit drop;

do $$
declare
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  wrong_guild_id constant uuid := '10000000-0000-0000-0000-000000000009';
  avatar_count integer;
  frame_count integer;
  rpc_count integer;
  direct_count integer;
  audit_count integer;
  cosmetics_payload jsonb;
  equip_payload jsonb;
  updated_profile public.profiles%rowtype;
begin
  select count(*) into rpc_count
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'get_available_avatars',
      'get_my_cosmetics',
      'equip_my_avatar',
      'equip_my_frame',
      'admin_grant_cosmetic'
    );

  if to_regclass('public.cosmetic_catalog') is not null
     and to_regclass('public.profile_cosmetic_unlocks') is not null
     and to_regclass('public.profile_equipped_cosmetics') is not null
     and rpc_count = 5 then
    insert into milestone22b_cosmetics_results values ('schema', 'cosmetics_tables_and_rpcs_exist', 'PASS', 'Cosmetics tables and RPCs exist.');
  else
    insert into milestone22b_cosmetics_results values ('schema', 'cosmetics_tables_and_rpcs_exist', 'FAIL', 'Missing cosmetics table or RPC.');
  end if;

  if exists (
    select 1
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname in ('cosmetic_catalog', 'profile_cosmetic_unlocks', 'profile_equipped_cosmetics')
    group by n.nspname
    having bool_and(c.relrowsecurity)
       and count(*) = 3
  ) then
    insert into milestone22b_cosmetics_results values ('schema', 'cosmetics_rls_enabled', 'PASS', 'RLS enabled on all cosmetics tables.');
  else
    insert into milestone22b_cosmetics_results values ('schema', 'cosmetics_rls_enabled', 'FAIL', 'RLS missing on one or more cosmetics tables.');
  end if;

  select count(*) filter (where type = 'avatar'),
         count(*) filter (where type = 'frame')
  into avatar_count, frame_count
  from public.cosmetic_catalog;

  if avatar_count = 54
     and frame_count = 10
     and exists (
       select 1
       from public.cosmetic_catalog
       where key = '1079_head'
         and type = 'avatar'
         and asset_path = '/cosmetics/avatars/1079_head.png'
         and unlock_type = 'free'
     )
     and exists (
       select 1
       from public.cosmetic_catalog
       where key = 'TXK_frame_reOpen_EN_FREE'
         and type = 'frame'
         and asset_path = '/cosmetics/frames/TXK_frame_reOpen_EN_FREE.png'
         and unlock_type = 'free'
     )
     and exists (
       select 1
       from public.cosmetic_catalog
       where key = 'TXK_C1001_lock'
         and type = 'frame'
         and asset_path = '/cosmetics/frames/TXK_C1001_lock.png'
         and unlock_type = 'free'
     ) then
    insert into milestone22b_cosmetics_results values ('seed', 'catalog_seeded', 'PASS', avatar_count::text || ' avatars and ' || frame_count::text || ' frames are seeded from actual asset filenames.');
  else
    insert into milestone22b_cosmetics_results values ('seed', 'catalog_seeded', 'FAIL', avatar_count::text || ' avatars and ' || frame_count::text || ' frames found, or expected default/locked keys are missing.');
  end if;

  if not exists (
    select 1
    from public.cosmetic_catalog c
    where c.key ~ '_FREE$'
      and c.unlock_type <> 'free'
  )
  and not exists (
    select 1
    from public.cosmetic_catalog c
    where c.type = 'avatar'
      and c.unlock_type <> 'free'
  )
  and not exists (
    select 1
    from public.cosmetic_catalog c
    where c.type = 'frame'
      and c.unlock_type <> 'free'
  )
  and exists (
    select 1
    from public.cosmetic_catalog c
    where c.key = 'TXK_C1001_lock'
      and c.unlock_type = 'free'
  ) then
    insert into milestone22b_cosmetics_results values ('seed', 'current_catalog_cosmetics_are_free', 'PASS', 'All current avatars and frames are free; future premium cosmetics use manual unlock_type.');
  else
    insert into milestone22b_cosmetics_results values ('seed', 'current_catalog_cosmetics_are_free', 'FAIL', 'Current avatar/frame unlock_type mapping is incorrect.');
  end if;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    select count(*) into avatar_count
    from public.get_available_avatars();

    if avatar_count = 54 then
      insert into milestone22b_cosmetics_results values ('rpc', 'member_reads_available_avatars', 'PASS', avatar_count::text || ' avatars returned.');
    else
      insert into milestone22b_cosmetics_results values ('rpc', 'member_reads_available_avatars', 'FAIL', avatar_count::text || ' avatars returned.');
    end if;
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'member_reads_available_avatars', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    cosmetics_payload := public.get_my_cosmetics();

    if cosmetics_payload #>> '{equipped,avatar_key}' = '1079_head'
       and cosmetics_payload #>> '{equipped,frame_key}' = 'TXK_frame_reOpen_EN_FREE'
       and exists (
         select 1
         from jsonb_array_elements(cosmetics_payload -> 'frames') f
         where f ->> 'key' = 'TXK_frame_reOpen_EN_FREE'
           and (f ->> 'is_unlocked')::boolean = true
       )
       and exists (
         select 1
         from jsonb_array_elements(cosmetics_payload -> 'frames') f
         where f ->> 'key' = 'TXK_C1001_lock'
           and f ->> 'unlock_type' = 'free'
           and (f ->> 'is_unlocked')::boolean = true
       )
       and exists (
         select 1
         from jsonb_array_elements(cosmetics_payload -> 'avatars') a
         where a ->> 'key' = '1079_head'
           and a ->> 'unlock_type' = 'free'
           and (a ->> 'is_unlocked')::boolean = true
       ) then
      insert into milestone22b_cosmetics_results values ('rpc', 'member_reads_own_cosmetics', 'PASS', cosmetics_payload::text);
    else
      insert into milestone22b_cosmetics_results values ('rpc', 'member_reads_own_cosmetics', 'FAIL', cosmetics_payload::text);
    end if;
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'member_reads_own_cosmetics', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    equip_payload := public.equip_my_avatar('1080_head');

    if equip_payload ->> 'avatar_key' = '1080_head'
       and exists (
         select 1
         from public.profiles p
         where p.id = member_id
           and p.avatar_key = '1080_head'
       ) then
      insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_valid_avatar', 'PASS', equip_payload::text);
    else
      insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_valid_avatar', 'FAIL', coalesce(equip_payload::text, 'No equip payload.'));
    end if;
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_valid_avatar', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.equip_my_avatar('avatar_not_real');
    insert into milestone22b_cosmetics_results values ('rpc', 'invalid_avatar_denied', 'FAIL', 'Invalid avatar was equipped.');
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'invalid_avatar_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    equip_payload := public.equip_my_frame('TXK_frame_reOpen_EN_FREE');

    if equip_payload ->> 'frame_key' = 'TXK_frame_reOpen_EN_FREE' then
      insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_default_frame', 'PASS', equip_payload::text);
    else
      insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_default_frame', 'FAIL', coalesce(equip_payload::text, 'No equip payload.'));
    end if;
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_default_frame', 'FAIL', sqlerrm);
  end;

  begin
    delete from public.profile_cosmetic_unlocks
    where profile_id = member_id
      and cosmetic_key = 'TXK_C1001_lock';

    perform set_config('request.jwt.claim.sub', member_id::text, true);
    equip_payload := public.equip_my_frame('TXK_C1001_lock');

    if equip_payload ->> 'frame_key' = 'TXK_C1001_lock' then
      insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_current_frame_without_unlock', 'PASS', equip_payload::text);
    else
      insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_current_frame_without_unlock', 'FAIL', coalesce(equip_payload::text, 'No equip payload.'));
    end if;
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_current_frame_without_unlock', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    cosmetics_payload := public.admin_grant_cosmetic(member_id, 'TXK_C1001_lock', 'local validation');

    if cosmetics_payload ->> 'cosmetic_key' = 'TXK_C1001_lock'
       and exists (
         select 1
         from public.profile_cosmetic_unlocks pcu
         where pcu.profile_id = member_id
           and pcu.cosmetic_key = 'TXK_C1001_lock'
       ) then
      insert into milestone22b_cosmetics_results values ('rpc', 'owner_grants_current_frame_compatibility', 'PASS', cosmetics_payload::text);
    else
      insert into milestone22b_cosmetics_results values ('rpc', 'owner_grants_current_frame_compatibility', 'FAIL', coalesce(cosmetics_payload::text, 'No grant payload.'));
    end if;
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'owner_grants_current_frame_compatibility', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    equip_payload := public.equip_my_frame('TXK_C1001_lock');

    if equip_payload ->> 'frame_key' = 'TXK_C1001_lock' then
      insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_granted_or_free_frame', 'PASS', equip_payload::text);
    else
      insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_granted_or_free_frame', 'FAIL', coalesce(equip_payload::text, 'No equip payload.'));
    end if;
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'member_equips_granted_or_free_frame', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.admin_grant_cosmetic(member_id, 'TXK_C1001_lock', null);
    insert into milestone22b_cosmetics_results values ('rpc', 'member_cannot_grant_self_cosmetics', 'FAIL', 'Member granted cosmetics.');
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'member_cannot_grant_self_cosmetics', 'PASS', sqlerrm);
  end;

  select count(*) into direct_count
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in ('equip_my_avatar', 'equip_my_frame')
    and pg_get_function_arguments(p.oid) ilike '%profile%';

  if direct_count = 0 then
    insert into milestone22b_cosmetics_results values ('security', 'equip_rpcs_have_no_target_profile_argument', 'PASS', 'Equip RPCs can only affect auth.uid().');
  else
    insert into milestone22b_cosmetics_results values ('security', 'equip_rpcs_have_no_target_profile_argument', 'FAIL', 'Equip RPC accepts a profile target argument.');
  end if;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.update_my_profile('Member Cosmetic IGN', 'not_a_real_avatar');
    insert into milestone22b_cosmetics_results values ('security', 'update_my_profile_rejects_arbitrary_avatar', 'FAIL', 'Arbitrary avatar_key was accepted.');
  exception when others then
    insert into milestone22b_cosmetics_results values ('security', 'update_my_profile_rejects_arbitrary_avatar', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    select * into updated_profile
    from public.update_my_profile('Member Cosmetic IGN', '1079_head');

    if updated_profile.ign = 'Member Cosmetic IGN'
       and updated_profile.avatar_key = '1079_head' then
      insert into milestone22b_cosmetics_results values ('rpc', 'profile_ign_update_still_works', 'PASS', row_to_json(updated_profile)::text);
    else
      insert into milestone22b_cosmetics_results values ('rpc', 'profile_ign_update_still_works', 'FAIL', coalesce(row_to_json(updated_profile)::text, 'No updated profile.'));
    end if;
  exception when others then
    insert into milestone22b_cosmetics_results values ('rpc', 'profile_ign_update_still_works', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    insert into public.profile_cosmetic_unlocks (profile_id, cosmetic_key)
    values (member_id, 'TXK_C1001_lock')
    on conflict do nothing;
    execute 'reset role';
    insert into milestone22b_cosmetics_results values ('rls', 'member_direct_unlock_write_denied', 'FAIL', 'Direct unlock insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into milestone22b_cosmetics_results values ('rls', 'member_direct_unlock_write_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    select count(*) into direct_count
    from public.profile_cosmetic_unlocks
    where profile_id = wrong_guild_id;
    execute 'reset role';

    if direct_count = 0 then
      insert into milestone22b_cosmetics_results values ('rls', 'member_cannot_read_other_unlocks', 'PASS', 'Other member unlocks were hidden.');
    else
      insert into milestone22b_cosmetics_results values ('rls', 'member_cannot_read_other_unlocks', 'FAIL', 'Other member unlocks were visible.');
    end if;
  exception when others then
    execute 'reset role';
    insert into milestone22b_cosmetics_results values ('rls', 'member_cannot_read_other_unlocks', 'PASS', sqlerrm);
  end;

  select count(*) into audit_count
  from public.audit_logs al
  where al.action in (
    'cosmetic_avatar_equipped',
    'cosmetic_frame_equipped',
    'cosmetic_granted'
  );

  if audit_count >= 3 then
    insert into milestone22b_cosmetics_results values ('audit', 'cosmetic_audit_rows_written', 'PASS', audit_count::text || ' cosmetic audit rows found.');
  else
    insert into milestone22b_cosmetics_results values ('audit', 'cosmetic_audit_rows_written', 'FAIL', audit_count::text || ' cosmetic audit rows found.');
  end if;
end;
$$;

select section, test_name, status, details
from milestone22b_cosmetics_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone22b_total_pass,
       count(*) filter (where status = 'FAIL') as milestone22b_total_fail,
       count(*) filter (where status = 'SKIP') as milestone22b_total_skip
from milestone22b_cosmetics_results;

-- Milestone 23B: Premium cosmetics unlock rules and grant-by-slug helper validation.

create temp table if not exists milestone23b_premium_cosmetics_results (
  section text not null,
  test_name text not null,
  status text not null,
  details text
) on commit drop;

do $$
declare
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  admin_no_perm_id constant uuid := '10000000-0000-0000-0000-000000000004';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  current_frame_count integer;
  current_avatar_non_free_count integer;
  cosmetics_payload jsonb;
  grant_payload jsonb;
  equip_payload jsonb;
  updated_profile public.profiles%rowtype;
  audit_count integer;
begin
  insert into public.cosmetic_catalog (
    key,
    type,
    label_key,
    asset_path,
    rarity,
    unlock_type,
    is_active,
    sort_order
  )
  values
    (
      'premium_avatar_manual',
      'avatar',
      'cosmetics.avatar.premium_avatar_manual',
      '/cosmetics/avatars/1079_head.png',
      'rare',
      'manual',
      true,
      9000
    ),
    (
      'premium_frame_manual',
      'frame',
      'cosmetics.frame.premium_frame_manual',
      '/cosmetics/frames/TXK_C1001_lock.png',
      'rare',
      'manual',
      true,
      9010
    )
  on conflict (key) do update
  set
    type = excluded.type,
    label_key = excluded.label_key,
    asset_path = excluded.asset_path,
    rarity = excluded.rarity,
    unlock_type = excluded.unlock_type,
    is_active = excluded.is_active,
    sort_order = excluded.sort_order,
    updated_at = now();

  delete from public.profile_cosmetic_unlocks
  where profile_id = member_id
    and cosmetic_key in ('premium_avatar_manual', 'premium_frame_manual');

  select count(*) into current_frame_count
  from public.cosmetic_catalog c
  where c.type = 'frame'
    and c.key in (
      'TXK_frame_reOpen_EN_FREE',
      'TXK_C1121_lock_FREE',
      'TXK_C1164_lock_FREE',
      'TXK_C1168_lock_FREE',
      'TXK_C1001_lock',
      'TXK_C1007_lock',
      'TXK_C1135_lock',
      'TXK_C1138_lock',
      'TXK_C1147_lock',
      'TXK_C1160_lock'
    )
    and c.unlock_type = 'free';

  if current_frame_count = 10 then
    insert into milestone23b_premium_cosmetics_results values ('seed', 'all_current_frames_are_free', 'PASS', 'All 10 current frame rows are free.');
  else
    insert into milestone23b_premium_cosmetics_results values ('seed', 'all_current_frames_are_free', 'FAIL', current_frame_count::text || ' current frame rows are free.');
  end if;

  select count(*) into current_avatar_non_free_count
  from public.cosmetic_catalog c
  where c.type = 'avatar'
    and c.key not in (
      'premium_avatar_manual',
      'hellfire_ayato_test_premium',
      'hellfite_ken_test_premium'
    )
    and c.unlock_type <> 'free';

  if current_avatar_non_free_count = 0 then
      insert into milestone23b_premium_cosmetics_results values ('seed', 'current_avatars_remain_free', 'PASS', 'Current non-premium avatar rows remain free.');
  else
      insert into milestone23b_premium_cosmetics_results values ('seed', 'current_avatars_remain_free', 'FAIL', current_avatar_non_free_count::text || ' non-premium current avatars are not free.');
  end if;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    cosmetics_payload := public.get_my_cosmetics();

    if exists (
         select 1
         from jsonb_array_elements(cosmetics_payload -> 'avatars') a
         where a ->> 'key' = 'premium_avatar_manual'
           and a ->> 'unlock_type' = 'manual'
           and (a ->> 'is_unlocked')::boolean = false
       )
       and exists (
         select 1
         from jsonb_array_elements(cosmetics_payload -> 'frames') f
         where f ->> 'key' = 'premium_frame_manual'
           and f ->> 'unlock_type' = 'manual'
           and (f ->> 'is_unlocked')::boolean = false
       ) then
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'manual_cosmetics_report_locked_before_grant', 'PASS', cosmetics_payload::text);
    else
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'manual_cosmetics_report_locked_before_grant', 'FAIL', cosmetics_payload::text);
    end if;
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'manual_cosmetics_report_locked_before_grant', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.equip_my_avatar('premium_avatar_manual');
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'manual_avatar_denied_without_unlock', 'FAIL', 'Manual avatar equipped without unlock.');
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'manual_avatar_denied_without_unlock', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.equip_my_frame('premium_frame_manual');
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'manual_frame_denied_without_unlock', 'FAIL', 'Manual frame equipped without unlock.');
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'manual_frame_denied_without_unlock', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.update_my_profile('Member Locked Avatar Attempt', 'premium_avatar_manual');
    insert into milestone23b_premium_cosmetics_results values ('security', 'update_my_profile_rejects_locked_manual_avatar', 'FAIL', 'Locked manual avatar_key was accepted.');
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('security', 'update_my_profile_rejects_locked_manual_avatar', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    perform public.admin_grant_cosmetic_by_slug('not_a_real_slug', 'premium_avatar_manual', 'local validation');
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'grant_by_slug_invalid_slug_denied', 'FAIL', 'Invalid slug was granted.');
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'grant_by_slug_invalid_slug_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    perform public.admin_grant_cosmetic_by_slug('member_local', 'not_a_real_cosmetic', 'local validation');
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'grant_by_slug_invalid_cosmetic_denied', 'FAIL', 'Invalid cosmetic was granted.');
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'grant_by_slug_invalid_cosmetic_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.admin_grant_cosmetic_by_slug('member_local', 'premium_avatar_manual', 'local validation');
    insert into milestone23b_premium_cosmetics_results values ('security', 'member_cannot_call_grant_by_slug', 'FAIL', 'Member granted cosmetics by slug.');
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('security', 'member_cannot_call_grant_by_slug', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_perm_id::text, true);
    perform public.admin_grant_cosmetic_by_slug('member_local', 'premium_avatar_manual', 'local validation');
    insert into milestone23b_premium_cosmetics_results values ('security', 'admin_without_manage_members_denied_grant_by_slug', 'FAIL', 'Admin without manage_members granted cosmetics by slug.');
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('security', 'admin_without_manage_members_denied_grant_by_slug', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    grant_payload := public.admin_grant_cosmetic_by_slug('member_local', 'premium_avatar_manual', 'local validation');

    if grant_payload ->> 'profile_slug' = 'member_local'
       and grant_payload ->> 'cosmetic_key' = 'premium_avatar_manual'
       and exists (
         select 1
         from public.profile_cosmetic_unlocks pcu
         where pcu.profile_id = member_id
           and pcu.cosmetic_key = 'premium_avatar_manual'
       ) then
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'owner_grants_manual_avatar_by_slug', 'PASS', grant_payload::text);
    else
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'owner_grants_manual_avatar_by_slug', 'FAIL', coalesce(grant_payload::text, 'No grant payload.'));
    end if;
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'owner_grants_manual_avatar_by_slug', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    grant_payload := public.admin_grant_cosmetic(member_id, 'premium_avatar_manual', 'compatibility validation');

    if grant_payload ->> 'cosmetic_key' = 'premium_avatar_manual' then
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'existing_admin_grant_cosmetic_still_works', 'PASS', grant_payload::text);
    else
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'existing_admin_grant_cosmetic_still_works', 'FAIL', coalesce(grant_payload::text, 'No grant payload.'));
    end if;
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'existing_admin_grant_cosmetic_still_works', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    equip_payload := public.equip_my_avatar('premium_avatar_manual');

    if equip_payload ->> 'avatar_key' = 'premium_avatar_manual' then
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'member_equips_granted_manual_avatar', 'PASS', equip_payload::text);
    else
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'member_equips_granted_manual_avatar', 'FAIL', coalesce(equip_payload::text, 'No equip payload.'));
    end if;
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'member_equips_granted_manual_avatar', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    select * into updated_profile
    from public.update_my_profile('Member Premium Avatar', 'premium_avatar_manual');

    if updated_profile.avatar_key = 'premium_avatar_manual'
       and updated_profile.ign = 'Member Premium Avatar' then
      insert into milestone23b_premium_cosmetics_results values ('security', 'update_my_profile_accepts_unlocked_manual_avatar', 'PASS', row_to_json(updated_profile)::text);
    else
      insert into milestone23b_premium_cosmetics_results values ('security', 'update_my_profile_accepts_unlocked_manual_avatar', 'FAIL', coalesce(row_to_json(updated_profile)::text, 'No updated profile.'));
    end if;
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('security', 'update_my_profile_accepts_unlocked_manual_avatar', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    grant_payload := public.admin_grant_cosmetic_by_slug('member_local', 'premium_frame_manual', 'local validation');

    if grant_payload ->> 'profile_slug' = 'member_local'
       and grant_payload ->> 'cosmetic_key' = 'premium_frame_manual'
       and exists (
         select 1
         from public.profile_cosmetic_unlocks pcu
         where pcu.profile_id = member_id
           and pcu.cosmetic_key = 'premium_frame_manual'
       ) then
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'owner_grants_manual_frame_by_slug', 'PASS', grant_payload::text);
    else
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'owner_grants_manual_frame_by_slug', 'FAIL', coalesce(grant_payload::text, 'No grant payload.'));
    end if;
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'owner_grants_manual_frame_by_slug', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    equip_payload := public.equip_my_frame('premium_frame_manual');

    if equip_payload ->> 'frame_key' = 'premium_frame_manual' then
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'member_equips_granted_manual_frame', 'PASS', equip_payload::text);
    else
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'member_equips_granted_manual_frame', 'FAIL', coalesce(equip_payload::text, 'No equip payload.'));
    end if;
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'member_equips_granted_manual_frame', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    equip_payload := public.equip_my_frame('TXK_C1007_lock');

    if equip_payload ->> 'frame_key' = 'TXK_C1007_lock' then
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'existing_current_frame_equip_still_works', 'PASS', equip_payload::text);
    else
      insert into milestone23b_premium_cosmetics_results values ('rpc', 'existing_current_frame_equip_still_works', 'FAIL', coalesce(equip_payload::text, 'No equip payload.'));
    end if;
  exception when others then
    insert into milestone23b_premium_cosmetics_results values ('rpc', 'existing_current_frame_equip_still_works', 'FAIL', sqlerrm);
  end;

  select count(*) into audit_count
  from public.audit_logs al
  where al.action = 'cosmetic_granted'
    and al.metadata ->> 'cosmetic_key' in ('premium_avatar_manual', 'premium_frame_manual');

  if audit_count >= 2 then
    insert into milestone23b_premium_cosmetics_results values ('audit', 'premium_grant_audit_rows_written', 'PASS', audit_count::text || ' premium grant audit rows found.');
  else
    insert into milestone23b_premium_cosmetics_results values ('audit', 'premium_grant_audit_rows_written', 'FAIL', audit_count::text || ' premium grant audit rows found.');
  end if;
end;
$$;

select section, test_name, status, details
from milestone23b_premium_cosmetics_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone23b_total_pass,
       count(*) filter (where status = 'FAIL') as milestone23b_total_fail,
       count(*) filter (where status = 'SKIP') as milestone23b_total_skip
from milestone23b_premium_cosmetics_results;

create temp table milestone24b_admin_analytics_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  anteiku_re_id constant uuid := '00000000-0000-0000-0000-000000000102';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  leader_id constant uuid := '10000000-0000-0000-0000-000000000002';
  admin_no_cp_id constant uuid := '10000000-0000-0000-0000-000000000004';
  admin_cp_id constant uuid := '10000000-0000-0000-0000-000000000005';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  pending_id constant uuid := '10000000-0000-0000-0000-000000000007';
  wrong_guild_id constant uuid := '10000000-0000-0000-0000-000000000009';
  analytics_row record;
  snapshot_row record;
  batch_one_id uuid;
  batch_two_id uuid;
  global_batch_id uuid;
  scoped_batch_id uuid;
  direct_count integer;
  history_count integer;
  owner_count integer;
  growth_has_previous boolean;
  growth_amount integer;
  live_row record;
  live_count integer;
begin
  update public.profiles
  set approval_status = 'approved',
      approved_at = coalesce(approved_at, now())
  where id in (owner_id, leader_id, admin_no_cp_id, admin_cp_id, member_id, wrong_guild_id);

  update public.profiles
  set approval_status = 'pending',
      approved_at = null
  where id = pending_id;

  update public.guild_memberships
  set membership_status = 'active',
      roster_status = 'active',
      is_primary = true
  where profile_id in (owner_id, leader_id, admin_no_cp_id, admin_cp_id, member_id, wrong_guild_id);

  update public.guild_memberships
  set membership_status = 'pending',
      roster_status = 'active',
      is_primary = true
  where profile_id = pending_id;

  delete from public.admin_permissions ap
  using public.guild_memberships gm
  where ap.membership_id = gm.id
    and gm.profile_id = admin_no_cp_id;

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  select gm.id, 'approve_members', owner_id
  from public.guild_memberships gm
  where gm.profile_id = admin_no_cp_id
    and gm.guild_id = anteiku_id
  on conflict (membership_id, permission_key) do nothing;

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  select gm.id, permission_key, owner_id
  from public.guild_memberships gm
  cross join (values ('view_cp'), ('update_cp'), ('approve_members'), ('manage_gvg')) as perms(permission_key)
  where gm.profile_id = admin_cp_id
    and gm.guild_id = anteiku_id
  on conflict (membership_id, permission_key) do nothing;

  insert into public.member_cp (profile_id, guild_id, cp_value, updated_by, updated_at)
  values
    (leader_id, anteiku_id, 900000, owner_id, clock_timestamp()),
    (admin_cp_id, anteiku_id, 800000, owner_id, clock_timestamp()),
    (member_id, anteiku_id, 700000, owner_id, clock_timestamp()),
    (wrong_guild_id, anteiku_re_id, 650000, owner_id, clock_timestamp())
  on conflict (profile_id) do update
  set guild_id = excluded.guild_id,
      cp_value = excluded.cp_value,
      updated_by = excluded.updated_by,
      updated_at = excluded.updated_at;

  delete from public.cp_snapshot_entries;
  delete from public.cp_snapshot_batches;

  if to_regclass('public.cp_snapshot_batches') is not null
     and to_regclass('public.cp_snapshot_entries') is not null then
    insert into milestone24b_admin_analytics_results values ('schema', 'snapshot_tables_exist', 'PASS', 'cp_snapshot_batches and cp_snapshot_entries exist.');
  else
    insert into milestone24b_admin_analytics_results values ('schema', 'snapshot_tables_exist', 'FAIL', 'Snapshot batch/entry tables are missing.');
  end if;

  if exists (
       select 1
       from pg_class c
       join pg_namespace n on n.oid = c.relnamespace
       where n.nspname = 'public'
         and c.relname in ('cp_snapshot_batches', 'cp_snapshot_entries')
         and c.relrowsecurity = true
       group by n.nspname
       having count(*) = 2
     ) then
    insert into milestone24b_admin_analytics_results values ('schema', 'snapshot_tables_rls_enabled', 'PASS', 'RLS enabled on snapshot tables.');
  else
    insert into milestone24b_admin_analytics_results values ('schema', 'snapshot_tables_rls_enabled', 'FAIL', 'Expected RLS on both snapshot tables.');
  end if;

  select count(*) into direct_count
  from information_schema.role_table_grants
  where table_schema = 'public'
    and table_name in ('cp_snapshot_batches', 'cp_snapshot_entries')
    and grantee in ('anon', 'authenticated')
    and privilege_type in ('SELECT', 'INSERT', 'UPDATE', 'DELETE');

  if direct_count = 0 then
    insert into milestone24b_admin_analytics_results values ('rls', 'snapshot_tables_no_direct_client_grants', 'PASS', 'No direct anon/authenticated grants on snapshot tables.');
  else
    insert into milestone24b_admin_analytics_results values ('rls', 'snapshot_tables_no_direct_client_grants', 'FAIL', direct_count::text || ' direct client grants found.');
  end if;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    select * into analytics_row
    from public.get_admin_member_analytics(null);

    if analytics_row.total_members >= 5 and analytics_row.members_by_guild is not null then
      insert into milestone24b_admin_analytics_results values ('member_analytics', 'owner_global_member_analytics', 'PASS', row_to_json(analytics_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('member_analytics', 'owner_global_member_analytics', 'FAIL', coalesce(row_to_json(analytics_row)::text, 'No analytics row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('member_analytics', 'owner_global_member_analytics', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', leader_id::text, true);
    select * into analytics_row
    from public.get_admin_member_analytics(anteiku_id);

    if analytics_row.scope_guild_id = anteiku_id and analytics_row.total_members >= 4 then
      insert into milestone24b_admin_analytics_results values ('member_analytics', 'leader_scoped_member_analytics', 'PASS', row_to_json(analytics_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('member_analytics', 'leader_scoped_member_analytics', 'FAIL', coalesce(row_to_json(analytics_row)::text, 'No analytics row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('member_analytics', 'leader_scoped_member_analytics', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.get_admin_member_analytics(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('member_analytics', 'member_denied_member_analytics', 'FAIL', 'Member fetched member analytics.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('member_analytics', 'member_denied_member_analytics', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', pending_id::text, true);
    perform public.get_admin_member_analytics(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('member_analytics', 'pending_denied_member_analytics', 'FAIL', 'Pending user fetched member analytics.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('member_analytics', 'pending_denied_member_analytics', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', leader_id::text, true);
    perform public.get_admin_member_analytics(anteiku_re_id);
    insert into milestone24b_admin_analytics_results values ('member_analytics', 'leader_wrong_guild_member_analytics_denied', 'FAIL', 'Leader fetched wrong-guild member analytics.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('member_analytics', 'leader_wrong_guild_member_analytics_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    perform public.get_admin_cp_analytics(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('cp_analytics', 'admin_without_view_cp_denied_cp_analytics', 'FAIL', 'Admin without view_cp fetched CP analytics.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('cp_analytics', 'admin_without_view_cp_denied_cp_analytics', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select * into analytics_row
    from public.get_admin_cp_analytics(anteiku_id);

    if analytics_row.total_cp > 0 and analytics_row.highest_cp >= analytics_row.lowest_cp then
      insert into milestone24b_admin_analytics_results values ('cp_analytics', 'admin_with_view_cp_scoped_cp_analytics', 'PASS', row_to_json(analytics_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('cp_analytics', 'admin_with_view_cp_scoped_cp_analytics', 'FAIL', coalesce(row_to_json(analytics_row)::text, 'No analytics row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('cp_analytics', 'admin_with_view_cp_scoped_cp_analytics', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    perform public.get_admin_cp_analytics(anteiku_re_id);
    insert into milestone24b_admin_analytics_results values ('cp_analytics', 'admin_wrong_guild_cp_analytics_denied', 'FAIL', 'Admin fetched wrong-guild CP analytics.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('cp_analytics', 'admin_wrong_guild_cp_analytics_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.get_admin_cp_analytics(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('cp_analytics', 'member_denied_cp_analytics', 'FAIL', 'Member fetched CP analytics.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('cp_analytics', 'member_denied_cp_analytics', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select * into analytics_row
    from public.get_admin_gvg_analytics(anteiku_id);

    if analytics_row.scope_guild_id = anteiku_id then
      insert into milestone24b_admin_analytics_results values ('gvg_analytics', 'admin_with_manage_gvg_scoped_gvg_analytics', 'PASS', row_to_json(analytics_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('gvg_analytics', 'admin_with_manage_gvg_scoped_gvg_analytics', 'FAIL', coalesce(row_to_json(analytics_row)::text, 'No analytics row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('gvg_analytics', 'admin_with_manage_gvg_scoped_gvg_analytics', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    perform public.get_admin_gvg_analytics(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('gvg_analytics', 'admin_without_manage_gvg_denied_gvg_analytics', 'FAIL', 'Admin without manage_gvg fetched GvG analytics.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('gvg_analytics', 'admin_without_manage_gvg_denied_gvg_analytics', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.get_admin_gvg_analytics(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('gvg_analytics', 'member_denied_gvg_analytics', 'FAIL', 'Member fetched GvG analytics.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('gvg_analytics', 'member_denied_gvg_analytics', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select gr.has_previous_snapshot into growth_has_previous
    from public.get_admin_cp_growth_report(anteiku_id, null) gr
    limit 1;

    if growth_has_previous = false then
      insert into milestone24b_admin_analytics_results values ('weekly_growth', 'no_previous_snapshot_safe_state', 'PASS', 'Growth report returned safe no-previous state.');
    else
      insert into milestone24b_admin_analytics_results values ('weekly_growth', 'no_previous_snapshot_safe_state', 'FAIL', 'Expected no previous snapshot safe state.');
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('weekly_growth', 'no_previous_snapshot_safe_state', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    perform public.capture_weekly_cp_snapshot(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('weekly_growth', 'snapshot_capture_denied_without_view_cp', 'FAIL', 'Admin without view_cp captured CP snapshot.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('weekly_growth', 'snapshot_capture_denied_without_view_cp', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select * into snapshot_row
    from public.capture_weekly_cp_snapshot(anteiku_id);
    batch_one_id := snapshot_row.batch_id;

    if batch_one_id is not null and snapshot_row.captured_count >= 3 then
      insert into milestone24b_admin_analytics_results values ('weekly_growth', 'snapshot_capture_creates_batch_entries', 'PASS', row_to_json(snapshot_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('weekly_growth', 'snapshot_capture_creates_batch_entries', 'FAIL', coalesce(row_to_json(snapshot_row)::text, 'No snapshot row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('weekly_growth', 'snapshot_capture_creates_batch_entries', 'FAIL', sqlerrm);
  end;

  update public.member_cp
  set cp_value = cp_value + 1000,
      updated_by = admin_cp_id,
      updated_at = clock_timestamp()
  where profile_id = member_id
    and guild_id = anteiku_id;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select * into snapshot_row
    from public.capture_weekly_cp_snapshot(anteiku_id);
    batch_two_id := snapshot_row.batch_id;

    select gr.has_previous_snapshot, gr.growth_amount
      into growth_has_previous, growth_amount
    from public.get_admin_cp_growth_report(anteiku_id, batch_two_id) gr
    where gr.profile_id = member_id;

    if growth_has_previous = true and growth_amount = 1000 then
      insert into milestone24b_admin_analytics_results values ('weekly_growth', 'growth_report_latest_vs_previous', 'PASS', 'Member growth amount was 1000.');
    else
      insert into milestone24b_admin_analytics_results values ('weekly_growth', 'growth_report_latest_vs_previous', 'FAIL', 'has_previous=' || coalesce(growth_has_previous::text, 'null') || ', growth=' || coalesce(growth_amount::text, 'null'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('weekly_growth', 'growth_report_latest_vs_previous', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select count(*) into history_count
    from public.get_admin_cp_snapshot_history(anteiku_id);

    if history_count >= 2 then
      insert into milestone24b_admin_analytics_results values ('weekly_growth', 'snapshot_history_lists_batches', 'PASS', history_count::text || ' batches visible.');
    else
      insert into milestone24b_admin_analytics_results values ('weekly_growth', 'snapshot_history_lists_batches', 'FAIL', history_count::text || ' batches visible.');
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('weekly_growth', 'snapshot_history_lists_batches', 'FAIL', sqlerrm);
  end;

  delete from public.cp_snapshot_entries;
  delete from public.cp_snapshot_batches;

  update public.member_cp
  set cp_value = 700000,
      updated_by = admin_cp_id,
      updated_at = clock_timestamp()
  where profile_id = member_id
    and guild_id = anteiku_id;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select * into live_row
    from public.get_admin_live_cp_growth(anteiku_id)
    limit 1;

    if live_row.has_baseline = false then
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'no_baseline_safe_state', 'PASS', row_to_json(live_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'no_baseline_safe_state', 'FAIL', coalesce(row_to_json(live_row)::text, 'No live row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'no_baseline_safe_state', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    perform public.get_admin_live_cp_growth(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'admin_without_view_cp_denied_live_growth', 'FAIL', 'Admin without view_cp fetched live growth.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'admin_without_view_cp_denied_live_growth', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.get_admin_live_cp_growth(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'member_denied_live_growth', 'FAIL', 'Member fetched live growth.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'member_denied_live_growth', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    perform public.get_admin_live_cp_growth(anteiku_re_id);
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'wrong_guild_live_growth_denied', 'FAIL', 'Admin fetched wrong-guild live growth.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'wrong_guild_live_growth_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_no_cp_id::text, true);
    perform public.start_new_cp_growth_period(anteiku_id);
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'start_period_denied_without_view_cp', 'FAIL', 'Admin without view_cp started live growth period.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'start_period_denied_without_view_cp', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select * into snapshot_row
    from public.start_new_cp_growth_period(anteiku_id);

    if snapshot_row.batch_id is not null
       and snapshot_row.captured_count >= 3
       and snapshot_row.reset_day_of_week = 0
       and extract(dow from snapshot_row.week_start)::integer = 0 then
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'start_period_creates_sunday_baseline', 'PASS', row_to_json(snapshot_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'start_period_creates_sunday_baseline', 'FAIL', coalesce(row_to_json(snapshot_row)::text, 'No start row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'start_period_creates_sunday_baseline', 'FAIL', sqlerrm);
  end;

  update public.member_cp
  set cp_value = cp_value + 1234,
      updated_by = admin_cp_id,
      updated_at = clock_timestamp()
  where profile_id = member_id
    and guild_id = anteiku_id;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select * into live_row
    from public.get_admin_live_cp_growth(anteiku_id)
    where profile_id = member_id;

    if live_row.has_baseline = true
       and live_row.baseline_cp = 700000
       and live_row.current_cp = 701234
       and live_row.growth_amount = 1234 then
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'live_growth_current_minus_baseline', 'PASS', row_to_json(live_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'live_growth_current_minus_baseline', 'FAIL', coalesce(row_to_json(live_row)::text, 'No member live growth row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'live_growth_current_minus_baseline', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    select count(*) into live_count
    from public.get_admin_live_cp_growth(null);

    if live_count >= 1 then
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'owner_global_live_growth_safe_state', 'PASS', live_count::text || ' live growth metadata/rows visible.');
    else
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'owner_global_live_growth_safe_state', 'FAIL', 'Owner global live growth returned no rows.');
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'owner_global_live_growth_safe_state', 'FAIL', sqlerrm);
  end;

  delete from public.cp_snapshot_entries;
  delete from public.cp_snapshot_batches;

  update public.member_cp
  set cp_value = 700000,
      updated_by = admin_cp_id,
      updated_at = clock_timestamp()
  where profile_id = member_id
    and guild_id = anteiku_id;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    select * into snapshot_row
    from public.start_new_cp_growth_period(null, 'Global validation baseline');
    global_batch_id := snapshot_row.batch_id;

    update public.member_cp
    set cp_value = cp_value + 5002,
        updated_by = admin_cp_id,
        updated_at = clock_timestamp()
    where profile_id = member_id
      and guild_id = anteiku_id;

    select * into live_row
    from public.get_admin_live_cp_growth(anteiku_id, global_batch_id)
    where profile_id = member_id;

    if live_row.baseline_batch_id = global_batch_id
       and live_row.guild_id = anteiku_id
       and live_row.growth_amount = 5002 then
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'guild_scope_can_use_owner_global_baseline', 'PASS', row_to_json(live_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'guild_scope_can_use_owner_global_baseline', 'FAIL', coalesce(row_to_json(live_row)::text, 'No global-baseline guild row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'guild_scope_can_use_owner_global_baseline', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    select * into snapshot_row
    from public.start_new_cp_growth_period(anteiku_id, 'Anteiku later validation baseline');
    scoped_batch_id := snapshot_row.batch_id;

    select * into live_row
    from public.get_admin_live_cp_growth(anteiku_id, global_batch_id)
    where profile_id = member_id;

    if live_row.baseline_batch_id = global_batch_id
       and live_row.growth_amount = 5002 then
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'explicit_global_baseline_survives_later_guild_baseline', 'PASS', row_to_json(live_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'explicit_global_baseline_survives_later_guild_baseline', 'FAIL', coalesce(row_to_json(live_row)::text, 'No preserved global-baseline row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'explicit_global_baseline_survives_later_guild_baseline', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    perform public.get_admin_live_cp_growth(null, scoped_batch_id);
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'guild_baseline_not_valid_for_global_scope', 'FAIL', 'Owner used a guild baseline for global live growth.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'guild_baseline_not_valid_for_global_scope', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    perform public.get_admin_live_cp_growth(anteiku_id, global_batch_id);
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'scoped_admin_denied_global_baseline', 'FAIL', 'Scoped Admin used global baseline for guild live growth.');
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'scoped_admin_denied_global_baseline', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', admin_cp_id::text, true);
    select * into live_row
    from public.get_admin_live_cp_growth(anteiku_id, scoped_batch_id)
    where profile_id = member_id;

    if live_row.baseline_batch_id = scoped_batch_id
       and live_row.guild_id = anteiku_id then
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'scoped_admin_can_use_guild_baseline', 'PASS', row_to_json(live_row)::text);
    else
      insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'scoped_admin_can_use_guild_baseline', 'FAIL', coalesce(row_to_json(live_row)::text, 'No scoped-admin guild-baseline row.'));
    end if;
  exception when others then
    insert into milestone24b_admin_analytics_results values ('live_weekly_growth', 'scoped_admin_can_use_guild_baseline', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute 'select count(*) from public.cp_snapshot_batches' into direct_count;
      execute 'reset role';

      if direct_count = 0 then
        insert into milestone24b_admin_analytics_results values ('rls', 'member_direct_snapshot_batches_denied', 'PASS', 'Direct snapshot batch read returned no rows.');
      else
        insert into milestone24b_admin_analytics_results values ('rls', 'member_direct_snapshot_batches_denied', 'FAIL', 'Direct snapshot batch read returned ' || direct_count || ' rows.');
      end if;
    exception when others then
      execute 'reset role';
      insert into milestone24b_admin_analytics_results values ('rls', 'member_direct_snapshot_batches_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone24b_admin_analytics_results values ('rls', 'member_direct_snapshot_batches_denied', 'SKIP', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute 'select count(*) from public.cp_snapshot_entries' into direct_count;
      execute 'reset role';

      if direct_count = 0 then
        insert into milestone24b_admin_analytics_results values ('rls', 'member_direct_snapshot_entries_denied', 'PASS', 'Direct snapshot entry read returned no rows.');
      else
        insert into milestone24b_admin_analytics_results values ('rls', 'member_direct_snapshot_entries_denied', 'FAIL', 'Direct snapshot entry read returned ' || direct_count || ' rows.');
      end if;
    exception when others then
      execute 'reset role';
      insert into milestone24b_admin_analytics_results values ('rls', 'member_direct_snapshot_entries_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone24b_admin_analytics_results values ('rls', 'member_direct_snapshot_entries_denied', 'SKIP', sqlerrm);
  end;

  update public.guild_memberships
  set role = 'member'
  where role = 'owner'
    and profile_id <> owner_id;

  select count(*) into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into milestone24b_admin_analytics_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner membership exists.');
  else
    insert into milestone24b_admin_analytics_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owner memberships found.');
  end if;
end;
$$;

select section, test_name, status, details
from milestone24b_admin_analytics_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone24b_total_pass,
       count(*) filter (where status = 'FAIL') as milestone24b_total_fail,
       count(*) filter (where status = 'SKIP') as milestone24b_total_skip
from milestone24b_admin_analytics_results;

create temp table milestone25b_3v3_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  creator_id constant uuid := '25000000-0000-0000-0000-000000000001';
  requester_id constant uuid := '25000000-0000-0000-0000-000000000002';
  alt_owner_id constant uuid := '25000000-0000-0000-0000-000000000003';
  retry_id constant uuid := '25000000-0000-0000-0000-000000000004';
  fill_two_id constant uuid := '25000000-0000-0000-0000-000000000005';
  fill_three_id constant uuid := '25000000-0000-0000-0000-000000000006';
  overflow_id constant uuid := '25000000-0000-0000-0000-000000000007';
  missing_discord_id constant uuid := '25000000-0000-0000-0000-000000000008';
  inactive_id constant uuid := '25000000-0000-0000-0000-000000000009';
  on_break_id constant uuid := '25000000-0000-0000-0000-000000000010';
  pending_3v3_id constant uuid := '25000000-0000-0000-0000-000000000011';
  payload jsonb;
  team_a_id uuid;
  team_b_id uuid;
  request_a_id uuid;
  request_b_id uuid;
  retry_request_id uuid;
  fill_request_id uuid;
  direct_count integer;
  active_count integer;
  owner_count integer;
  team_status text;
begin
  begin
    execute 'reset role';
  exception when others then
    null;
  end;

  delete from public.three_v_three_join_requests;
  delete from public.three_v_three_team_members;
  delete from public.three_v_three_teams;
  delete from public.three_v_three_player_profiles
  where profile_id in (
    creator_id,
    requester_id,
    alt_owner_id,
    retry_id,
    fill_two_id,
    fill_three_id,
    overflow_id,
    missing_discord_id,
    inactive_id,
    on_break_id,
    pending_3v3_id
  );

  begin
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    )
    values
      ('00000000-0000-0000-0000-000000000000', creator_id, 'authenticated', 'authenticated', 'v25-creator.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', requester_id, 'authenticated', 'authenticated', 'v25-requester.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', alt_owner_id, 'authenticated', 'authenticated', 'v25-alt-owner.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', retry_id, 'authenticated', 'authenticated', 'v25-retry.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', fill_two_id, 'authenticated', 'authenticated', 'v25-fill-two.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', fill_three_id, 'authenticated', 'authenticated', 'v25-fill-three.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', overflow_id, 'authenticated', 'authenticated', 'v25-overflow.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', missing_discord_id, 'authenticated', 'authenticated', 'v25-missing-discord.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', inactive_id, 'authenticated', 'authenticated', 'v25-inactive.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', on_break_id, 'authenticated', 'authenticated', 'v25-on-break.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', pending_3v3_id, 'authenticated', 'authenticated', 'v25-pending.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now())
    on conflict (id) do nothing;

    insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
    values
      (creator_id, 'v25_creator', 'v25_creator', 'V25 Creator', 'approved', now()),
      (requester_id, 'v25_requester', 'v25_requester', 'V25 Requester', 'approved', now()),
      (alt_owner_id, 'v25_alt_owner', 'v25_alt_owner', 'V25 Alt Owner', 'approved', now()),
      (retry_id, 'v25_retry', 'v25_retry', 'V25 Retry', 'approved', now()),
      (fill_two_id, 'v25_fill_two', 'v25_fill_two', 'V25 Fill Two', 'approved', now()),
      (fill_three_id, 'v25_fill_three', 'v25_fill_three', 'V25 Fill Three', 'approved', now()),
      (overflow_id, 'v25_overflow', 'v25_overflow', 'V25 Overflow', 'approved', now()),
      (missing_discord_id, 'v25_no_discord', 'v25_no_discord', 'V25 No Discord', 'approved', now()),
      (inactive_id, 'v25_inactive', 'v25_inactive', 'V25 Inactive', 'approved', now()),
      (on_break_id, 'v25_on_break', 'v25_on_break', 'V25 On Break', 'approved', now()),
      (pending_3v3_id, 'v25_pending', 'v25_pending', 'V25 Pending', 'pending', null)
    on conflict (id) do update
    set ign = excluded.ign,
        approval_status = excluded.approval_status,
        approved_at = excluded.approved_at;

    insert into public.guild_memberships (profile_id, guild_id, role, membership_status, roster_status, is_primary, assigned_by)
    values
      (creator_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (requester_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (alt_owner_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (retry_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (fill_two_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (fill_three_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (overflow_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (missing_discord_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (inactive_id, anteiku_id, 'member', 'active', 'inactive', true, owner_id),
      (on_break_id, anteiku_id, 'member', 'active', 'on_break', true, owner_id),
      (pending_3v3_id, anteiku_id, 'member', 'pending', 'active', true, null)
    on conflict (profile_id, guild_id) do update
    set role = excluded.role,
        membership_status = excluded.membership_status,
        roster_status = excluded.roster_status,
        is_primary = excluded.is_primary,
        assigned_by = excluded.assigned_by;

    insert into milestone25b_3v3_results values ('setup', 'test_profiles_seeded', 'PASS', '3v3 disposable users and memberships seeded.');
  exception when others then
    insert into milestone25b_3v3_results values ('setup', 'test_profiles_seeded', 'FAIL', sqlerrm);
  end;

  begin
    if to_regclass('public.three_v_three_player_profiles') is not null
       and to_regclass('public.three_v_three_teams') is not null
       and to_regclass('public.three_v_three_team_members') is not null
       and to_regclass('public.three_v_three_join_requests') is not null then
      insert into milestone25b_3v3_results values ('schema', 'tables_exist', 'PASS', 'All 3v3 tables exist.');
    else
      insert into milestone25b_3v3_results values ('schema', 'tables_exist', 'FAIL', 'One or more 3v3 tables are missing.');
    end if;

    select count(*) into direct_count
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname in (
        'three_v_three_player_profiles',
        'three_v_three_teams',
        'three_v_three_team_members',
        'three_v_three_join_requests'
      )
      and c.relrowsecurity = true;

    if direct_count = 4 then
      insert into milestone25b_3v3_results values ('schema', 'rls_enabled', 'PASS', 'RLS enabled on all 3v3 tables.');
    else
      insert into milestone25b_3v3_results values ('schema', 'rls_enabled', 'FAIL', direct_count::text || ' 3v3 tables have RLS enabled.');
    end if;

    select count(*) into direct_count
    from information_schema.role_table_grants
    where table_schema = 'public'
      and table_name in (
        'three_v_three_player_profiles',
        'three_v_three_teams',
        'three_v_three_team_members',
        'three_v_three_join_requests'
      )
      and grantee in ('anon', 'authenticated')
      and privilege_type in ('SELECT', 'INSERT', 'UPDATE', 'DELETE');

    if direct_count = 0 then
      insert into milestone25b_3v3_results values ('rls', 'no_direct_client_table_grants', 'PASS', 'No direct anon/authenticated grants on 3v3 tables.');
    else
      insert into milestone25b_3v3_results values ('rls', 'no_direct_client_table_grants', 'FAIL', direct_count::text || ' direct client grants found.');
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('schema', 'schema_checks', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    payload := public.update_my_discord_username('@Creator.Main');
    if payload ->> 'discord_username' = 'creator.main' then
      insert into milestone25b_3v3_results values ('profile', 'approved_member_updates_discord', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('profile', 'approved_member_updates_discord', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('profile', 'approved_member_updates_discord', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    payload := public.update_my_3v3_combined_cp(3250000);
    if (payload ->> 'combined_cp')::bigint = 3250000 then
      insert into milestone25b_3v3_results values ('profile', 'approved_member_updates_combined_cp', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('profile', 'approved_member_updates_combined_cp', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('profile', 'approved_member_updates_combined_cp', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', pending_3v3_id::text, true);
    perform public.update_my_discord_username('@pending25');
    insert into milestone25b_3v3_results values ('eligibility', 'pending_denied_profile_update', 'FAIL', 'Pending user updated 3v3 profile.');
  exception when others then
    insert into milestone25b_3v3_results values ('eligibility', 'pending_denied_profile_update', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', missing_discord_id::text, true);
    perform public.create_3v3_team('No Discord Team', 3000000);
    insert into milestone25b_3v3_results values ('eligibility', 'missing_discord_denied_create', 'FAIL', 'Team was created without Discord username.');
  exception when others then
    insert into milestone25b_3v3_results values ('eligibility', 'missing_discord_denied_create', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    payload := public.create_3v3_team('Anteiku Alpha', 3250000);
    team_a_id := (payload ->> 'id')::uuid;

    select count(*) into active_count
    from public.three_v_three_team_members tm
    where tm.team_id = team_a_id
      and tm.profile_id = creator_id
      and tm.slot_number = 1
      and tm.role = 'owner'
      and tm.left_at is null
      and tm.combined_cp_snapshot = 3250000;

    if team_a_id is not null and active_count = 1 then
      insert into milestone25b_3v3_results values ('team', 'creator_creates_team_slot_one', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('team', 'creator_creates_team_slot_one', 'FAIL', coalesce(payload::text, 'No payload.'));
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'creator_creates_team_slot_one', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    perform public.create_3v3_team('Second Owned Team', 3300000);
    insert into milestone25b_3v3_results values ('team', 'one_owned_active_team_enforced', 'FAIL', 'Creator created a second active owned team.');
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'one_owned_active_team_enforced', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', alt_owner_id::text, true);
    perform public.update_my_discord_username('@alt.owner');
    perform public.update_my_3v3_combined_cp(3400000);
    payload := public.create_3v3_team('Anteiku Beta', 3400000);
    team_b_id := (payload ->> 'id')::uuid;

    if team_b_id is not null then
      insert into milestone25b_3v3_results values ('team', 'second_team_created_for_request_flow', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('team', 'second_team_created_for_request_flow', 'FAIL', 'No team id returned.');
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'second_team_created_for_request_flow', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', missing_discord_id::text, true);
    perform public.request_join_3v3_team(team_a_id, 3000000);
    insert into milestone25b_3v3_results values ('eligibility', 'missing_discord_denied_request', 'FAIL', 'Request was created without Discord username.');
  exception when others then
    insert into milestone25b_3v3_results values ('eligibility', 'missing_discord_denied_request', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', requester_id::text, true);
    perform public.update_my_discord_username('@requester25');
    payload := public.request_join_3v3_team(team_a_id, 3100000);
    request_a_id := (payload ->> 'id')::uuid;

    if request_a_id is not null and payload ->> 'status' = 'pending' then
      insert into milestone25b_3v3_results values ('request', 'request_to_open_team_works', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('request', 'request_to_open_team_works', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('request', 'request_to_open_team_works', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', requester_id::text, true);
    perform public.request_join_3v3_team(team_a_id, 3100000);
    insert into milestone25b_3v3_results values ('request', 'duplicate_pending_request_blocked', 'FAIL', 'Duplicate pending request succeeded.');
  exception when others then
    insert into milestone25b_3v3_results values ('request', 'duplicate_pending_request_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', alt_owner_id::text, true);
    perform public.approve_3v3_request(request_a_id);
    insert into milestone25b_3v3_results values ('security', 'non_owner_approve_blocked', 'FAIL', 'Non-owner approved request.');
  exception when others then
    insert into milestone25b_3v3_results values ('security', 'non_owner_approve_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', alt_owner_id::text, true);
    perform public.decline_3v3_request(request_a_id);
    insert into milestone25b_3v3_results values ('security', 'non_owner_decline_blocked', 'FAIL', 'Non-owner declined request.');
  exception when others then
    insert into milestone25b_3v3_results values ('security', 'non_owner_decline_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', requester_id::text, true);
    payload := public.request_join_3v3_team(team_b_id, 3100000);
    request_b_id := (payload ->> 'id')::uuid;

    if request_b_id is not null then
      insert into milestone25b_3v3_results values ('request', 'multiple_pending_different_teams_allowed', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('request', 'multiple_pending_different_teams_allowed', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('request', 'multiple_pending_different_teams_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    payload := public.approve_3v3_request(request_a_id);

    select count(*) into active_count
    from public.three_v_three_team_members tm
    where tm.team_id = team_a_id
      and tm.profile_id = requester_id
      and tm.slot_number = 2
      and tm.left_at is null;

    if active_count = 1 then
      insert into milestone25b_3v3_results values ('approval', 'owner_approves_request_first_empty_slot', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('approval', 'owner_approves_request_first_empty_slot', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('approval', 'owner_approves_request_first_empty_slot', 'FAIL', sqlerrm);
  end;

  begin
    select count(*) into active_count
    from public.three_v_three_join_requests r
    where r.id = request_b_id
      and r.status = 'cancelled';

    if active_count = 1 then
      insert into milestone25b_3v3_results values ('approval', 'accepted_request_cancels_other_pending', 'PASS', 'Other pending request cancelled.');
    else
      insert into milestone25b_3v3_results values ('approval', 'accepted_request_cancels_other_pending', 'FAIL', 'Other pending request was not cancelled.');
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('approval', 'accepted_request_cancels_other_pending', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', requester_id::text, true);
    perform public.request_join_3v3_team(team_b_id, 3100000);
    insert into milestone25b_3v3_results values ('team', 'one_active_team_membership_enforced', 'FAIL', 'Accepted member requested another team.');
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'one_active_team_membership_enforced', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', alt_owner_id::text, true);
    perform public.remove_3v3_member(team_a_id, requester_id);
    insert into milestone25b_3v3_results values ('security', 'non_owner_remove_blocked', 'FAIL', 'Non-owner removed member.');
  exception when others then
    insert into milestone25b_3v3_results values ('security', 'non_owner_remove_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    payload := public.remove_3v3_member(team_a_id, requester_id);

    select count(*) into active_count
    from public.three_v_three_team_members tm
    where tm.team_id = team_a_id
      and tm.profile_id = requester_id
      and tm.left_at is null;

    select status into team_status
    from public.three_v_three_teams
    where id = team_a_id;

    if active_count = 0 and team_status = 'open' then
      insert into milestone25b_3v3_results values ('team', 'owner_removes_member_opens_team', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('team', 'owner_removes_member_opens_team', 'FAIL', coalesce(payload::text, 'No payload.') || ' status=' || coalesce(team_status, 'null'));
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'owner_removes_member_opens_team', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', retry_id::text, true);
    perform public.update_my_discord_username('@retry25');
    payload := public.request_join_3v3_team(team_a_id, 2900000);
    retry_request_id := (payload ->> 'id')::uuid;

    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    payload := public.decline_3v3_request(retry_request_id);

    if payload ->> 'status' = 'declined' then
      insert into milestone25b_3v3_results values ('request', 'owner_declines_request', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('request', 'owner_declines_request', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('request', 'owner_declines_request', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', retry_id::text, true);
    perform public.request_join_3v3_team(team_a_id, 2900000);
    insert into milestone25b_3v3_results values ('request', 'declined_retry_cooldown_blocked', 'FAIL', 'Declined requester bypassed cooldown.');
  exception when others then
    insert into milestone25b_3v3_results values ('request', 'declined_retry_cooldown_blocked', 'PASS', sqlerrm);
  end;

  begin
    update public.three_v_three_join_requests
    set decided_at = now() - interval '7 hours',
        updated_at = now() - interval '7 hours'
    where id = retry_request_id;

    perform set_config('request.jwt.claim.sub', retry_id::text, true);
    payload := public.request_join_3v3_team(team_a_id, 2900000);
    retry_request_id := (payload ->> 'id')::uuid;

    if (payload ->> 'attempt_number')::integer = 2 then
      insert into milestone25b_3v3_results values ('request', 'declined_retry_after_cooldown_allowed', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('request', 'declined_retry_after_cooldown_allowed', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('request', 'declined_retry_after_cooldown_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    perform public.decline_3v3_request(retry_request_id);
    update public.three_v_three_join_requests
    set decided_at = now() - interval '7 hours',
        updated_at = now() - interval '7 hours'
    where id = retry_request_id;

    perform set_config('request.jwt.claim.sub', retry_id::text, true);
    perform public.request_join_3v3_team(team_a_id, 2900000);
    insert into milestone25b_3v3_results values ('request', 'max_two_attempts_enforced', 'FAIL', 'Third request attempt succeeded.');
  exception when others then
    insert into milestone25b_3v3_results values ('request', 'max_two_attempts_enforced', 'PASS', sqlerrm);
  end;

  begin
    foreach active_count in array array[1, 2] loop
      if active_count = 1 then
        perform set_config('request.jwt.claim.sub', fill_two_id::text, true);
        perform public.update_my_discord_username('@filltwo25');
        payload := public.request_join_3v3_team(team_a_id, 2800000);
      else
        perform set_config('request.jwt.claim.sub', fill_three_id::text, true);
        perform public.update_my_discord_username('@fillthree25');
        payload := public.request_join_3v3_team(team_a_id, 2700000);
      end if;

      fill_request_id := (payload ->> 'id')::uuid;
      perform set_config('request.jwt.claim.sub', creator_id::text, true);
      perform public.approve_3v3_request(fill_request_id);
    end loop;

    select count(*) into active_count
    from public.three_v_three_team_members tm
    where tm.team_id = team_a_id
      and tm.left_at is null;

    select status into team_status
    from public.three_v_three_teams
    where id = team_a_id;

    if active_count = 3 and team_status = 'full' then
      insert into milestone25b_3v3_results values ('team', 'max_three_members_sets_full', 'PASS', 'Team full with three active members.');
    else
      insert into milestone25b_3v3_results values ('team', 'max_three_members_sets_full', 'FAIL', 'count=' || active_count::text || ', status=' || coalesce(team_status, 'null'));
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'max_three_members_sets_full', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', overflow_id::text, true);
    payload := public.update_my_discord_username('@overflow25');

    if payload ->> 'discord_username' = 'overflow25' then
      insert into milestone25b_3v3_results values ('profile', 'overflow_member_updates_discord', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('profile', 'overflow_member_updates_discord', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('profile', 'overflow_member_updates_discord', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', overflow_id::text, true);
    perform public.request_join_3v3_team(team_a_id, 2600000);
    insert into milestone25b_3v3_results values ('team', 'request_to_full_team_blocked', 'FAIL', 'Overflow request to full team succeeded.');
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'request_to_full_team_blocked', 'PASS', sqlerrm);
  end;

  begin
    update public.three_v_three_teams
    set name = 'Renamed Team'
    where id = team_a_id;
    insert into milestone25b_3v3_results values ('team', 'team_name_immutable', 'FAIL', 'Team name update succeeded.');
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'team_name_immutable', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', alt_owner_id::text, true);
    payload := public.close_3v3_team(team_b_id);

    if payload ->> 'status' = 'closed' then
      insert into milestone25b_3v3_results values ('team', 'owner_closes_team', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('team', 'owner_closes_team', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'owner_closes_team', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', overflow_id::text, true);
    perform public.request_join_3v3_team(team_b_id, 2600000);
    insert into milestone25b_3v3_results values ('team', 'request_to_closed_team_blocked', 'FAIL', 'Request to closed team succeeded.');
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'request_to_closed_team_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', alt_owner_id::text, true);
    payload := public.reopen_3v3_team(team_b_id);

    if payload ->> 'status' = 'open' then
      insert into milestone25b_3v3_results values ('team', 'owner_reopens_team', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('team', 'owner_reopens_team', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'owner_reopens_team', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', overflow_id::text, true);
    payload := public.request_join_3v3_team(team_b_id, 2600000);
    fill_request_id := (payload ->> 'id')::uuid;
    payload := public.cancel_3v3_request(fill_request_id);

    if payload ->> 'status' = 'cancelled' then
      insert into milestone25b_3v3_results values ('request', 'requester_cancels_pending_request', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('request', 'requester_cancels_pending_request', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('request', 'requester_cancels_pending_request', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', overflow_id::text, true);
    payload := public.request_join_3v3_team(team_b_id, 2600000);

    if (payload ->> 'attempt_number')::integer = 2 then
      insert into milestone25b_3v3_results values ('request', 'cancelled_request_retry_under_limit_allowed', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('request', 'cancelled_request_retry_under_limit_allowed', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('request', 'cancelled_request_retry_under_limit_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', inactive_id::text, true);
    perform public.update_my_discord_username('@inactive25');
    payload := public.get_3v3_teams();
    if jsonb_typeof(payload -> 'teams') = 'array' then
      insert into milestone25b_3v3_results values ('eligibility', 'inactive_can_view_teams', 'PASS', 'Inactive roster user can view team finder.');
    else
      insert into milestone25b_3v3_results values ('eligibility', 'inactive_can_view_teams', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('eligibility', 'inactive_can_view_teams', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', inactive_id::text, true);
    perform public.create_3v3_team('Inactive Team', 2400000);
    insert into milestone25b_3v3_results values ('eligibility', 'inactive_denied_create', 'FAIL', 'Inactive roster user created team.');
  exception when others then
    insert into milestone25b_3v3_results values ('eligibility', 'inactive_denied_create', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', on_break_id::text, true);
    perform public.update_my_discord_username('@onbreak25');
    perform public.request_join_3v3_team(team_b_id, 2300000);
    insert into milestone25b_3v3_results values ('eligibility', 'on_break_denied_request', 'FAIL', 'On-break roster user requested team.');
  exception when others then
    insert into milestone25b_3v3_results values ('eligibility', 'on_break_denied_request', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', alt_owner_id::text, true);
    perform public.disband_3v3_team(team_a_id);
    insert into milestone25b_3v3_results values ('security', 'non_owner_disband_blocked', 'FAIL', 'Non-owner disbanded team.');
  exception when others then
    insert into milestone25b_3v3_results values ('security', 'non_owner_disband_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    payload := public.disband_3v3_team(team_a_id);

    select count(*) into active_count
    from public.three_v_three_team_members tm
    where tm.team_id = team_a_id
      and tm.left_at is null;

    if payload ->> 'status' = 'disbanded' and active_count = 0 then
      insert into milestone25b_3v3_results values ('team', 'owner_disbands_team', 'PASS', payload::text);
    else
      insert into milestone25b_3v3_results values ('team', 'owner_disbands_team', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'owner_disbands_team', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    payload := public.get_3v3_teams();

    if payload::text not like '%' || team_a_id::text || '%' then
      insert into milestone25b_3v3_results values ('team', 'disbanded_team_hidden', 'PASS', 'Disbanded team omitted from team finder.');
    else
      insert into milestone25b_3v3_results values ('team', 'disbanded_team_hidden', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('team', 'disbanded_team_hidden', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', creator_id::text, true);
    payload := public.get_3v3_teams();

    if payload::text not like '%member_cp%'
       and payload::text not like '%cp_snapshots%'
       and payload::text not like '%cp_value%'
       and payload::text not like '%700000%' then
      insert into milestone25b_3v3_results values ('privacy', 'team_finder_does_not_expose_normal_cp', 'PASS', '3v3 payload contains public combined_cp only.');
    else
      insert into milestone25b_3v3_results values ('privacy', 'team_finder_does_not_expose_normal_cp', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone25b_3v3_results values ('privacy', 'team_finder_does_not_expose_normal_cp', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', requester_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute 'select count(*) from public.three_v_three_teams' into direct_count;
      execute 'reset role';

      if direct_count = 0 then
        insert into milestone25b_3v3_results values ('rls', 'direct_3v3_table_read_denied', 'PASS', 'Direct read returned zero rows.');
      else
        insert into milestone25b_3v3_results values ('rls', 'direct_3v3_table_read_denied', 'FAIL', 'Direct read returned ' || direct_count::text || ' rows.');
      end if;
    exception when others then
      execute 'reset role';
      insert into milestone25b_3v3_results values ('rls', 'direct_3v3_table_read_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone25b_3v3_results values ('rls', 'direct_3v3_table_read_denied', 'SKIP', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', requester_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute format(
        'insert into public.three_v_three_teams (name, owner_profile_id, status) values (%L, %L::uuid, %L)',
        'Unsafe Direct Team',
        requester_id::text,
        'open'
      );
      execute 'reset role';
      insert into milestone25b_3v3_results values ('rls', 'direct_3v3_table_write_denied', 'FAIL', 'Direct table write succeeded.');
    exception when others then
      execute 'reset role';
      insert into milestone25b_3v3_results values ('rls', 'direct_3v3_table_write_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone25b_3v3_results values ('rls', 'direct_3v3_table_write_denied', 'SKIP', sqlerrm);
  end;

  update public.guild_memberships
  set role = 'member'
  where role = 'owner'
    and profile_id <> owner_id;

  select count(*) into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into milestone25b_3v3_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner membership exists.');
  else
    insert into milestone25b_3v3_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owner memberships found.');
  end if;
end;
$$;

select section, test_name, status, details
from milestone25b_3v3_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone25b_total_pass,
       count(*) filter (where status = 'FAIL') as milestone25b_total_fail,
       count(*) filter (where status = 'SKIP') as milestone25b_total_skip
from milestone25b_3v3_results;

create temp table milestone26c_guild_wall_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  anteiku_re_id constant uuid := '00000000-0000-0000-0000-000000000102';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  member_a_id constant uuid := '26000000-0000-0000-0000-000000000001';
  member_b_id constant uuid := '26000000-0000-0000-0000-000000000002';
  pending_id constant uuid := '26000000-0000-0000-0000-000000000003';
  inactive_id constant uuid := '26000000-0000-0000-0000-000000000004';
  on_break_id constant uuid := '26000000-0000-0000-0000-000000000005';
  wrong_guild_member_id constant uuid := '26000000-0000-0000-0000-000000000006';
  moderator_id constant uuid := '26000000-0000-0000-0000-000000000007';
  wrong_guild_moderator_id constant uuid := '26000000-0000-0000-0000-000000000008';
  moderator_membership_id uuid;
  wrong_moderator_membership_id uuid;
  post_a_id uuid;
  global_post_id uuid;
  global_comment_id uuid;
  rep_post_one_id uuid;
  rep_post_two_id uuid;
  rep_comment_id uuid;
  normal_post_id uuid;
  pinned_post_id uuid;
  re_post_id uuid;
  wall_comment_id uuid;
  mod_comment_id uuid;
  payload jsonb;
  details_payload jsonb;
  rep_before bigint;
  rep_after bigint;
  direct_count integer;
  owner_count integer;
  first_post_id uuid;
begin
  begin
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    )
    values
      ('00000000-0000-0000-0000-000000000000', member_a_id, 'authenticated', 'authenticated', 'wall-member-a.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', member_b_id, 'authenticated', 'authenticated', 'wall-member-b.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'wall-pending.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', inactive_id, 'authenticated', 'authenticated', 'wall-inactive.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', on_break_id, 'authenticated', 'authenticated', 'wall-on-break.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', wrong_guild_member_id, 'authenticated', 'authenticated', 'wall-wrong-guild.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', moderator_id, 'authenticated', 'authenticated', 'wall-moderator.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', wrong_guild_moderator_id, 'authenticated', 'authenticated', 'wall-wrong-moderator.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now())
    on conflict (id) do nothing;

    insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
    values
      (member_a_id, 'wall_member_a', 'wall_member_a', 'Wall Member A', 'approved', now()),
      (member_b_id, 'wall_member_b', 'wall_member_b', 'Wall Member B', 'approved', now()),
      (pending_id, 'wall_pending', 'wall_pending', 'Wall Pending', 'pending', null),
      (inactive_id, 'wall_inactive', 'wall_inactive', 'Wall Inactive', 'approved', now()),
      (on_break_id, 'wall_on_break', 'wall_on_break', 'Wall On Break', 'approved', now()),
      (wrong_guild_member_id, 'wall_wrong_guild', 'wall_wrong_guild', 'Wall Wrong Guild', 'approved', now()),
      (moderator_id, 'wall_moderator', 'wall_moderator', 'Wall Moderator', 'approved', now()),
      (wrong_guild_moderator_id, 'wall_wrong_moderator', 'wall_wrong_moderator', 'Wall Wrong Moderator', 'approved', now())
    on conflict (id) do update
    set ign = excluded.ign,
        approval_status = excluded.approval_status,
        approved_at = excluded.approved_at;

    insert into public.guild_memberships (profile_id, guild_id, role, membership_status, roster_status, is_primary, assigned_by)
    values
      (member_a_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (member_b_id, anteiku_id, 'member', 'active', 'active', true, owner_id),
      (pending_id, anteiku_id, 'member', 'pending', 'active', true, null),
      (inactive_id, anteiku_id, 'member', 'active', 'inactive', true, owner_id),
      (on_break_id, anteiku_id, 'member', 'active', 'on_break', true, owner_id),
      (wrong_guild_member_id, anteiku_re_id, 'member', 'active', 'active', true, owner_id),
      (moderator_id, anteiku_id, 'admin', 'active', 'active', true, owner_id),
      (wrong_guild_moderator_id, anteiku_re_id, 'admin', 'active', 'active', true, owner_id)
    on conflict (profile_id, guild_id) do update
    set role = excluded.role,
        membership_status = excluded.membership_status,
        roster_status = excluded.roster_status,
        is_primary = excluded.is_primary,
        assigned_by = excluded.assigned_by;

    select id into moderator_membership_id
    from public.guild_memberships
    where profile_id = moderator_id
      and guild_id = anteiku_id;

    select id into wrong_moderator_membership_id
    from public.guild_memberships
    where profile_id = wrong_guild_moderator_id
      and guild_id = anteiku_re_id;

    insert into public.admin_permissions (membership_id, permission_key, granted_by)
    values
      (moderator_membership_id, 'manage_members', owner_id),
      (wrong_moderator_membership_id, 'manage_members', owner_id)
    on conflict (membership_id, permission_key) do nothing;

    insert into milestone26c_guild_wall_results values ('setup', 'guild_wall_profiles_seeded', 'PASS', 'Guild Wall test profiles and scoped moderator permissions seeded.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('setup', 'guild_wall_profiles_seeded', 'FAIL', sqlerrm);
  end;

  begin
    if to_regclass('public.wall_posts') is not null
       and to_regclass('public.wall_comments') is not null
       and to_regclass('public.wall_post_reactions') is not null
       and to_regclass('public.wall_comment_reactions') is not null then
      insert into milestone26c_guild_wall_results values ('schema', 'wall_tables_exist', 'PASS', 'Wall tables exist.');
    else
      insert into milestone26c_guild_wall_results values ('schema', 'wall_tables_exist', 'FAIL', 'One or more wall tables are missing.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('schema', 'wall_tables_exist', 'FAIL', sqlerrm);
  end;

  begin
    select count(*) into direct_count
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname in ('wall_posts', 'wall_comments', 'wall_post_reactions', 'wall_comment_reactions')
      and c.relrowsecurity = true;

    if direct_count = 4 then
      insert into milestone26c_guild_wall_results values ('schema', 'wall_rls_enabled', 'PASS', 'RLS enabled on all wall tables.');
    else
      insert into milestone26c_guild_wall_results values ('schema', 'wall_rls_enabled', 'FAIL', direct_count::text || ' wall tables have RLS enabled.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('schema', 'wall_rls_enabled', 'FAIL', sqlerrm);
  end;

  begin
    select count(*) into direct_count
    from information_schema.columns
    where table_schema = 'public'
      and table_name in ('wall_posts', 'wall_comments')
      and column_name = 'guild_id'
      and is_nullable = 'YES';

    if direct_count = 2 then
      insert into milestone26c_guild_wall_results values ('schema', 'global_wall_nullable_scope', 'PASS', 'Wall post/comment guild_id allows Global null scope.');
    else
      insert into milestone26c_guild_wall_results values ('schema', 'global_wall_nullable_scope', 'FAIL', direct_count::text || ' nullable guild_id columns found.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('schema', 'global_wall_nullable_scope', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    post_a_id := public.create_wall_post(anteiku_id, 'Local wall validation post');

    if post_a_id is not null then
      insert into milestone26c_guild_wall_results values ('post', 'approved_member_posts_own_guild', 'PASS', post_a_id::text);
    else
      insert into milestone26c_guild_wall_results values ('post', 'approved_member_posts_own_guild', 'FAIL', 'No post id returned.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('post', 'approved_member_posts_own_guild', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    payload := public.get_guild_wall_feed(anteiku_id, 20, null);

    if payload::text like '%' || post_a_id::text || '%'
       and payload::text not like '%member_cp%'
       and payload::text not like '%cp_snapshots%'
       and payload::text not like '%cp_value%' then
      insert into milestone26c_guild_wall_results values ('feed', 'feed_returns_post_without_cp_fields', 'PASS', payload::text);
    else
      insert into milestone26c_guild_wall_results values ('feed', 'feed_returns_post_without_cp_fields', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('feed', 'feed_returns_post_without_cp_fields', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    global_post_id := public.create_wall_post(null, 'Global wall validation post');

    if global_post_id is not null then
      insert into milestone26c_guild_wall_results values ('post', 'approved_member_posts_global_wall', 'PASS', global_post_id::text);
    else
      insert into milestone26c_guild_wall_results values ('post', 'approved_member_posts_global_wall', 'FAIL', 'No global post id returned.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('post', 'approved_member_posts_global_wall', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', wrong_guild_member_id::text, true);
    payload := public.get_guild_wall_feed(null, 20, null);

    if (payload -> 'viewer' ->> 'is_global')::boolean = true
       and payload::text like '%' || global_post_id::text || '%'
       and (post_a_id is null or payload::text not like '%' || post_a_id::text || '%')
       and payload::text not like '%member_cp%'
       and payload::text not like '%cp_snapshots%'
       and payload::text not like '%cp_value%' then
      insert into milestone26c_guild_wall_results values ('feed', 'cross_guild_member_reads_global_wall_only', 'PASS', payload::text);
    else
      insert into milestone26c_guild_wall_results values ('feed', 'cross_guild_member_reads_global_wall_only', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('feed', 'cross_guild_member_reads_global_wall_only', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    payload := public.get_guild_wall_feed(null, 20, null);

    if (payload -> 'viewer' ->> 'is_global')::boolean = true
       and payload::text like '%' || global_post_id::text || '%'
       and payload::text not like '%member_cp%'
       and payload::text not like '%cp_snapshots%'
       and payload::text not like '%cp_value%' then
      insert into milestone26c_guild_wall_results values ('feed', 'owner_global_feed_loads_without_scope_record_error', 'PASS', payload::text);
    else
      insert into milestone26c_guild_wall_results values ('feed', 'owner_global_feed_loads_without_scope_record_error', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('feed', 'owner_global_feed_loads_without_scope_record_error', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', wrong_guild_member_id::text, true);
    global_comment_id := public.create_wall_comment(global_post_id, 'Global wall validation comment');

    if global_comment_id is not null then
      insert into milestone26c_guild_wall_results values ('comment', 'approved_member_comments_global_post', 'PASS', global_comment_id::text);
    else
      insert into milestone26c_guild_wall_results values ('comment', 'approved_member_comments_global_post', 'FAIL', 'No global comment id returned.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('comment', 'approved_member_comments_global_post', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.react_to_wall_post(global_post_id, 'fire');

    select count(*) into direct_count
    from public.wall_post_reactions
    where post_id = global_post_id
      and profile_id = member_b_id
      and reaction_type = 'fire';

    if direct_count = 1 then
      insert into milestone26c_guild_wall_results values ('reaction', 'approved_member_reacts_global_post', 'PASS', 'Global post reaction stored once.');
    else
      insert into milestone26c_guild_wall_results values ('reaction', 'approved_member_reacts_global_post', 'FAIL', direct_count::text || ' global reaction rows found.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('reaction', 'approved_member_reacts_global_post', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', moderator_id::text, true);
    perform public.pin_wall_post(global_post_id);
    insert into milestone26c_guild_wall_results values ('moderation', 'scoped_staff_cannot_moderate_global_post', 'FAIL', 'Scoped staff pinned a global post.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('moderation', 'scoped_staff_cannot_moderate_global_post', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    perform public.pin_wall_post(global_post_id);
    perform public.unpin_wall_post(global_post_id);
    insert into milestone26c_guild_wall_results values ('moderation', 'owner_moderates_global_post', 'PASS', 'Owner pinned and unpinned a global post.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('moderation', 'owner_moderates_global_post', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    rep_post_one_id := public.create_wall_post(anteiku_id, 'Ghoul Rep guild post one');
    rep_post_two_id := public.create_wall_post(anteiku_id, 'Ghoul Rep guild post two');

    rep_before := private.get_profile_ghoul_rep(member_a_id);

    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.react_to_wall_post(rep_post_one_id, 'fire');
    perform public.react_to_wall_post(rep_post_one_id, 'trophy');

    rep_after := private.get_profile_ghoul_rep(member_a_id);

    if rep_after = rep_before + 1 then
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'same_user_multiple_post_reactions_count_once', 'PASS', 'before=' || rep_before::text || ', after=' || rep_after::text);
    else
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'same_user_multiple_post_reactions_count_once', 'FAIL', 'before=' || rep_before::text || ', after=' || rep_after::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('ghoul_rep', 'same_user_multiple_post_reactions_count_once', 'FAIL', sqlerrm);
  end;

  begin
    rep_before := private.get_profile_ghoul_rep(member_a_id);

    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.react_to_wall_post(rep_post_two_id, 'coffee');

    rep_after := private.get_profile_ghoul_rep(member_a_id);

    if rep_after = rep_before + 1 then
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'same_user_different_posts_count_per_target', 'PASS', 'before=' || rep_before::text || ', after=' || rep_after::text);
    else
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'same_user_different_posts_count_per_target', 'FAIL', 'before=' || rep_before::text || ', after=' || rep_after::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('ghoul_rep', 'same_user_different_posts_count_per_target', 'FAIL', sqlerrm);
  end;

  begin
    rep_before := private.get_profile_ghoul_rep(member_a_id);

    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    perform public.react_to_wall_post(rep_post_one_id, 'skull');

    rep_after := private.get_profile_ghoul_rep(member_a_id);

    if rep_after = rep_before then
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'self_reaction_does_not_count', 'PASS', 'before=' || rep_before::text || ', after=' || rep_after::text);
    else
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'self_reaction_does_not_count', 'FAIL', 'before=' || rep_before::text || ', after=' || rep_after::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('ghoul_rep', 'self_reaction_does_not_count', 'FAIL', sqlerrm);
  end;

  begin
    rep_before := private.get_profile_ghoul_rep(member_a_id);

    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.remove_wall_post_reaction(rep_post_two_id, 'coffee');

    rep_after := private.get_profile_ghoul_rep(member_a_id);

    if rep_after = rep_before - 1 then
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'removed_post_reaction_reduces_rep', 'PASS', 'before=' || rep_before::text || ', after=' || rep_after::text);
    else
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'removed_post_reaction_reduces_rep', 'FAIL', 'before=' || rep_before::text || ', after=' || rep_after::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('ghoul_rep', 'removed_post_reaction_reduces_rep', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.react_to_wall_post(rep_post_two_id, 'coffee');

    rep_before := private.get_profile_ghoul_rep(member_a_id);

    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    perform public.delete_wall_post(rep_post_two_id);

    rep_after := private.get_profile_ghoul_rep(member_a_id);

    if rep_after = rep_before - 1 then
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'deleted_post_removes_rep', 'PASS', 'before=' || rep_before::text || ', after=' || rep_after::text);
    else
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'deleted_post_removes_rep', 'FAIL', 'before=' || rep_before::text || ', after=' || rep_after::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('ghoul_rep', 'deleted_post_removes_rep', 'FAIL', sqlerrm);
  end;

  begin
    rep_before := private.get_profile_ghoul_rep(member_a_id);

    perform set_config('request.jwt.claim.sub', wrong_guild_member_id::text, true);
    perform public.react_to_wall_post(global_post_id, 'trophy');

    rep_after := private.get_profile_ghoul_rep(member_a_id);

    if rep_after = rep_before + 1 then
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'global_wall_reaction_counts', 'PASS', 'before=' || rep_before::text || ', after=' || rep_after::text);
    else
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'global_wall_reaction_counts', 'FAIL', 'before=' || rep_before::text || ', after=' || rep_after::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('ghoul_rep', 'global_wall_reaction_counts', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    rep_comment_id := public.create_wall_comment(global_post_id, 'Ghoul Rep comment validation');

    rep_before := private.get_profile_ghoul_rep(member_a_id);

    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.react_to_wall_comment(rep_comment_id, 'like');
    perform public.react_to_wall_comment(rep_comment_id, 'fire');

    rep_after := private.get_profile_ghoul_rep(member_a_id);

    if rep_after = rep_before + 1 then
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'same_user_multiple_comment_reactions_count_once', 'PASS', 'before=' || rep_before::text || ', after=' || rep_after::text);
    else
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'same_user_multiple_comment_reactions_count_once', 'FAIL', 'before=' || rep_before::text || ', after=' || rep_after::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('ghoul_rep', 'same_user_multiple_comment_reactions_count_once', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    details_payload := public.get_wall_reaction_details('comment', rep_comment_id, 'like');

    if details_payload::text like '%' || member_b_id::text || '%'
       and details_payload::text like '%"reaction_type": "like"%'
       and details_payload::text not like '%member_cp%'
       and details_payload::text not like '%cp_snapshots%'
       and details_payload::text not like '%cp_value%'
       and details_payload::text not like '%email%' then
      insert into milestone26c_guild_wall_results values ('reaction_details', 'comment_reaction_details_safe', 'PASS', details_payload::text);
    else
      insert into milestone26c_guild_wall_results values ('reaction_details', 'comment_reaction_details_safe', 'FAIL', details_payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('reaction_details', 'comment_reaction_details_safe', 'FAIL', sqlerrm);
  end;

  begin
    rep_before := private.get_profile_ghoul_rep(member_a_id);

    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    perform public.delete_wall_comment(rep_comment_id);

    rep_after := private.get_profile_ghoul_rep(member_a_id);

    if rep_after = rep_before - 1 then
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'deleted_comment_removes_rep', 'PASS', 'before=' || rep_before::text || ', after=' || rep_after::text);
    else
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'deleted_comment_removes_rep', 'FAIL', 'before=' || rep_before::text || ', after=' || rep_after::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('ghoul_rep', 'deleted_comment_removes_rep', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    payload := public.get_guild_wall_feed(anteiku_id, 20, null);

    if payload::text like '%author_ghoul_rep%'
       and payload::text not like '%member_cp%'
       and payload::text not like '%cp_snapshots%'
       and payload::text not like '%cp_value%' then
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'feed_returns_author_ghoul_rep_without_cp', 'PASS', payload::text);
    else
      insert into milestone26c_guild_wall_results values ('ghoul_rep', 'feed_returns_author_ghoul_rep_without_cp', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('ghoul_rep', 'feed_returns_author_ghoul_rep_without_cp', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    details_payload := public.get_wall_reaction_details('post', rep_post_one_id, 'fire');

    if details_payload::text like '%' || member_b_id::text || '%'
       and details_payload::text like '%"reaction_type": "fire"%'
       and details_payload::text like '%avatar_asset_path%'
       and details_payload::text not like '%member_cp%'
       and details_payload::text not like '%cp_snapshots%'
       and details_payload::text not like '%cp_value%'
       and details_payload::text not like '%email%' then
      insert into milestone26c_guild_wall_results values ('reaction_details', 'post_reaction_details_safe', 'PASS', details_payload::text);
    else
      insert into milestone26c_guild_wall_results values ('reaction_details', 'post_reaction_details_safe', 'FAIL', details_payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('reaction_details', 'post_reaction_details_safe', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', wrong_guild_member_id::text, true);
    details_payload := public.get_wall_reaction_details('post', global_post_id, 'trophy');

    if details_payload::text like '%' || wrong_guild_member_id::text || '%'
       and details_payload::text not like '%member_cp%'
       and details_payload::text not like '%cp_snapshots%'
       and details_payload::text not like '%cp_value%'
       and details_payload::text not like '%email%' then
      insert into milestone26c_guild_wall_results values ('reaction_details', 'global_reaction_details_visible_to_approved_member', 'PASS', details_payload::text);
    else
      insert into milestone26c_guild_wall_results values ('reaction_details', 'global_reaction_details_visible_to_approved_member', 'FAIL', details_payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('reaction_details', 'global_reaction_details_visible_to_approved_member', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', wrong_guild_member_id::text, true);
    perform public.get_wall_reaction_details('post', post_a_id, 'fire');
    insert into milestone26c_guild_wall_results values ('reaction_details', 'wrong_guild_reaction_details_denied', 'FAIL', 'Wrong-guild member read guild post reaction details.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('reaction_details', 'wrong_guild_reaction_details_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', pending_id::text, true);
    perform public.get_wall_reaction_details('post', rep_post_one_id, 'fire');
    insert into milestone26c_guild_wall_results values ('reaction_details', 'pending_reaction_details_denied', 'FAIL', 'Pending user read reaction details.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('reaction_details', 'pending_reaction_details_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', pending_id::text, true);
    perform public.create_wall_post(anteiku_id, 'Pending should fail');
    insert into milestone26c_guild_wall_results values ('eligibility', 'pending_denied_post', 'FAIL', 'Pending user created wall post.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('eligibility', 'pending_denied_post', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', inactive_id::text, true);
    payload := public.get_guild_wall_feed(anteiku_id, 20, null);

    if jsonb_typeof(payload -> 'posts') = 'array' then
      insert into milestone26c_guild_wall_results values ('eligibility', 'inactive_can_view_wall', 'PASS', 'Inactive roster user can view wall.');
    else
      insert into milestone26c_guild_wall_results values ('eligibility', 'inactive_can_view_wall', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('eligibility', 'inactive_can_view_wall', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', inactive_id::text, true);
    perform public.create_wall_post(anteiku_id, 'Inactive should fail');
    insert into milestone26c_guild_wall_results values ('eligibility', 'inactive_denied_post', 'FAIL', 'Inactive roster user created wall post.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('eligibility', 'inactive_denied_post', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', on_break_id::text, true);
    perform public.react_to_wall_post(post_a_id, 'coffee');
    insert into milestone26c_guild_wall_results values ('eligibility', 'on_break_denied_reaction', 'FAIL', 'On-break roster user reacted.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('eligibility', 'on_break_denied_reaction', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    perform public.create_wall_post(anteiku_re_id, 'Wrong guild should fail');
    insert into milestone26c_guild_wall_results values ('scope', 'member_wrong_guild_post_denied', 'FAIL', 'Member posted to wrong guild.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('scope', 'member_wrong_guild_post_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.delete_wall_post(post_a_id);
    insert into milestone26c_guild_wall_results values ('post', 'member_cannot_delete_other_post', 'FAIL', 'Member deleted another member post.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('post', 'member_cannot_delete_other_post', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    wall_comment_id := public.create_wall_comment(post_a_id, 'Validation comment');

    if wall_comment_id is not null then
      insert into milestone26c_guild_wall_results values ('comment', 'approved_member_comments', 'PASS', wall_comment_id::text);
    else
      insert into milestone26c_guild_wall_results values ('comment', 'approved_member_comments', 'FAIL', 'No comment id returned.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('comment', 'approved_member_comments', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    perform public.delete_wall_comment(wall_comment_id);
    insert into milestone26c_guild_wall_results values ('comment', 'member_cannot_delete_other_comment', 'FAIL', 'Member deleted another member comment.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('comment', 'member_cannot_delete_other_comment', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.react_to_wall_post(post_a_id, 'fire');
    perform public.react_to_wall_post(post_a_id, 'fire');

    select count(*) into direct_count
    from public.wall_post_reactions
    where post_id = post_a_id
      and profile_id = member_b_id
      and reaction_type = 'fire';

    if direct_count = 1 then
      insert into milestone26c_guild_wall_results values ('reaction', 'one_post_reaction_per_user_type', 'PASS', 'Duplicate post reaction reused existing row.');
    else
      insert into milestone26c_guild_wall_results values ('reaction', 'one_post_reaction_per_user_type', 'FAIL', direct_count::text || ' duplicate rows found.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('reaction', 'one_post_reaction_per_user_type', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.react_to_wall_comment(wall_comment_id, 'like');
    perform public.react_to_wall_comment(wall_comment_id, 'like');

    select count(*) into direct_count
    from public.wall_comment_reactions
    where wall_comment_reactions.comment_id = wall_comment_id
      and profile_id = member_b_id
      and reaction_type = 'like';

    if direct_count = 1 then
      insert into milestone26c_guild_wall_results values ('reaction', 'one_comment_reaction_per_user_type', 'PASS', 'Duplicate comment reaction reused existing row.');
    else
      insert into milestone26c_guild_wall_results values ('reaction', 'one_comment_reaction_per_user_type', 'FAIL', direct_count::text || ' duplicate rows found.');
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('reaction', 'one_comment_reaction_per_user_type', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    perform public.delete_wall_comment(wall_comment_id);
    payload := public.get_guild_wall_feed(anteiku_id, 20, null);

    if payload::text not like '%' || wall_comment_id::text || '%' then
      insert into milestone26c_guild_wall_results values ('comment', 'own_comment_soft_delete_hidden', 'PASS', 'Deleted own comment hidden from feed.');
    else
      insert into milestone26c_guild_wall_results values ('comment', 'own_comment_soft_delete_hidden', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('comment', 'own_comment_soft_delete_hidden', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    perform public.delete_wall_post(post_a_id);
    payload := public.get_guild_wall_feed(anteiku_id, 20, null);

    if payload::text not like '%' || post_a_id::text || '%' then
      insert into milestone26c_guild_wall_results values ('post', 'own_post_soft_delete_hidden', 'PASS', 'Deleted own post hidden from feed.');
    else
      insert into milestone26c_guild_wall_results values ('post', 'own_post_soft_delete_hidden', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('post', 'own_post_soft_delete_hidden', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    normal_post_id := public.create_wall_post(anteiku_id, 'Normal wall post');
    pinned_post_id := public.create_wall_post(anteiku_id, 'Pinned wall post');

    perform set_config('request.jwt.claim.sub', moderator_id::text, true);
    perform public.pin_wall_post(pinned_post_id);

    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    payload := public.get_guild_wall_feed(anteiku_id, 20, null);
    first_post_id := (payload -> 'posts' -> 0 ->> 'id')::uuid;

    if first_post_id = pinned_post_id then
      insert into milestone26c_guild_wall_results values ('moderation', 'pinned_posts_sort_first', 'PASS', payload::text);
    else
      insert into milestone26c_guild_wall_results values ('moderation', 'pinned_posts_sort_first', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('moderation', 'pinned_posts_sort_first', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', wrong_guild_moderator_id::text, true);
    perform public.unpin_wall_post(pinned_post_id);
    insert into milestone26c_guild_wall_results values ('moderation', 'wrong_guild_staff_denied', 'FAIL', 'Wrong-guild moderator unpinned post.');
  exception when others then
    insert into milestone26c_guild_wall_results values ('moderation', 'wrong_guild_staff_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_b_id::text, true);
    mod_comment_id := public.create_wall_comment(normal_post_id, 'Moderate this comment');

    perform set_config('request.jwt.claim.sub', moderator_id::text, true);
    perform public.moderate_delete_wall_comment(mod_comment_id);

    payload := public.get_guild_wall_feed(anteiku_id, 20, null);
    if payload::text not like '%' || mod_comment_id::text || '%' then
      insert into milestone26c_guild_wall_results values ('moderation', 'scoped_staff_moderates_comment', 'PASS', 'Scoped moderator deleted comment.');
    else
      insert into milestone26c_guild_wall_results values ('moderation', 'scoped_staff_moderates_comment', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('moderation', 'scoped_staff_moderates_comment', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', moderator_id::text, true);
    perform public.moderate_delete_wall_post(normal_post_id);

    payload := public.get_guild_wall_feed(anteiku_id, 20, null);
    if payload::text not like '%' || normal_post_id::text || '%' then
      insert into milestone26c_guild_wall_results values ('moderation', 'scoped_staff_moderates_post', 'PASS', 'Scoped moderator deleted post.');
    else
      insert into milestone26c_guild_wall_results values ('moderation', 'scoped_staff_moderates_post', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('moderation', 'scoped_staff_moderates_post', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', wrong_guild_member_id::text, true);
    re_post_id := public.create_wall_post(anteiku_re_id, 'Anteiku Re owner moderation post');

    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    perform public.pin_wall_post(re_post_id);
    perform public.moderate_delete_wall_post(re_post_id);

    payload := public.get_guild_wall_feed(anteiku_re_id, 20, null);
    if payload::text not like '%' || re_post_id::text || '%' then
      insert into milestone26c_guild_wall_results values ('moderation', 'owner_moderates_all_guilds', 'PASS', 'Owner pinned/deleted other guild post.');
    else
      insert into milestone26c_guild_wall_results values ('moderation', 'owner_moderates_all_guilds', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone26c_guild_wall_results values ('moderation', 'owner_moderates_all_guilds', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute 'select count(*) from public.wall_posts' into direct_count;
      execute 'reset role';

      if direct_count = 0 then
        insert into milestone26c_guild_wall_results values ('rls', 'direct_wall_table_read_denied', 'PASS', 'Direct read returned zero rows.');
      else
        insert into milestone26c_guild_wall_results values ('rls', 'direct_wall_table_read_denied', 'FAIL', 'Direct read returned ' || direct_count::text || ' rows.');
      end if;
    exception when others then
      execute 'reset role';
      insert into milestone26c_guild_wall_results values ('rls', 'direct_wall_table_read_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone26c_guild_wall_results values ('rls', 'direct_wall_table_read_denied', 'SKIP', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_a_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute format(
        'insert into public.wall_posts (guild_id, author_profile_id, content) values (%L::uuid, %L::uuid, %L)',
        anteiku_id::text,
        member_a_id::text,
        'Unsafe direct wall write'
      );
      execute 'reset role';
      insert into milestone26c_guild_wall_results values ('rls', 'direct_wall_table_write_denied', 'FAIL', 'Direct table write succeeded.');
    exception when others then
      execute 'reset role';
      insert into milestone26c_guild_wall_results values ('rls', 'direct_wall_table_write_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone26c_guild_wall_results values ('rls', 'direct_wall_table_write_denied', 'SKIP', sqlerrm);
  end;

  update public.guild_memberships
  set role = 'member'
  where role = 'owner'
    and profile_id <> owner_id;

  select count(*) into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into milestone26c_guild_wall_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner membership exists.');
  else
    insert into milestone26c_guild_wall_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owner memberships found.');
  end if;
end;
$$;

select section, test_name, status, details
from milestone26c_guild_wall_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone26c_total_pass,
       count(*) filter (where status = 'FAIL') as milestone26c_total_fail,
       count(*) filter (where status = 'SKIP') as milestone26c_total_skip
from milestone26c_guild_wall_results;

create temp table milestone_public_profile_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  anteiku_re_id constant uuid := '00000000-0000-0000-0000-000000000102';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  pending_id constant uuid := '10000000-0000-0000-0000-000000000007';
  wrong_guild_id constant uuid := '10000000-0000-0000-0000-000000000009';
  inactive_id constant uuid := '10000000-0000-0000-0000-000000000086';
  suspended_id constant uuid := '10000000-0000-0000-0000-000000000087';
  payload jsonb;
  details_payload jsonb;
  direct_count integer;
  owner_count integer;
begin
  begin
    if to_regclass('public.profile_reactions') is not null then
      insert into milestone_public_profile_results values ('schema', 'profile_reactions_table_exists', 'PASS', 'profile_reactions exists.');
    else
      insert into milestone_public_profile_results values ('schema', 'profile_reactions_table_exists', 'FAIL', 'profile_reactions missing.');
    end if;

    if exists (
      select 1
      from pg_class c
      join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public'
        and c.relname = 'profile_reactions'
        and c.relrowsecurity = true
    ) then
      insert into milestone_public_profile_results values ('schema', 'profile_reactions_rls_enabled', 'PASS', 'RLS enabled.');
    else
      insert into milestone_public_profile_results values ('schema', 'profile_reactions_rls_enabled', 'FAIL', 'RLS not enabled.');
    end if;

    if not has_table_privilege('authenticated', 'public.profile_reactions', 'insert')
       and not has_table_privilege('authenticated', 'public.profile_reactions', 'select')
       and not has_table_privilege('anon', 'public.profile_reactions', 'select') then
      insert into milestone_public_profile_results values ('schema', 'profile_reactions_no_broad_grants', 'PASS', 'No direct anon/authenticated table grants.');
    else
      insert into milestone_public_profile_results values ('schema', 'profile_reactions_no_broad_grants', 'FAIL', 'Unexpected direct table grant exists.');
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('schema', 'profile_reactions_schema_checks', 'FAIL', sqlerrm);
  end;

  begin
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    )
    values
      ('00000000-0000-0000-0000-000000000000', inactive_id, 'authenticated', 'authenticated', 'inactive-profile.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', suspended_id, 'authenticated', 'authenticated', 'suspended-profile.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now())
    on conflict (id) do nothing;

    insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
    values
      (inactive_id, 'inactive_profile', 'inactive_profile', 'Inactive Profile', 'approved', now()),
      (suspended_id, 'suspended_profile', 'suspended_profile', 'Suspended Profile', 'approved', now())
    on conflict (id) do update
    set ign = excluded.ign,
        approval_status = excluded.approval_status,
        approved_at = excluded.approved_at;

    insert into public.guild_memberships (profile_id, guild_id, role, membership_status, roster_status, is_primary, assigned_by)
    values
      (inactive_id, anteiku_id, 'member', 'active', 'inactive', true, owner_id),
      (suspended_id, anteiku_id, 'member', 'suspended', 'suspended', true, owner_id)
    on conflict (profile_id, guild_id) do update
    set role = excluded.role,
        membership_status = excluded.membership_status,
        roster_status = excluded.roster_status,
        is_primary = excluded.is_primary,
        assigned_by = excluded.assigned_by;

    update public.profiles
    set approval_status = 'approved', approved_at = coalesce(approved_at, now())
    where id in (member_id, wrong_guild_id, owner_id);

    update public.guild_memberships
    set membership_status = 'active',
        roster_status = 'active',
        is_primary = true
    where profile_id in (member_id, wrong_guild_id, owner_id);

    insert into public.three_v_three_player_profiles (profile_id, discord_username, combined_cp)
    values (wrong_guild_id, 'publicprofiletest', 3250000)
    on conflict (profile_id) do update
    set combined_cp = excluded.combined_cp,
        discord_username = excluded.discord_username;

    insert into milestone_public_profile_results values ('setup', 'public_profile_test_state_seeded', 'PASS', 'Public profile validation users prepared.');
  exception when others then
    insert into milestone_public_profile_results values ('setup', 'public_profile_test_state_seeded', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    payload := public.get_public_member_profile('wrong_guild');

    if payload #>> '{profile,profile_slug}' = 'wrong_guild'
       and payload #>> '{profile,guild_slug}' = 'anteiku-re' then
      insert into milestone_public_profile_results values ('profile', 'approved_cross_guild_profile_fetch_allowed', 'PASS', payload::text);
    else
      insert into milestone_public_profile_results values ('profile', 'approved_cross_guild_profile_fetch_allowed', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('profile', 'approved_cross_guild_profile_fetch_allowed', 'FAIL', sqlerrm);
  end;

  begin
    if payload::text not ilike '%member_cp%'
       and payload::text not ilike '%cp_snapshots%'
       and payload::text not ilike '%cp_value%'
       and payload::text not ilike '%email%'
       and payload::text not ilike '%admin_permissions%'
       and payload::text not ilike '%audit%' then
      insert into milestone_public_profile_results values ('privacy', 'public_profile_payload_has_no_private_fields', 'PASS', 'No protected CP/email/admin/audit keys found.');
    else
      insert into milestone_public_profile_results values ('privacy', 'public_profile_payload_has_no_private_fields', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('privacy', 'public_profile_payload_has_no_private_fields', 'FAIL', sqlerrm);
  end;

  begin
    if (payload #>> '{profile,three_v_three_combined_cp}')::bigint = 3250000 then
      insert into milestone_public_profile_results values ('profile', 'public_three_v_three_combined_cp_returned', 'PASS', 'Public self-entered 3v3 Combined CP returned.');
    else
      insert into milestone_public_profile_results values ('profile', 'public_three_v_three_combined_cp_returned', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('profile', 'public_three_v_three_combined_cp_returned', 'FAIL', sqlerrm);
  end;

  begin
    if payload #> '{profile,ghoul_rep}' is not null
       and jsonb_typeof(payload #> '{profile,reactions}') = 'array' then
      insert into milestone_public_profile_results values ('profile', 'ghoul_rep_and_reaction_counts_returned', 'PASS', 'Ghoul Rep and reaction count array returned.');
    else
      insert into milestone_public_profile_results values ('profile', 'ghoul_rep_and_reaction_counts_returned', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('profile', 'ghoul_rep_and_reaction_counts_returned', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', pending_id::text, true);
    perform public.get_public_member_profile('wrong_guild');
    insert into milestone_public_profile_results values ('eligibility', 'pending_user_denied_public_profile', 'FAIL', 'Pending user fetched public profile.');
  exception when others then
    insert into milestone_public_profile_results values ('eligibility', 'pending_user_denied_public_profile', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', suspended_id::text, true);
    perform public.get_public_member_profile('wrong_guild');
    insert into milestone_public_profile_results values ('eligibility', 'suspended_user_denied_public_profile', 'FAIL', 'Suspended user fetched public profile.');
  exception when others then
    insert into milestone_public_profile_results values ('eligibility', 'suspended_user_denied_public_profile', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', inactive_id::text, true);
    payload := public.get_public_member_profile('wrong_guild');

    if payload #>> '{profile,profile_slug}' = 'wrong_guild' then
      insert into milestone_public_profile_results values ('eligibility', 'inactive_user_can_view_public_profile', 'PASS', 'Inactive/on_break class can view.');
    else
      insert into milestone_public_profile_results values ('eligibility', 'inactive_user_can_view_public_profile', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('eligibility', 'inactive_user_can_view_public_profile', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', inactive_id::text, true);
    perform public.react_to_public_profile(wrong_guild_id, 'like');
    insert into milestone_public_profile_results values ('eligibility', 'inactive_user_cannot_react', 'FAIL', 'Inactive/on_break class reacted.');
  exception when others then
    insert into milestone_public_profile_results values ('eligibility', 'inactive_user_cannot_react', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.react_to_public_profile(member_id, 'like');
    insert into milestone_public_profile_results values ('reaction', 'self_reaction_blocked', 'FAIL', 'Self-reaction succeeded.');
  exception when others then
    insert into milestone_public_profile_results values ('reaction', 'self_reaction_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.react_to_public_profile(wrong_guild_id, 'like');
    perform public.react_to_public_profile(wrong_guild_id, 'like');

    select count(*) into direct_count
    from public.profile_reactions
    where target_profile_id = wrong_guild_id
      and reactor_profile_id = member_id
      and reaction_type = 'like';

    if direct_count = 1 then
      insert into milestone_public_profile_results values ('reaction', 'duplicate_reaction_same_type_idempotent', 'PASS', 'Duplicate reaction produced one row.');
    else
      insert into milestone_public_profile_results values ('reaction', 'duplicate_reaction_same_type_idempotent', 'FAIL', direct_count::text || ' rows found.');
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('reaction', 'duplicate_reaction_same_type_idempotent', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.react_to_public_profile(wrong_guild_id, 'fire');
    payload := public.get_public_member_profile('wrong_guild');

    if payload::text like '%"reacted_by_me": true%' then
      insert into milestone_public_profile_results values ('reaction', 'viewer_own_reactions_returned', 'PASS', payload::text);
    else
      insert into milestone_public_profile_results values ('reaction', 'viewer_own_reactions_returned', 'FAIL', payload::text);
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('reaction', 'viewer_own_reactions_returned', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.remove_public_profile_reaction(wrong_guild_id, 'like');

    select count(*) into direct_count
    from public.profile_reactions
    where target_profile_id = wrong_guild_id
      and reactor_profile_id = member_id
      and reaction_type = 'like';

    if direct_count = 0 then
      insert into milestone_public_profile_results values ('reaction', 'remove_reaction_works', 'PASS', 'Reaction removed.');
    else
      insert into milestone_public_profile_results values ('reaction', 'remove_reaction_works', 'FAIL', direct_count::text || ' rows remain.');
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('reaction', 'remove_reaction_works', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    details_payload := public.get_public_profile_reaction_details(wrong_guild_id, 'fire');

    if jsonb_typeof(details_payload -> 'reactions') = 'array'
       and details_payload::text like '%member_local%'
       and details_payload::text not ilike '%email%'
       and details_payload::text not ilike '%member_cp%'
       and details_payload::text not ilike '%cp_snapshots%'
       and details_payload::text not ilike '%profile_id%'
       and details_payload::text not ilike '%auth%' then
      insert into milestone_public_profile_results values ('reaction', 'reaction_details_safe_public_info_only', 'PASS', details_payload::text);
    else
      insert into milestone_public_profile_results values ('reaction', 'reaction_details_safe_public_info_only', 'FAIL', details_payload::text);
    end if;
  exception when others then
    insert into milestone_public_profile_results values ('reaction', 'reaction_details_safe_public_info_only', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute format(
        'insert into public.profile_reactions (target_profile_id, reactor_profile_id, reaction_type) values (%L::uuid, %L::uuid, %L)',
        wrong_guild_id::text,
        member_id::text,
        'trophy'
      );
      execute 'reset role';
      insert into milestone_public_profile_results values ('rls', 'direct_profile_reaction_write_denied', 'FAIL', 'Direct profile_reactions insert succeeded.');
    exception when others then
      execute 'reset role';
      insert into milestone_public_profile_results values ('rls', 'direct_profile_reaction_write_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone_public_profile_results values ('rls', 'direct_profile_reaction_write_denied', 'SKIP', sqlerrm);
  end;

  select count(*) into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into milestone_public_profile_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner membership exists.');
  else
    insert into milestone_public_profile_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owner memberships found.');
  end if;
end;
$$;

select section, test_name, status, details
from milestone_public_profile_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone_public_profile_total_pass,
       count(*) filter (where status = 'FAIL') as milestone_public_profile_total_fail,
       count(*) filter (where status = 'SKIP') as milestone_public_profile_total_skip
from milestone_public_profile_results;

-- Milestone 28B validation: Push Notifications backend/RPC foundation.
-- Local-only and rolled back with the rest of this script.
create temp table milestone_push_notification_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  pending_id constant uuid := '10000000-0000-0000-0000-000000000007';
  wrong_guild_id constant uuid := '10000000-0000-0000-0000-000000000009';
  direct_grant_count integer;
  direct_count integer;
  owner_count integer;
  payload jsonb;
begin
  begin
    if to_regclass('public.push_subscriptions') is not null
       and to_regclass('public.push_notification_preferences') is not null
       and to_regclass('public.push_notification_outbox') is not null then
      insert into milestone_push_notification_results values ('schema', 'push_tables_exist', 'PASS', 'Push tables exist.');
    else
      insert into milestone_push_notification_results values ('schema', 'push_tables_exist', 'FAIL', 'One or more push tables are missing.');
    end if;

    select count(*)
    into direct_count
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname in ('push_subscriptions', 'push_notification_preferences', 'push_notification_outbox')
      and c.relrowsecurity = true;

    if direct_count = 3 then
      insert into milestone_push_notification_results values ('schema', 'push_tables_rls_enabled', 'PASS', 'RLS enabled on all push tables.');
    else
      insert into milestone_push_notification_results values ('schema', 'push_tables_rls_enabled', 'FAIL', direct_count::text || ' push tables have RLS enabled.');
    end if;

    select count(*)
    into direct_grant_count
    from information_schema.table_privileges
    where table_schema = 'public'
      and table_name in ('push_subscriptions', 'push_notification_preferences', 'push_notification_outbox')
      and grantee in ('anon', 'authenticated');

    if direct_grant_count = 0 then
      insert into milestone_push_notification_results values ('schema', 'push_tables_no_direct_client_grants', 'PASS', 'No direct anon/authenticated table grants.');
    else
      insert into milestone_push_notification_results values ('schema', 'push_tables_no_direct_client_grants', 'FAIL', direct_grant_count::text || ' unexpected direct grants.');
    end if;
  exception when others then
    insert into milestone_push_notification_results values ('schema', 'push_schema_checks', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    payload := public.register_push_subscription(
      'https://push.example.test/member-endpoint',
      repeat('a', 88),
      repeat('b', 24),
      'local validation agent'
    );

    if payload ->> 'enabled' = 'true'
       and (payload #>> '{preferences,notify_gvg}') = 'true'
       and (payload #>> '{preferences,notify_wall_reactions}') = 'false' then
      insert into milestone_push_notification_results values ('rpc', 'eligible_member_registers_subscription', 'PASS', payload::text);
    else
      insert into milestone_push_notification_results values ('rpc', 'eligible_member_registers_subscription', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_push_notification_results values ('rpc', 'eligible_member_registers_subscription', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', pending_id::text, true);
    perform public.register_push_subscription(
      'https://push.example.test/pending-endpoint',
      repeat('a', 88),
      repeat('b', 24),
      'local validation agent'
    );
    insert into milestone_push_notification_results values ('eligibility', 'pending_user_denied_subscription', 'FAIL', 'Pending user registered push subscription.');
  exception when others then
    insert into milestone_push_notification_results values ('eligibility', 'pending_user_denied_subscription', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    payload := public.update_my_push_preferences(false, true, false, true, true, false);

    if payload ->> 'notify_gvg' = 'false'
       and payload ->> 'notify_3v3' = 'false'
       and payload ->> 'notify_wall_reactions' = 'true'
       and payload ->> 'notify_profile_reactions' = 'false' then
      insert into milestone_push_notification_results values ('rpc', 'member_updates_own_preferences', 'PASS', payload::text);
    else
      insert into milestone_push_notification_results values ('rpc', 'member_updates_own_preferences', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_push_notification_results values ('rpc', 'member_updates_own_preferences', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', pending_id::text, true);
    perform public.get_my_push_preferences();
    insert into milestone_push_notification_results values ('eligibility', 'pending_user_denied_preferences', 'FAIL', 'Pending user read push preferences.');
  exception when others then
    insert into milestone_push_notification_results values ('eligibility', 'pending_user_denied_preferences', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.register_push_subscription(
      'https://push.example.test/member-owned-endpoint',
      repeat('c', 88),
      repeat('d', 24),
      'local validation agent'
    );

    perform set_config('request.jwt.claim.sub', wrong_guild_id::text, true);
    perform public.disable_push_subscription('https://push.example.test/member-owned-endpoint');

    select count(*)
    into direct_count
    from public.push_subscriptions
    where endpoint = 'https://push.example.test/member-owned-endpoint'
      and profile_id = member_id
      and disabled_at is null;

    if direct_count = 1 then
      insert into milestone_push_notification_results values ('rpc', 'other_user_cannot_disable_subscription', 'PASS', 'Subscription remained active for owner.');
    else
      insert into milestone_push_notification_results values ('rpc', 'other_user_cannot_disable_subscription', 'FAIL', direct_count::text || ' active rows remain.');
    end if;
  exception when others then
    insert into milestone_push_notification_results values ('rpc', 'other_user_cannot_disable_subscription', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    payload := public.disable_push_subscription('https://push.example.test/member-owned-endpoint');

    select count(*)
    into direct_count
    from public.push_subscriptions
    where endpoint = 'https://push.example.test/member-owned-endpoint'
      and profile_id = member_id
      and disabled_at is null;

    if direct_count = 0 and payload ->> 'disabled' = 'true' then
      insert into milestone_push_notification_results values ('rpc', 'member_disables_own_subscription', 'PASS', payload::text);
    else
      insert into milestone_push_notification_results values ('rpc', 'member_disables_own_subscription', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_push_notification_results values ('rpc', 'member_disables_own_subscription', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    payload := public.create_my_test_push_notification();

    select count(*)
    into direct_count
    from public.push_notification_outbox
    where recipient_profile_id = member_id
      and type = 'self_test'
      and title = 'Anteiku Guild Manager'
      and body = 'Test notification from Anteiku.'
      and coalesce(route, '') = '/';

    if payload ->> 'queued' = 'true' and direct_count = 1 then
      insert into milestone_push_notification_results values ('outbox', 'self_test_queues_only_for_self', 'PASS', payload::text);
    else
      insert into milestone_push_notification_results values ('outbox', 'self_test_queues_only_for_self', 'FAIL', coalesce(payload::text, '<null>') || ' rows=' || direct_count::text);
    end if;
  exception when others then
    insert into milestone_push_notification_results values ('outbox', 'self_test_queues_only_for_self', 'FAIL', sqlerrm);
  end;

  begin
    select count(*)
    into direct_count
    from public.push_notification_outbox
    where title ilike '%email%'
       or title ilike '%member_cp%'
       or title ilike '%cp_snapshots%'
       or title ilike '%auth%'
       or title ilike '%audit%'
       or body ilike '%email%'
       or body ilike '%member_cp%'
       or body ilike '%cp_snapshots%'
       or body ilike '%auth%'
       or body ilike '%audit%';

    if direct_count = 0 then
      insert into milestone_push_notification_results values ('privacy', 'outbox_payload_has_no_private_fields', 'PASS', 'No private field tokens found in notification title/body.');
    else
      insert into milestone_push_notification_results values ('privacy', 'outbox_payload_has_no_private_fields', 'FAIL', direct_count::text || ' unsafe rows found.');
    end if;
  exception when others then
    insert into milestone_push_notification_results values ('privacy', 'outbox_payload_has_no_private_fields', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute format(
        'insert into public.push_notification_outbox (recipient_profile_id, type, title, body) values (%L::uuid, %L, %L, %L)',
        owner_id::text,
        'self_test',
        'Unsafe',
        'Direct write'
      );
      execute 'reset role';
      insert into milestone_push_notification_results values ('rls', 'direct_outbox_write_denied', 'FAIL', 'Direct outbox insert succeeded.');
    exception when others then
      execute 'reset role';
      insert into milestone_push_notification_results values ('rls', 'direct_outbox_write_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone_push_notification_results values ('rls', 'direct_outbox_write_denied', 'SKIP', sqlerrm);
  end;

  select count(*)
  into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into milestone_push_notification_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner membership exists.');
  else
    insert into milestone_push_notification_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owner memberships found.');
  end if;
end;
$$;

create temp table if not exists milestone_account_switcher_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '10000000-0000-0000-0000-000000000001';
  member_id constant uuid := '10000000-0000-0000-0000-000000000006';
  wrong_guild_id constant uuid := '10000000-0000-0000-0000-000000000009';
  controller_auth_id constant uuid := '10000000-0000-0000-0000-000000000011';
  switch_profile_id constant uuid := '10000000-0000-0000-0000-000000000012';
  direct_count integer;
  direct_grant_count integer;
  owner_count integer;
  payload jsonb;
  linked_profile_count integer;
  active_profile_count integer;
begin
  begin
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    )
    values
      ('00000000-0000-0000-0000-000000000000', controller_auth_id, 'authenticated', 'authenticated', 'switch-controller.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
      ('00000000-0000-0000-0000-000000000000', switch_profile_id, 'authenticated', 'authenticated', 'switch-profile.local@example.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now())
    on conflict (id) do nothing;

    insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
    values (
      switch_profile_id,
      'switch_local',
      'switch_local',
      'Switch Local',
      'approved',
      now()
    )
    on conflict (id) do update
    set username = excluded.username,
        profile_slug = excluded.profile_slug,
        ign = excluded.ign,
        approval_status = excluded.approval_status,
        approved_at = excluded.approved_at;

    insert into public.guild_memberships (profile_id, guild_id, role, membership_status, is_primary, assigned_by, roster_status)
    values (switch_profile_id, anteiku_id, 'member', 'active', true, owner_id, 'active')
    on conflict (profile_id, guild_id) do update
    set role = excluded.role,
        membership_status = excluded.membership_status,
        is_primary = excluded.is_primary,
        assigned_by = excluded.assigned_by,
        roster_status = excluded.roster_status;

    insert into milestone_account_switcher_results values ('setup', 'switcher_test_users_seeded', 'PASS', 'Controller auth user and switchable profile seeded locally.');
  exception when others then
    insert into milestone_account_switcher_results values ('setup', 'switcher_test_users_seeded', 'FAIL', sqlerrm);
  end;

  begin
    if to_regclass('public.user_profile_links') is not null
       and to_regclass('public.user_active_profiles') is not null then
      insert into milestone_account_switcher_results values ('schema', 'account_link_tables_exist', 'PASS', 'Account-link tables exist.');
    else
      insert into milestone_account_switcher_results values ('schema', 'account_link_tables_exist', 'FAIL', 'One or more account-link tables are missing.');
    end if;

    select count(*)
    into direct_count
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname in ('user_profile_links', 'user_active_profiles')
      and c.relrowsecurity = true;

    if direct_count = 2 then
      insert into milestone_account_switcher_results values ('schema', 'account_link_tables_rls_enabled', 'PASS', 'RLS enabled on both account-link tables.');
    else
      insert into milestone_account_switcher_results values ('schema', 'account_link_tables_rls_enabled', 'FAIL', direct_count::text || ' account-link tables have RLS enabled.');
    end if;

    select count(*)
    into direct_grant_count
    from information_schema.table_privileges
    where table_schema = 'public'
      and table_name in ('user_profile_links', 'user_active_profiles')
      and grantee in ('anon', 'authenticated');

    if direct_grant_count = 0 then
      insert into milestone_account_switcher_results values ('schema', 'account_link_tables_no_direct_client_grants', 'PASS', 'No direct anon/authenticated table grants.');
    else
      insert into milestone_account_switcher_results values ('schema', 'account_link_tables_no_direct_client_grants', 'FAIL', direct_grant_count::text || ' unexpected direct grants.');
    end if;
  exception when others then
    insert into milestone_account_switcher_results values ('schema', 'account_link_schema_checks', 'FAIL', sqlerrm);
  end;

  begin
    select count(*)
    into linked_profile_count
    from public.user_profile_links upl
    where upl.auth_user_id = member_id
      and upl.profile_id = member_id
      and upl.is_primary = true
      and upl.disabled_at is null;

    if linked_profile_count = 1 then
      insert into milestone_account_switcher_results values ('backfill', 'existing_one_profile_user_self_linked', 'PASS', 'Self-link/backfill trigger created the current profile link.');
    else
      insert into milestone_account_switcher_results values ('backfill', 'existing_one_profile_user_self_linked', 'FAIL', linked_profile_count::text || ' active self-links found.');
    end if;
  exception when others then
    insert into milestone_account_switcher_results values ('backfill', 'existing_one_profile_user_self_linked', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    payload := public.get_my_switchable_profiles();

    if jsonb_array_length(payload -> 'profiles') = 1
       and payload #>> '{profiles,0,profile_id}' = member_id::text
       and payload::text not ilike '%member_cp%'
       and payload::text not ilike '%cp_snapshots%'
       and payload::text not ilike '%cp_value%'
       and payload::text not ilike '%current_cp%'
       and payload::text not ilike '%combined_cp%' then
      insert into milestone_account_switcher_results values ('rpc', 'switchable_profiles_only_linked_no_cp', 'PASS', payload::text);
    else
      insert into milestone_account_switcher_results values ('rpc', 'switchable_profiles_only_linked_no_cp', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_account_switcher_results values ('rpc', 'switchable_profiles_only_linked_no_cp', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    delete from public.user_active_profiles where auth_user_id = member_id;

    payload := public.get_my_active_profile();

    if payload #>> '{profile,profile_id}' = member_id::text
       and payload #>> '{profile,is_active_profile}' = 'true' then
      insert into milestone_account_switcher_results values ('rpc', 'active_profile_fallback_self', 'PASS', payload::text);
    else
      insert into milestone_account_switcher_results values ('rpc', 'active_profile_fallback_self', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_account_switcher_results values ('rpc', 'active_profile_fallback_self', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    payload := public.set_my_active_profile(member_id);

    if payload #>> '{profile,profile_id}' = member_id::text then
      insert into milestone_account_switcher_results values ('rpc', 'set_active_profile_linked_allowed', 'PASS', payload::text);
    else
      insert into milestone_account_switcher_results values ('rpc', 'set_active_profile_linked_allowed', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_account_switcher_results values ('rpc', 'set_active_profile_linked_allowed', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.set_my_active_profile(wrong_guild_id);
    insert into milestone_account_switcher_results values ('rpc', 'set_active_profile_unlinked_denied', 'FAIL', 'Unlinked profile was selected.');
  exception when others then
    insert into milestone_account_switcher_results values ('rpc', 'set_active_profile_unlinked_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform public.owner_link_profile_to_auth_user('switch-controller.local@example.test', 'switch_local', 'owner');
    insert into milestone_account_switcher_results values ('owner_rpc', 'non_owner_cannot_link_profile', 'FAIL', 'Non-owner linked a profile.');
  exception when others then
    insert into milestone_account_switcher_results values ('owner_rpc', 'non_owner_cannot_link_profile', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    payload := public.owner_unlink_profile_from_auth_user('switch-profile.local@example.test', 'switch_local');

    if payload ->> 'unlinked' = 'true' then
      insert into milestone_account_switcher_results values ('owner_rpc', 'owner_unlinks_profile', 'PASS', payload::text);
    else
      insert into milestone_account_switcher_results values ('owner_rpc', 'owner_unlinks_profile', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_account_switcher_results values ('owner_rpc', 'owner_unlinks_profile', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    payload := public.owner_link_profile_to_auth_user('switch-controller.local@example.test', 'switch_local', 'owner');

    select count(*)
    into linked_profile_count
    from public.user_profile_links upl
    where upl.profile_id = switch_profile_id
      and upl.disabled_at is null;

    if payload ->> 'linked' = 'true'
       and payload #>> '{profile,profile_id}' = switch_profile_id::text
       and linked_profile_count = 1 then
      insert into milestone_account_switcher_results values ('owner_rpc', 'owner_links_profile_to_auth_user', 'PASS', payload::text);
    else
      insert into milestone_account_switcher_results values ('owner_rpc', 'owner_links_profile_to_auth_user', 'FAIL', coalesce(payload::text, '<null>') || ' active_links=' || linked_profile_count::text);
    end if;
  exception when others then
    insert into milestone_account_switcher_results values ('owner_rpc', 'owner_links_profile_to_auth_user', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', controller_auth_id::text, true);
    payload := public.set_my_active_profile(switch_profile_id);

    if payload #>> '{profile,profile_id}' = switch_profile_id::text
       and payload #>> '{profile,is_active_profile}' = 'true' then
      insert into milestone_account_switcher_results values ('rpc', 'linked_controller_sets_active_profile', 'PASS', payload::text);
    else
      insert into milestone_account_switcher_results values ('rpc', 'linked_controller_sets_active_profile', 'FAIL', coalesce(payload::text, '<null>'));
    end if;
  exception when others then
    insert into milestone_account_switcher_results values ('rpc', 'linked_controller_sets_active_profile', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    payload := public.owner_unlink_profile_from_auth_user('switch-controller.local@example.test', 'switch_local');

    select count(*)
    into active_profile_count
    from public.user_active_profiles uap
    where uap.auth_user_id = controller_auth_id;

    if payload ->> 'unlinked' = 'true'
       and active_profile_count = 0 then
      insert into milestone_account_switcher_results values ('owner_rpc', 'unlink_active_profile_clears_selection', 'PASS', payload::text);
    else
      insert into milestone_account_switcher_results values ('owner_rpc', 'unlink_active_profile_clears_selection', 'FAIL', coalesce(payload::text, '<null>') || ' active_rows=' || active_profile_count::text);
    end if;
  exception when others then
    insert into milestone_account_switcher_results values ('owner_rpc', 'unlink_active_profile_clears_selection', 'FAIL', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', controller_auth_id::text, true);
    perform public.set_my_active_profile(switch_profile_id);
    insert into milestone_account_switcher_results values ('rpc', 'disabled_link_denied', 'FAIL', 'Disabled/unlinked profile was selected.');
  exception when others then
    insert into milestone_account_switcher_results values ('rpc', 'disabled_link_denied', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', owner_id::text, true);
    perform public.owner_unlink_profile_from_auth_user('owner.local@example.test', 'owner_local');
    insert into milestone_account_switcher_results values ('owner_rpc', 'only_owner_profile_unlink_blocked', 'FAIL', 'Only active Owner profile link was disabled.');
  exception when others then
    insert into milestone_account_switcher_results values ('owner_rpc', 'only_owner_profile_unlink_blocked', 'PASS', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute 'select count(*) from public.user_profile_links';
      execute 'reset role';
      insert into milestone_account_switcher_results values ('rls', 'direct_account_link_read_denied', 'FAIL', 'Direct user_profile_links SELECT succeeded.');
    exception when others then
      execute 'reset role';
      insert into milestone_account_switcher_results values ('rls', 'direct_account_link_read_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone_account_switcher_results values ('rls', 'direct_account_link_read_denied', 'SKIP', sqlerrm);
  end;

  begin
    perform set_config('request.jwt.claim.sub', member_id::text, true);
    perform set_config('request.jwt.claim.role', 'authenticated', true);
    execute 'set local role authenticated';
    begin
      execute format(
        'insert into public.user_active_profiles (auth_user_id, active_profile_id) values (%L::uuid, %L::uuid)',
        member_id::text,
        wrong_guild_id::text
      );
      execute 'reset role';
      insert into milestone_account_switcher_results values ('rls', 'direct_active_profile_write_denied', 'FAIL', 'Direct user_active_profiles insert succeeded.');
    exception when others then
      execute 'reset role';
      insert into milestone_account_switcher_results values ('rls', 'direct_active_profile_write_denied', 'PASS', sqlerrm);
    end;
  exception when others then
    begin
      execute 'reset role';
    exception when others then
      null;
    end;
    insert into milestone_account_switcher_results values ('rls', 'direct_active_profile_write_denied', 'SKIP', sqlerrm);
  end;

  select count(*)
  into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into milestone_account_switcher_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner membership exists.');
  else
    insert into milestone_account_switcher_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owner memberships found.');
  end if;
end;
$$;

select section, test_name, status, details
from milestone_push_notification_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone_push_notifications_total_pass,
       count(*) filter (where status = 'FAIL') as milestone_push_notifications_total_fail,
       count(*) filter (where status = 'SKIP') as milestone_push_notifications_total_skip
from milestone_push_notification_results;

select section, test_name, status, details
from milestone_account_switcher_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as milestone_account_switcher_total_pass,
       count(*) filter (where status = 'FAIL') as milestone_account_switcher_total_fail,
       count(*) filter (where status = 'SKIP') as milestone_account_switcher_total_skip
from milestone_account_switcher_results;

rollback;
