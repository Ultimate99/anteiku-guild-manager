import React, { useEffect, useMemo, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { isSupabaseConfigured } from '../config/supabaseClient.js';
import { useAuth } from '../hooks/useAuth.js';
import { getCoreGuilds } from '../services/guildService.js';

const initialForm = {
  email: '',
  password: '',
  username: '',
  ign: '',
  requestedGuildId: '',
};

export function LoginRegister() {
  const {
    accessState,
    completeRegistration,
    error,
    notice,
    setError,
    setNotice,
    requestPasswordReset,
    signIn,
    signUpAndRegister,
    user,
  } = useAuth();
  const [mode, setMode] = useState('sign-in');
  const [form, setForm] = useState(initialForm);
  const [guilds, setGuilds] = useState([]);
  const [guildError, setGuildError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const isCompletingProfile = accessState === 'needs_profile';
  const isPasswordResetMode = mode === 'forgot-password';

  useEffect(() => {
    if (isCompletingProfile) {
      setMode('register');
    }
  }, [isCompletingProfile]);

  useEffect(() => {
    let mounted = true;

    async function loadGuilds() {
      try {
        const coreGuilds = await getCoreGuilds();

        if (!mounted) {
          return;
        }

        setGuilds(coreGuilds);
        setForm((current) => ({
          ...current,
          requestedGuildId: current.requestedGuildId || coreGuilds[0]?.id || '',
        }));
      } catch (loadError) {
        if (mounted) {
          setGuildError(loadError.message);
        }
      }
    }

    loadGuilds();

    return () => {
      mounted = false;
    };
  }, []);

  const normalizedUsername = useMemo(() => form.username.trim().toLowerCase(), [form.username]);

  function updateField(field, value) {
    setForm((current) => ({
      ...current,
      [field]: field === 'username' ? value.toLowerCase() : value,
    }));
  }

  async function handleSubmit(event) {
    event.preventDefault();
    setSubmitting(true);
    setError('');
    setNotice('');

    try {
      if (mode === 'sign-in' && !isCompletingProfile) {
        await signIn(form.email.trim(), form.password);
        return;
      }

      if (isPasswordResetMode && !isCompletingProfile) {
        await requestPasswordReset(form.email.trim());
        setForm((current) => ({
          ...current,
          password: '',
        }));
        return;
      }

      if (!form.requestedGuildId) {
        throw new Error('Choose a guild before registering.');
      }

      if (isCompletingProfile && user) {
        await completeRegistration({
          username: normalizedUsername,
          ign: form.ign,
          requestedGuildId: form.requestedGuildId,
        });
        return;
      }

      await signUpAndRegister({
        email: form.email.trim(),
        password: form.password,
        username: normalizedUsername,
        ign: form.ign,
        requestedGuildId: form.requestedGuildId,
      });
    } catch (submitError) {
      setError(submitError.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <StatusBadge tone={isSupabaseConfigured ? 'success' : 'danger'}>
          {isSupabaseConfigured ? 'Ready' : 'Setup needed'}
        </StatusBadge>
        <h3>Enter the guild</h3>
        <p>Sign in or register for approval.</p>
      </section>

      {!isCompletingProfile ? (
        <div className="segmented-control" aria-label="Auth mode">
          <button
            type="button"
            data-active={mode === 'sign-in' || mode === 'forgot-password'}
            onClick={() => setMode('sign-in')}
          >
            Sign in
          </button>
          <button type="button" data-active={mode === 'register'} onClick={() => setMode('register')}>
            Register
          </button>
        </div>
      ) : null}

      <form className="panel form-panel" onSubmit={handleSubmit}>
        {!isCompletingProfile ? (
          <>
            <label>
              Email
              <input
                type="email"
                value={form.email}
                placeholder="member@example.com"
                onChange={(event) => updateField('email', event.target.value)}
                required
              />
            </label>
            {!isPasswordResetMode ? (
              <label>
                Password
                <input
                  type="password"
                  value={form.password}
                  placeholder="Your password"
                  onChange={(event) => updateField('password', event.target.value)}
                  required
                />
              </label>
            ) : null}
          </>
        ) : (
          <StatusBadge tone="warning">Complete registration</StatusBadge>
        )}

        {mode === 'register' || isCompletingProfile ? (
          <>
            <label>
              Username
              <input
                type="text"
                value={form.username}
                placeholder="locked-after-registration"
                onChange={(event) => updateField('username', event.target.value)}
                required
              />
            </label>
            <label>
              IGN
              <input
                type="text"
                value={form.ign}
                placeholder="Your in-game name"
                onChange={(event) => updateField('ign', event.target.value)}
                required
              />
            </label>
            <label>
              Guild
              <select
                value={form.requestedGuildId}
                onChange={(event) => updateField('requestedGuildId', event.target.value)}
                required
              >
                <option value="" disabled>
                  Choose guild
                </option>
                {guilds.map((guild) => (
                  <option key={guild.id} value={guild.id}>
                    {guild.name}
                  </option>
                ))}
              </select>
            </label>
          </>
        ) : null}

        {!isCompletingProfile && mode === 'sign-in' ? (
          <button type="button" className="inline-text-action" onClick={() => setMode('forgot-password')}>
            Forgot password?
          </button>
        ) : null}

        {!isCompletingProfile && isPasswordResetMode ? (
          <button type="button" className="inline-text-action" onClick={() => setMode('sign-in')}>
            Back to sign in
          </button>
        ) : null}

        {notice ? <p className="notice-line">{notice}</p> : null}
        {error ? <p className="error-line">{error}</p> : null}
        {guildError ? <p className="error-line">{guildError}</p> : null}

        <button type="submit" className="primary-action" disabled={!isSupabaseConfigured || submitting}>
          {submitting
            ? 'Working...'
            : isPasswordResetMode && !isCompletingProfile
              ? 'Send reset link'
              : mode === 'sign-in' && !isCompletingProfile
              ? 'Sign in'
              : 'Register for approval'}
        </button>
      </form>
    </div>
  );
}
