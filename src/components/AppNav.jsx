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
          onClick={() => onNavigate(item.id)}
        >
          <span>{item.label}</span>
        </button>
      ))}
    </nav>
  );
}
