import React, { useEffect, useState } from 'react';
import { RankBadge } from '../components/RankBadge.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  isGvgLimitedRosterStatus,
  rosterStatusTone,
} from '../services/adminMemberService.js';
import { loadMyCpRankSummary } from '../services/cpRankBadgeService.js';

export function Dashboard({ onNavigate }) {
  const { t } = useLanguage();
  const { guild, membership, profile } = useAuth();
  const [rankSummary, setRankSummary] = useState(null);
  const [rankLoading, setRankLoading] = useState(false);
  const [rankError, setRankError] = useState('');
  const guildName = guild?.name ?? t('guild.assigned');
  const role = membership?.role ?? 'member';
  const rosterStatus = membership?.roster_status ?? 'active';
  const gvgStatus = isGvgLimitedRosterStatus(rosterStatus) ? t('dashboard.notExpected') : t('dashboard.awaitingEvent');
  const canNavigate = typeof onNavigate === 'function';

  useEffect(() => {
    let cancelled = false;

    async function loadRankBadge() {
      if (!profile?.id || !membership?.id) {
        return;
      }

      setRankLoading(true);
      setRankError('');

      try {
        const nextRankSummary = await loadMyCpRankSummary();

        if (!cancelled) {
          setRankSummary(nextRankSummary);
        }
      } catch {
        if (!cancelled) {
          setRankSummary(null);
          setRankError('load_error');
        }
      } finally {
        if (!cancelled) {
          setRankLoading(false);
        }
      }
    }

    loadRankBadge();

    return () => {
      cancelled = true;
    };
  }, [membership?.id, profile?.id]);

  return (
    <div className="stack">
      <section className="panel hero-panel member-home-panel member-command-panel">
        <div className="dashboard-identity">
          <div className="dashboard-identity-main">
            <div className="dashboard-guild-mark" aria-hidden="true">
              {String(guildName).slice(0, 1).toUpperCase()}
            </div>
            <div>
              <p className="eyebrow">{t('dashboard.commandCenter')}</p>
              <h3>{t('dashboard.welcome', { ign: profile?.ign ?? t('dashboard.memberFallback') })}</h3>
              <p>@{profile?.username ?? t('common.unknown')}</p>
            </div>
          </div>
          <div className="status-badge-row dashboard-status-row">
            <StatusBadge tone="success">{t(`approvalStatus.${profile?.approval_status ?? 'approved'}`)}</StatusBadge>
            <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
          </div>
        </div>
        <p>{t('dashboard.body')}</p>
        {rosterStatus !== 'active' ? <p className="muted-copy">{t(`roster.status.${rosterStatus}.summary`)}</p> : null}
      </section>

      <section className="dashboard-command-grid" aria-label={t('dashboard.quickActions')}>
        <button
          type="button"
          className="command-card dashboard-command-card"
          onClick={() => canNavigate && onNavigate('profile')}
          disabled={!canNavigate}
        >
          <span>{t('dashboard.quickProfile')}</span>
          <strong>{t('nav.profile')}</strong>
          <small>{t('dashboard.quickProfileBody')}</small>
        </button>
        <button
          type="button"
          className="command-card dashboard-command-card"
          onClick={() => canNavigate && onNavigate('gvg')}
          disabled={!canNavigate}
        >
          <span>{t('dashboard.quickGvg')}</span>
          <strong>{t('nav.gvg')}</strong>
          <small>{gvgStatus}</small>
        </button>
        <article className="command-card dashboard-command-card dashboard-status-card">
          <span>{t('dashboard.quickGuildStatus')}</span>
          <strong>{guildName}</strong>
          <small>{t(`roster.status.${rosterStatus}.label`)}</small>
        </article>
      </section>

      <section className="metric-grid compact-metric-grid dashboard-status-grid" aria-label={t('dashboard.overview')}>
        <article className="metric-card">
          <span>{t('dashboard.gvgStatus')}</span>
          <strong>{gvgStatus}</strong>
        </article>
        <article className="metric-card">
          <span>{t('dashboard.role')}</span>
          <strong>{t(`roles.${role}`)}</strong>
        </article>
        <article className="metric-card">
          <span>{t('dashboard.guild')}</span>
          <strong>{guildName}</strong>
        </article>
      </section>

      <section className="panel member-id-panel" aria-label={t('dashboard.memberSummary')}>
        <div>
          <h4>{profile?.ign ?? t('dashboard.memberFallback')}</h4>
          <p>@{profile?.username ?? t('common.unknown')}</p>
        </div>
        <div className="member-id-badges">
          <RankBadge compact summary={rankSummary} loading={rankLoading} error={rankError} />
          <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
        </div>
      </section>
    </div>
  );
}
