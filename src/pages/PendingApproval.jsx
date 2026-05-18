import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function PendingApproval() {
  const { error, profile, profileLoading, refreshProfile, signOut } = useAuth();

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <StatusBadge tone="warning">Pending users are locked out</StatusBadge>
        <h3>Approval required</h3>
        <p>
          Registered users must remain pending until an authorized guild admin approves them.
          This scaffold does not expose member, CP, or admin data to pending users.
        </p>
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
