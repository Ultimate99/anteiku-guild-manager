import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

export function AdminToolsSection({ plannedSections }) {
  return (
    <section className="panel admin-list" aria-label="Planned admin modules">
      {plannedSections.map((section) => (
        <article key={section}>
          <div>
            <h4>{section}</h4>
            <p>Planned for a later approved milestone.</p>
          </div>
          <StatusBadge>Planned</StatusBadge>
        </article>
      ))}
    </section>
  );
}
