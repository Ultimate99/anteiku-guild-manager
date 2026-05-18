import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function Dashboard() {
  const { guild, membership, profile } = useAuth();
  const guildName = guild?.name ?? 'Assigned guild';
  const roleLabel = membership?.role ?? 'member';

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <StatusBadge tone="success">{profile?.approval_status ?? 'approved'}</StatusBadge>
        <h3>{guildName} command floor</h3>
        <p>
          Mobile-first guild overview using safe profile and membership fields from Supabase.
          Sensitive statistics stay out of the member dashboard.
        </p>
      </section>

      <section className="metric-grid" aria-label="Guild overview">
        <article className="metric-card">
          <span>GvG status</span>
          <strong>Awaiting event</strong>
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
          <StatusBadge>{membership?.membership_status ?? 'active'}</StatusBadge>
        </article>
      </section>
    </div>
  );
}
