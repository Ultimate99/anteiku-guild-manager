import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function SuspendedStatus() {
  const { signOut } = useAuth();

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <StatusBadge tone="danger">Suspended</StatusBadge>
        <h3>Access suspended</h3>
        <p>
          This account is currently blocked from member areas. Contact an authorized guild leader
          outside the app if this seems wrong.
        </p>
        <button type="button" className="secondary-action" onClick={signOut}>
          Sign out
        </button>
      </section>
    </div>
  );
}
