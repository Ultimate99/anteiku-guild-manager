import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

export function AdminToolsSection({ plannedSections }) {
  return (
    <section className="panel admin-list compact-admin-card" aria-label="Planned admin modules">
      {plannedSections.map((section) => (
        <article key={section}>
          <div>
            <h4>{section}</h4>
            <p>Coming later.</p>
          </div>
          <StatusBadge>Later</StatusBadge>
        </article>
      ))}
    </section>
  );
}
