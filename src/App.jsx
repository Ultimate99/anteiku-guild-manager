import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { AuthProvider } from './context/AuthContext.jsx';
import { LanguageProvider, useLanguage } from './context/LanguageContext.jsx';
import { useAuth } from './hooks/useAuth.js';
import { useActiveAdminContext } from './hooks/useActiveAdminContext.js';
import { AppShell } from './layouts/AppShell.jsx';
import { navigationItems } from './data/navigation.js';
import { Dashboard } from './pages/Dashboard.jsx';
import { LoginRegister } from './pages/LoginRegister.jsx';
import { SetNewPassword } from './pages/SetNewPassword.jsx';
import { PendingApproval } from './pages/PendingApproval.jsx';
import { Profile } from './pages/Profile.jsx';
import { Leaderboard } from './pages/Leaderboard.jsx';
import { Gvg } from './pages/Gvg.jsx';
import { ThreeVThree } from './pages/ThreeVThree.jsx';
import { GuildWall } from './pages/GuildWall.jsx';
import { PublicMemberProfile } from './pages/PublicMemberProfile.jsx';
import { TcgCollection } from './pages/TcgCollection.jsx';
import { AdminPanel } from './pages/AdminPanel.jsx';
import { RejectedStatus } from './pages/RejectedStatus.jsx';
import { RosterRestrictedStatus } from './pages/RosterRestrictedStatus.jsx';
import { SuspendedStatus } from './pages/SuspendedStatus.jsx';
import { isHardBlockedRosterStatus } from './services/adminMemberService.js';

const pageComponents = {
  auth: LoginRegister,
  pending: PendingApproval,
  dashboard: Dashboard,
  profile: Profile,
  leaderboard: Leaderboard,
  gvg: Gvg,
  threeVThree: ThreeVThree,
  guildWall: GuildWall,
  tcg: TcgCollection,
  publicProfile: PublicMemberProfile,
  admin: AdminPanel,
};

function readPublicProfileSlugFromPath() {
  if (typeof window === 'undefined') {
    return '';
  }

  const match = window.location.pathname.match(/^\/members\/([^/]+)\/?$/);

  if (!match?.[1]) {
    return '';
  }

  try {
    return decodeURIComponent(match[1]);
  } catch {
    return match[1];
  }
}

function translateShellItem(item, t) {
  return {
    ...item,
    label: item.labelKey ? t(item.labelKey) : item.label,
    eyebrow: item.eyebrowKey ? t(item.eyebrowKey) : item.eyebrow,
  };
}

function LoadingPanel() {
  const { t } = useLanguage();

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <h3>{t('app.loadingTitle')}</h3>
        <p>{t('app.loadingBody')}</p>
      </section>
    </div>
  );
}

function readInitialPageFromPath() {
  if (readPublicProfileSlugFromPath()) {
    return 'publicProfile';
  }

  if (typeof window !== 'undefined' && window.location.pathname === '/tcg') {
    return 'tcg';
  }

  return 'dashboard';
}

function OfflineNotice() {
  const [isOnline, setIsOnline] = useState(() => (typeof navigator === 'undefined' ? true : navigator.onLine));

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  if (isOnline) {
    return null;
  }

  return (
    <aside className="offline-notice-banner" role="status" aria-live="polite">
      <strong>You are offline</strong>
      <span>Live guild data requires an internet connection.</span>
    </aside>
  );
}

function AppContent() {
  const { accessState, loading, membership, recoveryRequired } = useAuth();
  const {
    activeAdminContext,
    activeAdminContextLoading,
    canAccessAdminPanel,
  } = useActiveAdminContext();
  const { t } = useLanguage();
  const [publicProfileSlug, setPublicProfileSlug] = useState(() => readPublicProfileSlugFromPath());
  const [activePage, setActivePage] = useState(() => readInitialPageFromPath());
  const rosterStatus = membership?.roster_status ?? 'active';
  const statusItems = useMemo(
    () => ({
      loading: {
        id: 'loading',
        label: t('app.pages.loading'),
        eyebrow: t('app.eyebrow.session'),
      },
      auth: {
        id: 'auth',
        label: t('app.pages.auth'),
        eyebrow: t('app.eyebrow.entry'),
      },
      pending: {
        id: 'pending',
        label: t('app.pages.pending'),
        eyebrow: t('app.eyebrow.gate'),
      },
      rejected: {
        id: 'rejected',
        label: t('app.pages.rejected'),
        eyebrow: t('app.eyebrow.status'),
      },
      suspended: {
        id: 'suspended',
        label: t('app.pages.suspended'),
        eyebrow: t('app.eyebrow.status'),
      },
      recovery: {
        id: 'recovery',
        label: t('app.pages.password'),
        eyebrow: t('app.eyebrow.recovery'),
      },
    }),
    [t],
  );
  const isHardMembershipState = ['suspended', 'left'].includes(membership?.membership_status);
  const blockedRosterStatus = isHardBlockedRosterStatus(rosterStatus)
    ? rosterStatus
    : membership?.membership_status === 'left'
      ? 'left'
      : 'suspended';
  const isRosterBlocked =
    accessState === 'approved' && (isHardBlockedRosterStatus(rosterStatus) || isHardMembershipState);
  const canViewAdmin =
    accessState === 'approved' && !isRosterBlocked && !activeAdminContextLoading && canAccessAdminPanel;
  const rosterBlockedItem = {
    id: `roster-${blockedRosterStatus}`,
    label: blockedRosterStatus === 'kicked' ? t('app.pages.removed') : t(`roster.status.${blockedRosterStatus}.label`),
    eyebrow: t('app.eyebrow.roster'),
  };

  const approvedNavigationItems = useMemo(
    () =>
      navigationItems
        .filter((item) => {
          if (item.id === 'auth' || item.id === 'pending') {
            return false;
          }

          if (item.id === 'admin') {
            return canViewAdmin;
          }

          if (item.id === 'tcg') {
            return Boolean(activeAdminContext?.isOwner);
          }

          return true;
        })
        .map((item) => translateShellItem(item, t)),
    [activeAdminContext?.isOwner, canViewAdmin, t],
  );

  const handleNavigate = useCallback((pageId, options = {}) => {
    if (pageId === 'publicProfile') {
      const nextSlug = String(options?.profileSlug || '').trim();

      if (!nextSlug) {
        return;
      }

      setPublicProfileSlug(nextSlug);
      setActivePage('publicProfile');

      if (typeof window !== 'undefined') {
        window.history.pushState(
          { page: 'publicProfile', profileSlug: nextSlug },
          '',
          `/members/${encodeURIComponent(nextSlug)}`,
        );
      }

      return;
    }

    setPublicProfileSlug('');
    setActivePage(pageId);

    if (typeof window !== 'undefined') {
      if (pageId === 'tcg') {
        window.history.pushState({ page: pageId }, '', '/tcg');
      } else if (window.location.pathname.startsWith('/members/') || window.location.pathname === '/tcg') {
        window.history.pushState({ page: pageId }, '', '/');
      }
    }
  }, []);

  useEffect(() => {
    const handlePopState = () => {
      const nextSlug = readPublicProfileSlugFromPath();

      if (nextSlug) {
        setPublicProfileSlug(nextSlug);
        setActivePage('publicProfile');
        return;
      }

      setPublicProfileSlug('');
      setActivePage(window.location.pathname === '/tcg' ? 'tcg' : 'dashboard');
    };

    window.addEventListener('popstate', handlePopState);

    return () => {
      window.removeEventListener('popstate', handlePopState);
    };
  }, []);

  const safeActivePage = activePage;
  const activeItem = useMemo(() => {
    if (safeActivePage === 'admin') {
      return translateShellItem(navigationItems.find((item) => item.id === 'admin'), t);
    }

    if (safeActivePage === 'publicProfile') {
      return {
        id: 'publicProfile',
        label: t('publicProfile.title'),
        eyebrow: t('app.eyebrow.member'),
      };
    }

    if (safeActivePage === 'tcg') {
      return {
        id: 'tcg',
        label: t('tcg.title'),
        eyebrow: t('tcg.ownerPreview'),
      };
    }

    return approvedNavigationItems.find((item) => item.id === safeActivePage) ?? approvedNavigationItems[0];
  }, [approvedNavigationItems, safeActivePage, t]);
  const ActivePage = pageComponents[safeActivePage] ?? Dashboard;

  if (loading) {
    return (
      <AppShell activeItem={statusItems.loading} activePage="loading" navigationItems={[]}>
        <LoadingPanel />
      </AppShell>
    );
  }

  if (recoveryRequired) {
    return (
      <AppShell activeItem={statusItems.recovery} activePage="password-recovery" navigationItems={[]}>
        <SetNewPassword />
      </AppShell>
    );
  }

  if (accessState === 'unconfigured' || accessState === 'unauthenticated' || accessState === 'needs_profile') {
    return (
      <AppShell activeItem={statusItems.auth} activePage="auth" navigationItems={[]}>
        <LoginRegister />
      </AppShell>
    );
  }

  if (accessState === 'pending') {
    return (
      <AppShell activeItem={statusItems.pending} activePage="pending" navigationItems={[]}>
        <PendingApproval />
      </AppShell>
    );
  }

  if (accessState === 'rejected') {
    return (
      <AppShell activeItem={statusItems.rejected} activePage="rejected" navigationItems={[]}>
        <RejectedStatus />
      </AppShell>
    );
  }

  if (accessState === 'suspended') {
    return (
      <AppShell activeItem={statusItems.suspended} activePage="suspended" navigationItems={[]}>
        <SuspendedStatus />
      </AppShell>
    );
  }

  if (isRosterBlocked) {
    return (
      <AppShell activeItem={rosterBlockedItem} activePage={`roster-${blockedRosterStatus}`} navigationItems={[]}>
        <RosterRestrictedStatus />
      </AppShell>
    );
  }

  return (
    <AppShell
      activeItem={activeItem}
      activePage={safeActivePage}
      navigationItems={approvedNavigationItems}
      onNavigate={handleNavigate}
    >
      <ActivePage
        profileSlug={publicProfileSlug}
        onNavigate={handleNavigate}
        activeAdminContext={activeAdminContext}
        activeAdminContextLoading={activeAdminContextLoading}
      />
    </AppShell>
  );
}

export default function App() {
  return (
    <LanguageProvider>
      <OfflineNotice />
      <AuthProvider>
        <AppContent />
      </AuthProvider>
    </LanguageProvider>
  );
}
