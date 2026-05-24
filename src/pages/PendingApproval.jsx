import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function PendingApproval() {
  const { error, profile, profileLoading, refreshProfile, signOut } = useAuth();

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <StatusBadge tone="warning">Pending</StatusBadge>
        <h3>Awaiting approval.</h3>
        <p>A guild admin must approve this account before member access opens.</p>
        {profile?.username ? <p className="muted-line">@{profile.username}</p> : null}
        {error ? <p className="error-line">{error}</p> : null}
        <button type="button" className="primary-action" onClick={refreshProfile} disabled={profileLoading}>
          {profileLoading ? 'Refreshing...' : 'Refresh status'}
        </button>
        <button type="button" className="secondary-action" onClick={signOut}>
          Sign out
        </button>
      </section>
    </div>
  );
}
