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

rollback;
