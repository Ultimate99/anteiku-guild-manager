import React, { useEffect, useState } from 'react';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';

const MIN_PASSWORD_LENGTH = 6;

function getFriendlyPasswordError(error, t) {
  const message = error?.message || '';
  const normalized = message.toLowerCase();

  if (normalized.includes('expired') || normalized.includes('invalid') || normalized.includes('session')) {
    return t('recovery.expired');
  }

  if (normalized.includes('password')) {
    return message;
  }

  return message || t('recovery.failed');
}

export function SetNewPassword() {
  const { t } = useLanguage();
  const { recoveryError, signOut, updateRecoveredPassword } = useAuth();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [feedback, setFeedback] = useState(recoveryError);
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    setFeedback(recoveryError ? getFriendlyPasswordError({ message: recoveryError }, t) : '');
  }, [recoveryError, t]);

  async function handleSubmit(event) {
    event.preventDefault();
    setFeedback('');
    setSuccess('');

    if (!password) {
      setFeedback(t('recovery.newPasswordRequired'));
      return;
    }

    if (!confirmPassword) {
      setFeedback(t('recovery.confirmRequired'));
      return;
    }

    if (password.length < MIN_PASSWORD_LENGTH) {
      setFeedback(t('recovery.tooShort'));
      return;
    }

    if (password !== confirmPassword) {
      setFeedback(t('recovery.mismatch'));
      return;
    }

    setSubmitting(true);
    try {
      await updateRecoveredPassword(password);
      setPassword('');
      setConfirmPassword('');
      setSuccess(t('recovery.passwordUpdated'));
    } catch (updateError) {
      setFeedback(getFriendlyPasswordError(updateError, t));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="stack recovery-stack">
      <section className="panel recovery-panel member-compact-panel">
        <h3>{t('recovery.title')}</h3>
        <p>{t('recovery.body')}</p>
      </section>

      <form className="panel form-panel recovery-form compact-form-panel" onSubmit={handleSubmit}>
        <label>
          {t('recovery.newPassword')}
          <input
            type="password"
            value={password}
            autoComplete="new-password"
            placeholder={t('recovery.newPassword')}
            onChange={(event) => setPassword(event.target.value)}
            required
          />
        </label>

        <label>
          {t('recovery.confirmPassword')}
          <input
            type="password"
            value={confirmPassword}
            autoComplete="new-password"
            placeholder={t('recovery.confirmPassword')}
            onChange={(event) => setConfirmPassword(event.target.value)}
            required
          />
        </label>

        {success ? <p className="notice-line">{success}</p> : null}
        {feedback ? <p className="error-line">{feedback}</p> : null}

        <div className="recovery-actions">
          <button type="submit" className="primary-action" disabled={submitting}>
            {submitting ? t('recovery.updating') : t('recovery.updatePassword')}
          </button>
          <button type="button" className="secondary-action" onClick={signOut} disabled={submitting}>
            {t('common.signOut')}
          </button>
        </div>
      </form>
    </div>
  );
}
