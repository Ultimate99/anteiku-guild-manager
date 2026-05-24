import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function RejectedStatus() {
  const { profile, signOut } = useAuth();

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <StatusBadge tone="danger">Rejected</StatusBadge>
        <h3>Registration rejected</h3>
        <p>This account is not approved for guild access.</p>
        {profile?.username ? <p className="muted-line">@{profile.username}</p> : null}
        <button type="button" className="secondary-action" onClick={signOut}>
          Sign out
        </button>
      </section>
    </div>
  );
}
