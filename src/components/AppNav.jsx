import React from 'react';

const NAV_ICONS = {
  dashboard: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M4 11.5 12 4l8 7.5" />
      <path d="M6.5 10.5V20h4v-5.5h3V20h4v-9.5" />
    </svg>
  ),
  profile: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 12.5a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z" />
      <path d="M4.5 20c1.2-3.8 4-5.8 7.5-5.8s6.3 2 7.5 5.8" />
    </svg>
  ),
  leaderboard: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M7 20V9h4v11" />
      <path d="M13 20V5h4v15" />
      <path d="M3 20v-6h3v6" />
      <path d="M20 20H3" />
    </svg>
  ),
  gvg: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M6 5.5 18.5 18" />
      <path d="m14 5 5 5" />
      <path d="M18.5 5.5 6 18" />
      <path d="m5 5 5 5" />
    </svg>
  ),
  threeVThree: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M7 8.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z" />
      <path d="M17 8.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z" />
      <path d="M12 15a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z" />
      <path d="M3.8 20c.8-2.5 2.7-3.8 5.2-3.8" />
      <path d="M20.2 20c-.8-2.5-2.7-3.8-5.2-3.8" />
      <path d="M8.5 21c.6-2 1.8-3.1 3.5-3.1s2.9 1.1 3.5 3.1" />
    </svg>
  ),
  guildWall: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M5 5h14v10H8l-3 3V5Z" />
      <path d="M8 8h8" />
      <path d="M8 11h5" />
    </svg>
  ),
  tcg: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M7 3.8h8.5L18 6.3v13.9H7V3.8Z" />
      <path d="M15.5 3.8v3H18" />
      <path d="M9.5 12h6" />
      <path d="M10.5 15h4" />
    </svg>
  ),
  admin: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 3.5 19 6v5.2c0 4.4-2.7 7.6-7 9.3-4.3-1.7-7-4.9-7-9.3V6l7-2.5Z" />
      <path d="M9.5 12.2 11.2 14l3.8-4" />
    </svg>
  ),
};

function NavIcon({ id }) {
  return <span className="nav-icon">{NAV_ICONS[id] ?? NAV_ICONS.dashboard}</span>;
}

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
          <NavIcon id={item.id} />
          <span className="nav-label">{item.label}</span>
        </button>
      ))}
    </nav>
  );
}
