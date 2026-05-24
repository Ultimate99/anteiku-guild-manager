import React from 'react';
import { AppNav } from '../components/AppNav.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function AppShell({ activeItem, activePage, children, navigationItems, onNavigate }) {
  const { accessState, signOut } = useAuth();
  const showShellSignOut = accessState === 'approved';

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand-lockup">
          <img src="/anteiku-mark.svg" alt="" className="brand-mark" />
          <div>
            <p className="eyebrow">Anteiku</p>
            <h1>Guild Manager</h1>
          </div>
        </div>
        {showShellSignOut ? (
          <div className="topbar-actions">
            <button type="button" className="shell-signout" onClick={signOut}>
              Sign out
            </button>
          </div>
        ) : null}
      </header>

      <section className="page-heading" aria-labelledby="page-title">
        <p className="eyebrow">{activeItem.eyebrow}</p>
        <h2 id="page-title">{activeItem.label}</h2>
      </section>

      <main className="page-content">{children}</main>

      <AppNav activePage={activePage} items={navigationItems} onNavigate={onNavigate} />
    </div>
  );
}
