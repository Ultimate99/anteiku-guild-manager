import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  isHardBlockedRosterStatus,
  rosterStatusTone,
} from '../services/adminMemberService.js';

export function RosterRestrictedStatus() {
  const { t } = useLanguage();
  const { membership, signOut } = useAuth();
  const rosterStatus = isHardBlockedRosterStatus(membership?.roster_status)
    ? membership.roster_status
    : membership?.membership_status === 'left'
      ? 'left'
      : 'suspended';

  return (
    <div className="stack">
      <section className="panel hero-panel restricted-panel gate-panel member-compact-panel">
        <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
        <h3>{t(`roster.restricted.${rosterStatus}.title`)}</h3>
        <p>{t(`roster.restricted.${rosterStatus}.body`)}</p>
        <p className="muted-copy">{t(`roster.status.${rosterStatus}.summary`)}</p>
        <button type="button" className="secondary-action" onClick={signOut}>
          {t('common.signOut')}
        </button>
      </section>
    </div>
  );
}
