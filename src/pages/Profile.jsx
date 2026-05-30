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
import { loadMyGhoulRep, updateMyProfile } from '../services/profileService.js';
import {
  createMyTestPushNotification,
  disablePushSubscription,
  getCurrentPushSubscription,
  getNotificationPermission,
  isPushSupported,
  loadMyPushPreferences,
  registerPushSubscription,
  requestNotificationPermission,
  subscribeToPush,
  updateMyPushPreferences,
} from '../services/pushNotificationService.js';

const VAPID_PUBLIC_KEY = import.meta.env.VITE_VAPID_PUBLIC_KEY ?? '';

const PUSH_PREFERENCE_KEYS = [
  ['notify_gvg', 'pushNotifications.preferences.gvg'],
  ['notify_cp_window', 'pushNotifications.preferences.cpWindow'],
  ['notify_3v3', 'pushNotifications.preferences.threeVThree'],
  ['notify_wall_comments', 'pushNotifications.preferences.wallComments'],
  ['notify_wall_reactions', 'pushNotifications.preferences.wallReactions'],
  ['notify_profile_reactions', 'pushNotifications.preferences.profileReactions'],
];

function findCosmeticByKey(items, key) {
  return items?.find((item) => item.key === key) ?? null;
}

function formatProfileNumber(value, language) {
  const number = Number(value);

  if (!Number.isFinite(number)) {
    return '0';
  }

  return new Intl.NumberFormat(language).format(number);
}

export function Profile() {
  const { language, t } = useLanguage();
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
  const [ghoulRep, setGhoulRep] = useState(null);
  const [ghoulRepLoading, setGhoulRepLoading] = useState(false);
  const [cosmeticsState, setCosmeticsState] = useState(null);
  const [cosmeticsLoading, setCosmeticsLoading] = useState(false);
  const [cosmeticsSavingKey, setCosmeticsSavingKey] = useState('');
  const [cosmeticsMessage, setCosmeticsMessage] = useState('');
  const [cosmeticsError, setCosmeticsError] = useState('');
  const [cosmeticsPickerOpen, setCosmeticsPickerOpen] = useState(false);
  const [cosmeticsPickerTab, setCosmeticsPickerTab] = useState('avatars');
  const [settingsOpen, setSettingsOpen] = useState(false);
  const [pushSupported, setPushSupported] = useState(false);
  const [pushPermission, setPushPermission] = useState(getNotificationPermission());
  const [pushEndpoint, setPushEndpoint] = useState('');
  const [pushPreferences, setPushPreferences] = useState(null);
  const [pushLoading, setPushLoading] = useState(false);
  const [pushSaving, setPushSaving] = useState(false);
  const [pushMessage, setPushMessage] = useState('');
  const [pushError, setPushError] = useState('');
  const rosterStatus = membership?.roster_status ?? 'active';
  const rankVisualKey = rankSummary?.visualKey ?? 'unranked';
  const canSubmitCp = Boolean(cpWindowState?.can_submit);
  const pushConfigured = Boolean(VAPID_PUBLIC_KEY);
  const pushEnabled = Boolean(pushEndpoint);
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

    async function loadGhoulRepStat() {
      if (!profile?.id || !membership?.id) {
        return;
      }

      setGhoulRepLoading(true);

      try {
        const nextGhoulRep = await loadMyGhoulRep();

        if (!cancelled) {
          setGhoulRep(nextGhoulRep);
        }
      } catch {
        if (!cancelled) {
          setGhoulRep(null);
        }
      } finally {
        if (!cancelled) {
          setGhoulRepLoading(false);
        }
      }
    }

    loadGhoulRepStat();

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

  useEffect(() => {
    if (!cosmeticsPickerOpen) {
      return undefined;
    }

    function handleKeyDown(event) {
      if (event.key === 'Escape') {
        setCosmeticsPickerOpen(false);
      }
    }

    window.addEventListener('keydown', handleKeyDown);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [cosmeticsPickerOpen]);

  useEffect(() => {
    if (!settingsOpen) {
      return undefined;
    }

    function handleKeyDown(event) {
      if (event.key === 'Escape') {
        setSettingsOpen(false);
      }
    }

    window.addEventListener('keydown', handleKeyDown);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [settingsOpen]);

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

  function openCosmeticsPicker(tab = 'avatars') {
    setCosmeticsPickerTab(tab);
    setCosmeticsPickerOpen(true);

    if (!cosmeticsState && !cosmeticsLoading) {
      refreshCosmeticsPanel();
    }
  }

  function openSettingsPanel() {
    setSettingsOpen(true);
    refreshPushSettings();
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

  async function refreshPushSettings({ showMessage = false } = {}) {
    setPushLoading(true);
    setPushError('');
    if (!showMessage) {
      setPushMessage('');
    }

    const supported = isPushSupported();
    setPushSupported(supported);
    setPushPermission(getNotificationPermission());

    try {
      const [nextPreferences, currentSubscription] = await Promise.all([
        loadMyPushPreferences(),
        supported ? getCurrentPushSubscription().catch(() => null) : Promise.resolve(null),
      ]);

      setPushPreferences(nextPreferences);
      setPushEndpoint(currentSubscription?.endpoint ?? '');
      if (showMessage) {
        setPushMessage(t('pushNotifications.updated'));
      }
    } catch (loadError) {
      setPushPreferences(null);
      setPushError(loadError.message || t('pushNotifications.loadError'));
    } finally {
      setPushLoading(false);
    }
  }

  async function enablePushNotifications() {
    setPushSaving(true);
    setPushError('');
    setPushMessage('');

    try {
      if (!pushConfigured) {
        throw new Error(t('pushNotifications.configMissing'));
      }

      const nextPermission =
        getNotificationPermission() === 'default'
          ? await requestNotificationPermission()
          : getNotificationPermission();

      setPushPermission(nextPermission);

      if (nextPermission !== 'granted') {
        throw new Error(
          nextPermission === 'denied'
            ? t('pushNotifications.permissionDeniedHint')
            : t('pushNotifications.permissionRequired'),
        );
      }

      const subscription = await subscribeToPush({ vapidPublicKey: VAPID_PUBLIC_KEY });
      const registrationResult = await registerPushSubscription(subscription);
      setPushEndpoint(subscription.endpoint);
      setPushPreferences(registrationResult?.preferences ?? registrationResult);
      setPushMessage(t('pushNotifications.enabled'));
    } catch (enableError) {
      setPushError(enableError.message || t('pushNotifications.actionFailed'));
    } finally {
      setPushSaving(false);
    }
  }

  async function disableCurrentPushSubscription() {
    setPushSaving(true);
    setPushError('');
    setPushMessage('');

    try {
      const currentSubscription = await getCurrentPushSubscription().catch(() => null);
      const endpoint = currentSubscription?.endpoint ?? pushEndpoint;

      if (endpoint) {
        const disableResult = await disablePushSubscription(endpoint);
        setPushPreferences(disableResult?.preferences ?? disableResult);
      }

      if (currentSubscription) {
        await currentSubscription.unsubscribe();
      }

      setPushEndpoint('');
      setPushMessage(t('pushNotifications.disabled'));
    } catch (disableError) {
      setPushError(disableError.message || t('pushNotifications.actionFailed'));
    } finally {
      setPushSaving(false);
    }
  }

  function updatePushPreferenceDraft(key, checked) {
    setPushPreferences((current) => ({
      notify_gvg: true,
      notify_cp_window: true,
      notify_3v3: true,
      notify_wall_comments: true,
      notify_wall_reactions: false,
      notify_profile_reactions: false,
      ...(current ?? {}),
      [key]: checked,
    }));
  }

  async function savePushPreferences() {
    if (!pushPreferences) {
      return;
    }

    setPushSaving(true);
    setPushError('');
    setPushMessage('');

    try {
      const nextPreferences = await updateMyPushPreferences(pushPreferences);
      setPushPreferences(nextPreferences);
      setPushMessage(t('pushNotifications.preferencesSaved'));
    } catch (saveError) {
      setPushError(saveError.message || t('pushNotifications.actionFailed'));
    } finally {
      setPushSaving(false);
    }
  }

  async function sendTestPushNotification() {
    setPushSaving(true);
    setPushError('');
    setPushMessage('');

    try {
      const result = await createMyTestPushNotification();
      setPushMessage(result?.queued ? t('pushNotifications.testQueued') : t('pushNotifications.testNotQueued'));
    } catch (testError) {
      setPushError(testError.message || t('pushNotifications.actionFailed'));
    } finally {
      setPushSaving(false);
    }
  }

  async function equipAvatar(avatarKey) {
    const selectedAvatar = findCosmeticByKey(cosmeticsState?.avatars, avatarKey);

    if (!selectedAvatar?.isUnlocked) {
      setCosmeticsError(t('cosmetics.unlockRequired'));
      setCosmeticsMessage('');
      return;
    }

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
    const selectedFrame = findCosmeticByKey(cosmeticsState?.frames, frameKey);

    if (!selectedFrame?.isUnlocked) {
      setCosmeticsError(t('cosmetics.unlockRequired'));
      setCosmeticsMessage('');
      return;
    }

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
        <div className="profile-avatar-shell">
          <CosmeticPreview
            avatar={equippedAvatar}
            frame={equippedFrame}
            label={t('profile.currentCosmetics')}
            className="rank-avatar"
          />
        </div>
        <div className="profile-summary-main">
          <div className="profile-identity-stack">
            <div className="profile-title-block">
              <h3>{profile?.ign ?? t('dashboard.memberFallback')}</h3>
              <p>@{profile?.username ?? t('common.unknown')}</p>
            </div>
            <div className="status-badge-row">
              <StatusBadge tone="success">{t(`approvalStatus.${profile?.approval_status ?? 'approved'}`)}</StatusBadge>
              <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
            </div>
          </div>
          <div className="profile-identity-actions">
            <RankBadge className="profile-rank-badge" compact summary={rankSummary} loading={rankLoading} error={rankError} />
            {ghoulRep !== null || ghoulRepLoading ? (
              <span className="profile-ghoul-rep-chip" title={t('profile.ghoulRep')}>
                <strong>{ghoulRepLoading ? '...' : formatProfileNumber(ghoulRep, language)}</strong>
                <span>{t('profile.ghoulRep')}</span>
              </span>
            ) : null}
            <button
              type="button"
              className="secondary-action compact-action profile-customize-action"
              onClick={() => openCosmeticsPicker('avatars')}
              disabled={cosmeticsLoading && !cosmeticsState}
            >
              {cosmeticsLoading && !cosmeticsState ? t('common.loading') : t('cosmetics.customize')}
            </button>
            <button type="button" className="secondary-action compact-action profile-settings-action" onClick={openSettingsPanel}>
              {t('profile.settings')}
            </button>
          </div>
        </div>
      </section>

      {cosmeticsPickerOpen ? (
        <div
          className="cosmetic-modal-backdrop"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) {
              setCosmeticsPickerOpen(false);
            }
          }}
        >
          <section className="cosmetic-modal" role="dialog" aria-modal="true" aria-label={t('cosmetics.customize')}>
            <div className="cosmetic-modal-header">
              <div>
                <StatusBadge tone={cosmeticsState ? 'success' : 'warning'}>
                  {cosmeticsState ? t('profile.cosmeticsReady') : t('common.loading')}
                </StatusBadge>
                <h3>{t('cosmetics.customize')}</h3>
                <p>{t('profile.cosmeticsBody')}</p>
              </div>
              <div className="cosmetic-modal-actions">
                <button
                  type="button"
                  className="secondary-action compact-action"
                  onClick={() => refreshCosmeticsPanel()}
                  disabled={cosmeticsLoading || Boolean(cosmeticsSavingKey)}
                >
                  {cosmeticsLoading ? t('common.loading') : t('common.refresh')}
                </button>
                <button
                  type="button"
                  className="secondary-action compact-action"
                  onClick={() => setCosmeticsPickerOpen(false)}
                >
                  {t('cosmetics.close')}
                </button>
              </div>
            </div>

            <div className="cosmetic-current-card cosmetic-current-card-compact">
              <CosmeticPreview avatar={equippedAvatar} frame={equippedFrame} label={t('profile.currentCosmetics')} size="small" />
              <div>
                <span>{t('cosmetics.current')}</span>
                <strong>{equippedAvatar ? formatCosmeticLabel(equippedAvatar, t('profile.avatar')) : t('common.loading')}</strong>
                <small>{equippedFrame ? formatCosmeticLabel(equippedFrame, t('profile.frame')) : t('common.loading')}</small>
              </div>
            </div>

            {cosmeticsMessage ? <p className="notice-line">{cosmeticsMessage}</p> : null}
            {cosmeticsError ? <p className="error-line">{cosmeticsError}</p> : null}

            <div className="cosmetic-tab-bar" role="tablist" aria-label={t('profile.cosmetics')}>
              <button
                type="button"
                role="tab"
                aria-selected={cosmeticsPickerTab === 'avatars'}
                data-active={cosmeticsPickerTab === 'avatars'}
                onClick={() => setCosmeticsPickerTab('avatars')}
              >
                {t('cosmetics.avatars')}
              </button>
              <button
                type="button"
                role="tab"
                aria-selected={cosmeticsPickerTab === 'frames'}
                data-active={cosmeticsPickerTab === 'frames'}
                onClick={() => setCosmeticsPickerTab('frames')}
              >
                {t('cosmetics.frames')}
              </button>
            </div>

            {cosmeticsPickerTab === 'avatars' ? (
              <div className="cosmetic-picker-section" role="tabpanel" aria-label={t('profile.avatarPicker')}>
                <div className="cosmetic-picker-heading">
                  <h4>{t('cosmetics.chooseAvatar')}</h4>
                  <span>{t('profile.avatarPickerHint')}</span>
                </div>
                <div className="cosmetic-grid">
                  {(cosmeticsState?.avatars ?? []).map((avatar) => {
                    const isSaving = cosmeticsSavingKey === avatar.key;
                    const canEquipAvatar = avatar.isUnlocked && !avatar.isEquipped;
                    return (
                      <button
                        type="button"
                        className="cosmetic-card cosmetic-option-card"
                        key={avatar.key}
                        data-equipped={avatar.isEquipped}
                        data-locked={!avatar.isUnlocked}
                        aria-pressed={avatar.isEquipped}
                        onClick={() => equipAvatar(avatar.key)}
                        disabled={!canEquipAvatar || cosmeticActionBusy}
                      >
                        <CosmeticPreview avatar={avatar} label={formatCosmeticLabel(avatar, t('profile.avatar'))} size="small" />
                        <div className="cosmetic-card-copy">
                          <strong>{formatCosmeticLabel(avatar, t('profile.avatar'))}</strong>
                          <span>
                            {avatar.isEquipped
                              ? t('cosmetics.equipped')
                              : avatar.isUnlocked
                                ? t('profile.unlocked')
                                : t('cosmetics.locked')}
                          </span>
                        </div>
                        <span className="cosmetic-card-action">
                          {isSaving
                            ? t('profile.equipping')
                            : avatar.isEquipped
                              ? t('cosmetics.equipped')
                              : avatar.isUnlocked
                                ? t('profile.equipAvatar')
                                : t('cosmetics.unlockRequired')}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            ) : (
              <div className="cosmetic-picker-section" role="tabpanel" aria-label={t('profile.framePicker')}>
                <div className="cosmetic-picker-heading">
                  <h4>{t('cosmetics.chooseFrame')}</h4>
                  <span>{t('profile.framePickerHint')}</span>
                </div>
                <div className="cosmetic-grid">
                  {(cosmeticsState?.frames ?? []).map((frame) => {
                    const isSaving = cosmeticsSavingKey === frame.key;
                    const canEquipFrame = frame.isUnlocked && !frame.isEquipped;
                    return (
                      <button
                        type="button"
                        className="cosmetic-card cosmetic-option-card"
                        key={frame.key}
                        data-equipped={frame.isEquipped}
                        data-locked={!frame.isUnlocked}
                        aria-pressed={frame.isEquipped}
                        onClick={() => equipFrame(frame.key)}
                        disabled={!canEquipFrame || cosmeticActionBusy}
                      >
                        <CosmeticPreview avatar={equippedAvatar} frame={frame} label={formatCosmeticLabel(frame, t('profile.frame'))} size="small" />
                        <div className="cosmetic-card-copy">
                          <strong>{formatCosmeticLabel(frame, t('profile.frame'))}</strong>
                          <span>
                            {frame.isEquipped
                              ? t('cosmetics.equipped')
                              : frame.isUnlocked
                                ? t('profile.unlocked')
                                : t('cosmetics.locked')}
                          </span>
                        </div>
                        <span className="cosmetic-card-action">
                          {isSaving
                            ? t('profile.equipping')
                            : frame.isEquipped
                              ? t('cosmetics.equipped')
                              : frame.isUnlocked
                                ? t('profile.equipFrame')
                                : t('cosmetics.locked')}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {!cosmeticsLoading && cosmeticsState && !cosmeticsState.avatars.length && !cosmeticsState.frames.length ? (
              <p className="muted-line compact-state-line">{t('profile.noCosmetics')}</p>
            ) : null}
          </section>
        </div>
      ) : null}

      {settingsOpen ? (
        <div
          className="cosmetic-modal-backdrop profile-settings-backdrop"
          role="presentation"
          onMouseDown={(event) => {
            if (event.target === event.currentTarget) {
              setSettingsOpen(false);
            }
          }}
        >
          <section className="cosmetic-modal profile-settings-modal" role="dialog" aria-modal="true" aria-label={t('profile.settings')}>
            <div className="cosmetic-modal-header">
              <div>
                <StatusBadge tone={pushEnabled ? 'success' : 'muted'}>
                  {pushEnabled ? t('pushNotifications.enabledStatus') : t('pushNotifications.disabledStatus')}
                </StatusBadge>
                <h3>{t('profile.settings')}</h3>
                <p>{t('pushNotifications.optionalBody')}</p>
              </div>
              <div className="cosmetic-modal-actions">
                <button type="button" className="secondary-action compact-action" onClick={() => refreshPushSettings()} disabled={pushLoading || pushSaving}>
                  {pushLoading ? t('common.loading') : t('common.refresh')}
                </button>
                <button type="button" className="secondary-action compact-action" onClick={() => setSettingsOpen(false)}>
                  {t('common.close')}
                </button>
              </div>
            </div>

            <div className="push-settings-card">
              <div className="push-settings-heading">
                <div>
                  <h4>{t('pushNotifications.title')}</h4>
                  <p>{t('pushNotifications.body')}</p>
                </div>
              </div>

              <div className="push-status-grid">
                <div>
                  <span>{t('pushNotifications.support')}</span>
                  <strong>{pushSupported ? t('pushNotifications.supported') : t('pushNotifications.notSupported')}</strong>
                </div>
                <div>
                  <span>{t('pushNotifications.permission')}</span>
                  <strong>{t(`pushNotifications.permissionStates.${pushPermission}`)}</strong>
                </div>
                <div>
                  <span>{t('pushNotifications.status')}</span>
                  <strong>{pushEnabled ? t('pushNotifications.enabledStatus') : t('pushNotifications.disabledStatus')}</strong>
                </div>
              </div>

              {!pushConfigured ? <p className="warning-line">{t('pushNotifications.configMissing')}</p> : null}
              {pushPermission === 'denied' ? <p className="warning-line">{t('pushNotifications.permissionDeniedHint')}</p> : null}
              {!pushSupported ? <p className="muted-line compact-state-line">{t('pushNotifications.unsupportedBody')}</p> : null}
              {pushMessage ? <p className="notice-line">{pushMessage}</p> : null}
              {pushError ? <p className="error-line">{pushError}</p> : null}

              <div className="push-action-row">
                <button
                  type="button"
                  className="primary-action compact-action"
                  onClick={enablePushNotifications}
                  disabled={!pushSupported || !pushConfigured || pushSaving || pushLoading || pushPermission === 'denied'}
                >
                  {pushSaving ? t('common.working') : t('pushNotifications.enable')}
                </button>
                <button
                  type="button"
                  className="secondary-action compact-action"
                  onClick={disableCurrentPushSubscription}
                  disabled={pushSaving || pushLoading || !pushEnabled}
                >
                  {t('pushNotifications.disable')}
                </button>
                <button
                  type="button"
                  className="secondary-action compact-action"
                  onClick={sendTestPushNotification}
                  disabled={pushSaving || pushLoading || !pushEnabled}
                >
                  {t('pushNotifications.sendTest')}
                </button>
              </div>

              <div className="push-preference-list" aria-label={t('pushNotifications.preferencesTitle')}>
                {PUSH_PREFERENCE_KEYS.map(([key, labelKey]) => (
                  <label className="push-preference-row" key={key}>
                    <span>
                      <strong>{t(labelKey)}</strong>
                      <small>{t(`pushNotifications.preferenceHelp.${key}`)}</small>
                    </span>
                    <input
                      type="checkbox"
                      checked={Boolean(pushPreferences?.[key])}
                      onChange={(event) => updatePushPreferenceDraft(key, event.target.checked)}
                      disabled={pushLoading || pushSaving || !pushPreferences}
                    />
                  </label>
                ))}
              </div>

              <button
                type="button"
                className="primary-action push-save-preferences"
                onClick={savePushPreferences}
                disabled={pushLoading || pushSaving || !pushPreferences}
              >
                {pushSaving ? t('common.working') : t('pushNotifications.savePreferences')}
              </button>
            </div>
          </section>
        </div>
      ) : null}

      <section className="panel member-profile-card" aria-label={t('profile.memberProfile')}>
        <div className="member-profile-card-header">
          <div>
            <h3>{t('profile.memberProfile')}</h3>
            <p>{t('profile.lockedFields')}</p>
          </div>
        </div>

        {profileMessage ? <p className="notice-line">{profileMessage}</p> : null}
        {profileError ? <p className="error-line">{profileError}</p> : null}
        {cpMessage ? <p className="notice-line">{cpMessage}</p> : null}
        {cpError ? <p className="error-line">{cpError}</p> : null}

        <div className="member-profile-content-grid">
          <div className="member-profile-block member-profile-cp-block">
            <div className="member-profile-block-heading">
              <div>
                <StatusBadge tone={canSubmitCp ? 'success' : 'warning'}>
                  {canSubmitCp ? t('admin.cp.windowOpen') : t('admin.cp.windowClosed')}
                </StatusBadge>
                <h4>{t('profile.yourCp')}</h4>
              </div>
              <button type="button" className="secondary-action compact-action profile-refresh-action" onClick={() => refreshCpPanel()} disabled={cpLoading || cpSubmitting}>
                {cpLoading ? t('common.loading') : t('common.refresh')}
              </button>
            </div>

            <div className="profile-mini-stat-grid">
              <div>
                <span>{t('profile.currentCp')}</span>
                <strong>{formatCpDisplayValue(cpState?.cp_value, t('profile.cpNotEntered'))}</strong>
              </div>
              <div>
                <span>{t('profile.updateWindow')}</span>
                <strong>{canSubmitCp ? t('admin.cp.windowOpen') : t('admin.cp.windowClosed')}</strong>
              </div>
            </div>

            <p className="profile-private-cp-note">{t('profile.privateSelfCpShort')}</p>

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
                <button type="submit" className="primary-action compact-profile-submit" disabled={cpLoading || cpSubmitting}>
                  {cpSubmitting ? t('common.working') : t('profile.submitCp')}
                </button>
              </form>
            ) : (
              <p className="muted-line compact-state-line">{cpWindowMessage}</p>
            )}
          </div>

          <div className="member-profile-block member-profile-account-block">
            <div className="member-profile-block-heading">
              <div>
                <StatusBadge tone={isEditing ? 'warning' : 'muted'}>
                  {isEditing ? t('profile.editingIgn') : t('profile.account')}
                </StatusBadge>
                <h4>{t('profile.details')}</h4>
              </div>
            </div>

            <div className="profile-detail-grid">
              <div>
                <span>{t('profile.username')}</span>
                <strong>{profile?.profile_slug ?? profile?.username ?? t('common.unknown')}</strong>
                <small>{t('profile.lockedUsername')}</small>
              </div>
              {isEditing ? (
                <form className="profile-detail-edit-row" onSubmit={saveProfile}>
                  <label>
                    <span>{t('profile.ign')}</span>
                    <input
                      type="text"
                      value={ignDraft}
                      placeholder={t('auth.ignPlaceholder')}
                      onChange={(event) => setIgnDraft(event.target.value)}
                      disabled={saving}
                      required
                    />
                  </label>
                  <div className="profile-inline-row-actions">
                    <button type="submit" className="primary-action compact-action" disabled={saving}>
                      {saving ? t('profile.saving') : t('profile.saveIgn')}
                    </button>
                    <button type="button" className="secondary-action compact-action" onClick={cancelEditing} disabled={saving}>
                      {t('profile.cancelEdit')}
                    </button>
                  </div>
                </form>
              ) : (
                <div className="profile-detail-editable-row">
                  <div className="profile-detail-row-title">
                    <span>{t('profile.ign')}</span>
                    <button type="button" className="secondary-action compact-action profile-row-edit-button" onClick={startEditing}>
                      {t('profile.edit')}
                    </button>
                  </div>
                  <strong>{profile?.ign ?? t('common.notSet')}</strong>
                  <small>{t('profile.editableIgn')}</small>
                </div>
              )}
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
              <div>
                <span>{t('profile.profileStatus')}</span>
                <strong>{t(`approvalStatus.${profile?.approval_status ?? 'approved'}`)}</strong>
              </div>
            </div>

          </div>
        </div>
      </section>
    </div>
  );
}
