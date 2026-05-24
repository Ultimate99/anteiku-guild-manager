import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

export function AdminToolsSection({ plannedSections, t }) {
  return (
    <section className="panel admin-list compact-admin-card" aria-label={t('admin.tools.aria')}>
      {plannedSections.map((section) => (
        <article key={section}>
          <div>
            <h4>{section}</h4>
            <p>{t('admin.tools.comingLater')}</p>
          </div>
          <StatusBadge>{t('admin.common.later')}</StatusBadge>
        </article>
      ))}
    </section>
  );
}
