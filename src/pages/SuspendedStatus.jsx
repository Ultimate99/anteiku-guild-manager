import React from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function SuspendedStatus() {
  const { t } = useLanguage();
  const { signOut } = useAuth();

  return (
    <div className="stack">
      <section className="panel hero-panel gate-panel member-compact-panel">
        <StatusBadge tone="danger">{t('gate.suspended.badge')}</StatusBadge>
        <h3>{t('gate.suspended.title')}</h3>
        <p>{t('gate.suspended.body')}</p>
        <button type="button" className="secondary-action" onClick={signOut}>
          {t('common.signOut')}
        </button>
      </section>
    </div>
  );
}
