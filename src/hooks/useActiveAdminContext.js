import { useCallback, useEffect, useState } from 'react';
import { loadMyActiveAdminContext } from '../services/adminContextService.js';
import { useAuth } from './useAuth.js';

export function useActiveAdminContext() {
  const { accessState, profile } = useAuth();
  const [activeAdminContext, setActiveAdminContext] = useState(null);
  const [activeAdminContextLoading, setActiveAdminContextLoading] = useState(false);
  const [activeAdminContextError, setActiveAdminContextError] = useState('');
  const shouldLoadContext = accessState === 'approved' && Boolean(profile?.id);

  const refreshActiveAdminContext = useCallback(async () => {
    if (!shouldLoadContext) {
      setActiveAdminContext(null);
      setActiveAdminContextError('');
      setActiveAdminContextLoading(false);
      return null;
    }

    setActiveAdminContextLoading(true);
    setActiveAdminContextError('');

    try {
      const nextContext = await loadMyActiveAdminContext();
      setActiveAdminContext(nextContext);
      return nextContext;
    } catch (error) {
      setActiveAdminContext(null);
      setActiveAdminContextError(error.message || 'active_admin_context_load_failed');
      return null;
    } finally {
      setActiveAdminContextLoading(false);
    }
  }, [profile?.id, shouldLoadContext]);

  useEffect(() => {
    let cancelled = false;

    async function loadContext() {
      if (!shouldLoadContext) {
        setActiveAdminContext(null);
        setActiveAdminContextError('');
        setActiveAdminContextLoading(false);
        return;
      }

      setActiveAdminContextLoading(true);
      setActiveAdminContextError('');

      try {
        const nextContext = await loadMyActiveAdminContext();

        if (!cancelled) {
          setActiveAdminContext(nextContext);
        }
      } catch (error) {
        if (!cancelled) {
          setActiveAdminContext(null);
          setActiveAdminContextError(error.message || 'active_admin_context_load_failed');
        }
      } finally {
        if (!cancelled) {
          setActiveAdminContextLoading(false);
        }
      }
    }

    loadContext();

    return () => {
      cancelled = true;
    };
  }, [profile?.id, shouldLoadContext]);

  const isContextPending =
    shouldLoadContext && (activeAdminContextLoading || (!activeAdminContext && !activeAdminContextError));

  return {
    activeAdminContext,
    activeAdminContextLoading: isContextPending,
    activeAdminContextError,
    canAccessAdminPanel: Boolean(activeAdminContext?.canAccessAdminPanel),
    refreshActiveAdminContext,
  };
}
