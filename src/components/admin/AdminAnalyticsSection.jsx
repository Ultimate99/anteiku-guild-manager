import React, { useEffect, useMemo, useState } from 'react';
import { StatusBadge } from '../StatusBadge.jsx';
import {
  loadCpAnalytics,
  loadGvgAnalytics,
  loadLiveCpGrowth,
  loadMemberAnalytics,
  startNewCpGrowthPeriod,
} from '../../services/adminAnalyticsService.js';

const ANALYTICS_TABS = ['overview', 'members', 'cp', 'gvg', 'weeklyGrowth', 'attention'];
const CORE_GUILD_SCOPE_ORDER = ['anteiku', 'anteiku-re', 'anteiku-rose', 'anteiku-goat'];

function formatCompactNumber(value) {
  if (value === null || value === undefined) {
    return '-';
  }

  return Number(value).toLocaleString();
}

function formatPercent(value) {
  if (value === null || value === undefined) {
    return '-';
  }

  return `${Number(value).toLocaleString(undefined, { maximumFractionDigits: 2 })}%`;
}

function isPermissionError(error) {
  const message = String(error?.message ?? '').toLowerCase();
  return (
    error?.code?.includes('DENIED') ||
    message.includes('not authorized') ||
    message.includes('permission') ||
    message.includes('approved profile required')
  );
}

function formatWindowStatus(t, status) {
  if (status === 'open') {
    return t('admin.cp.windowOpen');
  }

  if (status === 'closed') {
    return t('admin.cp.windowClosed');
  }

  return status || t('admin.common.notRecorded');
}

function formatGvgStatus(t, status) {
  const translated = t(`admin.gvg.status.${status}`);
  return translated === `admin.gvg.status.${status}` ? status || t('admin.common.notRecorded') : translated;
}

function normalizeGuildOption(guild, fallbackName) {
  if (!guild?.id) {
    return null;
  }

  return {
    id: guild.id,
    name: guild.name ?? fallbackName,
    slug: guild.slug ?? '',
  };
}

function buildAnalyticsScopeOptions({ membership, currentGuild, guildOptions = [], t }) {
  if (!membership) {
    return [];
  }

  if (membership.role === 'owner') {
    const normalizedGuilds = guildOptions
      .map((guild) => normalizeGuildOption(guild, t('admin.common.unknownGuild')))
      .filter(Boolean)
      .sort((a, b) => {
        const aOrder = CORE_GUILD_SCOPE_ORDER.indexOf(a.slug);
        const bOrder = CORE_GUILD_SCOPE_ORDER.indexOf(b.slug);

        if (aOrder !== -1 || bOrder !== -1) {
          return (aOrder === -1 ? Number.MAX_SAFE_INTEGER : aOrder) - (bOrder === -1 ? Number.MAX_SAFE_INTEGER : bOrder);
        }

        return a.name.localeCompare(b.name);
      });

    return [
      {
        id: 'global',
        guildId: null,
        name: t('admin.analytics.globalScope'),
        scopeLabel: t('admin.analytics.globalScope'),
        isGlobal: true,
      },
      ...normalizedGuilds.map((guild) => ({
        id: guild.id,
        guildId: guild.id,
        name: guild.name,
        scopeLabel: guild.name,
        isGlobal: false,
      })),
    ];
  }

  const assignedGuild = normalizeGuildOption(
    {
      id: membership.guild_id,
      name: currentGuild?.name ?? membership.guild?.name ?? membership.guild_name,
      slug: currentGuild?.slug ?? membership.guild?.slug,
    },
    t('admin.common.assignedGuild'),
  );

  return assignedGuild
    ? [
        {
          id: assignedGuild.id,
          guildId: assignedGuild.id,
          name: assignedGuild.name,
          scopeLabel: assignedGuild.name,
          isGlobal: false,
        },
      ]
    : [];
}

function StatCard({ label, value, tone = 'neutral', helper }) {
  return (
    <article className="analytics-stat-card">
      <StatusBadge tone={tone}>{label}</StatusBadge>
      <strong>{value}</strong>
      {helper ? <span>{helper}</span> : null}
    </article>
  );
}

function LockedPanel({ title, body }) {
  return (
    <section className="analytics-locked-panel">
      <StatusBadge tone="warning">{title}</StatusBadge>
      <p>{body}</p>
    </section>
  );
}

function AnalyticsSubTabs({ activeTab, onChange, t }) {
  return (
    <div className="analytics-sub-tabs" role="tablist" aria-label={t('admin.analytics.title')}>
      {ANALYTICS_TABS.map((tabId) => (
        <button
          key={tabId}
          type="button"
          role="tab"
          aria-selected={activeTab === tabId}
          className="analytics-sub-tab"
          data-active={activeTab === tabId}
          onClick={() => onChange(tabId)}
        >
          {t(`admin.analytics.${tabId}`)}
        </button>
      ))}
    </div>
  );
}

function AnalyticsScopeSelector({ scopeOptions, selectedScopeId, selectedScope, onChange, t }) {
  if (scopeOptions.length === 0) {
    return (
      <section className="analytics-scope-panel">
        <StatusBadge tone="warning">{t('admin.analytics.scope')}</StatusBadge>
        <p>{t('admin.analytics.scopeDenied')}</p>
      </section>
    );
  }

  return (
    <section className="analytics-scope-panel" aria-label={t('admin.analytics.scope')}>
      <div>
        <StatusBadge tone="crimson">{t('admin.analytics.scope')}</StatusBadge>
        <strong>{t('admin.analytics.viewingScope', { scope: selectedScope?.scopeLabel ?? '-' })}</strong>
      </div>
      <div className="analytics-scope-options">
        {scopeOptions.map((scopeOption) => (
          <button
            key={scopeOption.id}
            type="button"
            className="analytics-scope-chip"
            data-active={selectedScopeId === scopeOption.id}
            onClick={() => onChange(scopeOption.id)}
            disabled={scopeOptions.length === 1}
          >
            {scopeOption.isGlobal ? t('admin.analytics.globalScope') : scopeOption.name}
          </button>
        ))}
      </div>
    </section>
  );
}

export function AdminAnalyticsSection({
  membership,
  currentGuild,
  guildOptions = [],
  canViewMemberAnalytics,
  canViewCpAnalytics,
  canViewGvgAnalytics,
  refreshSignal = 0,
  formatDate,
  formatCpValue,
  t,
}) {
  const [activeSubTab, setActiveSubTab] = useState('overview');
  const [memberAnalytics, setMemberAnalytics] = useState(null);
  const [cpAnalytics, setCpAnalytics] = useState(null);
  const [gvgAnalytics, setGvgAnalytics] = useState(null);
  const [liveGrowthReport, setLiveGrowthReport] = useState([]);
  const [loading, setLoading] = useState({});
  const [errors, setErrors] = useState({});
  const [snapshotMessage, setSnapshotMessage] = useState('');
  const [confirmStartWeek, setConfirmStartWeek] = useState(false);
  const [selectedScopeId, setSelectedScopeId] = useState('');
  const [selectedBaselineId, setSelectedBaselineId] = useState('');

  const scopeOptions = useMemo(
    () => buildAnalyticsScopeOptions({ membership, currentGuild, guildOptions, t }),
    [currentGuild, guildOptions, membership, t],
  );
  const selectedScope = useMemo(
    () => scopeOptions.find((scopeOption) => scopeOption.id === selectedScopeId) ?? scopeOptions[0] ?? null,
    [scopeOptions, selectedScopeId],
  );
  const guildId = selectedScope?.guildId ?? null;
  const selectedScopeLabel = selectedScope?.scopeLabel ?? t('admin.analytics.globalScope');
  const liveGrowthMeta = liveGrowthReport[0] ?? null;
  const hasWeeklyBaseline = Boolean(liveGrowthMeta?.hasBaseline);
  const growthRows = liveGrowthReport.filter((row) => row.rank !== null && row.profileId);
  const attentionCount =
    (memberAnalytics?.pendingApprovals ?? 0) +
    (memberAnalytics?.inactiveMembers ?? 0) +
    (memberAnalytics?.onBreakMembers ?? 0) +
    (memberAnalytics?.pendingTransferMembers ?? 0) +
    (memberAnalytics?.suspendedMembers ?? 0) +
    (canViewCpAnalytics ? cpAnalytics?.membersMissingCp ?? 0 : 0) +
    (canViewGvgAnalytics ? gvgAnalytics?.noVoteCount ?? 0 : 0);

  useEffect(() => {
    setSelectedScopeId((current) =>
      current && scopeOptions.some((scopeOption) => scopeOption.id === current) ? current : scopeOptions[0]?.id ?? '',
    );
  }, [scopeOptions]);

  useEffect(() => {
    setMemberAnalytics(null);
    setCpAnalytics(null);
    setGvgAnalytics(null);
    setLiveGrowthReport([]);
    setSnapshotMessage('');
    setConfirmStartWeek(false);
    setErrors({});
  }, [selectedScopeId]);

  useEffect(() => {
    if (!selectedScopeId || scopeOptions.length === 0) {
      return;
    }

    if (activeSubTab === 'overview') {
      void loadOverviewData();
    }

    if (activeSubTab === 'members') {
      void loadMemberData();
    }

    if (activeSubTab === 'cp') {
      void loadCpData();
    }

    if (activeSubTab === 'gvg') {
      void loadGvgData();
    }

    if (activeSubTab === 'weeklyGrowth') {
      void loadGrowthData();
    }

    if (activeSubTab === 'attention') {
      void loadAttentionData();
    }
  }, [
    activeSubTab,
    guildId,
    selectedScopeId,
    scopeOptions.length,
    canViewMemberAnalytics,
    canViewCpAnalytics,
    canViewGvgAnalytics,
    refreshSignal,
  ]);

  async function runLoader(key, loader) {
    setLoading((current) => ({ ...current, [key]: true }));
    setErrors((current) => ({ ...current, [key]: '' }));

    try {
      return await loader();
    } catch (error) {
      setErrors((current) => ({
        ...current,
        [key]: isPermissionError(error) ? 'permission' : error.message,
      }));
      return null;
    } finally {
      setLoading((current) => ({ ...current, [key]: false }));
    }
  }

  async function loadMemberData() {
    if (!canViewMemberAnalytics) {
      setErrors((current) => ({ ...current, members: 'permission' }));
      return null;
    }

    const nextMemberAnalytics = await runLoader('members', () => loadMemberAnalytics({ guildId }));
    if (nextMemberAnalytics) {
      setMemberAnalytics(nextMemberAnalytics);
    }
    return nextMemberAnalytics;
  }

  async function loadCpData() {
    if (!canViewCpAnalytics) {
      setErrors((current) => ({ ...current, cp: 'permission' }));
      setCpAnalytics(null);
      return null;
    }

    const nextCpAnalytics = await runLoader('cp', () => loadCpAnalytics({ guildId }));
    if (nextCpAnalytics) {
      setCpAnalytics(nextCpAnalytics);
    }
    return nextCpAnalytics;
  }

  async function loadGvgData() {
    if (!canViewGvgAnalytics) {
      setErrors((current) => ({ ...current, gvg: 'permission' }));
      setGvgAnalytics(null);
      return null;
    }

    const nextGvgAnalytics = await runLoader('gvg', () => loadGvgAnalytics({ guildId }));
    if (nextGvgAnalytics) {
      setGvgAnalytics(nextGvgAnalytics);
    }
    return nextGvgAnalytics;
  }

  async function loadGrowthData({ baselineBatchId = selectedBaselineId } = {}) {
    if (!canViewCpAnalytics) {
      setErrors((current) => ({ ...current, weeklyGrowth: 'permission' }));
      setLiveGrowthReport([]);
      return;
    }

    const nextGrowthReport = await runLoader('weeklyGrowth', () =>
      loadLiveCpGrowth({ guildId, baselineBatchId: baselineBatchId || null }),
    );

    if (nextGrowthReport) {
      setLiveGrowthReport(nextGrowthReport);
      const nextBaselineId = nextGrowthReport.find((row) => row.baselineBatchId)?.baselineBatchId ?? '';
      if (!baselineBatchId && !selectedBaselineId && nextBaselineId) {
        setSelectedBaselineId(nextBaselineId);
      }
    }
  }

  async function loadOverviewData() {
    await Promise.all([loadMemberData(), canViewCpAnalytics ? loadCpData() : null, canViewGvgAnalytics ? loadGvgData() : null]);
  }

  async function loadAttentionData() {
    await Promise.all([loadMemberData(), canViewCpAnalytics ? loadCpData() : null, canViewGvgAnalytics ? loadGvgData() : null]);
  }

  async function handleStartNewCpWeek() {
    setSnapshotMessage('');

    if (!confirmStartWeek) {
      setConfirmStartWeek(true);
      return;
    }

    const captured = await runLoader('startNewCpWeek', () => startNewCpGrowthPeriod({ guildId }));

    if (!captured) {
      return;
    }

    setSnapshotMessage(
      t('admin.analytics.weekStarted', {
        count: captured.capturedCount,
      }),
    );
    setConfirmStartWeek(false);
    setSelectedBaselineId(captured.batchId ?? '');
    await loadGrowthData({ baselineBatchId: captured.batchId ?? '' });
  }

  function handleCancelStartNewCpWeek() {
    setConfirmStartWeek(false);
    setSnapshotMessage('');
  }

  function renderPermissionError(key, titleKey) {
    if (errors[key] !== 'permission') {
      return errors[key] ? <p className="error-line">{errors[key]}</p> : null;
    }

    return <LockedPanel title={t(titleKey)} body={t('admin.analytics.permissionRequired')} />;
  }

  function renderOverview() {
    const loadingOverview = loading.members || loading.cp || loading.gvg;

    return (
      <section className="analytics-section-stack">
        {loadingOverview ? <p className="muted-line">{t('admin.analytics.loading')}</p> : null}
        <div className="analytics-stat-grid">
          <StatCard
            label={t('admin.analytics.totalMembers')}
            value={formatCompactNumber(memberAnalytics?.totalMembers)}
            tone="success"
          />
          <StatCard
            label={t('admin.analytics.activeMembers')}
            value={formatCompactNumber(memberAnalytics?.activeMembers)}
            tone="success"
          />
          <StatCard
            label={t('admin.analytics.pendingApprovals')}
            value={formatCompactNumber(memberAnalytics?.pendingApprovals)}
            tone={memberAnalytics?.pendingApprovals > 0 ? 'warning' : 'neutral'}
          />
          <StatCard
            label={t('admin.analytics.gvgState')}
            value={gvgAnalytics?.latestEventStatus ? formatGvgStatus(t, gvgAnalytics.latestEventStatus) : '-'}
            tone={gvgAnalytics?.latestEventStatus === 'active' ? 'success' : 'warning'}
            helper={gvgAnalytics?.latestEventTitle}
          />
          <StatCard
            label={t('admin.analytics.updateWindow')}
            value={cpAnalytics ? formatWindowStatus(t, cpAnalytics.cpUpdateWindowStatus) : '-'}
            tone={cpAnalytics?.cpUpdateWindowStatus === 'open' ? 'success' : 'warning'}
          />
          <StatCard
            label={t('admin.analytics.attention')}
            value={formatCompactNumber(attentionCount)}
            tone={attentionCount > 0 ? 'warning' : 'success'}
          />
        </div>
        {!canViewCpAnalytics ? (
          <LockedPanel title={t('admin.analytics.cp')} body={t('admin.analytics.cpPermissionRequired')} />
        ) : null}
      </section>
    );
  }

  function renderMembers() {
    if (!canViewMemberAnalytics || errors.members === 'permission') {
      return <LockedPanel title={t('admin.analytics.members')} body={t('admin.analytics.permissionRequired')} />;
    }

    return (
      <section className="analytics-section-stack">
        {loading.members ? <p className="muted-line">{t('admin.analytics.loading')}</p> : null}
        {renderPermissionError('members', 'admin.analytics.members')}
        <div className="analytics-stat-grid">
          <StatCard label={t('admin.analytics.totalMembers')} value={formatCompactNumber(memberAnalytics?.totalMembers)} />
          <StatCard label={t('admin.analytics.activeMembers')} value={formatCompactNumber(memberAnalytics?.activeMembers)} />
          <StatCard label={t('admin.analytics.trial')} value={formatCompactNumber(memberAnalytics?.trialMembers)} />
          <StatCard
            label={t('admin.analytics.pendingTransfer')}
            value={formatCompactNumber(memberAnalytics?.pendingTransferMembers)}
          />
          <StatCard label={t('admin.analytics.inactive')} value={formatCompactNumber(memberAnalytics?.inactiveMembers)} />
          <StatCard label={t('admin.analytics.onBreak')} value={formatCompactNumber(memberAnalytics?.onBreakMembers)} />
          <StatCard label={t('admin.analytics.suspended')} value={formatCompactNumber(memberAnalytics?.suspendedMembers)} />
          <StatCard label={t('admin.analytics.left')} value={formatCompactNumber(memberAnalytics?.leftMembers)} />
          <StatCard label={t('admin.analytics.kicked')} value={formatCompactNumber(memberAnalytics?.kickedMembers)} />
          <StatCard
            label={t('admin.analytics.pendingApprovals')}
            value={formatCompactNumber(memberAnalytics?.pendingApprovals)}
            tone={memberAnalytics?.pendingApprovals > 0 ? 'warning' : 'neutral'}
          />
        </div>
        {memberAnalytics?.membersByGuild?.length > 0 ? (
          <div className="analytics-list-panel">
            <h4>{t('admin.analytics.membersByGuild')}</h4>
            {memberAnalytics.membersByGuild.map((guildRow) => (
              <article className="analytics-list-row" key={guildRow.guild_id}>
                <strong>{guildRow.guild_name}</strong>
                <span>{t('admin.analytics.totalMembers')}: {formatCompactNumber(guildRow.total_members)}</span>
                <span>{t('admin.analytics.activeMembers')}: {formatCompactNumber(guildRow.active_members)}</span>
                <span>{t('admin.analytics.pendingApprovals')}: {formatCompactNumber(guildRow.pending_approvals)}</span>
              </article>
            ))}
          </div>
        ) : null}
      </section>
    );
  }

  function renderCp() {
    if (!canViewCpAnalytics || errors.cp === 'permission') {
      return <LockedPanel title={t('admin.analytics.cp')} body={t('admin.analytics.cpPermissionRequired')} />;
    }

    return (
      <section className="analytics-section-stack">
        {loading.cp ? <p className="muted-line">{t('admin.analytics.loading')}</p> : null}
        {renderPermissionError('cp', 'admin.analytics.cp')}
        <div className="analytics-stat-grid">
          <StatCard label={t('admin.analytics.totalCp')} value={formatCpValue(cpAnalytics?.totalCp)} tone="success" />
          <StatCard label={t('admin.analytics.averageCp')} value={formatCpValue(cpAnalytics?.averageCp)} />
          <StatCard label={t('admin.analytics.highestCp')} value={formatCpValue(cpAnalytics?.highestCp)} />
          <StatCard label={t('admin.analytics.lowestCp')} value={formatCpValue(cpAnalytics?.lowestCp)} />
          <StatCard
            label={t('admin.analytics.missingCp')}
            value={formatCompactNumber(cpAnalytics?.membersMissingCp)}
            tone={cpAnalytics?.membersMissingCp > 0 ? 'warning' : 'success'}
          />
          <StatCard
            label={t('admin.analytics.recentlyUpdatedCp')}
            value={formatCompactNumber(cpAnalytics?.recentlyUpdatedCpCount)}
          />
          <StatCard
            label={t('admin.analytics.updateWindow')}
            value={formatWindowStatus(t, cpAnalytics?.cpUpdateWindowStatus)}
            tone={cpAnalytics?.cpUpdateWindowStatus === 'open' ? 'success' : 'warning'}
          />
          <StatCard
            label={t('admin.analytics.selfSubmitted')}
            value={formatCompactNumber(cpAnalytics?.selfSubmittedCount)}
          />
        </div>
      </section>
    );
  }

  function renderGvg() {
    if (!canViewGvgAnalytics || errors.gvg === 'permission') {
      return <LockedPanel title={t('admin.analytics.gvg')} body={t('admin.analytics.permissionRequired')} />;
    }

    return (
      <section className="analytics-section-stack">
        {loading.gvg ? <p className="muted-line">{t('admin.analytics.loading')}</p> : null}
        {renderPermissionError('gvg', 'admin.analytics.gvg')}
        <div className="analytics-stat-grid">
          <StatCard
            label={t('admin.analytics.latestEvent')}
            value={gvgAnalytics?.latestEventTitle ?? '-'}
            helper={gvgAnalytics?.latestEventGuildName}
          />
          <StatCard
            label={t('admin.common.status')}
            value={formatGvgStatus(t, gvgAnalytics?.latestEventStatus)}
            tone={gvgAnalytics?.latestEventStatus === 'active' ? 'success' : 'warning'}
          />
          <StatCard label={t('admin.analytics.present')} value={formatCompactNumber(gvgAnalytics?.presentCount)} />
          <StatCard label={t('admin.analytics.absent')} value={formatCompactNumber(gvgAnalytics?.absentCount)} />
          <StatCard label={t('admin.analytics.noVote')} value={formatCompactNumber(gvgAnalytics?.noVoteCount)} />
          <StatCard
            label={t('admin.analytics.participation')}
            value={formatPercent(gvgAnalytics?.participationPercent)}
            tone="success"
          />
        </div>
        {gvgAnalytics?.absenceReasons?.length > 0 ? (
          <div className="analytics-list-panel">
            <h4>{t('admin.analytics.absenceReasons')}</h4>
            {gvgAnalytics.absenceReasons.map((reason) => (
              <article className="analytics-list-row" key={`${reason.profile_id}-${reason.updated_at}`}>
                <strong>{reason.ign ?? reason.username ?? t('admin.common.unknownMember')}</strong>
                <span>{reason.absence_reason}</span>
              </article>
            ))}
          </div>
        ) : null}
      </section>
    );
  }

  function renderWeeklyGrowth() {
    if (!canViewCpAnalytics || errors.weeklyGrowth === 'permission') {
      return (
        <LockedPanel
          title={t('admin.analytics.weeklyGrowth')}
          body={t('admin.analytics.weeklyGrowthPermissionRequired')}
        />
      );
    }

    const resetDayLabel =
      liveGrowthMeta?.resetDayOfWeek === 0 || liveGrowthMeta?.resetDayOfWeek === null || liveGrowthMeta?.resetDayOfWeek === undefined
        ? t('admin.analytics.resetDaySunday')
        : liveGrowthMeta?.resetDayLabel ?? t('admin.analytics.resetDaySunday');
    const baselineValue = hasWeeklyBaseline
      ? formatDate(liveGrowthMeta?.baselineCapturedAt)
      : t('admin.analytics.noWeeklyBaseline');
    const baselineHelper = hasWeeklyBaseline
      ? liveGrowthMeta?.baselineLabel
      : t('admin.analytics.startNewCpWeek');

    return (
      <section className="analytics-section-stack">
        <div className="analytics-growth-summary">
          <StatCard label={t('admin.analytics.resetDay')} value={resetDayLabel} tone="crimson" />
          <StatCard label={t('admin.analytics.baseline')} value={baselineValue} helper={baselineHelper} />
          <StatCard label={t('admin.analytics.scope')} value={selectedScopeLabel} helper={t('admin.analytics.liveGrowth')} />
        </div>

        <div className="analytics-action-row analytics-growth-action-row">
          <button
            type="button"
            className="primary-action compact-action"
            onClick={handleStartNewCpWeek}
            disabled={loading.startNewCpWeek}
          >
            {loading.startNewCpWeek ? t('common.working') : t('admin.analytics.startNewCpWeek')}
          </button>
        </div>

        {confirmStartWeek ? (
          <section className="analytics-confirm-panel">
            <div>
              <StatusBadge tone="warning">{t('admin.analytics.confirmStartNewCpWeek')}</StatusBadge>
              <p>{t('admin.analytics.confirmStartNewCpWeekBody', { scope: selectedScopeLabel })}</p>
            </div>
            <div className="analytics-confirm-actions">
              <button
                type="button"
                className="primary-action compact-action"
                onClick={handleStartNewCpWeek}
                disabled={loading.startNewCpWeek}
              >
                {loading.startNewCpWeek ? t('common.working') : t('admin.analytics.confirmStart')}
              </button>
              <button
                type="button"
                className="secondary-action compact-action"
                onClick={handleCancelStartNewCpWeek}
                disabled={loading.startNewCpWeek}
              >
                {t('admin.analytics.cancelStartWeek')}
              </button>
            </div>
          </section>
        ) : null}

        {snapshotMessage ? <p className="notice-line">{snapshotMessage}</p> : null}
        {loading.weeklyGrowth ? <p className="muted-line">{t('admin.analytics.loading')}</p> : null}
        {renderPermissionError('weeklyGrowth', 'admin.analytics.weeklyGrowth')}
        {errors.startNewCpWeek === 'permission' ? (
          <LockedPanel title={t('admin.analytics.weeklyGrowth')} body={t('admin.analytics.weeklyGrowthPermissionRequired')} />
        ) : errors.startNewCpWeek ? (
          <p className="error-line">{errors.startNewCpWeek}</p>
        ) : null}

        {!loading.weeklyGrowth && !hasWeeklyBaseline ? (
          <section className="compact-empty-state">
            <StatusBadge tone="warning">{t('admin.analytics.noWeeklyBaseline')}</StatusBadge>
            <h3>{t('admin.analytics.noWeeklyBaseline')}</h3>
          </section>
        ) : null}

        {hasWeeklyBaseline && growthRows.length === 0 ? (
          <section className="compact-empty-state">
            <StatusBadge>{t('admin.common.empty')}</StatusBadge>
            <h3>{t('admin.analytics.noGrowthRows')}</h3>
          </section>
        ) : null}

        {growthRows.length > 0 ? (
          <div className="analytics-growth-table" role="table" aria-label={t('admin.analytics.weeklyGrowth')}>
            <div className="analytics-growth-row analytics-growth-head" role="row">
              <span>{t('admin.cp.rank')}</span>
              <span>{t('admin.common.members')}</span>
              <span>{t('admin.common.guild')}</span>
              <span>{t('admin.analytics.baselineCp')}</span>
              <span>{t('admin.analytics.currentCp')}</span>
              <span>{t('admin.analytics.growth')}</span>
              <span>{t('admin.analytics.growthPercent')}</span>
              <span>{t('admin.common.updated')}</span>
            </div>
            {growthRows.map((row) => (
              <article className="analytics-growth-row" role="row" key={`${row.profileId}-${row.baselineBatchId ?? 'live'}`}>
                <span>#{row.rank}</span>
                <strong>{row.ign ?? row.username ?? t('admin.common.unknownMember')}</strong>
                <span>{row.guildName ?? t('admin.common.selectedGuild')}</span>
                <span>{formatCpValue(row.baselineCp)}</span>
                <span>{formatCpValue(row.currentCp)}</span>
                <span>{formatCpValue(row.growthAmount)}</span>
                <span>{formatPercent(row.growthPercent)}</span>
                <span>
                  {row.missingBaseline
                    ? t('admin.analytics.missingBaseline')
                    : row.missingCurrentCp
                      ? t('admin.analytics.missingCurrentCp')
                      : formatDate(row.lastUpdated)}
                </span>
              </article>
            ))}
          </div>
        ) : null}
      </section>
    );
  }

  function renderAttention() {
    return (
      <section className="analytics-section-stack">
        {loading.members || loading.cp || loading.gvg ? <p className="muted-line">{t('admin.analytics.loading')}</p> : null}
        <div className="analytics-stat-grid">
          <StatCard
            label={t('admin.analytics.pendingApprovals')}
            value={formatCompactNumber(memberAnalytics?.pendingApprovals)}
            tone={memberAnalytics?.pendingApprovals > 0 ? 'warning' : 'success'}
          />
          <StatCard
            label={t('admin.analytics.missingCp')}
            value={canViewCpAnalytics ? formatCompactNumber(cpAnalytics?.membersMissingCp) : '-'}
            tone={cpAnalytics?.membersMissingCp > 0 ? 'warning' : 'neutral'}
          />
          <StatCard label={t('admin.analytics.inactive')} value={formatCompactNumber(memberAnalytics?.inactiveMembers)} />
          <StatCard label={t('admin.analytics.onBreak')} value={formatCompactNumber(memberAnalytics?.onBreakMembers)} />
          <StatCard
            label={t('admin.analytics.pendingTransfer')}
            value={formatCompactNumber(memberAnalytics?.pendingTransferMembers)}
          />
          <StatCard
            label={t('admin.analytics.suspended')}
            value={formatCompactNumber(memberAnalytics?.suspendedMembers)}
            tone={memberAnalytics?.suspendedMembers > 0 ? 'danger' : 'neutral'}
          />
          <StatCard
            label={t('admin.analytics.noVote')}
            value={canViewGvgAnalytics ? formatCompactNumber(gvgAnalytics?.noVoteCount) : '-'}
          />
        </div>
      </section>
    );
  }

  function renderActiveAnalyticsTab() {
    if (activeSubTab === 'members') {
      return renderMembers();
    }

    if (activeSubTab === 'cp') {
      return renderCp();
    }

    if (activeSubTab === 'gvg') {
      return renderGvg();
    }

    if (activeSubTab === 'weeklyGrowth') {
      return renderWeeklyGrowth();
    }

    if (activeSubTab === 'attention') {
      return renderAttention();
    }

    return renderOverview();
  }

  return (
    <section className="admin-analytics admin-section" aria-label={t('admin.analytics.title')}>
      <div className="panel admin-analytics-panel">
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="crimson">{t('admin.analytics.title')}</StatusBadge>
            <h3>{t('admin.analytics.title')}</h3>
            <p>{t('admin.analytics.body')}</p>
          </div>
        </div>

        <AnalyticsScopeSelector
          scopeOptions={scopeOptions}
          selectedScopeId={selectedScope?.id ?? ''}
          selectedScope={selectedScope}
          onChange={setSelectedScopeId}
          t={t}
        />
        <AnalyticsSubTabs activeTab={activeSubTab} onChange={setActiveSubTab} t={t} />
        {renderActiveAnalyticsTab()}
      </div>
    </section>
  );
}
