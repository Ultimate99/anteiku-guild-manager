import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  approveRegistration,
  canReviewApprovals,
  getAllowedApprovalRoles,
  getOwnAdminPermissionKeys,
  loadApprovalQueue,
  rejectRegistration,
} from '../services/adminApprovalService.js';
import {
  AUDIT_ACTION_OPTIONS,
  canViewAuditLogs,
  formatAuditAction,
  formatAuditActor,
  formatAuditMetadata,
  formatAuditTarget,
  getDefaultAuditFilters,
  loadAuditLogs,
} from '../services/adminAuditService.js';
import {
  canUpdateCp,
  canViewCp,
  formatCpValue,
  isValidCpInput,
  loadCpGuildOptions,
  loadCpLeaderboard,
  loadCurrentCpRoster,
  updateMemberCp,
} from '../services/adminCpService.js';
import {
  canManageAdminPermissions,
  canToggleAdminPermission,
  isCpPermissionKey,
  isSensitivePermissionKey,
  loadAdminPermissionManagementData,
  saveAdminPermissionChanges,
} from '../services/adminPermissionService.js';
import {
  canManageGvg,
  createGvgEvent,
  getGvgManageGuildOptions,
  loadGvgGuildOptions,
  loadGvgResults,
  loadManageableGvgEvents,
  setGvgEventStatus,
} from '../services/gvgService.js';
import {
  adminResetProfileSlug,
  adminUpdateMemberIgn,
  assignMemberRole,
  canAssignMemberRole,
  canEditMemberIgn,
  canResetMemberSlug,
  canTransferMemberGuild,
  canViewMemberManagement,
  getAllowedMemberRoleOptions,
  isValidProfileSlug,
  loadActiveGuildOptions,
  loadMemberRoster,
  normalizeProfileSlug,
  transferMemberGuild,
} from '../services/adminMemberService.js';

const plannedSections = ['Guild and subguild management'];

function formatDate(value) {
  if (!value) {
    return 'Not recorded';
  }

  return new Intl.DateTimeFormat('en', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

function formatRole(role) {
  return role ? role.charAt(0).toUpperCase() + role.slice(1) : 'Member';
}

function statusTone(status) {
  if (status === 'active') {
    return 'success';
  }

  if (status === 'pending') {
    return 'warning';
  }

  if (status === 'rejected') {
    return 'danger';
  }

  return 'neutral';
}

function buildMemberDrafts(roster) {
  return roster.reduce((drafts, item) => {
    drafts[item.id] = {
      ign: item.profile?.ign ?? '',
      role: item.role ?? 'member',
      slug: item.profile?.profile_slug ?? item.profile?.username ?? '',
      targetGuildId: '',
    };
    return drafts;
  }, {});
}

function buildCpDrafts(roster) {
  return roster.reduce((drafts, item) => {
    drafts[item.profile_id] = item.cp_value === null || item.cp_value === undefined ? '' : String(item.cp_value);
    return drafts;
  }, {});
}

function buildScopedCpGuildOptions({ membership, allGuilds = [] }) {
  if (!membership) {
    return [];
  }

  if (membership.role === 'owner') {
    return allGuilds;
  }

  if (!membership.guild_id) {
    return [];
  }

  return [
    {
      id: membership.guild_id,
      name: membership.guild?.name ?? membership.guild_name ?? 'Assigned guild',
      slug: membership.guild?.slug ?? '',
      status: 'active',
      is_core: true,
    },
  ];
}

function buildAdminPermissionDrafts(targets) {
  return targets.reduce((drafts, target) => {
    drafts[target.id] = (target.permissionKeys ?? []).reduce((permissions, permissionKey) => {
      permissions[permissionKey] = true;
      return permissions;
    }, {});
    return drafts;
  }, {});
}

function buildNextPermissionKeys({ catalog, currentKeys = [], draft = {}, membership }) {
  const currentSet = new Set(currentKeys);

  return catalog
    .filter((permission) => {
      if (!canToggleAdminPermission({ membership, permissionKey: permission.key })) {
        return currentSet.has(permission.key);
      }

      return Boolean(draft[permission.key]);
    })
    .map((permission) => permission.key);
}

function hasPermissionDraftChanges({ catalog, target, draft = {}, membership }) {
  const currentSet = new Set(target.permissionKeys ?? []);

  return catalog.some((permission) => {
    if (!canToggleAdminPermission({ membership, permissionKey: permission.key })) {
      return false;
    }

    return currentSet.has(permission.key) !== Boolean(draft[permission.key]);
  });
}

function buildGvgGuildOptions({ membership, allGuilds = [] }) {
  return getGvgManageGuildOptions({ membership, activeGuilds: allGuilds });
}

function buildGvgSummary(results) {
  return results.reduce(
    (summary, vote) => {
      if (vote.vote_status === 'present') {
        summary.present.push(vote);
      }

      if (vote.vote_status === 'absent') {
        summary.absent.push(vote);
      }

      return summary;
    },
    { present: [], absent: [] },
  );
}

function appendGuildOption(map, guild) {
  if (guild?.id && !map.has(guild.id)) {
    map.set(guild.id, {
      id: guild.id,
      name: guild.name ?? 'Unknown guild',
      slug: guild.slug ?? '',
    });
  }
}

function buildAuditGuildOptions({ membership, guild, guildOptions = [], activeGuildOptions = [], cpGuildOptions = [], gvgGuildOptions = [] }) {
  if (!membership) {
    return [];
  }

  if (membership.role !== 'owner') {
    if (!membership.guild_id) {
      return [];
    }

    return [
      {
        id: membership.guild_id,
        name: guild?.name ?? 'Assigned guild',
        slug: guild?.slug ?? '',
      },
    ];
  }

  const guildMap = new Map();
  appendGuildOption(guildMap, guild);
  guildOptions.forEach((guildOption) => appendGuildOption(guildMap, guildOption));
  activeGuildOptions.forEach((guildOption) => appendGuildOption(guildMap, guildOption));
  cpGuildOptions.forEach((guildOption) => appendGuildOption(guildMap, guildOption));
  gvgGuildOptions.forEach((guildOption) => appendGuildOption(guildMap, guildOption));

  return Array.from(guildMap.values()).sort((a, b) => a.name.localeCompare(b.name));
}

function toDateRangeBoundary(value, endOfDay = false) {
  if (!value) {
    return null;
  }

  const suffix = endOfDay ? 'T23:59:59.999' : 'T00:00:00.000';
  const date = new Date(`${value}${suffix}`);

  if (Number.isNaN(date.getTime())) {
    return null;
  }

  return date.toISOString();
}

function buildAuditRpcFilters(filters, before = null) {
  return {
    guildId: filters.guildId,
    action: filters.action,
    from: toDateRangeBoundary(filters.dateFrom),
    to: toDateRangeBoundary(filters.dateTo, true),
    limit: filters.limit,
    before,
  };
}

function formatAuditGuild(row) {
  if (row.guild_name) {
    return row.guild_slug ? `${row.guild_name} (${row.guild_slug})` : row.guild_name;
  }

  if (row.guild_id) {
    return `Guild ${String(row.guild_id).slice(0, 8)}`;
  }

  return 'Global';
}

function formatAuditEntity(row) {
  if (row.entity_table && row.entity_id) {
    return `${row.entity_table} - ${String(row.entity_id).slice(0, 8)}`;
  }

  if (row.entity_table) {
    return row.entity_table;
  }

  if (row.entity_id) {
    return String(row.entity_id).slice(0, 8);
  }

  return '';
}

export function AdminPanel() {
  const { membership, guild } = useAuth();
  const [permissionKeys, setPermissionKeys] = useState([]);
  const [queue, setQueue] = useState([]);
  const [memberRoster, setMemberRoster] = useState([]);
  const [approvalLoading, setApprovalLoading] = useState(false);
  const [memberLoading, setMemberLoading] = useState(false);
  const [permissionLoading, setPermissionLoading] = useState(false);
  const [adminPermissionLoading, setAdminPermissionLoading] = useState(false);
  const [adminError, setAdminError] = useState('');
  const [actionMessage, setActionMessage] = useState('');
  const [selectedRoles, setSelectedRoles] = useState({});
  const [rejectReasons, setRejectReasons] = useState({});
  const [permissionCatalog, setPermissionCatalog] = useState([]);
  const [adminPermissionTargets, setAdminPermissionTargets] = useState([]);
  const [adminPermissionDrafts, setAdminPermissionDrafts] = useState({});
  const [gvgLoading, setGvgLoading] = useState(false);
  const [gvgEvents, setGvgEvents] = useState([]);
  const [gvgResults, setGvgResults] = useState([]);
  const [gvgGuildOptions, setGvgGuildOptions] = useState([]);
  const [selectedGvgEventId, setSelectedGvgEventId] = useState('');
  const [gvgDraft, setGvgDraft] = useState({
    title: '',
    scope: 'guild',
    guildId: '',
    startsAt: '',
    endsAt: '',
  });
  const [memberDrafts, setMemberDrafts] = useState({});
  const [memberSearch, setMemberSearch] = useState('');
  const [guildFilter, setGuildFilter] = useState('all');
  const [activeGuildOptions, setActiveGuildOptions] = useState([]);
  const [cpGuildOptions, setCpGuildOptions] = useState([]);
  const [selectedCpGuildId, setSelectedCpGuildId] = useState('');
  const [cpRoster, setCpRoster] = useState([]);
  const [cpLeaderboard, setCpLeaderboard] = useState([]);
  const [cpDrafts, setCpDrafts] = useState({});
  const [cpSearch, setCpSearch] = useState('');
  const [cpLoading, setCpLoading] = useState(false);
  const [auditLogs, setAuditLogs] = useState([]);
  const [auditFilters, setAuditFilters] = useState(() => getDefaultAuditFilters());
  const [auditLoading, setAuditLoading] = useState(false);
  const [auditError, setAuditError] = useState('');
  const [auditNotAuthorized, setAuditNotAuthorized] = useState(false);
  const [activeAction, setActiveAction] = useState(null);
  const [confirmAction, setConfirmAction] = useState(null);

  const canViewAdmin = ['owner', 'leader', 'vice', 'admin'].includes(membership?.role);
  const allowedRoles = useMemo(() => getAllowedApprovalRoles(membership?.role), [membership?.role]);
  const canReviewQueue = canReviewApprovals({ membership, permissionKeys });
  const canViewMembers = canViewMemberManagement({ membership, permissionKeys });
  const canEditIgn = canEditMemberIgn({ membership, permissionKeys });
  const canResetSlug = canResetMemberSlug({ membership, permissionKeys });
  const canManageRoles = canAssignMemberRole({ membership, permissionKeys });
  const canManagePermissions = canManageAdminPermissions({ membership });
  const canManageGvgEvents = canManageGvg({ membership, permissionKeys });
  const canTransferGuilds = canTransferMemberGuild({ membership });
  const canViewCpSection = canViewCp({ membership, permissionKeys });
  const canUpdateCpValues = canUpdateCp({ membership, permissionKeys });
  const canViewAuditSection = canViewAuditLogs({ membership, permissionKeys });
  const allowedMemberRoles = useMemo(
    () => getAllowedMemberRoleOptions({ membership, permissionKeys }),
    [membership, permissionKeys],
  );

  const selectedCpGuild = useMemo(
    () => cpGuildOptions.find((guild) => guild.id === selectedCpGuildId) ?? null,
    [cpGuildOptions, selectedCpGuildId],
  );

  const filteredCpRoster = useMemo(() => {
    const normalizedSearch = cpSearch.trim().toLowerCase();

    if (!normalizedSearch) {
      return cpRoster;
    }

    return cpRoster.filter((item) => {
      const searchableText = [
        item.username,
        item.ign,
        selectedCpGuild?.name,
        selectedCpGuild?.slug,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      return searchableText.includes(normalizedSearch);
    });
  }, [cpRoster, cpSearch, selectedCpGuild]);

  const guildOptions = useMemo(() => {
    const guilds = new Map();
    memberRoster.forEach((item) => {
      if (item.guild?.id) {
        guilds.set(item.guild.id, item.guild.name ?? 'Unknown guild');
      }
    });

    return Array.from(guilds, ([id, name]) => ({ id, name })).sort((a, b) => a.name.localeCompare(b.name));
  }, [memberRoster]);

  const filteredMembers = useMemo(() => {
    const normalizedSearch = memberSearch.trim().toLowerCase();

    return memberRoster.filter((item) => {
      const matchesGuild = guildFilter === 'all' || item.guild_id === guildFilter;

      if (!matchesGuild) {
        return false;
      }

      if (!normalizedSearch) {
        return true;
      }

      const searchableText = [
        item.profile?.username,
        item.profile?.profile_slug,
        item.profile?.ign,
        item.guild?.name,
        item.guild?.slug,
        item.role,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      return searchableText.includes(normalizedSearch);
    });
  }, [guildFilter, memberRoster, memberSearch]);

  const selectedGvgEvent = useMemo(
    () => gvgEvents.find((event) => event.id === selectedGvgEventId) ?? null,
    [gvgEvents, selectedGvgEventId],
  );

  const gvgSummary = useMemo(() => buildGvgSummary(gvgResults), [gvgResults]);
  const auditGuildOptions = useMemo(
    () =>
      buildAuditGuildOptions({
        membership,
        guild,
        guildOptions,
        activeGuildOptions,
        cpGuildOptions,
        gvgGuildOptions,
      }),
    [activeGuildOptions, cpGuildOptions, guild, guildOptions, gvgGuildOptions, membership],
  );
  const oldestAuditCreatedAt = auditLogs[auditLogs.length - 1]?.created_at ?? null;

  async function loadPermissionManagementSection() {
    const nextPermissionData = await loadAdminPermissionManagementData();
    setPermissionCatalog(nextPermissionData.catalog);
    setAdminPermissionTargets(nextPermissionData.targets);
    setAdminPermissionDrafts(buildAdminPermissionDrafts(nextPermissionData.targets));
  }

  async function loadGvgManagementSection({ preferredEventId = selectedGvgEventId } = {}) {
    const allGvgGuilds = membership?.role === 'owner' ? await loadGvgGuildOptions() : [];
    const nextGvgGuildOptions = buildGvgGuildOptions({ membership, allGuilds: allGvgGuilds });
    const nextEvents = await loadManageableGvgEvents();
    const nextSelectedEventId =
      nextEvents.find((event) => event.id === preferredEventId)?.id ?? nextEvents[0]?.id ?? '';
    const nextResults = nextSelectedEventId ? await loadGvgResults({ eventId: nextSelectedEventId }) : [];

    setGvgGuildOptions(nextGvgGuildOptions);
    setGvgEvents(nextEvents);
    setSelectedGvgEventId(nextSelectedEventId);
    setGvgResults(nextResults);
    setGvgDraft((current) => ({
      ...current,
      scope: membership?.role === 'owner' ? current.scope : 'guild',
      guildId: nextGvgGuildOptions.find((guild) => guild.id === current.guildId)?.id ?? nextGvgGuildOptions[0]?.id ?? '',
    }));
  }

  const loadAdminData = useCallback(
    async ({ clearMessage = true } = {}) => {
      if (!canViewAdmin) {
        setPermissionKeys([]);
        setQueue([]);
        setMemberRoster([]);
        setPermissionCatalog([]);
        setAdminPermissionTargets([]);
        setAdminPermissionDrafts({});
        setGvgEvents([]);
        setGvgResults([]);
        setGvgGuildOptions([]);
        setSelectedGvgEventId('');
        setActiveGuildOptions([]);
        setCpGuildOptions([]);
        setSelectedCpGuildId('');
        setCpRoster([]);
        setCpLeaderboard([]);
        setCpDrafts({});
        setAuditLogs([]);
        setAuditError('');
        setAuditNotAuthorized(false);
        return;
      }

      setAdminError('');

      if (clearMessage) {
        setActionMessage('');
      }

      setPermissionLoading(true);
      setApprovalLoading(true);
      setMemberLoading(true);
      setAdminPermissionLoading(true);
      setGvgLoading(true);
      setCpLoading(true);

      try {
        const nextPermissionKeys =
          membership?.role === 'admin' ? await getOwnAdminPermissionKeys(membership?.id) : [];
        setPermissionKeys(nextPermissionKeys);

        const canLoadQueue = canReviewApprovals({
          membership,
          permissionKeys: nextPermissionKeys,
        });
        const canLoadMembers = canViewMemberManagement({
          membership,
          permissionKeys: nextPermissionKeys,
        });
        const canLoadPermissionManagement = canManageAdminPermissions({ membership });
        const canLoadGvg = canManageGvg({ membership, permissionKeys: nextPermissionKeys });
        const canLoadCp = canViewCp({
          membership,
          permissionKeys: nextPermissionKeys,
        });

        if (canLoadQueue) {
          const nextQueue = await loadApprovalQueue();
          setQueue(nextQueue);
          setSelectedRoles((current) => {
            const nextRoles = {};

            nextQueue.forEach((item) => {
              nextRoles[item.id] = current[item.id] ?? allowedRoles[0] ?? 'member';
            });

            return nextRoles;
          });
        } else {
          setQueue([]);
        }

        if (canLoadMembers) {
          const nextRoster = await loadMemberRoster();
          const nextActiveGuildOptions = canTransferMemberGuild({ membership })
            ? await loadActiveGuildOptions()
            : [];

          setMemberRoster(nextRoster);
          setActiveGuildOptions(nextActiveGuildOptions);
          setMemberDrafts(buildMemberDrafts(nextRoster));
          setGuildFilter((current) =>
            current === 'all' || nextRoster.some((item) => item.guild_id === current) ? current : 'all',
          );
        } else {
          setMemberRoster([]);
          setActiveGuildOptions([]);
          setMemberDrafts({});
          setGuildFilter('all');
        }

        if (canLoadPermissionManagement) {
          await loadPermissionManagementSection();
        } else {
          setPermissionCatalog([]);
          setAdminPermissionTargets([]);
          setAdminPermissionDrafts({});
        }

        if (canLoadGvg) {
          await loadGvgManagementSection();
        } else {
          setGvgEvents([]);
          setGvgResults([]);
          setGvgGuildOptions([]);
          setSelectedGvgEventId('');
        }

        if (canLoadCp) {
          const allCpGuilds = membership?.role === 'owner' ? await loadCpGuildOptions() : [];
          const nextCpGuildOptions = buildScopedCpGuildOptions({
            membership,
            allGuilds: allCpGuilds,
          });
          const nextSelectedCpGuildId =
            nextCpGuildOptions.find((guild) => guild.id === selectedCpGuildId)?.id ??
            nextCpGuildOptions[0]?.id ??
            '';

          setCpGuildOptions(nextCpGuildOptions);
          setSelectedCpGuildId(nextSelectedCpGuildId);

          if (nextSelectedCpGuildId) {
            const [nextCpRoster, nextCpLeaderboard] = await Promise.all([
              loadCurrentCpRoster({ guildId: nextSelectedCpGuildId }),
              loadCpLeaderboard({ guildId: nextSelectedCpGuildId }),
            ]);

            setCpRoster(nextCpRoster);
            setCpLeaderboard(nextCpLeaderboard);
            setCpDrafts(buildCpDrafts(nextCpRoster));
          } else {
            setCpRoster([]);
            setCpLeaderboard([]);
            setCpDrafts({});
          }
        } else {
          setCpGuildOptions([]);
          setSelectedCpGuildId('');
          setCpRoster([]);
          setCpLeaderboard([]);
          setCpDrafts({});
        }
      } catch (approvalError) {
        setQueue([]);
        setMemberRoster([]);
        setPermissionCatalog([]);
        setAdminPermissionTargets([]);
        setAdminPermissionDrafts({});
        setGvgEvents([]);
        setGvgResults([]);
        setGvgGuildOptions([]);
        setSelectedGvgEventId('');
        setActiveGuildOptions([]);
        setCpGuildOptions([]);
        setCpRoster([]);
        setCpLeaderboard([]);
        setCpDrafts({});
        setMemberDrafts({});
        setAdminError(approvalError.message);
      } finally {
        setPermissionLoading(false);
        setApprovalLoading(false);
        setMemberLoading(false);
        setAdminPermissionLoading(false);
        setGvgLoading(false);
        setCpLoading(false);
      }
    },
    [allowedRoles, canViewAdmin, membership, selectedCpGuildId],
  );

  useEffect(() => {
    loadAdminData();
  }, [loadAdminData]);

  useEffect(() => {
    if (!canViewAuditSection) {
      setAuditLogs([]);
      setAuditError('');
      setAuditNotAuthorized(false);
      return;
    }

    loadAuditLogPage({ append: false });
  }, [canViewAuditSection, membership?.id]);

  async function loadAuditLogPage({ append = false, before = null } = {}) {
    if (!canViewAuditSection) {
      setAuditLogs([]);
      setAuditError('');
      setAuditNotAuthorized(false);
      return;
    }

    setAuditLoading(true);
    setAuditError('');
    setAuditNotAuthorized(false);

    try {
      const nextLogs = await loadAuditLogs(buildAuditRpcFilters(auditFilters, before));
      setAuditLogs((current) => (append ? [...current, ...nextLogs] : nextLogs));
    } catch (nextAuditError) {
      if (nextAuditError.code === 'AUDIT_NOT_AUTHORIZED') {
        setAuditLogs([]);
        setAuditNotAuthorized(true);
        setAuditError('');
      } else {
        setAuditError(nextAuditError.message);
      }
    } finally {
      setAuditLoading(false);
    }
  }

  function updateAuditFilter(field, value) {
    setAuditFilters((current) => ({
      ...current,
      [field]: field === 'limit' ? Number(value) : value,
    }));
    setAuditError('');
    setAuditNotAuthorized(false);
  }

  async function handleApprove(item) {
    const role = selectedRoles[item.id] ?? allowedRoles[0];

    if (!allowedRoles.includes(role)) {
      setAdminError('Selected approval role is not allowed for your current role.');
      return;
    }

    setActiveAction({ id: item.id, type: 'approve' });
    setAdminError('');
    setActionMessage('');

    try {
      await approveRegistration({
        profileId: item.profile_id,
        guildId: item.guild_id,
        role,
      });
      setActionMessage(`Approved @${item.profile?.username ?? 'member'} as ${formatRole(role)}.`);
      await loadAdminData({ clearMessage: false });
    } catch (approvalError) {
      setAdminError(approvalError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleReject(item) {
    const reason = rejectReasons[item.id]?.trim() ?? '';

    if (reason.length > 1000) {
      setAdminError('Rejection reason cannot exceed 1000 characters.');
      return;
    }

    setActiveAction({ id: item.id, type: 'reject' });
    setAdminError('');
    setActionMessage('');

    try {
      await rejectRegistration({
        profileId: item.profile_id,
        reason,
      });
      setActionMessage(`Rejected @${item.profile?.username ?? 'member'}.`);
      setRejectReasons((current) => ({ ...current, [item.id]: '' }));
      await loadAdminData({ clearMessage: false });
    } catch (approvalError) {
      setAdminError(approvalError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleSaveMemberIgn(item) {
    const nextIgn = memberDrafts[item.id]?.ign?.trim() ?? '';

    if (!nextIgn) {
      setAdminError('IGN is required.');
      return;
    }

    setActiveAction({ id: item.id, type: 'edit-ign' });
    setAdminError('');
    setActionMessage('');

    try {
      await adminUpdateMemberIgn({
        profileId: item.profile_id,
        ign: nextIgn,
      });
      setActionMessage(`Updated IGN for @${item.profile?.username ?? 'member'}.`);
      await loadAdminData({ clearMessage: false });
    } catch (memberError) {
      setAdminError(memberError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleResetMemberSlug(item) {
    const nextSlug = normalizeProfileSlug(memberDrafts[item.id]?.slug ?? '');

    if (!isValidProfileSlug(nextSlug)) {
      setAdminError('Username/profile slug must be 3-32 lowercase letters, numbers, hyphen, or underscore; start and end with a letter or number.');
      return;
    }

    setActiveAction({ id: item.id, type: 'reset-slug' });
    setAdminError('');
    setActionMessage('');

    try {
      await adminResetProfileSlug({
        profileId: item.profile_id,
        newSlug: nextSlug,
      });
      setActionMessage(`Reset username/profile slug for @${item.profile?.username ?? 'member'}.`);
      await loadAdminData({ clearMessage: false });
    } catch (memberError) {
      setAdminError(memberError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleAssignMemberRole(item) {
    const draftedRole = memberDrafts[item.id]?.role ?? item.role ?? 'member';
    const nextRole = allowedMemberRoles.includes(draftedRole) ? draftedRole : allowedMemberRoles[0] ?? '';

    if (item.role === 'owner') {
      setAdminError('Owner role changes are manual-only and cannot be made through this UI.');
      return;
    }

    if (!allowedMemberRoles.includes(nextRole)) {
      setAdminError('Selected role is not allowed for your current role or permissions.');
      return;
    }

    if (nextRole === item.role) {
      setAdminError('Choose a different role before saving.');
      return;
    }

    setActiveAction({ id: item.id, type: 'assign-role' });
    setAdminError('');
    setActionMessage('');

    try {
      await assignMemberRole({
        profileId: item.profile_id,
        guildId: item.guild_id,
        role: nextRole,
      });
      setActionMessage(`Updated @${item.profile?.username ?? 'member'} to ${formatRole(nextRole)}.`);
      setConfirmAction(null);
      await loadAdminData({ clearMessage: false });
    } catch (memberError) {
      setAdminError(memberError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleTransferMemberGuild(item) {
    const targetGuildId = memberDrafts[item.id]?.targetGuildId ?? '';
    const targetGuild = activeGuildOptions.find((guild) => guild.id === targetGuildId);

    if (!canTransferGuilds) {
      setAdminError('Guild transfer is Owner-only in this version.');
      return;
    }

    if (!targetGuildId || targetGuildId === item.guild_id) {
      setAdminError('Choose a different active guild before transferring.');
      return;
    }

    if (!targetGuild) {
      setAdminError('Selected target guild is not available.');
      return;
    }

    setActiveAction({ id: item.id, type: 'transfer-guild' });
    setAdminError('');
    setActionMessage('');

    try {
      await transferMemberGuild({
        profileId: item.profile_id,
        fromGuildId: item.guild_id,
        toGuildId: targetGuildId,
      });
      setActionMessage(
        `Moved @${item.profile?.username ?? 'member'} to ${targetGuild.name ?? 'selected guild'} as Member.`,
      );
      setConfirmAction(null);
      await loadAdminData({ clearMessage: false });
    } catch (memberError) {
      setAdminError(memberError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleUpdateCp(item) {
    const rawCpValue = cpDrafts[item.profile_id]?.trim() ?? '';

    if (!isValidCpInput(rawCpValue)) {
      setAdminError('CP must be a whole number greater than or equal to 0.');
      return;
    }

    setActiveAction({ id: item.profile_id, type: 'update-cp' });
    setAdminError('');
    setActionMessage('');

    try {
      await updateMemberCp({
        profileId: item.profile_id,
        cpValue: Number(rawCpValue),
      });
      setActionMessage(`Updated CP for @${item.username ?? 'member'}.`);
      await loadAdminData({ clearMessage: false });
    } catch (cpError) {
      setAdminError(cpError.message);
    } finally {
      setActiveAction(null);
    }
  }

  function updateCpDraft(profileId, value) {
    setCpDrafts((current) => ({
      ...current,
      [profileId]: value,
    }));
  }

  function resetCpDraft(item) {
    setCpDrafts((current) => ({
      ...current,
      [item.profile_id]: item.cp_value === null || item.cp_value === undefined ? '' : String(item.cp_value),
    }));
  }

  function updateAdminPermissionDraft(targetId, permissionKey, checked) {
    setAdminPermissionDrafts((current) => ({
      ...current,
      [targetId]: {
        ...current[targetId],
        [permissionKey]: checked,
      },
    }));
  }

  function resetAdminPermissionDraft(target) {
    setAdminPermissionDrafts((current) => ({
      ...current,
      [target.id]: (target.permissionKeys ?? []).reduce((permissions, permissionKey) => {
        permissions[permissionKey] = true;
        return permissions;
      }, {}),
    }));
  }

  async function handleSaveAdminPermissions(target) {
    const draft = adminPermissionDrafts[target.id] ?? {};
    const nextKeys = buildNextPermissionKeys({
      catalog: permissionCatalog,
      currentKeys: target.permissionKeys ?? [],
      draft,
      membership,
    });

    setActiveAction({ id: target.id, type: 'save-permissions' });
    setAdminPermissionLoading(true);
    setAdminError('');
    setActionMessage('');

    try {
      const result = await saveAdminPermissionChanges({
        membershipId: target.id,
        currentKeys: target.permissionKeys ?? [],
        nextKeys,
      });
      setActionMessage(
        `Updated permissions for @${target.profile?.username ?? 'admin'} (${result.granted} granted, ${result.revoked} revoked).`,
      );
      await loadPermissionManagementSection();
    } catch (permissionError) {
      setAdminError(permissionError.message);
      await loadPermissionManagementSection();
    } finally {
      setActiveAction(null);
      setAdminPermissionLoading(false);
    }
  }

  function updateGvgDraft(field, value) {
    setGvgDraft((current) => ({
      ...current,
      [field]: value,
    }));
  }

  async function handleCreateGvgEvent() {
    const title = gvgDraft.title.trim();
    const scope = membership?.role === 'owner' ? gvgDraft.scope : 'guild';

    if (!title) {
      setAdminError('GvG event title is required.');
      return;
    }

    if (scope === 'guild' && !gvgDraft.guildId) {
      setAdminError('Choose a guild for this GvG event.');
      return;
    }

    setActiveAction({ id: 'gvg-create', type: 'gvg-create' });
    setGvgLoading(true);
    setAdminError('');
    setActionMessage('');

    try {
      const newEvent = await createGvgEvent({
        title,
        scope,
        guildId: gvgDraft.guildId,
        startsAt: gvgDraft.startsAt ? new Date(gvgDraft.startsAt).toISOString() : null,
        endsAt: gvgDraft.endsAt ? new Date(gvgDraft.endsAt).toISOString() : null,
      });
      setActionMessage(`Created GvG event "${newEvent.title}". Activate it when voting should open.`);
      setGvgDraft((current) => ({ ...current, title: '', startsAt: '', endsAt: '' }));
      await loadGvgManagementSection({ preferredEventId: newEvent.id });
    } catch (gvgError) {
      setAdminError(gvgError.message);
    } finally {
      setActiveAction(null);
      setGvgLoading(false);
    }
  }

  async function handleSetGvgStatus(eventId, status) {
    setActiveAction({ id: eventId, type: `gvg-${status}` });
    setGvgLoading(true);
    setAdminError('');
    setActionMessage('');

    try {
      const updatedEvent = await setGvgEventStatus({ eventId, status });
      setActionMessage(`GvG event "${updatedEvent.title}" is now ${updatedEvent.status}.`);
      await loadGvgManagementSection({ preferredEventId: eventId });
    } catch (gvgError) {
      setAdminError(gvgError.message);
    } finally {
      setActiveAction(null);
      setGvgLoading(false);
    }
  }

  async function handleSelectGvgEvent(eventId) {
    setSelectedGvgEventId(eventId);
    setGvgLoading(true);
    setAdminError('');
    setActionMessage('');

    try {
      const nextResults = await loadGvgResults({ eventId });
      setGvgResults(nextResults);
    } catch (gvgError) {
      setGvgResults([]);
      setAdminError(gvgError.message);
    } finally {
      setGvgLoading(false);
    }
  }

  function updateMemberDraft(itemId, field, value) {
    setConfirmAction(null);
    setMemberDrafts((current) => ({
      ...current,
      [itemId]: {
        ...current[itemId],
        [field]: field === 'slug' ? normalizeProfileSlug(value) : value,
      },
    }));
  }

  if (!canViewAdmin) {
    return (
      <div className="stack">
        <section className="panel hero-panel">
          <StatusBadge tone="danger">Restricted</StatusBadge>
          <h3>Admin access unavailable</h3>
          <p>
            This view is hidden for normal members. Database policies and RPC checks remain the
            real security layer.
          </p>
        </section>
      </div>
    );
  }

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <StatusBadge tone={canReviewQueue || canViewMembers || canManagePermissions ? 'success' : 'warning'}>Admin operations</StatusBadge>
        <h3>Guild management</h3>
        <p>
          Manage registration requests and safe member profile fields. All writes use approved
          database RPCs; frontend checks are only the control surface.
        </p>
        <button type="button" className="secondary-action" onClick={() => loadAdminData()} disabled={approvalLoading || memberLoading || adminPermissionLoading || cpLoading}>
          {approvalLoading || memberLoading || adminPermissionLoading || cpLoading ? 'Refreshing...' : 'Refresh admin data'}
        </button>
      </section>

      {permissionLoading ? <p className="muted-line">Checking admin permissions...</p> : null}
      {adminError ? <p className="error-line">{adminError}</p> : null}
      {actionMessage ? <p className="notice-line">{actionMessage}</p> : null}

      {!canReviewQueue && !permissionLoading ? (
        <section className="panel hero-panel">
          <StatusBadge tone="danger">Approval access unavailable</StatusBadge>
          <h3>No approval permission</h3>
          <p>
            Owners, Leaders, Vice members, and Admins with approve_members can use the approval
            queue. Supabase RPC checks remain the real authority.
          </p>
        </section>
      ) : null}

      {canReviewQueue ? (
        <section className="approval-list" aria-label="Registration approval queue">
          <div className="section-heading-row">
            <div>
              <StatusBadge tone="warning">Registration</StatusBadge>
              <h3>Approval queue</h3>
            </div>
            <button type="button" className="secondary-action compact-action" onClick={() => loadAdminData()} disabled={approvalLoading}>
              {approvalLoading ? 'Loading...' : 'Refresh'}
            </button>
          </div>

          {approvalLoading ? <p className="muted-line">Loading approval queue...</p> : null}

          {!approvalLoading && queue.length === 0 ? (
            <section className="panel hero-panel">
              <StatusBadge>Clear</StatusBadge>
              <h3>No pending requests</h3>
              <p>Pending users and rejected users with reapply requests will appear here.</p>
            </section>
          ) : null}

          {queue.map((item) => {
            const selectedRole = selectedRoles[item.id] ?? allowedRoles[0] ?? 'member';
            const isApproving = activeAction?.id === item.id && activeAction.type === 'approve';
            const isRejecting = activeAction?.id === item.id && activeAction.type === 'reject';
            const actionDisabled = Boolean(activeAction);

            return (
              <article className="panel approval-card" key={item.id}>
                <div className="approval-card-header">
                  <div>
                    <h4>{item.profile?.ign ?? 'Unknown IGN'}</h4>
                    <p>@{item.profile?.username ?? 'unknown'}</p>
                  </div>
                  <StatusBadge tone={statusTone(item.membership_status)}>
                    {item.membership_status}
                  </StatusBadge>
                </div>

                <div className="approval-meta" aria-label="Approval request details">
                  <div>
                    <span>Guild</span>
                    <strong>{item.guild?.name ?? 'Unknown guild'}</strong>
                  </div>
                  <div>
                    <span>Profile status</span>
                    <strong>{item.profile?.approval_status ?? 'unknown'}</strong>
                  </div>
                  <div>
                    <span>Requested</span>
                    <strong>{formatDate(item.created_at)}</strong>
                  </div>
                  {item.profile?.reapply_requested_at ? (
                    <div>
                      <span>Reapply requested</span>
                      <strong>{formatDate(item.profile.reapply_requested_at)}</strong>
                    </div>
                  ) : null}
                </div>

                {item.profile?.reapply_note ? (
                  <p className="muted-line">{item.profile.reapply_note}</p>
                ) : null}

                <label>
                  Approve as
                  <select
                    value={selectedRole}
                    onChange={(event) =>
                      setSelectedRoles((current) => ({ ...current, [item.id]: event.target.value }))
                    }
                    disabled={actionDisabled}
                  >
                    {allowedRoles.map((role) => (
                      <option key={role} value={role}>
                        {formatRole(role)}
                      </option>
                    ))}
                  </select>
                </label>

                <div className="approval-actions">
                  <button
                    type="button"
                    className="primary-action"
                    onClick={() => handleApprove(item)}
                    disabled={actionDisabled}
                  >
                    {isApproving ? 'Approving...' : 'Approve'}
                  </button>
                  <button
                    type="button"
                    className="danger-action"
                    onClick={() => handleReject(item)}
                    disabled={actionDisabled}
                  >
                    {isRejecting ? 'Rejecting...' : 'Reject'}
                  </button>
                </div>

                <label>
                  Rejection reason
                  <textarea
                    value={rejectReasons[item.id] ?? ''}
                    maxLength={1000}
                    placeholder="Optional reason, stored through the rejection RPC"
                    onChange={(event) =>
                      setRejectReasons((current) => ({ ...current, [item.id]: event.target.value }))
                    }
                    disabled={actionDisabled}
                  />
                </label>
              </article>
            );
          })}
        </section>
      ) : null}

      {canManageGvgEvents ? (
        <section className="gvg-management" aria-label="GvG management">
          <div className="panel gvg-management-tools">
            <div className="section-heading-row">
              <div>
                <StatusBadge tone="success">GvG</StatusBadge>
                <h3>GvG management</h3>
              </div>
              <button
                type="button"
                className="secondary-action compact-action"
                onClick={async () => {
                  setGvgLoading(true);
                  setAdminError('');
                  setActionMessage('');
                  try {
                    await loadGvgManagementSection();
                  } catch (gvgError) {
                    setAdminError(gvgError.message);
                  } finally {
                    setGvgLoading(false);
                  }
                }}
                disabled={gvgLoading || Boolean(activeAction)}
              >
                {gvgLoading ? 'Loading...' : 'Refresh'}
              </button>
            </div>

            <p className="muted-line">
              Create events, open voting, close voting, and review present/absent results for your allowed scope.
            </p>
          </div>

          <section className="panel gvg-create-panel" aria-label="Create GvG event">
            <StatusBadge tone="warning">Create event</StatusBadge>
            <label>
              Event title
              <input
                type="text"
                value={gvgDraft.title}
                placeholder="GvG readiness check"
                onChange={(event) => updateGvgDraft('title', event.target.value)}
                disabled={gvgLoading || Boolean(activeAction)}
              />
            </label>

            {membership?.role === 'owner' ? (
              <label>
                Scope
                <select
                  value={gvgDraft.scope}
                  onChange={(event) => updateGvgDraft('scope', event.target.value)}
                  disabled={gvgLoading || Boolean(activeAction)}
                >
                  <option value="guild">Guild</option>
                  <option value="global">Global</option>
                </select>
              </label>
            ) : null}

            {gvgDraft.scope === 'guild' || membership?.role !== 'owner' ? (
              <label>
                Guild
                <select
                  value={gvgDraft.guildId}
                  onChange={(event) => updateGvgDraft('guildId', event.target.value)}
                  disabled={gvgLoading || Boolean(activeAction) || gvgGuildOptions.length <= 1}
                >
                  {gvgGuildOptions.length === 0 ? <option value="">No guild scope</option> : null}
                  {gvgGuildOptions.map((guild) => (
                    <option key={guild.id} value={guild.id}>
                      {guild.name}
                    </option>
                  ))}
                </select>
              </label>
            ) : null}

            <div className="gvg-date-grid">
              <label>
                Starts
                <input
                  type="datetime-local"
                  value={gvgDraft.startsAt}
                  onChange={(event) => updateGvgDraft('startsAt', event.target.value)}
                  disabled={gvgLoading || Boolean(activeAction)}
                />
              </label>
              <label>
                Ends
                <input
                  type="datetime-local"
                  value={gvgDraft.endsAt}
                  onChange={(event) => updateGvgDraft('endsAt', event.target.value)}
                  disabled={gvgLoading || Boolean(activeAction)}
                />
              </label>
            </div>

            <button
              type="button"
              className="primary-action"
              onClick={handleCreateGvgEvent}
              disabled={gvgLoading || Boolean(activeAction)}
            >
              {activeAction?.type === 'gvg-create' ? 'Creating...' : 'Create draft event'}
            </button>
          </section>

          {gvgLoading ? <p className="muted-line">Loading GvG events...</p> : null}

          {!gvgLoading && gvgEvents.length === 0 ? (
            <section className="panel hero-panel">
              <StatusBadge>Empty</StatusBadge>
              <h3>No manageable GvG events</h3>
              <p>Create a draft event, then activate it when members should vote.</p>
            </section>
          ) : null}

          {gvgEvents.length > 0 ? (
            <section className="panel gvg-results-panel" aria-label="GvG results">
              <label>
                Event
                <select
                  value={selectedGvgEventId}
                  onChange={(event) => handleSelectGvgEvent(event.target.value)}
                  disabled={gvgLoading || Boolean(activeAction)}
                >
                  {gvgEvents.map((event) => (
                    <option key={event.id} value={event.id}>
                      {event.title} · {event.status}
                    </option>
                  ))}
                </select>
              </label>

              {selectedGvgEvent ? (
                <>
                  <div className="approval-meta" aria-label="Selected GvG event details">
                    <div>
                      <span>Status</span>
                      <strong>{selectedGvgEvent.status}</strong>
                    </div>
                    <div>
                      <span>Scope</span>
                      <strong>
                        {selectedGvgEvent.scope === 'global'
                          ? 'Global'
                          : selectedGvgEvent.guild?.name ?? 'Guild'}
                      </strong>
                    </div>
                    <div>
                      <span>Starts</span>
                      <strong>{formatDate(selectedGvgEvent.starts_at)}</strong>
                    </div>
                    <div>
                      <span>Updated</span>
                      <strong>{formatDate(selectedGvgEvent.updated_at)}</strong>
                    </div>
                  </div>

                  <div className="member-action-row">
                    <button
                      type="button"
                      className="primary-action"
                      onClick={() => handleSetGvgStatus(selectedGvgEvent.id, 'active')}
                      disabled={Boolean(activeAction) || selectedGvgEvent.status === 'active'}
                    >
                      {activeAction?.id === selectedGvgEvent.id && activeAction?.type === 'gvg-active'
                        ? 'Opening...'
                        : 'Open voting'}
                    </button>
                    <button
                      type="button"
                      className="danger-action"
                      onClick={() => handleSetGvgStatus(selectedGvgEvent.id, 'closed')}
                      disabled={Boolean(activeAction) || selectedGvgEvent.status === 'closed'}
                    >
                      {activeAction?.id === selectedGvgEvent.id && activeAction?.type === 'gvg-closed'
                        ? 'Closing...'
                        : 'Close voting'}
                    </button>
                  </div>

                  <div className="gvg-summary-grid">
                    <article>
                      <span>Present</span>
                      <strong>{gvgSummary.present.length}</strong>
                    </article>
                    <article>
                      <span>Absent</span>
                      <strong>{gvgSummary.absent.length}</strong>
                    </article>
                  </div>

                  <div className="gvg-results-grid">
                    <section>
                      <h4>Present list</h4>
                      {gvgSummary.present.length === 0 ? (
                        <p className="muted-line">No present votes yet.</p>
                      ) : (
                        gvgSummary.present.map((vote) => (
                          <article className="gvg-vote-row" key={vote.profile_id}>
                            <strong>{vote.ign ?? 'Unknown IGN'}</strong>
                            <span>@{vote.username ?? 'unknown'}</span>
                          </article>
                        ))
                      )}
                    </section>

                    <section>
                      <h4>Absent list</h4>
                      {gvgSummary.absent.length === 0 ? (
                        <p className="muted-line">No absent votes yet.</p>
                      ) : (
                        gvgSummary.absent.map((vote) => (
                          <article className="gvg-vote-row" key={vote.profile_id}>
                            <strong>{vote.ign ?? 'Unknown IGN'}</strong>
                            <span>@{vote.username ?? 'unknown'}</span>
                            {vote.absence_reason ? <p>{vote.absence_reason}</p> : null}
                          </article>
                        ))
                      )}
                    </section>
                  </div>
                </>
              ) : null}
            </section>
          ) : null}
        </section>
      ) : null}

      {!canViewAuditSection && membership?.role === 'admin' && !permissionLoading ? (
        <section className="panel hero-panel audit-access-panel">
          <StatusBadge tone="danger">Audit access unavailable</StatusBadge>
          <h3>Not authorized to view audit logs.</h3>
          <p>Admins need view_audit_logs for scoped audit access.</p>
        </section>
      ) : null}

      {canViewAuditSection ? (
        <section className="audit-management" aria-label="Audit logs">
          <div className="panel audit-management-tools">
            <div className="section-heading-row">
              <div>
                <StatusBadge tone="warning">Audit</StatusBadge>
                <h3>Audit logs</h3>
              </div>
              <button
                type="button"
                className="secondary-action compact-action"
                onClick={() => loadAuditLogPage({ append: false })}
                disabled={auditLoading}
              >
                {auditLoading ? 'Loading...' : 'Refresh'}
              </button>
            </div>

            <div className="audit-filter-grid">
              <label>
                Action
                <select
                  value={auditFilters.action}
                  onChange={(event) => updateAuditFilter('action', event.target.value)}
                  disabled={auditLoading}
                >
                  {AUDIT_ACTION_OPTIONS.map((actionOption) => (
                    <option key={actionOption.value} value={actionOption.value}>
                      {actionOption.label}
                    </option>
                  ))}
                </select>
              </label>

              {auditGuildOptions.length > 0 ? (
                <label>
                  Guild
                  <select
                    value={auditFilters.guildId}
                    onChange={(event) => updateAuditFilter('guildId', event.target.value)}
                    disabled={auditLoading || auditGuildOptions.length <= 1}
                  >
                    <option value="all">
                      {membership?.role === 'owner' ? 'All/global logs' : 'All allowed logs'}
                    </option>
                    {auditGuildOptions.map((guildOption) => (
                      <option key={guildOption.id} value={guildOption.id}>
                        {guildOption.name}
                      </option>
                    ))}
                  </select>
                </label>
              ) : null}

              <label>
                Date from
                <input
                  type="date"
                  value={auditFilters.dateFrom}
                  onChange={(event) => updateAuditFilter('dateFrom', event.target.value)}
                  disabled={auditLoading}
                />
              </label>

              <label>
                Date to
                <input
                  type="date"
                  value={auditFilters.dateTo}
                  onChange={(event) => updateAuditFilter('dateTo', event.target.value)}
                  disabled={auditLoading}
                />
              </label>

              <label>
                Limit
                <select
                  value={auditFilters.limit}
                  onChange={(event) => updateAuditFilter('limit', event.target.value)}
                  disabled={auditLoading}
                >
                  <option value={25}>25</option>
                  <option value={50}>50</option>
                  <option value={100}>100</option>
                </select>
              </label>
            </div>
          </div>

          {auditLoading && auditLogs.length === 0 ? <p className="muted-line">Loading audit logs...</p> : null}

          {auditNotAuthorized ? (
            <section className="panel hero-panel audit-access-panel">
              <StatusBadge tone="danger">Restricted</StatusBadge>
              <h3>Not authorized to view audit logs.</h3>
              <p>The backend rejected this audit log request.</p>
            </section>
          ) : null}

          {auditError ? <p className="error-line">{auditError}</p> : null}

          {!auditLoading && !auditError && !auditNotAuthorized && auditLogs.length === 0 ? (
            <section className="panel hero-panel">
              <StatusBadge>Empty</StatusBadge>
              <h3>No audit logs found</h3>
              <p>Try another action, guild, date range, or limit.</p>
            </section>
          ) : null}

          <div className="audit-card-list">
            {auditLogs.map((row) => {
              const metadataItems = formatAuditMetadata(row.metadata, row.metadata_redacted);
              const targetDisplay = formatAuditTarget(row);
              const entityDisplay = formatAuditEntity(row);

              return (
                <article className="panel audit-card" key={row.id}>
                  <div className="approval-card-header">
                    <div>
                      <h4>{formatAuditAction(row.action)}</h4>
                      <p>{row.action}</p>
                    </div>
                    <StatusBadge tone={row.metadata_redacted ? 'warning' : 'success'}>Read-only</StatusBadge>
                  </div>

                  <div className="approval-meta audit-meta" aria-label="Audit log details">
                    <div>
                      <span>Timestamp</span>
                      <strong>{formatDate(row.created_at)}</strong>
                    </div>
                    <div>
                      <span>Actor</span>
                      <strong>{formatAuditActor(row)}</strong>
                    </div>
                    {targetDisplay ? (
                      <div>
                        <span>Target</span>
                        <strong>{targetDisplay}</strong>
                      </div>
                    ) : null}
                    <div>
                      <span>Guild</span>
                      <strong>{formatAuditGuild(row)}</strong>
                    </div>
                    {entityDisplay ? (
                      <div>
                        <span>Entity</span>
                        <strong>{entityDisplay}</strong>
                      </div>
                    ) : null}
                  </div>

                  {row.metadata_redacted ? (
                    <p className="member-warning">Sensitive CP metadata hidden.</p>
                  ) : null}

                  {metadataItems.length > 0 ? (
                    <div className="audit-metadata-list" aria-label="Audit metadata summary">
                      {metadataItems.map((item) => (
                        <div key={item.key}>
                          <span>{item.label}</span>
                          <strong>{item.value}</strong>
                        </div>
                      ))}
                    </div>
                  ) : row.metadata_redacted ? null : (
                    <p className="muted-line">No displayable metadata.</p>
                  )}
                </article>
              );
            })}
          </div>

          {auditLogs.length > 0 ? (
            <div className="audit-load-row">
              <button
                type="button"
                className="secondary-action"
                onClick={() => loadAuditLogPage({ append: true, before: oldestAuditCreatedAt })}
                disabled={auditLoading || !oldestAuditCreatedAt}
              >
                {auditLoading ? 'Loading older...' : 'Load older'}
              </button>
            </div>
          ) : null}
        </section>
      ) : null}

      {!canViewMembers && !permissionLoading ? (
        <section className="panel hero-panel">
          <StatusBadge tone="danger">Member management unavailable</StatusBadge>
          <h3>No member-management permission</h3>
          <p>
            Owners, Leaders, Vice members, and Admins with manage_members, edit_member_ign, or
            reset_profile_slug can view this roster.
          </p>
        </section>
      ) : null}

      {canViewMembers ? (
        <section className="member-management" aria-label="Member management">
          <div className="panel member-management-tools">
            <div className="section-heading-row">
              <div>
                <StatusBadge tone="success">Members</StatusBadge>
                <h3>Active roster</h3>
              </div>
              <button type="button" className="secondary-action compact-action" onClick={() => loadAdminData()} disabled={memberLoading}>
                {memberLoading ? 'Loading...' : 'Refresh'}
              </button>
            </div>

            <div className="member-filter-grid">
              <label>
                Search
                <input
                  type="search"
                  value={memberSearch}
                  placeholder="Username, IGN, guild"
                  onChange={(event) => setMemberSearch(event.target.value)}
                />
              </label>
              <label>
                Guild
                <select value={guildFilter} onChange={(event) => setGuildFilter(event.target.value)}>
                  <option value="all">All visible guilds</option>
                  {guildOptions.map((guild) => (
                    <option key={guild.id} value={guild.id}>
                      {guild.name}
                    </option>
                  ))}
                </select>
              </label>
            </div>
          </div>

          {memberLoading ? <p className="muted-line">Loading active roster...</p> : null}

          {!memberLoading && filteredMembers.length === 0 ? (
            <section className="panel hero-panel">
              <StatusBadge>Roster empty</StatusBadge>
              <h3>No active approved members found</h3>
              <p>Only active memberships with approved profiles are shown here.</p>
            </section>
          ) : null}

          <div className="member-card-list">
            {filteredMembers.map((item) => {
              const isEditingIgn = activeAction?.id === item.id && activeAction.type === 'edit-ign';
              const isResettingSlug = activeAction?.id === item.id && activeAction.type === 'reset-slug';
              const isAssigningRole = activeAction?.id === item.id && activeAction.type === 'assign-role';
              const isTransferringGuild = activeAction?.id === item.id && activeAction.type === 'transfer-guild';
              const isConfirmingRole = confirmAction?.id === item.id && confirmAction.type === 'assign-role';
              const isConfirmingTransfer = confirmAction?.id === item.id && confirmAction.type === 'transfer-guild';
              const actionDisabled = Boolean(activeAction);
              const draft = memberDrafts[item.id] ?? {
                ign: item.profile?.ign ?? '',
                role: item.role ?? 'member',
                slug: item.profile?.profile_slug ?? item.profile?.username ?? '',
                targetGuildId: '',
              };
              const transferGuildOptions = activeGuildOptions.filter((guild) => guild.id !== item.guild_id);
              const selectedTargetGuild = transferGuildOptions.find((guild) => guild.id === draft.targetGuildId);
              const roleCanBeChanged = canManageRoles && item.role !== 'owner' && allowedMemberRoles.length > 0;
              const roleSelectValue = allowedMemberRoles.includes(draft.role)
                ? draft.role
                : allowedMemberRoles[0] ?? 'member';

              return (
                <article className="panel member-card" key={item.id}>
                  <div className="approval-card-header">
                    <div>
                      <h4>{item.profile?.ign ?? 'Unknown IGN'}</h4>
                      <p>@{item.profile?.username ?? 'unknown'}</p>
                    </div>
                    <StatusBadge tone={statusTone(item.membership_status)}>
                      {item.membership_status}
                    </StatusBadge>
                  </div>

                  <div className="approval-meta" aria-label="Member details">
                    <div>
                      <span>Guild</span>
                      <strong>{item.guild?.name ?? 'Unknown guild'}</strong>
                    </div>
                    <div>
                      <span>Role</span>
                      <strong>{formatRole(item.role)}</strong>
                    </div>
                    <div>
                      <span>Profile status</span>
                      <strong>{item.profile?.approval_status ?? 'unknown'}</strong>
                    </div>
                    <div>
                      <span>Updated</span>
                      <strong>{formatDate(item.profile?.updated_at ?? item.updated_at)}</strong>
                    </div>
                  </div>

                  {canEditIgn || canResetSlug ? (
                    <div className="member-edit-grid">
                      {canEditIgn ? (
                        <div className="member-edit-block">
                          <label>
                            IGN
                            <input
                              type="text"
                              value={draft.ign}
                              onChange={(event) => updateMemberDraft(item.id, 'ign', event.target.value)}
                              disabled={actionDisabled}
                            />
                          </label>
                          <button
                            type="button"
                            className="primary-action"
                            onClick={() => handleSaveMemberIgn(item)}
                            disabled={actionDisabled}
                          >
                            {isEditingIgn ? 'Saving IGN...' : 'Save IGN'}
                          </button>
                        </div>
                      ) : null}

                      {canResetSlug ? (
                        <div className="member-edit-block">
                          <label>
                            Username / profile slug
                            <input
                              type="text"
                              value={draft.slug}
                              onChange={(event) => updateMemberDraft(item.id, 'slug', event.target.value)}
                              disabled={actionDisabled}
                            />
                          </label>
                          <button
                            type="button"
                            className="danger-action"
                            onClick={() => handleResetMemberSlug(item)}
                            disabled={actionDisabled}
                          >
                            {isResettingSlug ? 'Resetting...' : 'Reset slug'}
                          </button>
                        </div>
                      ) : null}
                    </div>
                  ) : (
                    <p className="muted-line">Roster visibility only. No edit action is available for this permission set.</p>
                  )}

                  {canManageRoles || canTransferGuilds ? (
                    <div className="member-admin-actions">
                      {canManageRoles ? (
                        <div className="member-edit-block">
                          <div>
                            <h4>Role management</h4>
                            <p className="muted-copy">
                              Owner assignment is manual-only and is never available here.
                            </p>
                          </div>

                          {item.role === 'owner' ? (
                            <p className="muted-line">Owner role changes are manual-only.</p>
                          ) : (
                            <>
                              <label>
                                New role
                                <select
                                  value={roleSelectValue}
                                  onChange={(event) => updateMemberDraft(item.id, 'role', event.target.value)}
                                  disabled={actionDisabled || !roleCanBeChanged}
                                >
                                  {allowedMemberRoles.map((role) => (
                                    <option key={role} value={role}>
                                      {formatRole(role)}
                                    </option>
                                  ))}
                                </select>
                              </label>

                              {isConfirmingRole ? (
                                <p className="member-warning">
                                  Confirm role change from {formatRole(item.role)} to {formatRole(roleSelectValue)}.
                                </p>
                              ) : null}

                              <div className="member-action-row">
                                {isConfirmingRole ? (
                                  <>
                                    <button
                                      type="button"
                                      className="primary-action"
                                      onClick={() => handleAssignMemberRole(item)}
                                      disabled={actionDisabled}
                                    >
                                      {isAssigningRole ? 'Saving role...' : 'Confirm role'}
                                    </button>
                                    <button
                                      type="button"
                                      className="secondary-action"
                                      onClick={() => setConfirmAction(null)}
                                      disabled={actionDisabled}
                                    >
                                      Cancel
                                    </button>
                                  </>
                                ) : (
                                  <button
                                    type="button"
                                    className="primary-action"
                                    onClick={() => setConfirmAction({ id: item.id, type: 'assign-role' })}
                                    disabled={actionDisabled || !roleCanBeChanged || roleSelectValue === item.role}
                                  >
                                    Review role change
                                  </button>
                                )}
                              </div>
                            </>
                          )}
                        </div>
                      ) : null}

                      {canTransferGuilds ? (
                        <div className="member-edit-block">
                          <div>
                            <h4>Guild transfer</h4>
                            <p className="muted-copy">Owner-only. Moving guild resets this member's role to Member.</p>
                          </div>

                          <label>
                            Target guild
                            <select
                              value={draft.targetGuildId}
                              onChange={(event) => updateMemberDraft(item.id, 'targetGuildId', event.target.value)}
                              disabled={actionDisabled || transferGuildOptions.length === 0}
                            >
                              <option value="">Select active guild</option>
                              {transferGuildOptions.map((guild) => (
                                <option key={guild.id} value={guild.id}>
                                  {guild.name}
                                </option>
                              ))}
                            </select>
                          </label>

                          <p className="member-warning">Moving guild resets this member's role to Member.</p>

                          {isConfirmingTransfer ? (
                            <p className="muted-line">
                              Confirm transfer from {item.guild?.name ?? 'current guild'} to{' '}
                              {selectedTargetGuild?.name ?? 'selected guild'}.
                            </p>
                          ) : null}

                          <div className="member-action-row">
                            {isConfirmingTransfer ? (
                              <>
                                <button
                                  type="button"
                                  className="danger-action"
                                  onClick={() => handleTransferMemberGuild(item)}
                                  disabled={actionDisabled}
                                >
                                  {isTransferringGuild ? 'Transferring...' : 'Confirm transfer'}
                                </button>
                                <button
                                  type="button"
                                  className="secondary-action"
                                  onClick={() => setConfirmAction(null)}
                                  disabled={actionDisabled}
                                >
                                  Cancel
                                </button>
                              </>
                            ) : (
                              <button
                                type="button"
                                className="danger-action"
                                onClick={() => setConfirmAction({ id: item.id, type: 'transfer-guild' })}
                                disabled={actionDisabled || !draft.targetGuildId || draft.targetGuildId === item.guild_id}
                              >
                                Review transfer
                              </button>
                            )}
                          </div>
                        </div>
                      ) : null}
                    </div>
                  ) : null}
                </article>
              );
            })}
          </div>
        </section>
      ) : null}

      {canManagePermissions ? (
        <section className="permission-management" aria-label="Admin permission management">
          <div className="panel permission-management-tools">
            <div className="section-heading-row">
              <div>
                <StatusBadge tone="warning">Permissions</StatusBadge>
                <h3>Admin permissions</h3>
              </div>
              <button
                type="button"
                className="secondary-action compact-action"
                onClick={async () => {
                  setAdminPermissionLoading(true);
                  setAdminError('');
                  setActionMessage('');
                  try {
                    await loadPermissionManagementSection();
                  } catch (permissionError) {
                    setAdminError(permissionError.message);
                  } finally {
                    setAdminPermissionLoading(false);
                  }
                }}
                disabled={adminPermissionLoading || Boolean(activeAction)}
              >
                {adminPermissionLoading ? 'Loading...' : 'Refresh'}
              </button>
            </div>

            <p className="muted-line">
              Permission checkboxes apply only to active Admin memberships. CP permissions are Owner-only.
            </p>
          </div>

          {adminPermissionLoading ? <p className="muted-line">Loading Admin permission targets...</p> : null}

          {!adminPermissionLoading && adminPermissionTargets.length === 0 ? (
            <section className="panel hero-panel">
              <StatusBadge>Empty</StatusBadge>
              <h3>No active Admin memberships found</h3>
              <p>Only approved active Admin memberships in your allowed scope appear here.</p>
            </section>
          ) : null}

          <div className="permission-card-list">
            {adminPermissionTargets.map((target) => {
              const draft = adminPermissionDrafts[target.id] ?? {};
              const actionDisabled = Boolean(activeAction);
              const isSavingPermissions = activeAction?.id === target.id && activeAction.type === 'save-permissions';
              const hasChanges = hasPermissionDraftChanges({
                catalog: permissionCatalog,
                target,
                draft,
                membership,
              });
              const cpPermissionLocked = ['leader', 'vice'].includes(membership?.role);

              return (
                <article className="panel permission-card" key={target.id}>
                  <div className="approval-card-header">
                    <div>
                      <h4>{target.profile?.ign ?? 'Unknown IGN'}</h4>
                      <p>@{target.profile?.username ?? 'unknown'}</p>
                    </div>
                    <StatusBadge tone="success">Admin</StatusBadge>
                  </div>

                  <div className="approval-meta" aria-label="Admin permission target details">
                    <div>
                      <span>Guild</span>
                      <strong>{target.guild?.name ?? 'Unknown guild'}</strong>
                    </div>
                    <div>
                      <span>Membership</span>
                      <strong>{target.membership_status}</strong>
                    </div>
                    <div>
                      <span>Profile status</span>
                      <strong>{target.profile?.approval_status ?? 'unknown'}</strong>
                    </div>
                  </div>

                  {cpPermissionLocked ? (
                    <p className="member-warning">CP permissions are Owner-only.</p>
                  ) : null}

                  <div className="permission-checkbox-grid">
                    {permissionCatalog.map((permission) => {
                      const canToggle = canToggleAdminPermission({
                        membership,
                        permissionKey: permission.key,
                      });
                      const checked = Boolean(draft[permission.key]);
                      const sensitive = isSensitivePermissionKey(permission.key);
                      const cpPermission = isCpPermissionKey(permission.key);

                      return (
                        <label className="permission-checkbox" key={permission.key}>
                          <span className="permission-checkbox-control">
                            <input
                              type="checkbox"
                              checked={checked}
                              onChange={(event) =>
                                updateAdminPermissionDraft(target.id, permission.key, event.target.checked)
                              }
                              disabled={actionDisabled || !canToggle}
                            />
                            <span>
                              {permission.label ?? permission.key}
                              {sensitive ? <em>Sensitive</em> : null}
                            </span>
                          </span>
                          <small>
                            {cpPermission && !canToggle
                              ? 'CP permissions are Owner-only.'
                              : permission.description ?? permission.key}
                          </small>
                        </label>
                      );
                    })}
                  </div>

                  <div className="member-action-row">
                    <button
                      type="button"
                      className="primary-action"
                      onClick={() => handleSaveAdminPermissions(target)}
                      disabled={actionDisabled || !hasChanges}
                    >
                      {isSavingPermissions ? 'Saving permissions...' : 'Save permissions'}
                    </button>
                    <button
                      type="button"
                      className="secondary-action"
                      onClick={() => resetAdminPermissionDraft(target)}
                      disabled={actionDisabled || !hasChanges}
                    >
                      Cancel
                    </button>
                  </div>
                </article>
              );
            })}
          </div>
        </section>
      ) : null}

      {canViewCpSection ? (
        <section className="cp-management" aria-label="CP management">
          <div className="panel cp-management-tools">
            <div className="section-heading-row">
              <div>
                <StatusBadge tone="success">CP</StatusBadge>
                <h3>CP management</h3>
              </div>
              <button type="button" className="secondary-action compact-action" onClick={() => loadAdminData()} disabled={cpLoading}>
                {cpLoading ? 'Loading...' : 'Refresh'}
              </button>
            </div>

            <div className="member-filter-grid">
              <label>
                Search
                <input
                  type="search"
                  value={cpSearch}
                  placeholder="Username, IGN, guild"
                  onChange={(event) => setCpSearch(event.target.value)}
                />
              </label>
              <label>
                Guild
                <select
                  value={selectedCpGuildId}
                  onChange={(event) => setSelectedCpGuildId(event.target.value)}
                  disabled={cpLoading || cpGuildOptions.length <= 1}
                >
                  {cpGuildOptions.length === 0 ? <option value="">No CP guild scope</option> : null}
                  {cpGuildOptions.map((guild) => (
                    <option key={guild.id} value={guild.id}>
                      {guild.name}
                    </option>
                  ))}
                </select>
              </label>
            </div>
          </div>

          {cpLoading ? <p className="muted-line">Loading CP roster...</p> : null}

          {!cpLoading && selectedCpGuildId && filteredCpRoster.length === 0 ? (
            <section className="panel hero-panel">
              <StatusBadge>CP roster empty</StatusBadge>
              <h3>No CP rows found</h3>
              <p>Active approved members for the selected guild will appear here, including missing CP entries.</p>
            </section>
          ) : null}

          {!cpLoading && !selectedCpGuildId ? (
            <section className="panel hero-panel">
              <StatusBadge tone="warning">No guild scope</StatusBadge>
              <h3>CP scope unavailable</h3>
              <p>Choose an active guild scope before loading CP data.</p>
            </section>
          ) : null}

          <div className="cp-card-list">
            {filteredCpRoster.map((item) => {
              const isUpdatingCp = activeAction?.id === item.profile_id && activeAction.type === 'update-cp';
              const draftValue = cpDrafts[item.profile_id] ?? '';
              const originalValue = item.cp_value === null || item.cp_value === undefined ? '' : String(item.cp_value);
              const cpChanged = draftValue.trim() !== originalValue;
              const actionDisabled = Boolean(activeAction);

              return (
                <article className="panel cp-card" key={item.profile_id}>
                  <div className="approval-card-header">
                    <div>
                      <h4>{item.ign ?? 'Unknown IGN'}</h4>
                      <p>@{item.username ?? 'unknown'}</p>
                    </div>
                    <StatusBadge tone={item.cp_value === null || item.cp_value === undefined ? 'warning' : 'success'}>
                      {formatCpValue(item.cp_value)}
                    </StatusBadge>
                  </div>

                  <div className="approval-meta" aria-label="CP member details">
                    <div>
                      <span>Guild</span>
                      <strong>{selectedCpGuild?.name ?? 'Selected guild'}</strong>
                    </div>
                    <div>
                      <span>Current CP</span>
                      <strong>{formatCpValue(item.cp_value)}</strong>
                    </div>
                    <div>
                      <span>Updated</span>
                      <strong>{formatDate(item.updated_at)}</strong>
                    </div>
                  </div>

                  {canUpdateCpValues ? (
                    <div className="cp-edit-row">
                      <label>
                        CP value
                        <input
                          type="text"
                          inputMode="numeric"
                          pattern="[0-9]*"
                          value={draftValue}
                          placeholder="Not entered"
                          onChange={(event) => updateCpDraft(item.profile_id, event.target.value)}
                          disabled={actionDisabled}
                        />
                      </label>
                      <div className="member-action-row">
                        <button
                          type="button"
                          className="primary-action"
                          onClick={() => handleUpdateCp(item)}
                          disabled={actionDisabled || !cpChanged}
                        >
                          {isUpdatingCp ? 'Saving CP...' : 'Save CP'}
                        </button>
                        <button
                          type="button"
                          className="secondary-action"
                          onClick={() => resetCpDraft(item)}
                          disabled={actionDisabled || !cpChanged}
                        >
                          Cancel
                        </button>
                      </div>
                    </div>
                  ) : (
                    <p className="muted-line">Read-only CP access. Update permission is required to edit CP.</p>
                  )}
                </article>
              );
            })}
          </div>

          <section className="panel cp-leaderboard" aria-label="CP leaderboard">
            <div className="section-heading-row">
              <div>
                <StatusBadge tone="success">Leaderboard</StatusBadge>
                <h3>CP leaderboard</h3>
              </div>
              <p className="muted-copy">{selectedCpGuild?.name ?? 'Selected guild'}</p>
            </div>

            {cpLeaderboard.length === 0 ? (
              <p className="muted-line">No ranked CP entries yet.</p>
            ) : (
              <div className="cp-leaderboard-list">
                {cpLeaderboard.map((item) => (
                  <article className="cp-leaderboard-row" key={item.profile_id}>
                    <strong>#{item.leaderboard_rank}</strong>
                    <div>
                      <h4>{item.ign ?? 'Unknown IGN'}</h4>
                      <p>@{item.username ?? 'unknown'} · {selectedCpGuild?.name ?? 'Selected guild'}</p>
                    </div>
                    <span>{formatCpValue(item.cp_value)}</span>
                  </article>
                ))}
              </div>
            )}
          </section>
        </section>
      ) : null}

      <section className="panel admin-list" aria-label="Planned admin modules">
        {plannedSections.map((section) => (
          <article key={section}>
            <div>
              <h4>{section}</h4>
              <p>Planned for a later approved milestone.</p>
            </div>
            <StatusBadge>Planned</StatusBadge>
          </article>
        ))}
      </section>
    </div>
  );
}
