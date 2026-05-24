import React, { useEffect, useMemo, useState } from 'react';
import { AuthProvider } from './context/AuthContext.jsx';
import { useAuth } from './hooks/useAuth.js';
import { AppShell } from './layouts/AppShell.jsx';
import { navigationItems } from './data/navigation.js';
import { Dashboard } from './pages/Dashboard.jsx';
import { LoginRegister } from './pages/LoginRegister.jsx';
import { PendingApproval } from './pages/PendingApproval.jsx';
import { Profile } from './pages/Profile.jsx';
import { Gvg } from './pages/Gvg.jsx';
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
  gvg: Gvg,
  admin: AdminPanel,
};

const statusItems = {
  loading: {
    id: 'loading',
    label: 'Loading',
    eyebrow: 'Session',
  },
  auth: {
    id: 'auth',
    label: 'Auth',
    eyebrow: 'Entry',
  },
  pending: {
    id: 'pending',
    label: 'Pending',
    eyebrow: 'Gate',
  },
  rejected: {
    id: 'rejected',
    label: 'Rejected',
    eyebrow: 'Status',
  },
  suspended: {
    id: 'suspended',
    label: 'Suspended',
    eyebrow: 'Status',
  },
};

function isPrivilegedRole(role) {
  return ['owner', 'leader', 'vice', 'admin'].includes(role);
}

function LoadingPanel() {
  return (
    <div className="stack">
      <section className="panel hero-panel">
        <h3>Restoring session</h3>
        <p>One moment.</p>
      </section>
    </div>
  );
}

function AppContent() {
  const { accessState, loading, membership } = useAuth();
  const [activePage, setActivePage] = useState('dashboard');
  const rosterStatus = membership?.roster_status ?? 'active';
  const isHardMembershipState = ['suspended', 'left'].includes(membership?.membership_status);
  const blockedRosterStatus = isHardBlockedRosterStatus(rosterStatus)
    ? rosterStatus
    : membership?.membership_status === 'left'
      ? 'left'
      : 'suspended';
  const isRosterBlocked =
    accessState === 'approved' && (isHardBlockedRosterStatus(rosterStatus) || isHardMembershipState);
  const canViewAdmin = accessState === 'approved' && !isRosterBlocked && isPrivilegedRole(membership?.role);
  const rosterBlockedItem = {
    id: `roster-${blockedRosterStatus}`,
    label: blockedRosterStatus === 'kicked' ? 'Removed' : blockedRosterStatus,
    eyebrow: 'Roster',
  };

  const approvedNavigationItems = useMemo(
    () =>
      navigationItems.filter((item) => {
        if (item.id === 'auth' || item.id === 'pending') {
          return false;
        }

        if (item.id === 'admin') {
          return canViewAdmin;
        }

        return true;
      }),
    [canViewAdmin],
  );

  useEffect(() => {
    if (activePage === 'admin' && !canViewAdmin) {
      setActivePage('dashboard');
    }
  }, [activePage, canViewAdmin]);

  const safeActivePage = activePage === 'admin' && !canViewAdmin ? 'dashboard' : activePage;
  const activeItem = useMemo(
    () => approvedNavigationItems.find((item) => item.id === safeActivePage) ?? approvedNavigationItems[0],
    [approvedNavigationItems, safeActivePage],
  );
  const ActivePage = pageComponents[safeActivePage] ?? Dashboard;

  if (loading) {
    return (
      <AppShell activeItem={statusItems.loading} activePage="loading" navigationItems={[]}>
        <LoadingPanel />
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
      onNavigate={setActivePage}
    >
      <ActivePage />
    </AppShell>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}
