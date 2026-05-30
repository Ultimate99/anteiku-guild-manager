import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { CosmeticPreview } from '../components/CosmeticPreview.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import {
  PROFILE_REACTION_TYPES,
  getProfileReactionCount,
  hasMyProfileReaction,
  loadPublicMemberProfile,
  loadPublicProfileReactionDetails,
  reactToPublicProfile,
  removePublicProfileReaction,
} from '../services/publicProfileService.js';

const REACTION_ICONS = {
  like: '\u{1F44D}',
  fire: '\u{1F525}',
  coffee: '\u2615',
  skull: '\u{1F480}',
  trophy: '\u{1F3C6}',
};

function formatNumber(value, language) {
  const number = Number(value);

  if (!Number.isFinite(number)) {
    return '';
  }

  return new Intl.NumberFormat(language).format(number);
}

function formatDate(value, language) {
  if (!value) {
    return '';
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return '';
  }

  return new Intl.DateTimeFormat(language, {
    month: 'short',
    day: 'numeric',
  }).format(date);
}

function displayName(profile, fallback) {
  return profile?.ign || profile?.username || profile?.profileSlug || fallback;
}

function getPublicProfileError(error, t) {
  const message = String(error?.message || '').toLowerCase();

  if (message.includes('not found')) {
    return t('publicProfile.profileUnavailable');
  }

  if (message.includes('approved') || message.includes('authorized') || message.includes('access')) {
    return t('publicProfile.permissionDenied');
  }

  if (message.includes('self profile reactions')) {
    return t('publicProfile.selfReactionBlocked');
  }

  return error?.message || t('publicProfile.loadError');
}

function PublicProfileReactionButton({ type, reactions, disabled, onToggle, onShowDetails }) {
  const { t } = useLanguage();
  const count = getProfileReactionCount(reactions, type);
  const active = hasMyProfileReaction(reactions, type);
  const label = t(`wall.reaction.${type}`);
  const title = `${REACTION_ICONS[type] ?? type} ${label}`;

  return (
    <button
      type="button"
      className="public-profile-reaction-button"
      data-active={active}
      disabled={disabled}
      onClick={() => onToggle(type, active)}
      onMouseEnter={() => onShowDetails(type)}
      onFocus={() => onShowDetails(type)}
      aria-pressed={active}
      aria-label={title}
      title={title}
    >
      <span aria-hidden="true">{REACTION_ICONS[type] ?? type}</span>
      <strong>{count}</strong>
    </button>
  );
}

function PublicProfileReactionDetails({ details, onClose }) {
  const { language, t } = useLanguage();

  if (!details.open) {
    return null;
  }

  const icon = REACTION_ICONS[details.reactionType] ?? '';

  return (
    <aside className="public-profile-reaction-details" role="dialog" aria-label={t('publicProfile.reactionDetails')}>
      <div className="wall-reaction-details-header">
        <div>
          <p className="eyebrow">{t('publicProfile.reactionDetails')}</p>
          <h3>{icon ? `${icon} ${t('publicProfile.reactedBy')}` : t('publicProfile.reactedBy')}</h3>
        </div>
        <button type="button" className="inline-text-action" onClick={onClose}>
          {t('publicProfile.close')}
        </button>
      </div>

      {details.loading ? (
        <p className="notice-line">{t('common.loading')}</p>
      ) : details.error ? (
        <p className="error-line">{details.error}</p>
      ) : details.reactions.length === 0 ? (
        <p className="notice-line">{t('publicProfile.noReactions')}</p>
      ) : (
        <div className="wall-reaction-detail-list">
          {details.reactions.map((reaction, index) => (
            <article
              key={`${reaction.reactionType}:${reaction.profileSlug}:${reaction.reactedAt}:${index}`}
              className="wall-reaction-detail-row"
            >
              <CosmeticPreview
                avatar={reaction.avatar}
                frame={reaction.frame}
                label={displayName(reaction, t('common.unknown'))}
                size="small"
                className="wall-reaction-detail-avatar"
              />
              <div>
                <strong>{displayName(reaction, t('common.unknown'))}</strong>
                <span>{reaction.guildName || t('publicProfile.guild')}</span>
              </div>
              <small>
                {REACTION_ICONS[reaction.reactionType] ?? reaction.reactionType}
                {reaction.reactedAt ? ` ${formatDate(reaction.reactedAt, language)}` : ''}
              </small>
            </article>
          ))}
        </div>
      )}
    </aside>
  );
}

export function PublicMemberProfile({ profileSlug, onNavigate }) {
  const { language, t } = useLanguage();
  const [profileState, setProfileState] = useState({ viewer: null, profile: null });
  const [loading, setLoading] = useState(false);
  const [busyReaction, setBusyReaction] = useState('');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [reactionDetails, setReactionDetails] = useState({
    open: false,
    loading: false,
    error: '',
    reactionType: '',
    reactions: [],
  });

  const profile = profileState.profile;
  const viewer = profileState.viewer;
  const canReact = Boolean(viewer?.canReact && profile?.profileId);
  const displayCp = useMemo(() => {
    if (profile?.threeVThreeCombinedCp === null || profile?.threeVThreeCombinedCp === undefined) {
      return '';
    }

    return `${formatNumber(profile.threeVThreeCombinedCp, language)} CP`;
  }, [language, profile?.threeVThreeCombinedCp]);

  const refreshProfile = useCallback(async () => {
    if (!profileSlug) {
      setProfileState({ viewer: null, profile: null });
      setError(t('publicProfile.profileUnavailable'));
      return;
    }

    setLoading(true);
    setError('');
    setMessage('');

    try {
      const data = await loadPublicMemberProfile(profileSlug);
      setProfileState(data);
    } catch (loadError) {
      setProfileState({ viewer: null, profile: null });
      setError(getPublicProfileError(loadError, t));
    } finally {
      setLoading(false);
    }
  }, [profileSlug, t]);

  useEffect(() => {
    refreshProfile();
  }, [refreshProfile]);

  async function openReactionDetails(reactionType) {
    if (!profile?.profileId) {
      return;
    }

    setReactionDetails({
      open: true,
      loading: true,
      error: '',
      reactionType,
      reactions: [],
    });

    try {
      const details = await loadPublicProfileReactionDetails({
        targetProfileId: profile.profileId,
        reactionType,
      });
      setReactionDetails({
        open: true,
        loading: false,
        error: '',
        reactionType: details.reactionType || reactionType,
        reactions: details.reactions,
      });
    } catch (detailsError) {
      setReactionDetails({
        open: true,
        loading: false,
        error: getPublicProfileError(detailsError, t),
        reactionType,
        reactions: [],
      });
    }
  }

  async function handleReactionToggle(reactionType, active) {
    if (!profile?.profileId || !canReact) {
      return;
    }

    setBusyReaction(reactionType);
    setError('');
    setMessage('');

    try {
      if (active) {
        await removePublicProfileReaction({ targetProfileId: profile.profileId, reactionType });
      } else {
        await reactToPublicProfile({ targetProfileId: profile.profileId, reactionType });
      }

      await refreshProfile();
      await openReactionDetails(reactionType);
    } catch (reactionError) {
      setError(getPublicProfileError(reactionError, t));
    } finally {
      setBusyReaction('');
    }
  }

  function closeReactionDetails() {
    setReactionDetails((current) => ({
      ...current,
      open: false,
      loading: false,
    }));
  }

  return (
    <div className="stack public-profile-page">
      <section className="panel public-profile-hero">
        {loading && !profile ? (
          <div className="compact-empty-state">
            <h3>{t('common.loading')}</h3>
            <p>{t('publicProfile.loading')}</p>
          </div>
        ) : profile ? (
          <>
            <CosmeticPreview
              avatar={profile.avatar}
              frame={profile.frame}
              label={displayName(profile, t('common.unknown'))}
              size="large"
              className="public-profile-avatar"
            />
            <div className="public-profile-identity">
              <p className="eyebrow">{t('publicProfile.memberProfile')}</p>
              <h2>{displayName(profile, t('common.unknown'))}</h2>
              <span>@{profile.profileSlug || profile.username}</span>
              <div className="status-badge-row">
                {profile.guildName ? <StatusBadge tone="crimson">{profile.guildName}</StatusBadge> : null}
                {profile.roleLabel ? <StatusBadge tone="info">{profile.roleLabel}</StatusBadge> : null}
                {profile.rosterStatus ? <StatusBadge tone="success">{profile.rosterStatus}</StatusBadge> : null}
              </div>
            </div>
            <div className="public-profile-actions">
              {viewer?.isSelf ? (
                <button type="button" className="secondary-action compact-action" onClick={() => onNavigate?.('profile')}>
                  {t('publicProfile.editOwnProfile')}
                </button>
              ) : null}
              <button type="button" className="secondary-action compact-action" onClick={refreshProfile} disabled={loading}>
                {loading ? t('common.refreshing') : t('common.refresh')}
              </button>
            </div>
          </>
        ) : (
          <div className="compact-empty-state">
            <h3>{t('publicProfile.profileUnavailable')}</h3>
            <p>{error || t('publicProfile.permissionDenied')}</p>
          </div>
        )}
      </section>

      {profile ? (
        <>
          <section className="panel public-profile-stats-card">
            <div className="public-profile-stat">
              <span>{t('publicProfile.ghoulRep')}</span>
              <strong>{formatNumber(profile.ghoulRep ?? 0, language)}</strong>
            </div>
            {displayCp ? (
              <div className="public-profile-stat">
                <span>{t('publicProfile.threeVThreeCp')}</span>
                <strong>{displayCp}</strong>
              </div>
            ) : null}
            <div className="public-profile-stat">
              <span>{t('publicProfile.guild')}</span>
              <strong>{profile.guildName || '-'}</strong>
            </div>
          </section>

          <section className="panel public-profile-reactions-card">
            <div className="section-heading-row">
              <div>
                <p className="eyebrow">{t('publicProfile.profileReactions')}</p>
                <h3>{t('publicProfile.reactions')}</h3>
              </div>
              <StatusBadge tone={canReact ? 'success' : 'muted'}>
                {canReact ? t('common.ready') : t('publicProfile.viewOnly')}
              </StatusBadge>
            </div>
            <div className="public-profile-reaction-row" aria-label={t('publicProfile.profileReactions')}>
              {PROFILE_REACTION_TYPES.map((type) => (
                <PublicProfileReactionButton
                  key={type}
                  type={type}
                  reactions={profile.reactions}
                  disabled={!canReact || busyReaction === type}
                  onToggle={handleReactionToggle}
                  onShowDetails={openReactionDetails}
                />
              ))}
            </div>
            <p className="muted-line">{t('publicProfile.noCpNotice')}</p>
          </section>
        </>
      ) : null}

      {message ? <p className="notice-line">{message}</p> : null}
      {error && profile ? <p className="error-line">{error}</p> : null}

      <PublicProfileReactionDetails details={reactionDetails} onClose={closeReactionDetails} />
    </div>
  );
}
