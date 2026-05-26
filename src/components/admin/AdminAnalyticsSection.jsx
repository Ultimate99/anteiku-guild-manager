import React, { useEffect, useMemo, useState } from 'react';
import { StatusBadge } from '../StatusBadge.jsx';
import {
  captureWeeklyCpSnapshot,
  loadCpAnalytics,
  loadCpGrowthReport,
  loadCpSnapshotHistory,
  loadGvgAnalytics,
  loadMemberAnalytics,
} from '../../services/adminAnalyticsService.js';

const ANALYTICS_TABS = ['overview', 'members', 'cp', 'gvg', 'weeklyGrowth', 'attention'];

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

function getAnalyticsScope({ membership }) {
  if (membership?.role === 'owner') {
    return null;
  }

  return membership?.guild_id ?? null;
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

export function AdminAnalyticsSection({
  membership,
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
  const [snapshotHistory, setSnapshotHistory] = useState([]);
  const [growthReport, setGrowthReport] = useState([]);
  const [selectedSnapshotId, setSelectedSnapshotId] = useState('');
  const [loading, setLoading] = useState({});
  const [errors, setErrors] = useState({});
  const [snapshotMessage, setSnapshotMessage] = useState('');

  const guildId = useMemo(() => getAnalyticsScope({ membership }), [membership]);
  const hasPreviousSnapshot = growthReport.some((row) => row.hasPreviousSnapshot);
  const growthRows = growthReport.filter((row) => row.rank !== null && row.profileId);
  const attentionCount =
    (memberAnalytics?.pendingApprovals ?? 0) +
    (memberAnalytics?.inactiveMembers ?? 0) +
    (memberAnalytics?.onBreakMembers ?? 0) +
    (memberAnalytics?.pendingTransferMembers ?? 0) +
    (memberAnalytics?.suspendedMembers ?? 0) +
    (canViewCpAnalytics ? cpAnalytics?.membersMissingCp ?? 0 : 0) +
    (canViewGvgAnalytics ? gvgAnalytics?.noVoteCount ?? 0 : 0);

  useEffect(() => {
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
  }, [activeSubTab, guildId, canViewMemberAnalytics, canViewCpAnalytics, canViewGvgAnalytics, refreshSignal]);

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

  async function loadSnapshotHistory() {
    if (!canViewCpAnalytics) {
      setErrors((current) => ({ ...current, weeklyGrowth: 'permission' }));
      return [];
    }

    const nextHistory = await runLoader('snapshotHistory', () => loadCpSnapshotHistory({ guildId }));
    if (nextHistory) {
      setSnapshotHistory(nextHistory);
      setSelectedSnapshotId((current) =>
        current && nextHistory.some((snapshot) => snapshot.id === current) ? current : nextHistory[0]?.id ?? '',
      );
      return nextHistory;
    }

    return [];
  }

  async function loadGrowthData({ snapshotId = selectedSnapshotId } = {}) {
    if (!canViewCpAnalytics) {
      setErrors((current) => ({ ...current, weeklyGrowth: 'permission' }));
      setGrowthReport([]);
      return;
    }

    const nextHistory = snapshotHistory.length > 0 ? snapshotHistory : await loadSnapshotHistory();
    const effectiveSnapshotId =
      snapshotId && nextHistory.some((snapshot) => snapshot.id === snapshotId)
        ? snapshotId
        : nextHistory[0]?.id ?? '';
    const nextGrowthReport = await runLoader('weeklyGrowth', () =>
      loadCpGrowthReport({ guildId, snapshotId: effectiveSnapshotId || null }),
    );

    if (nextGrowthReport) {
      setGrowthReport(nextGrowthReport);
    }
  }

  async function loadOverviewData() {
    await Promise.all([loadMemberData(), canViewCpAnalytics ? loadCpData() : null, canViewGvgAnalytics ? loadGvgData() : null]);
  }

  async function loadAttentionData() {
    await Promise.all([loadMemberData(), canViewCpAnalytics ? loadCpData() : null, canViewGvgAnalytics ? loadGvgData() : null]);
  }

  async function handleSelectSnapshot(snapshotId) {
    setSelectedSnapshotId(snapshotId);
    await loadGrowthData({ snapshotId });
  }

  async function handleCaptureSnapshot() {
    setSnapshotMessage('');
    const captured = await runLoader('captureSnapshot', () => captureWeeklyCpSnapshot({ guildId }));

    if (!captured) {
      return;
    }

    setSnapshotMessage(
      t('admin.analytics.snapshotCaptured', {
        count: captured.capturedCount,
      }),
    );
    const nextHistory = await loadSnapshotHistory();
    await loadGrowthData({ snapshotId: nextHistory[0]?.id ?? '' });
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

    return (
      <section className="analytics-section-stack">
        <div className="analytics-action-row">
          <label>
            {t('admin.analytics.snapshotHistory')}
            <select
              value={selectedSnapshotId}
              onChange={(event) => handleSelectSnapshot(event.target.value)}
              disabled={loading.weeklyGrowth || loading.snapshotHistory || snapshotHistory.length === 0}
            >
              {snapshotHistory.length === 0 ? <option value="">{t('admin.analytics.noSnapshots')}</option> : null}
              {snapshotHistory.map((snapshot) => (
                <option key={snapshot.id} value={snapshot.id}>
                  {snapshot.label || `${formatDate(snapshot.capturedAt)} - ${snapshot.memberCount}`}
                </option>
              ))}
            </select>
          </label>
          <button
            type="button"
            className="primary-action compact-action"
            onClick={handleCaptureSnapshot}
            disabled={loading.captureSnapshot}
          >
            {loading.captureSnapshot ? t('common.working') : t('admin.analytics.captureSnapshot')}
          </button>
        </div>

        {snapshotMessage ? <p className="notice-line">{snapshotMessage}</p> : null}
        {loading.weeklyGrowth || loading.snapshotHistory ? <p className="muted-line">{t('admin.analytics.loading')}</p> : null}
        {renderPermissionError('weeklyGrowth', 'admin.analytics.weeklyGrowth')}

        {!hasPreviousSnapshot ? (
          <section className="compact-empty-state">
            <StatusBadge tone="warning">{t('admin.analytics.noPreviousSnapshot')}</StatusBadge>
            <h3>{t('admin.analytics.noPreviousSnapshot')}</h3>
          </section>
        ) : null}

        {hasPreviousSnapshot && growthRows.length === 0 ? (
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
              <span>{t('admin.analytics.previousCp')}</span>
              <span>{t('admin.analytics.currentCp')}</span>
              <span>{t('admin.analytics.growth')}</span>
              <span>{t('admin.analytics.growthPercent')}</span>
              <span>{t('admin.common.updated')}</span>
            </div>
            {growthRows.map((row) => (
              <article className="analytics-growth-row" role="row" key={`${row.profileId}-${row.currentSnapshotId}`}>
                <span>#{row.rank}</span>
                <strong>{row.ign ?? row.username ?? t('admin.common.unknownMember')}</strong>
                <span>{row.guildName ?? t('admin.common.selectedGuild')}</span>
                <span>{formatCpValue(row.previousCp)}</span>
                <span>{formatCpValue(row.currentCp)}</span>
                <span>{formatCpValue(row.growthAmount)}</span>
                <span>{formatPercent(row.growthPercent)}</span>
                <span>{row.missingUpdate ? t('admin.analytics.missingUpdate') : formatDate(row.lastUpdated)}</span>
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

        <AnalyticsSubTabs activeTab={activeSubTab} onChange={setActiveSubTab} t={t} />
        {renderActiveAnalyticsTab()}
      </div>
    </section>
  );
}
