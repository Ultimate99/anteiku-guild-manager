import React, { useEffect, useMemo, useState } from 'react';
import { AdminAnalyticsSection } from '../components/admin/AdminAnalyticsSection.jsx';
import { AdminApprovalsSection } from '../components/admin/AdminApprovalsSection.jsx';
import { AdminCpLeaderboardSection } from '../components/admin/AdminCpLeaderboardSection.jsx';
import { AdminAuditSection } from '../components/admin/AdminAuditSection.jsx';
import { AdminCpSection } from '../components/admin/AdminCpSection.jsx';
import { AdminGvgSection } from '../components/admin/AdminGvgSection.jsx';
import { AdminMembersSection } from '../components/admin/AdminMembersSection.jsx';
import { AdminPermissionsSection } from '../components/admin/AdminPermissionsSection.jsx';
import { AdminTabs } from '../components/admin/AdminTabs.jsx';
import { AdminToolsSection } from '../components/admin/AdminToolsSection.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
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
  loadAdminCpRankings,
  loadCpGuildOptions,
  loadCurrentCpRoster,
  updateMemberCp,
} from '../services/adminCpService.js';
import {
  closeCpUpdateWindow,
  loadCpUpdateWindowForGuild,
  openCpUpdateWindow,
} from '../services/cpWindowService.js';
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
  ROSTER_STATUS_OPTIONS,
  canAssignMemberRole,
  canEditMemberIgn,
  canResetMemberSlug,
  canTransferMemberGuild,
  canUpdateMemberRosterStatus,
  canViewMemberManagement,
  formatRosterStatus,
  getAllowedRosterStatusOptions,
  getAllowedMemberRoleOptions,
  isHardBlockedRosterStatus,
  isValidProfileSlug,
  loadActiveGuildOptions,
  loadMemberRoster,
  normalizeProfileSlug,
  rosterStatusTone,
  transferMemberGuild,
  updateMemberRosterStatus,
} from '../services/adminMemberService.js';

const ADMIN_TABS = [
  { id: 'overview', label: 'Overview', labelKey: 'admin.tabs.overview' },
  { id: 'analytics', label: 'Analytics', labelKey: 'admin.tabs.analytics' },
  { id: 'approvals', label: 'Approvals', labelKey: 'admin.tabs.approvals' },
  { id: 'members', label: 'Members', labelKey: 'admin.tabs.members' },
  { id: 'cp', label: 'CP', labelKey: 'admin.tabs.cp' },
  { id: 'cpLeaderboard', label: 'CP Ranking', labelKey: 'admin.tabs.cpLeaderboard' },
  { id: 'gvg', label: 'GvG', labelKey: 'admin.tabs.gvg' },
  { id: 'audit', label: 'Audit Logs', labelKey: 'admin.tabs.audit' },
  { id: 'permissions', label: 'Permissions', labelKey: 'admin.tabs.permissions' },
  { id: 'tools', label: 'Tools', labelKey: 'admin.tabs.tools' },
];

function translateWithFallback(t, key, fallback, params) {
  const translated = t(key, params);
  return translated === key ? fallback : translated;
}

function formatDate(value, language = 'en', notRecordedLabel = 'Not recorded') {
  if (!value) {
    return notRecordedLabel;
  }

  return new Intl.DateTimeFormat(language, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

function formatRole(role) {
  return role ? role.charAt(0).toUpperCase() + role.slice(1) : 'Member';
}

function formatLocalizedRole(t, role) {
  return translateWithFallback(t, `roles.${role}`, formatRole(role));
}

function formatLocalizedRosterStatus(t, status) {
  return translateWithFallback(t, `roster.status.${status}.label`, formatRosterStatus(status));
}

function formatLocalizedApprovalStatus(t, status) {
  return translateWithFallback(t, `approvalStatus.${status}`, status ?? t('common.unknown'));
}

function formatLocalizedMembershipStatus(t, status) {
  return translateWithFallback(t, `admin.membershipStatus.${status}`, status ?? t('common.unknown'));
}

function formatLocalizedGvgStatus(t, status) {
  return translateWithFallback(t, `admin.gvg.status.${status}`, status ?? t('common.unknown'));
}

function humanizeAdminCopy(value) {
  return String(value ?? '')
    .replaceAll('Profile slug', 'Username')
    .replaceAll('profile slug', 'username')
    .replaceAll('Username/Username', 'Username')
    .replaceAll('username/username', 'username')
    .replaceAll('reset_profile_slug', 'reset username');
}

function translateRosterStatusOptions(t, options) {
  return options.map((option) => ({
    ...option,
    label: formatLocalizedRosterStatus(t, option.value),
    summary: translateWithFallback(t, `roster.status.${option.value}.summary`, option.summary),
  }));
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
      rosterStatus: item.roster_status ?? 'active',
      statusReason: '',
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

function buildScopedCpGuildOptions({ membership, allGuilds = [], assignedGuildLabel = 'Assigned guild' }) {
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
      name: membership.guild?.name ?? membership.guild_name ?? assignedGuildLabel,
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

function appendGuildOption(map, guild, unknownGuildLabel = 'Unknown guild') {
  if (guild?.id && !map.has(guild.id)) {
    map.set(guild.id, {
      id: guild.id,
      name: guild.name ?? unknownGuildLabel,
      slug: guild.slug ?? '',
    });
  }
}

function buildAuditGuildOptions({
  membership,
  guild,
  guildOptions = [],
  activeGuildOptions = [],
  cpGuildOptions = [],
  gvgGuildOptions = [],
  assignedGuildLabel = 'Assigned guild',
  unknownGuildLabel = 'Unknown guild',
}) {
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
        name: guild?.name ?? assignedGuildLabel,
        slug: guild?.slug ?? '',
      },
    ];
  }

  const guildMap = new Map();
  appendGuildOption(guildMap, guild, unknownGuildLabel);
  guildOptions.forEach((guildOption) => appendGuildOption(guildMap, guildOption, unknownGuildLabel));
  activeGuildOptions.forEach((guildOption) => appendGuildOption(guildMap, guildOption, unknownGuildLabel));
  cpGuildOptions.forEach((guildOption) => appendGuildOption(guildMap, guildOption, unknownGuildLabel));
  gvgGuildOptions.forEach((guildOption) => appendGuildOption(guildMap, guildOption, unknownGuildLabel));

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

function formatAuditGuild(row, t) {
  if (row.guild_name) {
    return row.guild_slug ? `${row.guild_name} (${row.guild_slug})` : row.guild_name;
  }

  if (row.guild_id) {
    return `${t('admin.common.guild')} ${String(row.guild_id).slice(0, 8)}`;
  }

  return t('admin.common.global');
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
  const { language, t } = useLanguage();
  const { membership, guild } = useAuth();
  const [permissionKeys, setPermissionKeys] = useState([]);
  const [permissionLoading, setPermissionLoading] = useState(true);
  const [loadedTabs, setLoadedTabs] = useState({});
  const [activeTab, setActiveTab] = useState('overview');
  const [queue, setQueue] = useState([]);
  const [memberRoster, setMemberRoster] = useState([]);
  const [approvalLoading, setApprovalLoading] = useState(false);
  const [memberLoading, setMemberLoading] = useState(false);
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
  const [memberStatusFilter, setMemberStatusFilter] = useState('all');
  const [activeGuildOptions, setActiveGuildOptions] = useState([]);
  const [cpGuildOptions, setCpGuildOptions] = useState([]);
  const [selectedCpGuildId, setSelectedCpGuildId] = useState('');
  const [cpRoster, setCpRoster] = useState([]);
  const [cpLeaderboard, setCpLeaderboard] = useState([]);
  const [cpLeaderboardScope, setCpLeaderboardScope] = useState('guild');
  const [cpLeaderboardError, setCpLeaderboardError] = useState('');
  const [cpDrafts, setCpDrafts] = useState({});
  const [cpSearch, setCpSearch] = useState('');
  const [cpLoading, setCpLoading] = useState(false);
  const [cpWindow, setCpWindow] = useState(null);
  const [cpWindowNote, setCpWindowNote] = useState('');
  const [auditLogs, setAuditLogs] = useState([]);
  const [auditFilters, setAuditFilters] = useState(() => getDefaultAuditFilters());
  const [auditLoading, setAuditLoading] = useState(false);
  const [auditError, setAuditError] = useState('');
  const [auditNotAuthorized, setAuditNotAuthorized] = useState(false);
  const [analyticsRefreshSignal, setAnalyticsRefreshSignal] = useState(0);
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
  const canManageRosterStatuses = canUpdateMemberRosterStatus({ membership, permissionKeys });
  const canViewCpSection = canViewCp({ membership, permissionKeys });
  const canUpdateCpValues = canUpdateCp({ membership, permissionKeys });
  const canViewGlobalCpLeaderboard = membership?.role === 'owner';
  const canViewAuditSection = canViewAuditLogs({ membership, permissionKeys });
  const canViewAnalyticsMemberData = canViewMembers || canReviewQueue;
  const canViewAnalyticsSection =
    canViewAnalyticsMemberData || canViewCpSection || canManageGvgEvents || canViewAuditSection;
  const allowedMemberRoles = useMemo(
    () => getAllowedMemberRoleOptions({ membership, permissionKeys }),
    [membership, permissionKeys],
  );
  const selectedCpGuild = useMemo(
    () => cpGuildOptions.find((guildOption) => guildOption.id === selectedCpGuildId) ?? null,
    [cpGuildOptions, selectedCpGuildId],
  );
  const plannedSections = useMemo(() => [t('admin.tools.guildManagement')], [t]);
  const formatAdminDate = (value) => formatDate(value, language, t('admin.common.notRecorded'));
  const formatAdminRole = (role) => formatLocalizedRole(t, role);
  const formatAdminRosterStatus = (status) => formatLocalizedRosterStatus(t, status);
  const formatAdminApprovalStatus = (status) => formatLocalizedApprovalStatus(t, status);
  const formatAdminMembershipStatus = (status) => formatLocalizedMembershipStatus(t, status);
  const formatAdminGvgStatus = (status) => formatLocalizedGvgStatus(t, status);
  const visibleRosterStatusOptions = useMemo(() => translateRosterStatusOptions(t, ROSTER_STATUS_OPTIONS), [t]);
  const translatedAuditActionOptions = useMemo(
    () =>
      AUDIT_ACTION_OPTIONS.map((actionOption) => ({
        ...actionOption,
        label: translateWithFallback(t, `admin.audit.actions.${actionOption.value}`, actionOption.label),
      })),
    [t],
  );
  const formatLocalizedAuditAction = (action) =>
    translateWithFallback(t, `admin.audit.actions.${action}`, formatAuditAction(action));
  const formatLocalizedAuditMetadata = (metadata, metadataRedacted) =>
    formatAuditMetadata(metadata, metadataRedacted).map((item) => ({
      ...item,
      label: translateWithFallback(t, `admin.audit.metadata.${item.key}`, item.label),
    }));
  const formatPermissionLabel = (permission) =>
    translateWithFallback(
      t,
      `admin.permissions.catalog.${permission.key}.label`,
      humanizeAdminCopy(permission.label ?? permission.key),
    );
  const formatPermissionDescription = (permission) =>
    translateWithFallback(
      t,
      `admin.permissions.catalog.${permission.key}.description`,
      humanizeAdminCopy(permission.description ?? permission.key),
    );

  const filteredCpRoster = useMemo(() => {
    const normalizedSearch = cpSearch.trim().toLowerCase();

    if (!normalizedSearch) {
      return cpRoster;
    }

    return cpRoster.filter((item) => {
      const searchableText = [item.username, item.ign, selectedCpGuild?.name, selectedCpGuild?.slug]
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
        guilds.set(item.guild.id, item.guild.name ?? t('admin.common.unknownGuild'));
      }
    });

    return Array.from(guilds, ([id, name]) => ({ id, name })).sort((a, b) => a.name.localeCompare(b.name));
  }, [memberRoster, t]);

  const filteredMembers = useMemo(() => {
    const normalizedSearch = memberSearch.trim().toLowerCase();

    return memberRoster.filter((item) => {
      const matchesGuild = guildFilter === 'all' || item.guild_id === guildFilter;
      const matchesRosterStatus =
        memberStatusFilter === 'all' || (item.roster_status ?? 'active') === memberStatusFilter;

      if (!matchesGuild || !matchesRosterStatus) {
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
        item.roster_status,
      ]
        .filter(Boolean)
        .join(' ')
        .toLowerCase();

      return searchableText.includes(normalizedSearch);
    });
  }, [guildFilter, memberRoster, memberSearch, memberStatusFilter]);

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
        assignedGuildLabel: t('admin.common.assignedGuild'),
        unknownGuildLabel: t('admin.common.unknownGuild'),
      }),
    [activeGuildOptions, cpGuildOptions, guild, guildOptions, gvgGuildOptions, membership, t],
  );
  const oldestAuditCreatedAt = auditLogs[auditLogs.length - 1]?.created_at ?? null;

  const visibleTabs = useMemo(() => {
    if (!canViewAdmin) {
      return [];
    }

    return ADMIN_TABS.filter((tab) => {
      if (tab.id === 'overview') {
        return true;
      }
      if (tab.id === 'analytics') {
        return canViewAnalyticsSection;
      }
      if (tab.id === 'approvals') {
        return canReviewQueue;
      }
      if (tab.id === 'members') {
        return canViewMembers;
      }
      if (tab.id === 'cp') {
        return canViewCpSection;
      }
      if (tab.id === 'cpLeaderboard') {
        return canViewCpSection;
      }
      if (tab.id === 'gvg') {
        return canManageGvgEvents;
      }
      if (tab.id === 'audit') {
        return canViewAuditSection;
      }
      if (tab.id === 'permissions') {
        return canManagePermissions;
      }
      return tab.id === 'tools';
    }).map((tab) => ({
      ...tab,
      label: tab.labelKey ? t(tab.labelKey) : tab.label,
    }));
  }, [
    canManageGvgEvents,
    canManagePermissions,
    canReviewQueue,
    canViewAnalyticsSection,
    canViewAdmin,
    canViewAuditSection,
    canViewCpSection,
    canViewMembers,
    t,
  ]);

  const activeTabMeta = visibleTabs.find((tab) => tab.id === activeTab) ?? null;
  const adminOverviewCards = useMemo(() => {
    const cardCopy = {
      approvals: {
        badge: t('admin.overview.approvalsBadge'),
        title: t('admin.tabs.approvals'),
        body: t('admin.overview.approvalsBody'),
        tone: 'warning',
      },
      analytics: {
        badge: t('admin.overview.analyticsBadge'),
        title: t('admin.tabs.analytics'),
        body: t('admin.overview.analyticsBody'),
        tone: 'crimson',
      },
      members: {
        badge: t('admin.overview.membersBadge'),
        title: t('admin.tabs.members'),
        body: t('admin.overview.membersBody'),
        tone: 'success',
      },
      cp: {
        badge: t('admin.overview.cpBadge'),
        title: t('admin.tabs.cp'),
        body: t('admin.overview.cpBody'),
        tone: 'success',
      },
      cpLeaderboard: {
        badge: t('admin.overview.cpLeaderboardBadge'),
        title: t('admin.tabs.cpLeaderboard'),
        body: t('admin.overview.cpLeaderboardBody'),
        tone: 'success',
      },
      gvg: {
        badge: t('admin.overview.gvgBadge'),
        title: t('admin.tabs.gvg'),
        body: t('admin.overview.gvgBody'),
        tone: 'warning',
      },
      audit: {
        badge: t('admin.overview.auditBadge'),
        title: t('admin.tabs.audit'),
        body: t('admin.overview.auditBody'),
        tone: 'warning',
      },
      permissions: {
        badge: t('admin.overview.permissionsBadge'),
        title: t('admin.tabs.permissions'),
        body: t('admin.overview.permissionsBody'),
        tone: 'danger',
      },
      tools: {
        badge: t('admin.overview.toolsBadge'),
        title: membership?.role === 'owner' ? t('admin.overview.ownerTools') : t('admin.tabs.tools'),
        body: t('admin.overview.toolsBody'),
        tone: 'danger',
      },
    };

    return visibleTabs
      .filter((tab) => tab.id !== 'overview')
      .filter((tab) => tab.id !== 'tools' || membership?.role === 'owner')
      .map((tab) => ({
        id: tab.id,
        ...cardCopy[tab.id],
      }))
      .filter((card) => card.title);
  }, [membership?.role, t, visibleTabs]);
  const currentTabLoading =
    (activeTab === 'approvals' && approvalLoading) ||
    (activeTab === 'members' && memberLoading) ||
    (activeTab === 'cp' && cpLoading) ||
    (activeTab === 'cpLeaderboard' && cpLoading) ||
    (activeTab === 'gvg' && gvgLoading) ||
    (activeTab === 'audit' && auditLoading) ||
    (activeTab === 'permissions' && adminPermissionLoading);

  useEffect(() => {
    let cancelled = false;

    async function loadPermissionKeys() {
      setPermissionLoading(true);
      setAdminError('');
      setActionMessage('');
      setLoadedTabs({});
      clearAdminData();

      if (!canViewAdmin) {
        setPermissionKeys([]);
        setPermissionLoading(false);
        return;
      }

      try {
        const nextPermissionKeys =
          membership?.role === 'admin' ? await getOwnAdminPermissionKeys(membership?.id) : [];

        if (!cancelled) {
          setPermissionKeys(nextPermissionKeys);
        }
      } catch (permissionError) {
        if (!cancelled) {
          setPermissionKeys([]);
          setAdminError(permissionError.message);
        }
      } finally {
        if (!cancelled) {
          setPermissionLoading(false);
        }
      }
    }

    loadPermissionKeys();

    return () => {
      cancelled = true;
    };
  }, [canViewAdmin, membership?.id, membership?.role]);

  useEffect(() => {
    if (permissionLoading || visibleTabs.length === 0) {
      return;
    }

    if (!activeTabMeta) {
      setActiveTab(visibleTabs[0].id);
    }
  }, [activeTabMeta, permissionLoading, visibleTabs]);

  useEffect(() => {
    if (permissionLoading || !activeTabMeta || loadedTabs[activeTab]) {
      return;
    }

    loadTabData(activeTab, { clearMessage: false });
  }, [activeTab, activeTabMeta, loadedTabs, permissionLoading]);

  function clearAdminData() {
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
    setCpLeaderboardScope('guild');
    setCpLeaderboardError('');
    setCpDrafts({});
    setCpWindow(null);
    setCpWindowNote('');
    setMemberDrafts({});
    setMemberStatusFilter('all');
    setAuditLogs([]);
    setAuditError('');
    setAuditNotAuthorized(false);
    setAnalyticsRefreshSignal(0);
    setConfirmAction(null);
  }

  function markTabLoaded(tabId) {
    setLoadedTabs((current) => ({
      ...current,
      [tabId]: true,
    }));
  }

  async function loadTabData(tabId, { force = false, clearMessage = true } = {}) {
    if (!force && loadedTabs[tabId]) {
      return;
    }

    if (tabId === 'approvals') {
      await loadApprovalsSection({ clearMessage });
    } else if (tabId === 'members') {
      await loadMembersSection({ clearMessage });
    } else if (tabId === 'cp') {
      await loadCpSection({ clearMessage });
    } else if (tabId === 'cpLeaderboard') {
      await loadCpSection({ clearMessage, loadedTabId: 'cpLeaderboard' });
    } else if (tabId === 'gvg') {
      await loadGvgSection({ clearMessage });
    } else if (tabId === 'audit') {
      await loadAuditLogPage({ append: false, clearMessage });
    } else if (tabId === 'permissions') {
      await loadPermissionManagementSection({ clearMessage });
    } else if (tabId === 'analytics') {
      if (force) {
        setAnalyticsRefreshSignal((current) => current + 1);
      }
      markTabLoaded('analytics');
    } else if (tabId === 'overview') {
      markTabLoaded('overview');
    } else {
      markTabLoaded('tools');
    }
  }

  async function loadApprovalsSection({ clearMessage = true } = {}) {
    if (!canReviewQueue) {
      setQueue([]);
      markTabLoaded('approvals');
      return;
    }

    setApprovalLoading(true);
    setAdminError('');
    if (clearMessage) {
      setActionMessage('');
    }

    try {
      const nextQueue = await loadApprovalQueue();
      setQueue(nextQueue);
      setSelectedRoles((current) => {
        const nextRoles = {};

        nextQueue.forEach((item) => {
          nextRoles[item.id] = current[item.id] ?? allowedRoles[0] ?? 'member';
        });

        return nextRoles;
      });
    } catch (approvalError) {
      setQueue([]);
      setAdminError(approvalError.message);
    } finally {
      markTabLoaded('approvals');
      setApprovalLoading(false);
    }
  }

  async function loadMembersSection({ clearMessage = true } = {}) {
    if (!canViewMembers) {
      setMemberRoster([]);
      setActiveGuildOptions([]);
      setMemberDrafts({});
      setGuildFilter('all');
      setMemberStatusFilter('all');
      markTabLoaded('members');
      return;
    }

    setMemberLoading(true);
    setAdminError('');
    if (clearMessage) {
      setActionMessage('');
    }

    try {
      const nextRoster = await loadMemberRoster();
      const nextActiveGuildOptions = canTransferMemberGuild({ membership }) ? await loadActiveGuildOptions() : [];

      setMemberRoster(nextRoster);
      setActiveGuildOptions(nextActiveGuildOptions);
      setMemberDrafts(buildMemberDrafts(nextRoster));
      setGuildFilter((current) =>
        current === 'all' || nextRoster.some((item) => item.guild_id === current) ? current : 'all',
      );
      setMemberStatusFilter((current) =>
        current === 'all' || nextRoster.some((item) => (item.roster_status ?? 'active') === current) ? current : 'all',
      );
    } catch (memberError) {
      setMemberRoster([]);
      setActiveGuildOptions([]);
      setMemberDrafts({});
      setMemberStatusFilter('all');
      setAdminError(memberError.message);
    } finally {
      markTabLoaded('members');
      setMemberLoading(false);
    }
  }

  async function loadCpDataForGuild(guildId, { leaderboardScope = cpLeaderboardScope } = {}) {
    if (!guildId) {
      setCpRoster([]);
      setCpLeaderboard([]);
      setCpLeaderboardScope('guild');
      setCpLeaderboardError('');
      setCpDrafts({});
      setCpWindow(null);
      return;
    }

    const nextLeaderboardScope =
      leaderboardScope === 'global' && canViewGlobalCpLeaderboard ? 'global' : 'guild';
    const [nextCpRoster, nextCpLeaderboard, nextCpWindow] = await Promise.all([
      loadCurrentCpRoster({ guildId }),
      loadAdminCpRankings({ guildId, scope: nextLeaderboardScope }),
      loadCpUpdateWindowForGuild({ guildId }),
    ]);

    setCpRoster(nextCpRoster);
    setCpLeaderboard(nextCpLeaderboard);
    setCpLeaderboardScope(nextLeaderboardScope);
    setCpLeaderboardError('');
    setCpDrafts(buildCpDrafts(nextCpRoster));
    setCpWindow(nextCpWindow);
  }

  async function loadCpSection({ clearMessage = true, loadedTabId = 'cp' } = {}) {
    if (!canViewCpSection) {
      setCpGuildOptions([]);
      setSelectedCpGuildId('');
      setCpRoster([]);
      setCpLeaderboard([]);
      setCpLeaderboardScope('guild');
      setCpLeaderboardError('');
      setCpDrafts({});
      setCpWindow(null);
      markTabLoaded(loadedTabId);
      return;
    }

    setCpLoading(true);
    setAdminError('');
    if (clearMessage) {
      setActionMessage('');
    }

    try {
      const allCpGuilds = membership?.role === 'owner' ? await loadCpGuildOptions() : [];
      const nextCpGuildOptions = buildScopedCpGuildOptions({
        membership,
        allGuilds: allCpGuilds,
        assignedGuildLabel: t('admin.common.assignedGuild'),
      });
      const nextSelectedCpGuildId =
        nextCpGuildOptions.find((guildOption) => guildOption.id === selectedCpGuildId)?.id ??
        nextCpGuildOptions[0]?.id ??
        '';

      setCpGuildOptions(nextCpGuildOptions);
      setSelectedCpGuildId(nextSelectedCpGuildId);
      await loadCpDataForGuild(nextSelectedCpGuildId);
    } catch (cpError) {
      setCpGuildOptions([]);
      setCpRoster([]);
      setCpLeaderboard([]);
      setCpLeaderboardError('');
      setCpDrafts({});
      setCpWindow(null);
      setAdminError(cpError.message);
    } finally {
      markTabLoaded(loadedTabId);
      setCpLoading(false);
    }
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
      guildId: nextGvgGuildOptions.find((guildOption) => guildOption.id === current.guildId)?.id ?? nextGvgGuildOptions[0]?.id ?? '',
    }));
  }

  async function loadGvgSection({ clearMessage = true, preferredEventId = selectedGvgEventId } = {}) {
    if (!canManageGvgEvents) {
      setGvgEvents([]);
      setGvgResults([]);
      setGvgGuildOptions([]);
      setSelectedGvgEventId('');
      markTabLoaded('gvg');
      return;
    }

    setGvgLoading(true);
    setAdminError('');
    if (clearMessage) {
      setActionMessage('');
    }

    try {
      await loadGvgManagementSection({ preferredEventId });
    } catch (gvgError) {
      setGvgEvents([]);
      setGvgResults([]);
      setGvgGuildOptions([]);
      setSelectedGvgEventId('');
      setAdminError(gvgError.message);
    } finally {
      markTabLoaded('gvg');
      setGvgLoading(false);
    }
  }

  async function loadPermissionManagementSection({ clearMessage = true } = {}) {
    if (!canManagePermissions) {
      setPermissionCatalog([]);
      setAdminPermissionTargets([]);
      setAdminPermissionDrafts({});
      markTabLoaded('permissions');
      return;
    }

    setAdminPermissionLoading(true);
    setAdminError('');
    if (clearMessage) {
      setActionMessage('');
    }

    try {
      const nextPermissionData = await loadAdminPermissionManagementData();
      setPermissionCatalog(nextPermissionData.catalog);
      setAdminPermissionTargets(nextPermissionData.targets);
      setAdminPermissionDrafts(buildAdminPermissionDrafts(nextPermissionData.targets));
    } catch (permissionError) {
      setPermissionCatalog([]);
      setAdminPermissionTargets([]);
      setAdminPermissionDrafts({});
      setAdminError(permissionError.message);
    } finally {
      markTabLoaded('permissions');
      setAdminPermissionLoading(false);
    }
  }

  async function loadAuditLogPage({ append = false, before = null, clearMessage = true } = {}) {
    if (!canViewAuditSection) {
      setAuditLogs([]);
      setAuditError('');
      setAuditNotAuthorized(false);
      markTabLoaded('audit');
      return;
    }

    setAuditLoading(true);
    setAuditError('');
    setAuditNotAuthorized(false);
    if (clearMessage) {
      setActionMessage('');
    }

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
      markTabLoaded('audit');
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
      setAdminError(t('admin.errors.selectedApprovalRole'));
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
      setActionMessage(
        t('admin.success.approvedUser', {
          username: item.profile?.username ?? t('admin.common.unknownMember'),
          role: formatAdminRole(role),
        }),
      );
      await loadApprovalsSection({ clearMessage: false });
    } catch (approvalError) {
      setAdminError(approvalError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleReject(item) {
    const reason = rejectReasons[item.id]?.trim() ?? '';

    if (reason.length > 1000) {
      setAdminError(t('admin.errors.rejectionReasonTooLong'));
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
      setActionMessage(
        t('admin.success.rejectedUser', {
          username: item.profile?.username ?? t('admin.common.unknownMember'),
        }),
      );
      setRejectReasons((current) => ({ ...current, [item.id]: '' }));
      await loadApprovalsSection({ clearMessage: false });
    } catch (approvalError) {
      setAdminError(approvalError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleSaveMemberIgn(item) {
    const nextIgn = memberDrafts[item.id]?.ign?.trim() ?? '';

    if (!nextIgn) {
      setAdminError(t('admin.errors.ignRequired'));
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
      setActionMessage(
        t('admin.success.updatedIgn', {
          username: item.profile?.username ?? t('admin.common.unknownMember'),
        }),
      );
      await loadMembersSection({ clearMessage: false });
    } catch (memberError) {
      setAdminError(memberError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleResetMemberSlug(item) {
    const nextSlug = normalizeProfileSlug(memberDrafts[item.id]?.slug ?? '');

    if (!isValidProfileSlug(nextSlug)) {
      setAdminError(t('admin.errors.invalidUsername'));
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
      setActionMessage(
        t('admin.success.resetUsername', {
          username: item.profile?.username ?? t('admin.common.unknownMember'),
        }),
      );
      await loadMembersSection({ clearMessage: false });
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
      setAdminError(t('admin.errors.ownerRoleUnavailable'));
      return;
    }

    if (!allowedMemberRoles.includes(nextRole)) {
      setAdminError(t('admin.errors.selectedRoleNotAllowed'));
      return;
    }

    if (nextRole === item.role) {
      setAdminError(t('admin.errors.chooseDifferentRole'));
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
      setActionMessage(
        t('admin.success.updatedRole', {
          username: item.profile?.username ?? t('admin.common.unknownMember'),
          role: formatAdminRole(nextRole),
        }),
      );
      setConfirmAction(null);
      await loadMembersSection({ clearMessage: false });
    } catch (memberError) {
      setAdminError(memberError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleTransferMemberGuild(item) {
    const targetGuildId = memberDrafts[item.id]?.targetGuildId ?? '';
    const targetGuild = activeGuildOptions.find((guildOption) => guildOption.id === targetGuildId);

    if (!canTransferGuilds) {
      setAdminError(t('admin.errors.ownerTransferRequired'));
      return;
    }

    if (!targetGuildId || targetGuildId === item.guild_id) {
      setAdminError(t('admin.errors.chooseDifferentGuild'));
      return;
    }

    if (!targetGuild) {
      setAdminError(t('admin.errors.targetGuildUnavailable'));
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
        t('admin.success.transferredGuild', {
          username: item.profile?.username ?? t('admin.common.unknownMember'),
          guild: targetGuild.name ?? t('admin.common.selectedGuildLower'),
        }),
      );
      setConfirmAction(null);
      await loadMembersSection({ clearMessage: false });
    } catch (memberError) {
      setAdminError(memberError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleUpdateMemberRosterStatus(item) {
    const currentStatus = item.roster_status ?? 'active';
    const draftedStatus = memberDrafts[item.id]?.rosterStatus ?? currentStatus;
    const reason = memberDrafts[item.id]?.statusReason?.trim() ?? '';
    const allowedStatusOptions = getAllowedRosterStatusOptions({
      membership,
      permissionKeys,
      targetMembership: item,
    });
    const allowedStatuses = allowedStatusOptions.map((option) => option.value);

    if (!allowedStatuses.includes(draftedStatus)) {
      setAdminError(t('admin.errors.rosterStatusNotAllowed'));
      return;
    }

    if (draftedStatus === currentStatus) {
      setAdminError(t('admin.errors.chooseDifferentRosterStatus'));
      return;
    }

    if (isHardBlockedRosterStatus(draftedStatus) && !reason) {
      setAdminError(t('admin.errors.hardBlockReasonRequired'));
      return;
    }

    setActiveAction({ id: item.id, type: 'roster-status' });
    setAdminError('');
    setActionMessage('');

    try {
      await updateMemberRosterStatus({
        membershipId: item.id,
        status: draftedStatus,
        reason,
      });
      setActionMessage(
        t('admin.success.updatedRosterStatus', {
          username: item.profile?.username ?? t('admin.common.unknownMember'),
          status: formatAdminRosterStatus(draftedStatus),
        }),
      );
      setConfirmAction(null);
      await loadMembersSection({ clearMessage: false });
    } catch (memberError) {
      setAdminError(memberError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleUpdateCp(item) {
    const rawCpValue = cpDrafts[item.profile_id]?.trim() ?? '';

    if (!isValidCpInput(rawCpValue)) {
      setAdminError(t('admin.errors.invalidCp'));
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
      setActionMessage(
        t('admin.success.updatedCp', {
          username: item.username ?? t('admin.common.unknownMember'),
        }),
      );
      await loadCpSection({ clearMessage: false });
    } catch (cpError) {
      setAdminError(cpError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleSelectCpGuild(guildId) {
    setSelectedCpGuildId(guildId);
    setCpLoading(true);
    setAdminError('');
    setActionMessage('');

    try {
      await loadCpDataForGuild(guildId);
      markTabLoaded('cp');
    } catch (cpError) {
      setCpRoster([]);
      setCpLeaderboard([]);
      setCpLeaderboardError('');
      setCpDrafts({});
      setCpWindow(null);
      setAdminError(cpError.message);
    } finally {
      setCpLoading(false);
    }
  }

  async function handleSelectCpLeaderboardScope(scope) {
    const nextScope = scope === 'global' && canViewGlobalCpLeaderboard ? 'global' : 'guild';

    if (scope === 'global' && !canViewGlobalCpLeaderboard) {
      setCpLeaderboardError(t('admin.cp.globalOwnerOnly'));
      return;
    }

    setCpLeaderboardScope(nextScope);
    setCpLoading(true);
    setAdminError('');
    setActionMessage('');

    try {
      await loadCpDataForGuild(selectedCpGuildId, { leaderboardScope: nextScope });
      markTabLoaded('cpLeaderboard');
    } catch (cpError) {
      setCpLeaderboard([]);
      setCpLeaderboardError(cpError.message || t('admin.cp.loadRankingsError'));
    } finally {
      setCpLoading(false);
    }
  }

  async function handleOpenCpWindow() {
    if (!selectedCpGuildId) {
      setAdminError(t('admin.common.chooseGuild'));
      return;
    }

    setActiveAction({ id: selectedCpGuildId, type: 'open-cp-window' });
    setAdminError('');
    setActionMessage('');

    try {
      await openCpUpdateWindow({
        guildId: selectedCpGuildId,
        note: cpWindowNote,
      });
      setCpWindowNote('');
      setActionMessage(t('admin.cp.windowOpened'));
      await loadCpDataForGuild(selectedCpGuildId);
      markTabLoaded('cp');
    } catch (cpError) {
      setAdminError(cpError.message);
    } finally {
      setActiveAction(null);
    }
  }

  async function handleCloseCpWindow() {
    if (!cpWindow?.id || cpWindow.status !== 'open') {
      setAdminError(t('admin.cp.noOpenWindow'));
      return;
    }

    setActiveAction({ id: cpWindow.id, type: 'close-cp-window' });
    setAdminError('');
    setActionMessage('');

    try {
      await closeCpUpdateWindow({ windowId: cpWindow.id });
      setActionMessage(t('admin.cp.windowClosedSuccess'));
      await loadCpDataForGuild(selectedCpGuildId);
      markTabLoaded('cp');
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
        t('admin.success.updatedPermissions', {
          username: target.profile?.username ?? t('admin.common.unknownAdmin'),
          granted: result.granted,
          revoked: result.revoked,
        }),
      );
      await loadPermissionManagementSection({ clearMessage: false });
    } catch (permissionError) {
      setAdminError(permissionError.message);
      await loadPermissionManagementSection({ clearMessage: false });
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
      setAdminError(t('admin.errors.gvgTitleRequired'));
      return;
    }

    if (scope === 'guild' && !gvgDraft.guildId) {
      setAdminError(t('admin.errors.gvgGuildRequired'));
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
      setActionMessage(t('admin.success.createdGvgEvent', { title: newEvent.title }));
      setGvgDraft((current) => ({ ...current, title: '', startsAt: '', endsAt: '' }));
      await loadGvgManagementSection({ preferredEventId: newEvent.id });
      markTabLoaded('gvg');
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
      setActionMessage(
        t('admin.success.updatedGvgStatus', {
          title: updatedEvent.title,
          status: formatAdminGvgStatus(updatedEvent.status),
        }),
      );
      await loadGvgManagementSection({ preferredEventId: eventId });
      markTabLoaded('gvg');
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

  function updateSelectedRole(itemId, value) {
    setSelectedRoles((current) => ({ ...current, [itemId]: value }));
  }

  function updateRejectReason(itemId, value) {
    setRejectReasons((current) => ({ ...current, [itemId]: value }));
  }

  function renderActiveSection() {
    if (permissionLoading) {
      return null;
    }

    if (activeTab === 'approvals' && canReviewQueue) {
      return (
        <AdminApprovalsSection
          queue={queue}
          allowedRoles={allowedRoles}
          selectedRoles={selectedRoles}
          rejectReasons={rejectReasons}
          approvalLoading={approvalLoading}
          activeAction={activeAction}
          onRefresh={() => loadTabData('approvals', { force: true })}
          onRoleChange={updateSelectedRole}
          onRejectReasonChange={updateRejectReason}
          onApprove={handleApprove}
          onReject={handleReject}
          formatDate={formatAdminDate}
          formatRole={formatAdminRole}
          formatMembershipStatus={formatAdminMembershipStatus}
          formatApprovalStatus={formatAdminApprovalStatus}
          statusTone={statusTone}
          t={t}
        />
      );
    }

    if (activeTab === 'overview') {
      return (
        <section className="admin-overview admin-section" aria-label={t('admin.overview.aria')}>
          <div className="panel admin-overview-panel">
            <div className="section-heading-row admin-section-heading">
              <div>
                <StatusBadge tone="success">{t('admin.overview.badge')}</StatusBadge>
                <h3>{t('admin.overview.title')}</h3>
                <p>{t('admin.overview.body')}</p>
              </div>
            </div>

            {adminOverviewCards.length > 0 ? (
              <div className="admin-command-grid">
                {adminOverviewCards.map((card) => (
                  <button
                    key={card.id}
                    type="button"
                    className="command-card admin-command-card"
                    onClick={() => setActiveTab(card.id)}
                  >
                    <StatusBadge tone={card.tone}>{card.badge}</StatusBadge>
                    <strong>{card.title}</strong>
                    <small>{card.body}</small>
                  </button>
                ))}
              </div>
            ) : (
              <section className="panel compact-empty-state">
                <StatusBadge>{t('admin.common.readOnly')}</StatusBadge>
                <h3>{t('admin.overview.noShortcuts')}</h3>
              </section>
            )}
          </div>
        </section>
      );
    }

    if (activeTab === 'members' && canViewMembers) {
      return (
        <AdminMembersSection
          memberLoading={memberLoading}
          filteredMembers={filteredMembers}
          memberSearch={memberSearch}
          guildFilter={guildFilter}
          memberStatusFilter={memberStatusFilter}
          guildOptions={guildOptions}
          memberDrafts={memberDrafts}
          activeGuildOptions={activeGuildOptions}
          activeAction={activeAction}
          confirmAction={confirmAction}
          canEditIgn={canEditIgn}
          canResetSlug={canResetSlug}
          canManageRoles={canManageRoles}
          canTransferGuilds={canTransferGuilds}
          canManageRosterStatuses={canManageRosterStatuses}
          allowedMemberRoles={allowedMemberRoles}
          visibleRosterStatusOptions={visibleRosterStatusOptions}
          onRefresh={() => loadTabData('members', { force: true })}
          onSearchChange={setMemberSearch}
          onGuildFilterChange={setGuildFilter}
          onMemberStatusFilterChange={setMemberStatusFilter}
          onUpdateDraft={updateMemberDraft}
          onSetConfirmAction={setConfirmAction}
          onSaveIgn={handleSaveMemberIgn}
          onResetSlug={handleResetMemberSlug}
          onAssignRole={handleAssignMemberRole}
          onTransferGuild={handleTransferMemberGuild}
          onUpdateRosterStatus={handleUpdateMemberRosterStatus}
          formatDate={formatAdminDate}
          formatRole={formatAdminRole}
          formatRosterStatus={formatAdminRosterStatus}
          formatMembershipStatus={formatAdminMembershipStatus}
          formatApprovalStatus={formatAdminApprovalStatus}
          getAllowedRosterStatusOptions={(item) =>
            translateRosterStatusOptions(
              t,
              getAllowedRosterStatusOptions({ membership, permissionKeys, targetMembership: item }),
            )
          }
          rosterStatusTone={rosterStatusTone}
          statusTone={statusTone}
          t={t}
        />
      );
    }

    if (activeTab === 'analytics') {
      return (
        <AdminAnalyticsSection
          membership={membership}
          canViewMemberAnalytics={canViewAnalyticsMemberData}
          canViewCpAnalytics={canViewCpSection}
          canViewGvgAnalytics={canManageGvgEvents}
          refreshSignal={analyticsRefreshSignal}
          formatDate={formatAdminDate}
          formatCpValue={formatCpValue}
          t={t}
        />
      );
    }

    if (activeTab === 'cp' && canViewCpSection) {
      return (
        <AdminCpSection
          cpLoading={cpLoading}
          cpSearch={cpSearch}
          selectedCpGuildId={selectedCpGuildId}
          cpGuildOptions={cpGuildOptions}
          selectedCpGuild={selectedCpGuild}
          filteredCpRoster={filteredCpRoster}
          cpDrafts={cpDrafts}
          cpWindow={cpWindow}
          cpWindowNote={cpWindowNote}
          activeAction={activeAction}
          canUpdateCpValues={canUpdateCpValues}
          onRefresh={() => loadTabData('cp', { force: true })}
          onSearchChange={setCpSearch}
          onSelectedGuildChange={handleSelectCpGuild}
          onUpdateCpDraft={updateCpDraft}
          onResetCpDraft={resetCpDraft}
          onUpdateCp={handleUpdateCp}
          onWindowNoteChange={setCpWindowNote}
          onOpenWindow={handleOpenCpWindow}
          onCloseWindow={handleCloseCpWindow}
          formatDate={formatAdminDate}
          formatCpValue={formatCpValue}
          t={t}
        />
      );
    }

    if (activeTab === 'cpLeaderboard' && canViewCpSection) {
      return (
        <AdminCpLeaderboardSection
          cpLoading={cpLoading}
          selectedCpGuild={selectedCpGuild}
          cpLeaderboard={cpLeaderboard}
          cpLeaderboardScope={cpLeaderboardScope}
          cpLeaderboardError={cpLeaderboardError}
          canViewGlobalCpLeaderboard={canViewGlobalCpLeaderboard}
          onRefresh={() => loadTabData('cpLeaderboard', { force: true })}
          onLeaderboardScopeChange={handleSelectCpLeaderboardScope}
          formatDate={formatAdminDate}
          formatCpValue={formatCpValue}
          t={t}
        />
      );
    }

    if (activeTab === 'gvg' && canManageGvgEvents) {
      return (
        <AdminGvgSection
          membership={membership}
          gvgLoading={gvgLoading}
          gvgEvents={gvgEvents}
          gvgSummary={gvgSummary}
          gvgGuildOptions={gvgGuildOptions}
          selectedGvgEventId={selectedGvgEventId}
          selectedGvgEvent={selectedGvgEvent}
          gvgDraft={gvgDraft}
          activeAction={activeAction}
          onRefresh={() => loadTabData('gvg', { force: true })}
          onUpdateDraft={updateGvgDraft}
          onCreateEvent={handleCreateGvgEvent}
          onSetStatus={handleSetGvgStatus}
          onSelectEvent={handleSelectGvgEvent}
          formatDate={formatAdminDate}
          formatGvgStatus={formatAdminGvgStatus}
          t={t}
        />
      );
    }

    if (activeTab === 'audit' && canViewAuditSection) {
      return (
        <AdminAuditSection
          membership={membership}
          auditActionOptions={translatedAuditActionOptions}
          auditLoading={auditLoading}
          auditLogs={auditLogs}
          auditFilters={auditFilters}
          auditGuildOptions={auditGuildOptions}
          auditError={auditError}
          auditNotAuthorized={auditNotAuthorized}
          oldestAuditCreatedAt={oldestAuditCreatedAt}
          onRefresh={() => loadAuditLogPage({ append: false })}
          onLoadOlder={() => loadAuditLogPage({ append: true, before: oldestAuditCreatedAt })}
          onUpdateFilter={updateAuditFilter}
          formatDate={formatAdminDate}
          formatAuditAction={formatLocalizedAuditAction}
          formatAuditActor={formatAuditActor}
          formatAuditMetadata={formatLocalizedAuditMetadata}
          formatAuditTarget={formatAuditTarget}
          formatAuditGuild={(row) => formatAuditGuild(row, t)}
          formatAuditEntity={formatAuditEntity}
          t={t}
        />
      );
    }

    if (activeTab === 'permissions' && canManagePermissions) {
      return (
        <AdminPermissionsSection
          membership={membership}
          adminPermissionLoading={adminPermissionLoading}
          permissionCatalog={permissionCatalog}
          adminPermissionTargets={adminPermissionTargets}
          adminPermissionDrafts={adminPermissionDrafts}
          activeAction={activeAction}
          onRefresh={() => loadTabData('permissions', { force: true })}
          onUpdateDraft={updateAdminPermissionDraft}
          onSavePermissions={handleSaveAdminPermissions}
          onResetDraft={resetAdminPermissionDraft}
          canToggleAdminPermission={canToggleAdminPermission}
          isSensitivePermissionKey={isSensitivePermissionKey}
          isCpPermissionKey={isCpPermissionKey}
          hasPermissionDraftChanges={hasPermissionDraftChanges}
          formatPermissionLabel={formatPermissionLabel}
          formatPermissionDescription={formatPermissionDescription}
          formatMembershipStatus={formatAdminMembershipStatus}
          formatApprovalStatus={formatAdminApprovalStatus}
          t={t}
        />
      );
    }

    return <AdminToolsSection membership={membership} plannedSections={plannedSections} t={t} />;
  }

  if (!canViewAdmin) {
    return (
      <div className="stack">
        <section className="panel hero-panel compact-empty-state">
          <StatusBadge tone="danger">{t('admin.common.restricted')}</StatusBadge>
          <h3>{t('admin.shell.accessUnavailable')}</h3>
          <p>{t('admin.shell.accessUnavailableBody')}</p>
        </section>
      </div>
    );
  }

  return (
    <div className="stack">
      <section className="panel hero-panel admin-hero-panel">
        <StatusBadge tone={visibleTabs.length > 1 ? 'success' : 'warning'}>{t('nav.admin')}</StatusBadge>
        <h3>{t('admin.shell.title')}</h3>
        <p>{t('admin.shell.selectSection')}</p>
        <button
          type="button"
          className="secondary-action compact-action admin-refresh-action"
          onClick={() => loadTabData(activeTab, { force: true })}
          disabled={permissionLoading || currentTabLoading}
        >
          {permissionLoading || currentTabLoading
            ? t('common.refreshing')
            : t('admin.shell.refreshTab', { tab: activeTabMeta?.label ?? t('admin.common.currentTab') })}
        </button>
      </section>

      {permissionLoading ? <p className="muted-line">{t('admin.shell.checkingPermissions')}</p> : null}
      {adminError ? <p className="error-line">{adminError}</p> : null}
      {actionMessage ? <p className="notice-line">{actionMessage}</p> : null}

      <AdminTabs tabs={visibleTabs} activeTab={activeTab} onChange={setActiveTab} />

      <div className="admin-tab-content">{renderActiveSection()}</div>
    </div>
  );
}
