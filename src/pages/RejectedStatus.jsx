import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function RejectedStatus() {
  const { t } = useLanguage();
  const { profile, signOut } = useAuth();

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <StatusBadge tone="danger">{t('gate.rejected.badge')}</StatusBadge>
        <h3>{t('gate.rejected.title')}</h3>
        <p>{t('gate.rejected.body')}</p>
        {profile?.username ? <p className="muted-line">@{profile.username}</p> : null}
        <button type="button" className="secondary-action" onClick={signOut}>
          {t('common.signOut')}
        </button>
      </section>
    </div>
  );
}
