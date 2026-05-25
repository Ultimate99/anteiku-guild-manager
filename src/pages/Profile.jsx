import React, { useEffect, useState } from 'react';
import { CosmeticPreview } from '../components/CosmeticPreview.jsx';
import { RankBadge } from '../components/RankBadge.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  equipMyAvatar,
  equipMyFrame,
  formatCosmeticLabel,
  loadMyCosmetics,
} from '../services/cosmeticsService.js';
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

function findCosmeticByKey(items, key) {
  return items?.find((item) => item.key === key) ?? null;
}

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
  const [cosmeticsState, setCosmeticsState] = useState(null);
  const [cosmeticsLoading, setCosmeticsLoading] = useState(false);
  const [cosmeticsSavingKey, setCosmeticsSavingKey] = useState('');
  const [cosmeticsMessage, setCosmeticsMessage] = useState('');
  const [cosmeticsError, setCosmeticsError] = useState('');
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

  useEffect(() => {
    let cancelled = false;

    async function loadCosmeticsPanel() {
      if (!profile?.id || !membership?.id) {
        return;
      }

      setCosmeticsLoading(true);
      setCosmeticsError('');

      try {
        const nextCosmeticsState = await loadMyCosmetics();

        if (!cancelled) {
          setCosmeticsState(nextCosmeticsState);
        }
      } catch (loadError) {
        if (!cancelled) {
          setCosmeticsState(null);
          setCosmeticsError(loadError.message || t('profile.cosmeticsLoadError'));
        }
      } finally {
        if (!cancelled) {
          setCosmeticsLoading(false);
        }
      }
    }

    loadCosmeticsPanel();

    return () => {
      cancelled = true;
    };
  }, [membership?.id, profile?.id, t]);

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

  async function refreshCosmeticsPanel({ showMessage = false } = {}) {
    setCosmeticsLoading(true);
    setCosmeticsError('');
    if (!showMessage) {
      setCosmeticsMessage('');
    }

    try {
      const nextCosmeticsState = await loadMyCosmetics();
      setCosmeticsState(nextCosmeticsState);
      if (showMessage) {
        setCosmeticsMessage(t('profile.cosmeticsUpdated'));
      }
    } catch (loadError) {
      setCosmeticsError(loadError.message || t('profile.cosmeticsLoadError'));
    } finally {
      setCosmeticsLoading(false);
    }
  }

  async function equipAvatar(avatarKey) {
    setCosmeticsSavingKey(avatarKey);
    setCosmeticsError('');
    setCosmeticsMessage('');

    try {
      await equipMyAvatar(avatarKey);
      await Promise.all([refreshCosmeticsPanel({ showMessage: true }), refreshProfile()]);
    } catch (equipError) {
      setCosmeticsError(equipError.message || t('profile.cosmeticsSaveError'));
    } finally {
      setCosmeticsSavingKey('');
    }
  }

  async function equipFrame(frameKey) {
    setCosmeticsSavingKey(frameKey);
    setCosmeticsError('');
    setCosmeticsMessage('');

    try {
      await equipMyFrame(frameKey);
      await refreshCosmeticsPanel({ showMessage: true });
    } catch (equipError) {
      setCosmeticsError(equipError.message || t('profile.cosmeticsSaveError'));
    } finally {
      setCosmeticsSavingKey('');
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

  const equippedAvatar = findCosmeticByKey(cosmeticsState?.avatars, cosmeticsState?.equipped?.avatarKey);
  const equippedFrame = findCosmeticByKey(cosmeticsState?.frames, cosmeticsState?.equipped?.frameKey);
  const cosmeticActionBusy = Boolean(cosmeticsSavingKey) || cosmeticsLoading;

  return (
    <div className="stack">
      <section className="panel profile-panel compact-profile-panel rank-profile-panel" data-rank-visual={rankVisualKey}>
        <CosmeticPreview
          avatar={equippedAvatar}
          frame={equippedFrame}
          label={t('profile.currentCosmetics')}
          className="rank-avatar"
        />
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

      <section className="panel member-compact-panel profile-cosmetics-panel" aria-label={t('profile.cosmetics')}>
        <div className="section-heading-row profile-cosmetics-heading">
          <div>
            <StatusBadge tone={cosmeticsState ? 'success' : 'warning'}>
              {cosmeticsState ? t('profile.cosmeticsReady') : t('common.loading')}
            </StatusBadge>
            <h3>{t('profile.cosmetics')}</h3>
            <p>{t('profile.cosmeticsBody')}</p>
          </div>
          <button
            type="button"
            className="secondary-action compact-action"
            onClick={() => refreshCosmeticsPanel()}
            disabled={cosmeticsLoading || Boolean(cosmeticsSavingKey)}
          >
            {cosmeticsLoading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>

        {cosmeticsMessage ? <p className="notice-line">{cosmeticsMessage}</p> : null}
        {cosmeticsError ? <p className="error-line">{cosmeticsError}</p> : null}

        <div className="cosmetic-current-card">
          <CosmeticPreview avatar={equippedAvatar} frame={equippedFrame} label={t('profile.currentCosmetics')} size="large" />
          <div>
            <span>{t('profile.currentCosmetics')}</span>
            <strong>{equippedAvatar ? formatCosmeticLabel(equippedAvatar, t('profile.avatar')) : t('common.loading')}</strong>
            <small>{equippedFrame ? formatCosmeticLabel(equippedFrame, t('profile.frame')) : t('common.loading')}</small>
          </div>
        </div>

        <div className="cosmetic-picker-section" aria-label={t('profile.avatarPicker')}>
          <div className="cosmetic-picker-heading">
            <h4>{t('profile.avatarPicker')}</h4>
            <span>{t('profile.avatarPickerHint')}</span>
          </div>
          <div className="cosmetic-grid">
            {(cosmeticsState?.avatars ?? []).map((avatar) => {
              const isSaving = cosmeticsSavingKey === avatar.key;
              return (
                <article className="cosmetic-card" key={avatar.key} data-equipped={avatar.isEquipped}>
                  <CosmeticPreview avatar={avatar} label={formatCosmeticLabel(avatar, t('profile.avatar'))} size="small" />
                  <div className="cosmetic-card-copy">
                    <strong>{formatCosmeticLabel(avatar, t('profile.avatar'))}</strong>
                    <span>{avatar.isEquipped ? t('profile.equipped') : t('profile.unlocked')}</span>
                  </div>
                  <button
                    type="button"
                    className={avatar.isEquipped ? 'secondary-action' : 'primary-action'}
                    onClick={() => equipAvatar(avatar.key)}
                    disabled={avatar.isEquipped || cosmeticActionBusy}
                  >
                    {isSaving ? t('profile.equipping') : avatar.isEquipped ? t('profile.equipped') : t('profile.equipAvatar')}
                  </button>
                </article>
              );
            })}
          </div>
        </div>

        <div className="cosmetic-picker-section" aria-label={t('profile.framePicker')}>
          <div className="cosmetic-picker-heading">
            <h4>{t('profile.framePicker')}</h4>
            <span>{t('profile.framePickerHint')}</span>
          </div>
          <div className="cosmetic-grid">
            {(cosmeticsState?.frames ?? []).map((frame) => {
              const isSaving = cosmeticsSavingKey === frame.key;
              const canEquipFrame = frame.isUnlocked && !frame.isEquipped;
              return (
                <article className="cosmetic-card" key={frame.key} data-equipped={frame.isEquipped} data-locked={!frame.isUnlocked}>
                  <CosmeticPreview avatar={equippedAvatar} frame={frame} label={formatCosmeticLabel(frame, t('profile.frame'))} size="small" />
                  <div className="cosmetic-card-copy">
                    <strong>{formatCosmeticLabel(frame, t('profile.frame'))}</strong>
                    <span>
                      {frame.isEquipped
                        ? t('profile.equipped')
                        : frame.isUnlocked
                          ? t('profile.unlocked')
                          : t('profile.locked')}
                    </span>
                  </div>
                  <button
                    type="button"
                    className={canEquipFrame ? 'primary-action' : 'secondary-action'}
                    onClick={() => equipFrame(frame.key)}
                    disabled={!canEquipFrame || cosmeticActionBusy}
                  >
                    {isSaving
                      ? t('profile.equipping')
                      : frame.isEquipped
                        ? t('profile.equipped')
                        : frame.isUnlocked
                          ? t('profile.equipFrame')
                          : t('profile.locked')}
                  </button>
                </article>
              );
            })}
          </div>
        </div>

        {!cosmeticsLoading && cosmeticsState && !cosmeticsState.avatars.length && !cosmeticsState.frames.length ? (
          <p className="muted-line compact-state-line">{t('profile.noCosmetics')}</p>
        ) : null}
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
