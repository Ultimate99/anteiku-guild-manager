import React, { useEffect, useState } from 'react';
import { RankBadge } from '../components/RankBadge.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import { rosterStatusTone } from '../services/adminMemberService.js';
import { loadMyCpRankSummary } from '../services/cpRankBadgeService.js';
import {
  formatCpDisplayValue,
  isValidCpValueInput,
  loadMyCp,
  loadMyCpUpdateWindow,
  submitMyCpUpdate,
} from '../services/cpWindowService.js';
import { updateMyProfile } from '../services/profileService.js';

export function Profile() {
  const { t } = useLanguage();
  const { guild, membership, profile, refreshProfile } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [ignDraft, setIgnDraft] = useState(profile?.ign ?? '');
  const [saving, setSaving] = useState(false);
  const [profileMessage, setProfileMessage] = useState('');
  const [profileError, setProfileError] = useState('');
  const [cpState, setCpState] = useState(null);
  const [cpWindowState, setCpWindowState] = useState(null);
  const [cpDraft, setCpDraft] = useState('');
  const [cpLoading, setCpLoading] = useState(false);
  const [cpSubmitting, setCpSubmitting] = useState(false);
  const [cpMessage, setCpMessage] = useState('');
  const [cpError, setCpError] = useState('');
  const [rankSummary, setRankSummary] = useState(null);
  const [rankLoading, setRankLoading] = useState(false);
  const [rankError, setRankError] = useState('');
  const rosterStatus = membership?.roster_status ?? 'active';
  const rankVisualKey = rankSummary?.visualKey ?? 'unranked';
  const canSubmitCp = Boolean(cpWindowState?.can_submit);
  const cpWindowMessage =
    cpWindowState?.reason === 'not_eligible_roster_status' ? t('profile.cpNotEligible') : t('profile.cpWindowClosed');

  useEffect(() => {
    if (!isEditing) {
      setIgnDraft(profile?.ign ?? '');
    }
  }, [isEditing, profile?.ign]);

  useEffect(() => {
    let cancelled = false;

    async function loadCpPanel() {
      if (!profile?.id || !membership?.id) {
        return;
      }

      setCpLoading(true);
      setCpError('');
      setCpMessage('');

      try {
        const [nextCpState, nextWindowState] = await Promise.all([loadMyCp(), loadMyCpUpdateWindow()]);

        if (!cancelled) {
          setCpState(nextCpState);
          setCpWindowState(nextWindowState);
          setCpDraft(nextCpState?.cp_value === null || nextCpState?.cp_value === undefined ? '' : String(nextCpState.cp_value));
        }
      } catch (loadError) {
        if (!cancelled) {
          setCpState(null);
          setCpWindowState(null);
          setCpError(loadError.message || t('profile.cpLoadError'));
        }
      } finally {
        if (!cancelled) {
          setCpLoading(false);
        }
      }
    }

    loadCpPanel();

    return () => {
      cancelled = true;
    };
  }, [membership?.id, profile?.id, t]);

  useEffect(() => {
    let cancelled = false;

    async function loadRankBadge() {
      if (!profile?.id || !membership?.id) {
        return;
      }

      setRankLoading(true);
      setRankError('');

      try {
        const nextRankSummary = await loadMyCpRankSummary();

        if (!cancelled) {
          setRankSummary(nextRankSummary);
        }
      } catch {
        if (!cancelled) {
          setRankSummary(null);
          setRankError('load_error');
        }
      } finally {
        if (!cancelled) {
          setRankLoading(false);
        }
      }
    }

    loadRankBadge();

    return () => {
      cancelled = true;
    };
  }, [membership?.id, profile?.id]);

  function startEditing() {
    setIgnDraft(profile?.ign ?? '');
    setProfileMessage('');
    setProfileError('');
    setIsEditing(true);
  }

  function cancelEditing() {
    setIgnDraft(profile?.ign ?? '');
    setProfileError('');
    setIsEditing(false);
  }

  async function saveProfile(event) {
    event.preventDefault();
    const nextIgn = ignDraft.trim();

    if (!nextIgn) {
      setProfileError(t('profile.ignRequired'));
      return;
    }

    setSaving(true);
    setProfileError('');
    setProfileMessage('');

    try {
      await updateMyProfile({
        ign: nextIgn,
        avatarKey: profile?.avatar_key ?? null,
      });
      await refreshProfile();
      setProfileMessage(t('profile.ignUpdated'));
      setIsEditing(false);
    } catch (saveError) {
      setProfileError(saveError.message);
    } finally {
      setSaving(false);
    }
  }

  async function refreshCpPanel({ showMessage = false } = {}) {
    setCpLoading(true);
    setCpError('');
    if (!showMessage) {
      setCpMessage('');
    }

    try {
      const [nextCpState, nextWindowState] = await Promise.all([loadMyCp(), loadMyCpUpdateWindow()]);
      setCpState(nextCpState);
      setCpWindowState(nextWindowState);
      setCpDraft(nextCpState?.cp_value === null || nextCpState?.cp_value === undefined ? '' : String(nextCpState.cp_value));
      if (showMessage) {
        setCpMessage(t('profile.cpUpdated'));
      }
    } catch (loadError) {
      setCpError(loadError.message || t('profile.cpLoadError'));
    } finally {
      setCpLoading(false);
    }
  }

  async function saveCp(event) {
    event.preventDefault();
    const nextCpValue = cpDraft.trim();

    if (!nextCpValue) {
      setCpError(t('profile.cpRequired'));
      return;
    }

    if (!isValidCpValueInput(nextCpValue)) {
      setCpError(t('profile.cpInvalid'));
      return;
    }

    setCpSubmitting(true);
    setCpError('');
    setCpMessage('');

    try {
      await submitMyCpUpdate({ cpValue: Number(nextCpValue) });
      await refreshCpPanel({ showMessage: true });
    } catch (submitError) {
      setCpError(submitError.message);
    } finally {
      setCpSubmitting(false);
    }
  }

  return (
    <div className="stack">
      <section className="panel profile-panel compact-profile-panel rank-profile-panel" data-rank-visual={rankVisualKey}>
        <div className="avatar-placeholder rank-avatar" aria-hidden="true">
          AG
        </div>
        <div>
          <div className="status-badge-row">
            <StatusBadge tone="success">{t(`approvalStatus.${profile?.approval_status ?? 'approved'}`)}</StatusBadge>
            <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
          </div>
          <h3>{profile?.ign ?? t('dashboard.memberFallback')}</h3>
          <p>@{profile?.username ?? t('common.unknown')}</p>
          <RankBadge className="profile-rank-badge" summary={rankSummary} loading={rankLoading} error={rankError} />
        </div>
      </section>

      <section className="panel profile-edit-panel member-compact-panel" aria-label={t('profile.editProfile')}>
        <div className="profile-edit-header">
          <div>
            <StatusBadge tone={isEditing ? 'warning' : 'success'}>
              {isEditing ? t('profile.editingIgn') : t('profile.profileLocked')}
            </StatusBadge>
            <h3>{t('profile.memberProfile')}</h3>
            <p>{t('profile.lockedFields')}</p>
            {rosterStatus !== 'active' ? <p className="muted-copy">{t(`roster.status.${rosterStatus}.summary`)}</p> : null}
          </div>
          {!isEditing ? (
            <button type="button" className="secondary-action compact-action" onClick={startEditing}>
              {t('profile.edit')}
            </button>
          ) : null}
        </div>

        {profileMessage ? <p className="notice-line">{profileMessage}</p> : null}
        {profileError ? <p className="error-line">{profileError}</p> : null}

        {isEditing ? (
          <form className="profile-edit-form" onSubmit={saveProfile}>
            <label>
              {t('profile.ign')}
              <input
                type="text"
                value={ignDraft}
                placeholder={t('auth.ignPlaceholder')}
                onChange={(event) => setIgnDraft(event.target.value)}
                disabled={saving}
                required
              />
            </label>
            <div className="profile-edit-actions">
              <button type="submit" className="primary-action" disabled={saving}>
                {saving ? t('profile.saving') : t('common.save')}
              </button>
              <button type="button" className="secondary-action" onClick={cancelEditing} disabled={saving}>
                {t('common.cancel')}
              </button>
            </div>
          </form>
        ) : null}
      </section>

      <section className="panel detail-list compact-detail-list" aria-label={t('profile.details')}>
        <div>
          <span>{t('profile.username')}</span>
          <strong>{profile?.profile_slug ?? profile?.username ?? t('common.unknown')}</strong>
          <small>{t('profile.lockedUsername')}</small>
        </div>
        <div>
          <span>{t('profile.ign')}</span>
          <strong>{profile?.ign ?? t('common.notSet')}</strong>
          <small>{t('profile.editableIgn')}</small>
        </div>
        <div>
          <span>{t('profile.guild')}</span>
          <strong>{guild?.name ?? t('guild.unknown')}</strong>
        </div>
        <div>
          <span>{t('profile.role')}</span>
          <strong>{t(`roles.${membership?.role ?? 'member'}`)}</strong>
        </div>
        <div>
          <span>{t('profile.rosterStatus')}</span>
          <strong>{t(`roster.status.${rosterStatus}.label`)}</strong>
          <small>{t(`roster.status.${rosterStatus}.summary`)}</small>
        </div>
      </section>

      <section className="panel member-compact-panel profile-cp-panel" aria-label={t('profile.yourCp')}>
        <div className="section-heading-row profile-cp-heading">
          <div>
            <StatusBadge tone={canSubmitCp ? 'success' : 'warning'}>
              {canSubmitCp ? t('admin.cp.windowOpen') : t('admin.cp.windowClosed')}
            </StatusBadge>
            <h3>{t('profile.yourCp')}</h3>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={() => refreshCpPanel()} disabled={cpLoading || cpSubmitting}>
            {cpLoading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>

        <div className="approval-meta compact-meta profile-cp-meta">
          <div>
            <span>{t('profile.currentCp')}</span>
            <strong>{formatCpDisplayValue(cpState?.cp_value, t('profile.cpNotEntered'))}</strong>
          </div>
          <div>
            <span>{t('admin.cp.windowStatus')}</span>
            <strong>{canSubmitCp ? t('admin.cp.windowOpen') : t('admin.cp.windowClosed')}</strong>
          </div>
        </div>

        {cpMessage ? <p className="notice-line">{cpMessage}</p> : null}
        {cpError ? <p className="error-line">{cpError}</p> : null}

        {canSubmitCp ? (
          <form className="profile-cp-form" onSubmit={saveCp}>
            <label>
              {t('profile.updateCp')}
              <input
                type="text"
                inputMode="numeric"
                pattern="[0-9]*"
                value={cpDraft}
                placeholder={t('profile.currentCp')}
                onChange={(event) => setCpDraft(event.target.value)}
                disabled={cpLoading || cpSubmitting}
                required
              />
            </label>
            <button type="submit" className="primary-action" disabled={cpLoading || cpSubmitting}>
              {cpSubmitting ? t('common.working') : t('profile.submitCp')}
            </button>
          </form>
        ) : (
          <p className="muted-line compact-state-line">{cpWindowMessage}</p>
        )}
      </section>
    </div>
  );
}
