import React, { useEffect, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  formatRosterStatus,
  getRosterStatusSummary,
  rosterStatusTone,
} from '../services/adminMemberService.js';
import { updateMyProfile } from '../services/profileService.js';

export function Profile() {
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
      setProfileError('IGN is required.');
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
      setProfileMessage('IGN updated.');
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
            <StatusBadge tone="success">{profile?.approval_status ?? 'approved'}</StatusBadge>
            <StatusBadge tone={rosterStatusTone(rosterStatus)}>{formatRosterStatus(rosterStatus)}</StatusBadge>
          </div>
          <h3>{profile?.ign ?? 'Member'}</h3>
          <p>@{profile?.username ?? 'unknown'}</p>
        </div>
      </section>

      <section className="panel profile-edit-panel" aria-label="Edit profile">
        <div className="profile-edit-header">
          <div>
            <StatusBadge tone={isEditing ? 'warning' : 'success'}>
              {isEditing ? 'Editing IGN' : 'Profile locked'}
            </StatusBadge>
            <h3>Member profile</h3>
            <p>IGN can be edited. Username, guild, role, and status are locked.</p>
            {rosterStatus !== 'active' ? <p className="muted-copy">{getRosterStatusSummary(rosterStatus)}</p> : null}
          </div>
          {!isEditing ? (
            <button type="button" className="secondary-action compact-action" onClick={startEditing}>
              Edit
            </button>
          ) : null}
        </div>

        {profileMessage ? <p className="notice-line">{profileMessage}</p> : null}
        {profileError ? <p className="error-line">{profileError}</p> : null}

        {isEditing ? (
          <form className="profile-edit-form" onSubmit={saveProfile}>
            <label>
              IGN
              <input
                type="text"
                value={ignDraft}
                placeholder="Your in-game name"
                onChange={(event) => setIgnDraft(event.target.value)}
                disabled={saving}
                required
              />
            </label>
            <div className="profile-edit-actions">
              <button type="submit" className="primary-action" disabled={saving}>
                {saving ? 'Saving...' : 'Save'}
              </button>
              <button type="button" className="secondary-action" onClick={cancelEditing} disabled={saving}>
                Cancel
              </button>
            </div>
          </form>
        ) : null}
      </section>

      <section className="panel detail-list" aria-label="Profile details">
        <div>
          <span>Username</span>
          <strong>{profile?.profile_slug ?? profile?.username ?? 'unknown'}</strong>
          <small>Locked for normal users after registration.</small>
        </div>
        <div>
          <span>IGN</span>
          <strong>{profile?.ign ?? 'Not set'}</strong>
          <small>Editable by the player or an authorized admin later.</small>
        </div>
        <div>
          <span>Guild</span>
          <strong>{guild?.name ?? 'Unknown guild'}</strong>
        </div>
        <div>
          <span>Role</span>
          <strong>{membership?.role ?? 'member'}</strong>
        </div>
        <div>
          <span>Roster status</span>
          <strong>{formatRosterStatus(rosterStatus)}</strong>
          <small>{getRosterStatusSummary(rosterStatus)}</small>
        </div>
      </section>
    </div>
  );
}
