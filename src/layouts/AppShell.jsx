import React from 'react';
import { AppNav } from '../components/AppNav.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';

export function AppShell({ activeItem, activePage, children, navigationItems, onNavigate }) {
  const { accessState, signOut } = useAuth();
  const { language, languageOptions, setLanguage, t } = useLanguage();
  const showShellSignOut = accessState === 'approved';

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand-lockup">
          <img src="/anteiku-mark.svg" alt="" className="brand-mark" />
          <div>
            <p className="eyebrow">Anteiku</p>
            <h1>{t('app.title')}</h1>
          </div>
        </div>
        <div className="topbar-actions">
          <label className="language-switcher">
            <span>{t('language.label')}</span>
            <select value={language} onChange={(event) => setLanguage(event.target.value)}>
              {languageOptions.map((option) => (
                <option key={option.code} value={option.code}>
                  {t(option.labelKey)}
                </option>
              ))}
            </select>
          </label>
          {showShellSignOut ? (
            <button type="button" className="shell-signout" onClick={signOut}>
              {t('common.signOut')}
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
