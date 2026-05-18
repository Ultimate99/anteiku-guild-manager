import React from 'react';

export function StatusBadge({ children, tone = 'neutral' }) {
  return (
    <span className="status-badge" data-tone={tone}>
      {children}
    </span>
  );
}
