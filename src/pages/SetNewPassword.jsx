import React, { useEffect, useState } from 'react';
import { useAuth } from '../hooks/useAuth.js';

const MIN_PASSWORD_LENGTH = 6;

function getFriendlyPasswordError(error) {
  const message = error?.message || '';
  const normalized = message.toLowerCase();

  if (normalized.includes('expired') || normalized.includes('invalid') || normalized.includes('session')) {
    return 'Reset link expired. Request a new one.';
  }

  if (normalized.includes('password')) {
    return message;
  }

  return message || 'Password could not be updated.';
}

export function SetNewPassword() {
  const { recoveryError, signOut, updateRecoveredPassword } = useAuth();
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [feedback, setFeedback] = useState(recoveryError);
  const [success, setSuccess] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    setFeedback(recoveryError);
  }, [recoveryError]);

  async function handleSubmit(event) {
    event.preventDefault();
    setFeedback('');
    setSuccess('');

    if (!password) {
      setFeedback('New password is required.');
      return;
    }

    if (!confirmPassword) {
      setFeedback('Confirm the new password.');
      return;
    }

    if (password.length < MIN_PASSWORD_LENGTH) {
      setFeedback('Password is too short.');
      return;
    }

    if (password !== confirmPassword) {
      setFeedback('Passwords do not match.');
      return;
    }

    setSubmitting(true);
    try {
      await updateRecoveredPassword(password);
      setPassword('');
      setConfirmPassword('');
      setSuccess('Password updated.');
    } catch (updateError) {
      setFeedback(getFriendlyPasswordError(updateError));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="stack recovery-stack">
      <section className="panel recovery-panel">
        <h3>Set new password</h3>
        <p>Choose a new password to continue.</p>
      </section>

      <form className="panel form-panel recovery-form" onSubmit={handleSubmit}>
        <label>
          New password
          <input
            type="password"
            value={password}
            autoComplete="new-password"
            placeholder="New password"
            onChange={(event) => setPassword(event.target.value)}
            required
          />
        </label>

        <label>
          Confirm password
          <input
            type="password"
            value={confirmPassword}
            autoComplete="new-password"
            placeholder="Confirm password"
            onChange={(event) => setConfirmPassword(event.target.value)}
            required
          />
        </label>

        {success ? <p className="notice-line">{success}</p> : null}
        {feedback ? <p className="error-line">{feedback}</p> : null}

        <div className="recovery-actions">
          <button type="submit" className="primary-action" disabled={submitting}>
            {submitting ? 'Updating...' : 'Update password'}
          </button>
          <button type="button" className="secondary-action" onClick={signOut} disabled={submitting}>
            Sign out
          </button>
        </div>
      </form>
    </div>
  );
}
