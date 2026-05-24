import React, { createContext, useCallback, useEffect, useMemo, useState } from 'react';
import { isSupabaseConfigured } from '../config/supabaseClient.js';
import {
  getSession,
  onAuthStateChange,
  requestPasswordReset as requestPasswordResetEmail,
  signInWithPassword,
  signOutUser,
  signUpWithPassword,
  updateRecoveredPassword as updateRecoveredPasswordAuth,
} from '../services/authService.js';
import { loadSafeViewerState, registerProfile } from '../services/profileService.js';

export const AuthContext = createContext(null);
const RECOVERY_MARKER_KEY = 'anteiku.passwordRecoveryRequired';

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

function safeSessionStorage() {
  if (typeof window === 'undefined') {
    return null;
  }

  try {
    return window.sessionStorage;
  } catch {
    return null;
  }
}

function readRecoveryMarker() {
  return safeSessionStorage()?.getItem(RECOVERY_MARKER_KEY) === 'true';
}

function writeRecoveryMarker() {
  safeSessionStorage()?.setItem(RECOVERY_MARKER_KEY, 'true');
}

function removeRecoveryMarker() {
  safeSessionStorage()?.removeItem(RECOVERY_MARKER_KEY);
}

function getRecoveryUrlState() {
  if (typeof window === 'undefined') {
    return { isRecovery: false, errorMessage: '' };
  }

  const searchParams = new URLSearchParams(window.location.search);
  const hashValue = window.location.hash.startsWith('#') ? window.location.hash.slice(1) : window.location.hash;
  const hashParams = new URLSearchParams(hashValue);
  const type = searchParams.get('type') || hashParams.get('type');
  const mode = searchParams.get('mode') || hashParams.get('mode');
  const event = searchParams.get('event') || hashParams.get('event');
  const error = searchParams.get('error') || hashParams.get('error');
  const errorCode = searchParams.get('error_code') || hashParams.get('error_code');
  const errorDescription = searchParams.get('error_description') || hashParams.get('error_description');
  const isRecovery = [type, mode, event].some((value) => value?.toLowerCase() === 'recovery');

  if (!error && !errorCode && !errorDescription) {
    return { isRecovery, errorMessage: '' };
  }

  const combinedError = `${error ?? ''} ${errorCode ?? ''} ${errorDescription ?? ''}`.toLowerCase();
  const errorMessage =
    combinedError.includes('expired') || combinedError.includes('otp')
      ? 'Reset link expired. Request a new one.'
      : 'Reset link invalid. Request a new one.';

  return { isRecovery: true, errorMessage };
}

function clearRecoveryUrlState() {
  if (typeof window === 'undefined' || (!window.location.search && !window.location.hash)) {
    return;
  }

  const cleanUrl = `${window.location.origin}${window.location.pathname}`;
  window.history.replaceState({}, document.title, cleanUrl);
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
  const [recoveryRequired, setRecoveryRequired] = useState(() => readRecoveryMarker());
  const [recoveryError, setRecoveryError] = useState('');

  const requirePasswordRecovery = useCallback((message = '') => {
    writeRecoveryMarker();
    setRecoveryRequired(true);
    setRecoveryError(message);
    setNotice('');
    setError('');
  }, []);

  const clearPasswordRecovery = useCallback(() => {
    removeRecoveryMarker();
    clearRecoveryUrlState();
    setRecoveryRequired(false);
    setRecoveryError('');
  }, []);

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
        const recoveryUrlState = getRecoveryUrlState();
        const restoredSession = await getSession();

        if (!mounted) {
          return;
        }

        setSession(restoredSession);
        if (recoveryUrlState.isRecovery || (readRecoveryMarker() && restoredSession)) {
          requirePasswordRecovery(recoveryUrlState.errorMessage);
        } else if (!restoredSession) {
          clearPasswordRecovery();
        }

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

      if (event === 'PASSWORD_RECOVERY') {
        requirePasswordRecovery();
      }

      if (event === 'SIGNED_OUT') {
        clearPasswordRecovery();
      }

      loadViewerAfterAuthEvent(nextSession);
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, [clearPasswordRecovery, loadViewer, requirePasswordRecovery]);

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

  const requestPasswordReset = useCallback(async (email) => {
    setError('');
    setNotice('');
    await requestPasswordResetEmail(email);
    setNotice('If the email exists, a reset link was sent.');
  }, []);

  const updateRecoveredPassword = useCallback(
    async (newPassword) => {
      if (!session?.user) {
        throw new Error('Reset link expired. Request a new one.');
      }

      setError('');
      setNotice('');
      await updateRecoveredPasswordAuth(newPassword);
      clearPasswordRecovery();
      setNotice('Password updated.');

      const currentSession = await getSession();
      setSession(currentSession);
      await loadViewer(currentSession);
    },
    [clearPasswordRecovery, loadViewer, session],
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
      clearPasswordRecovery();
    }
  }, [clearPasswordRecovery]);

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
      recoveryRequired,
      recoveryError,
      setError,
      setNotice,
      refreshProfile,
      signIn,
      requestPasswordReset,
      updateRecoveredPassword,
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
      recoveryRequired,
      recoveryError,
      refreshProfile,
      signIn,
      requestPasswordReset,
      updateRecoveredPassword,
      signUpAndRegister,
      completeRegistration,
      signOut,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
