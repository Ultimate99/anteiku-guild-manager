import React, { useEffect, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import { rosterStatusTone } from '../services/adminMemberService.js';
import { updateMyProfile } from '../services/profileService.js';

export function Profile() {
  const { t } = useLanguage();
  const { guild, membership, profile, refreshProfile } = useAuth();
  const [isEditing, setIsEditing] = useState(false);
  const [ignDraft, setIgnDraft] = useState(profile?.ign ?? '');
  const [saving, setSaving] = useState(false);
  const [profileMessage, setProfileMessage] = useState('');
  const [profileError, setProfileError] = useState('');
  const rosterStatus = membership?.roster_status ?? 'active';

  useEffect(() => {
    if (!isEditing) {
      setIgnDraft(profile?.ign ?? '');
    }
  }, [isEditing, profile?.ign]);

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

  return (
    <div className="stack">
      <section className="panel profile-panel">
        <div className="avatar-placeholder" aria-hidden="true">
          AG
        </div>
        <div>
          <div className="status-badge-row">
            <StatusBadge tone="success">{t(`approvalStatus.${profile?.approval_status ?? 'approved'}`)}</StatusBadge>
            <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
          </div>
          <h3>{profile?.ign ?? t('dashboard.memberFallback')}</h3>
          <p>@{profile?.username ?? t('common.unknown')}</p>
        </div>
      </section>

      <section className="panel profile-edit-panel" aria-label={t('profile.editProfile')}>
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

      <section className="panel detail-list" aria-label={t('profile.details')}>
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
    </div>
  );
}
