import React from 'react';
import { AppNav } from '../components/AppNav.jsx';
import { isSupabaseConfigured, supabaseEnvironmentLabel } from '../config/supabaseClient.js';
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
        <div className="topbar-actions">
          <div className="connection-pill" data-ready={isSupabaseConfigured}>
            {supabaseEnvironmentLabel}
          </div>
          {showShellSignOut ? (
            <button type="button" className="shell-signout" onClick={signOut}>
              Sign out
            </button>
          ) : null}
        </div>
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
