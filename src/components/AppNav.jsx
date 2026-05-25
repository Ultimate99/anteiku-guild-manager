import React from 'react';

export function AppNav({ activePage, items, onNavigate }) {
  if (!items?.length) {
    return null;
  }

  return (
    <nav className="app-nav" aria-label="Primary">
      {items.map((item) => (
        <button
          key={item.id}
          className="nav-button"
          type="button"
          data-active={activePage === item.id}
          data-page={item.id}
          onClick={() => onNavigate(item.id)}
          aria-current={activePage === item.id ? 'page' : undefined}
        >
          <span>{item.label}</span>
        </button>
      ))}
    </nav>
  );
}
