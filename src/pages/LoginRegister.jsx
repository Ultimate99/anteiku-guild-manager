import React, { useEffect, useMemo, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { isSupabaseConfigured } from '../config/supabaseClient.js';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import { getCoreGuilds } from '../services/guildService.js';

const initialForm = {
  email: '',
  password: '',
  username: '',
  ign: '',
  requestedGuildId: '',
};

function translateAuthFeedback(message, t) {
  const messageMap = {
    'If the email exists, a reset link was sent.': 'auth.notices.resetSent',
    'If a confirmation email was sent, confirm it first. Your account still needs guild approval.':
      'auth.notices.confirmationMaybeSent',
    'Invalid email or password.': 'auth.errors.invalidEmailOrPassword',
    'Too many attempts. Try again later.': 'auth.errors.tooManyAttempts',
    'Email limit reached. Try again later.': 'auth.errors.emailLimitReached',
    'Something went wrong. Try again.': 'auth.errors.generic',
  };

  return messageMap[message] ? t(messageMap[message]) : message;
}

export function LoginRegister() {
  const { t } = useLanguage();
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
  const displayNotice = notice ? translateAuthFeedback(notice, t) : '';
  const displayError = error ? translateAuthFeedback(error, t) : '';

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
        throw new Error(t('auth.errors.chooseGuild'));
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
          {isSupabaseConfigured ? t('common.ready') : t('common.setupNeeded')}
        </StatusBadge>
        <h3>{t('auth.enterGuild')}</h3>
        <p>{t('auth.registerForGuildApproval')}</p>
      </section>

      {!isCompletingProfile ? (
        <div className="segmented-control" aria-label={t('auth.mode')}>
          <button
            type="button"
            data-active={mode === 'sign-in' || mode === 'forgot-password'}
            onClick={() => setMode('sign-in')}
          >
            {t('auth.signIn')}
          </button>
          <button type="button" data-active={mode === 'register'} onClick={() => setMode('register')}>
            {t('auth.register')}
          </button>
        </div>
      ) : null}

      <form className="panel form-panel" onSubmit={handleSubmit}>
        {!isCompletingProfile ? (
          <>
            <label>
              {t('auth.email')}
              <input
                type="email"
                value={form.email}
                placeholder={t('auth.emailPlaceholder')}
                onChange={(event) => updateField('email', event.target.value)}
                required
              />
              {mode === 'register' ? <small>{t('auth.realEmailWarning')}</small> : null}
            </label>
            {!isPasswordResetMode ? (
              <label>
                {t('auth.password')}
                <input
                  type="password"
                  value={form.password}
                  placeholder={t('auth.passwordPlaceholder')}
                  onChange={(event) => updateField('password', event.target.value)}
                  required
                />
              </label>
            ) : null}
          </>
        ) : (
          <StatusBadge tone="warning">{t('auth.completeRegistration')}</StatusBadge>
        )}

        {mode === 'register' || isCompletingProfile ? (
          <>
            <label>
              {t('auth.username')}
              <input
                type="text"
                value={form.username}
                placeholder={t('auth.usernamePlaceholder')}
                onChange={(event) => updateField('username', event.target.value)}
                required
              />
            </label>
            <label>
              {t('auth.ign')}
              <input
                type="text"
                value={form.ign}
                placeholder={t('auth.ignPlaceholder')}
                onChange={(event) => updateField('ign', event.target.value)}
                required
              />
            </label>
            <label>
              {t('auth.guild')}
              <select
                value={form.requestedGuildId}
                onChange={(event) => updateField('requestedGuildId', event.target.value)}
                required
              >
                <option value="" disabled>
                  {t('auth.chooseGuild')}
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
            {t('auth.forgotPassword')}
          </button>
        ) : null}

        {!isCompletingProfile && isPasswordResetMode ? (
          <button type="button" className="inline-text-action" onClick={() => setMode('sign-in')}>
            {t('auth.backToSignIn')}
          </button>
        ) : null}

        {displayNotice ? <p className="notice-line">{displayNotice}</p> : null}
        {displayError ? <p className="error-line">{displayError}</p> : null}
        {guildError ? <p className="error-line">{guildError}</p> : null}

        <button type="submit" className="primary-action" disabled={!isSupabaseConfigured || submitting}>
          {submitting
            ? t('common.working')
            : isPasswordResetMode && !isCompletingProfile
              ? t('auth.sendResetLink')
              : mode === 'sign-in' && !isCompletingProfile
                ? t('auth.signIn')
                : t('auth.requestApproval')}
        </button>
      </form>
    </div>
  );
}
