import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  isGvgLimitedRosterStatus,
  rosterStatusTone,
} from '../services/adminMemberService.js';

export function Dashboard() {
  const { t } = useLanguage();
  const { guild, membership, profile } = useAuth();
  const guildName = guild?.name ?? t('guild.assigned');
  const role = membership?.role ?? 'member';
  const rosterStatus = membership?.roster_status ?? 'active';
  const gvgStatus = isGvgLimitedRosterStatus(rosterStatus) ? t('dashboard.notExpected') : t('dashboard.awaitingEvent');

  return (
    <div className="stack">
      <section className="panel hero-panel member-home-panel member-compact-panel">
        <div className="status-badge-row">
          <StatusBadge tone="success">{t(`approvalStatus.${profile?.approval_status ?? 'approved'}`)}</StatusBadge>
          <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
        </div>
        <h3>{t('dashboard.title', { guildName })}</h3>
        <p>{t('dashboard.body')}</p>
        {rosterStatus !== 'active' ? <p className="muted-copy">{t(`roster.status.${rosterStatus}.summary`)}</p> : null}
      </section>

      <section className="metric-grid compact-metric-grid" aria-label={t('dashboard.overview')}>
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
        <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
      </section>
    </div>
  );
}
