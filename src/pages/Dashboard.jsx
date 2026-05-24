import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  formatRosterStatus,
  getRosterStatusSummary,
  isGvgLimitedRosterStatus,
  rosterStatusTone,
} from '../services/adminMemberService.js';

export function Dashboard() {
  const { guild, membership, profile } = useAuth();
  const guildName = guild?.name ?? 'Assigned guild';
  const roleLabel = membership?.role ?? 'member';
  const rosterStatus = membership?.roster_status ?? 'active';
  const gvgStatus = isGvgLimitedRosterStatus(rosterStatus) ? 'Not expected' : 'Awaiting event';

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <div className="status-badge-row">
          <StatusBadge tone="success">{profile?.approval_status ?? 'approved'}</StatusBadge>
          <StatusBadge tone={rosterStatusTone(rosterStatus)}>{formatRosterStatus(rosterStatus)}</StatusBadge>
        </div>
        <h3>{guildName} command floor</h3>
        <p>Guild status at a glance.</p>
        {rosterStatus !== 'active' ? <p className="muted-copy">{getRosterStatusSummary(rosterStatus)}</p> : null}
      </section>

      <section className="metric-grid" aria-label="Guild overview">
        <article className="metric-card">
          <span>GvG status</span>
          <strong>{gvgStatus}</strong>
        </article>
        <article className="metric-card">
          <span>Role</span>
          <strong>{roleLabel}</strong>
        </article>
        <article className="metric-card">
          <span>Guild</span>
          <strong>{guildName}</strong>
        </article>
      </section>

      <section className="guild-list" aria-label="Core guilds">
        <article className="guild-row">
          <div>
            <h4>{profile?.ign ?? 'Member'}</h4>
            <p>@{profile?.username ?? 'unknown'}</p>
          </div>
          <StatusBadge tone={rosterStatusTone(rosterStatus)}>{formatRosterStatus(rosterStatus)}</StatusBadge>
        </article>
      </section>
    </div>
  );
}
