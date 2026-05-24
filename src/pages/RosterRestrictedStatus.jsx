import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  formatRosterStatus,
  getRosterStatusSummary,
  isHardBlockedRosterStatus,
  rosterStatusTone,
} from '../services/adminMemberService.js';

const restrictedCopy = {
  suspended: {
    title: 'Access suspended',
    body: 'This account is currently blocked from member and admin areas. Contact an authorized guild leader outside the app if this seems wrong.',
  },
  left: {
    title: 'No active membership',
    body: 'This account is preserved for guild history, but it no longer has active member access.',
  },
  kicked: {
    title: 'Access removed',
    body: 'This account is preserved for guild history, but access to member and admin areas has been removed.',
  },
};

export function RosterRestrictedStatus() {
  const { membership, signOut } = useAuth();
  const rosterStatus = isHardBlockedRosterStatus(membership?.roster_status)
    ? membership.roster_status
    : membership?.membership_status === 'left'
      ? 'left'
      : 'suspended';
  const copy = restrictedCopy[rosterStatus] ?? restrictedCopy.suspended;

  return (
    <div className="stack">
      <section className="panel hero-panel restricted-panel">
        <StatusBadge tone={rosterStatusTone(rosterStatus)}>{formatRosterStatus(rosterStatus)}</StatusBadge>
        <h3>{copy.title}</h3>
        <p>{copy.body}</p>
        <p className="muted-copy">{getRosterStatusSummary(rosterStatus)}</p>
        <button type="button" className="secondary-action" onClick={signOut}>
          Sign out
        </button>
      </section>
    </div>
  );
}
