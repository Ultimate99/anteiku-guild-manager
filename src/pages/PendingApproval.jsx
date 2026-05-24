import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function PendingApproval() {
  const { t } = useLanguage();
  const { error, profile, profileLoading, refreshProfile, signOut } = useAuth();

  return (
    <div className="stack">
      <section className="panel hero-panel gate-panel member-compact-panel">
        <StatusBadge tone="warning">{t('gate.pending.badge')}</StatusBadge>
        <h3>{t('gate.pending.title')}</h3>
        <p>{t('gate.pending.body')}</p>
        {profile?.username ? <p className="muted-line">@{profile.username}</p> : null}
        {error ? <p className="error-line">{error}</p> : null}
        <button type="button" className="primary-action" onClick={refreshProfile} disabled={profileLoading}>
          {profileLoading ? t('gate.pending.refreshingStatus') : t('gate.pending.refreshStatus')}
        </button>
        <button type="button" className="secondary-action" onClick={signOut}>
          {t('common.signOut')}
        </button>
      </section>
    </div>
  );
}
