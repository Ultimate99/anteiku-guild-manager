import React from 'react';
import { AppNav } from '../components/AppNav.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import { useActiveProfileSummary } from '../hooks/useActiveProfileSummary.js';

export function AppShell({ activeItem, activePage, children, navigationItems, onNavigate }) {
  const { accessState, profile, signOut } = useAuth();
  const { activeProfile } = useActiveProfileSummary();
  const { language, languageOptions, setLanguage, t } = useLanguage();
  const showShellSignOut = accessState === 'approved';
  const pageContent = React.isValidElement(children) ? React.cloneElement(children, { onNavigate }) : children;
  const activeProfileName = activeProfile?.ign || profile?.ign || '';
  const activeProfileSlug = activeProfile?.profileSlug || profile?.profile_slug || profile?.username || '';
  const activeDiffersFromLegacy = Boolean(activeProfile?.profileId && profile?.id && activeProfile.profileId !== profile.id);

  return (
    <div className="app-shell" data-page={activePage}>
      <header className="topbar">
        <div className="brand-lockup">
          <img src="/anteiku-mark.svg" alt="" className="brand-mark" />
          <div>
            <p className="eyebrow">Anteiku</p>
            <h1>{t('app.title')}</h1>
          </div>
        </div>
        <div className="topbar-actions">
          {showShellSignOut && activeProfileName ? (
            <div className="topbar-active-profile" data-switched={activeDiffersFromLegacy}>
              <span>{t('accountSwitcher.viewingAsLabel')}</span>
              <strong>{activeProfileName}</strong>
              {activeProfileSlug ? <small>@{activeProfileSlug}</small> : null}
            </div>
          ) : null}
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

      <main className="page-content">{pageContent}</main>

      <AppNav activePage={activePage} items={navigationItems} onNavigate={onNavigate} />
    </div>
  );
}
