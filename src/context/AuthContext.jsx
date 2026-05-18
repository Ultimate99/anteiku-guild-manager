import React, { createContext, useCallback, useEffect, useMemo, useState } from 'react';
import { isSupabaseConfigured } from '../config/supabaseClient.js';
import {
  getSession,
  onAuthStateChange,
  signInWithPassword,
  signOutUser,
  signUpWithPassword,
} from '../services/authService.js';
import { loadSafeViewerState, registerProfile } from '../services/profileService.js';

export const AuthContext = createContext(null);

function getAccessState(session, profile) {
  if (!isSupabaseConfigured) {
    return 'unconfigured';
  }

  if (!session) {
    return 'unauthenticated';
  }

  if (!profile) {
    return 'needs_profile';
  }

  return profile.approval_status ?? 'pending';
}

export function AuthProvider({ children }) {
  const [session, setSession] = useState(null);
  const [profile, setProfile] = useState(null);
  const [membership, setMembership] = useState(null);
  const [guild, setGuild] = useState(null);
  const [loading, setLoading] = useState(true);
  const [profileLoading, setProfileLoading] = useState(false);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');

  const loadViewer = useCallback(async (activeSession) => {
    if (!activeSession?.user?.id || !isSupabaseConfigured) {
      setProfile(null);
      setMembership(null);
      setGuild(null);
      return null;
    }

    setProfileLoading(true);
    try {
      const viewerState = await loadSafeViewerState(activeSession.user.id);
      setProfile(viewerState.profile);
      setMembership(viewerState.membership);
      setGuild(viewerState.guild);
      return viewerState;
    } catch (viewerError) {
      setProfile(null);
      setMembership(null);
      setGuild(null);
      throw viewerError;
    } finally {
      setProfileLoading(false);
    }
  }, []);

  const refreshProfile = useCallback(async () => {
    setError('');
    try {
      return await loadViewer(session);
    } catch (refreshError) {
      setError(refreshError.message);
      return null;
    }
  }, [loadViewer, session]);

  useEffect(() => {
    let mounted = true;

    async function restoreSession() {
      if (!isSupabaseConfigured) {
        setLoading(false);
        return;
      }

      try {
        const restoredSession = await getSession();

        if (!mounted) {
          return;
        }

        setSession(restoredSession);
        await loadViewer(restoredSession);
      } catch (sessionError) {
        if (mounted) {
          setError(sessionError.message);
        }
      } finally {
        if (mounted) {
          setLoading(false);
        }
      }
    }

    restoreSession();

    function loadViewerAfterAuthEvent(nextSession) {
      setTimeout(async () => {
        if (!mounted) {
          return;
        }

        try {
          await loadViewer(nextSession);
        } catch (authStateError) {
          if (mounted) {
            setError(authStateError.message);
          }
        } finally {
          if (mounted) {
            setLoading(false);
          }
        }
      }, 0);
    }

    const subscription = onAuthStateChange((event, nextSession) => {
      if (!mounted || event === 'INITIAL_SESSION') {
        return;
      }

      setSession(nextSession);
      setNotice('');
      setError('');
      loadViewerAfterAuthEvent(nextSession);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, [loadViewer]);

  const signIn = useCallback(
    async (email, password) => {
      setError('');
      setNotice('');
      const data = await signInWithPassword(email, password);
      setSession(data.session);
      await loadViewer(data.session);
      return data;
    },
    [loadViewer],
  );

  const signUpAndRegister = useCallback(
    async ({ email, password, username, ign, requestedGuildId }) => {
      setError('');
      setNotice('');
      const data = await signUpWithPassword(email, password);

      if (!data.session || !data.user) {
        setSession(null);
        setNotice('Check your email to confirm the account, then sign in to finish registration.');
        return {
          needsEmailConfirmation: true,
        };
      }

      setSession(data.session);
      const normalizedUsername = username.trim().toLowerCase();
      await registerProfile({
        username: normalizedUsername,
        ign: ign.trim(),
        requestedGuildId,
      });
      await loadViewer(data.session);

      return {
        needsEmailConfirmation: false,
      };
    },
    [loadViewer],
  );

  const completeRegistration = useCallback(
    async ({ username, ign, requestedGuildId }) => {
      if (!session?.user) {
        throw new Error('Sign in before completing registration.');
      }

      setError('');
      setNotice('');
      const normalizedUsername = username.trim().toLowerCase();
      await registerProfile({
        username: normalizedUsername,
        ign: ign.trim(),
        requestedGuildId,
      });
      await loadViewer(session);
    },
    [loadViewer, session],
  );

  const signOut = useCallback(async () => {
    setError('');
    setNotice('');
    try {
      await signOutUser();
    } finally {
      setSession(null);
      setProfile(null);
      setMembership(null);
      setGuild(null);
      setProfileLoading(false);
      setLoading(false);
    }
  }, []);

  const value = useMemo(
    () => ({
      session,
      user: session?.user ?? null,
      profile,
      membership,
      guild,
      accessState: getAccessState(session, profile),
      loading,
      profileLoading,
      error,
      notice,
      setError,
      setNotice,
      refreshProfile,
      signIn,
      signUpAndRegister,
      completeRegistration,
      signOut,
    }),
    [
      session,
      profile,
      membership,
      guild,
      loading,
      profileLoading,
      error,
      notice,
      refreshProfile,
      signIn,
      signUpAndRegister,
      completeRegistration,
      signOut,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
