import { useCallback, useEffect, useState } from 'react';
import { loadActiveProfile } from '../services/accountSwitcherService.js';
import { useAuth } from './useAuth.js';

export function useActiveProfileSummary() {
  const { profile } = useAuth();
  const [activeProfile, setActiveProfile] = useState(null);
  const [activeProfileLoading, setActiveProfileLoading] = useState(false);
  const [activeProfileError, setActiveProfileError] = useState('');

  const refreshActiveProfile = useCallback(async () => {
    if (!profile?.id) {
      setActiveProfile(null);
      setActiveProfileError('');
      return null;
    }

    setActiveProfileLoading(true);
    setActiveProfileError('');

    try {
      const nextActiveProfile = await loadActiveProfile();
      setActiveProfile(nextActiveProfile);
      return nextActiveProfile;
    } catch (error) {
      setActiveProfile(null);
      setActiveProfileError(error.message || 'active_profile_load_failed');
      return null;
    } finally {
      setActiveProfileLoading(false);
    }
  }, [profile?.id]);

  useEffect(() => {
    let cancelled = false;

    async function loadInitialActiveProfile() {
      if (!profile?.id) {
        setActiveProfile(null);
        setActiveProfileError('');
        return;
      }

      setActiveProfileLoading(true);
      setActiveProfileError('');

      try {
        const nextActiveProfile = await loadActiveProfile();

        if (!cancelled) {
          setActiveProfile(nextActiveProfile);
        }
      } catch (error) {
        if (!cancelled) {
          setActiveProfile(null);
          setActiveProfileError(error.message || 'active_profile_load_failed');
        }
      } finally {
        if (!cancelled) {
          setActiveProfileLoading(false);
        }
      }
    }

    loadInitialActiveProfile();

    return () => {
      cancelled = true;
    };
  }, [profile?.id]);

  return {
    activeProfile,
    activeProfileLoading,
    activeProfileError,
    refreshActiveProfile,
  };
}
