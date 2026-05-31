import React, { useEffect, useState } from 'react';
import { CosmeticPreview } from '../components/CosmeticPreview.jsx';
import { RankBadge } from '../components/RankBadge.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import { useActiveProfileSummary } from '../hooks/useActiveProfileSummary.js';
import {
  isGvgLimitedRosterStatus,
  rosterStatusTone,
} from '../services/adminMemberService.js';
import { loadMyCpRankSummary } from '../services/cpRankBadgeService.js';
import { loadMyCosmetics } from '../services/cosmeticsService.js';

function findCosmeticByKey(items, key) {
  return items?.find((item) => item.key === key) ?? null;
}

export function Dashboard({ onNavigate }) {
  const { t } = useLanguage();
  const { guild, membership, profile } = useAuth();
  const { activeProfile, activeProfileError } = useActiveProfileSummary();
  const [rankSummary, setRankSummary] = useState(null);
  const [rankLoading, setRankLoading] = useState(false);
  const [rankError, setRankError] = useState('');
  const [cosmeticsState, setCosmeticsState] = useState(null);
  const dashboardProfile = activeProfile?.profileId ? activeProfile : null;
  const displayIgn = dashboardProfile?.ign || profile?.ign || t('dashboard.memberFallback');
  const displaySlug = dashboardProfile?.profileSlug || profile?.profile_slug || profile?.username || t('common.unknown');
  const guildName = dashboardProfile?.guildName || guild?.name || t('guild.assigned');
  const displayRole = dashboardProfile?.role || membership?.role || 'member';
  const displayRosterStatus = dashboardProfile?.rosterStatus || membership?.roster_status || 'active';
  const activeDiffersFromLegacy = Boolean(dashboardProfile?.profileId && profile?.id && dashboardProfile.profileId !== profile.id);
  const rosterStatus = membership?.roster_status ?? 'active';
  const gvgStatus = isGvgLimitedRosterStatus(rosterStatus) ? t('dashboard.notExpected') : t('dashboard.awaitingEvent');
  const canNavigate = typeof onNavigate === 'function';

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

    async function loadDashboardCosmetics() {
      if (!profile?.id || !membership?.id) {
        return;
      }

      try {
        const nextCosmeticsState = await loadMyCosmetics();

        if (!cancelled) {
          setCosmeticsState(nextCosmeticsState);
        }
      } catch {
        if (!cancelled) {
          setCosmeticsState(null);
        }
      }
    }

    loadDashboardCosmetics();

    return () => {
      cancelled = true;
    };
  }, [membership?.id, profile?.id]);

  const equippedAvatar = findCosmeticByKey(cosmeticsState?.avatars, cosmeticsState?.equipped?.avatarKey);
  const equippedFrame = findCosmeticByKey(cosmeticsState?.frames, cosmeticsState?.equipped?.frameKey);
  const displayAvatar = dashboardProfile?.avatar?.assetPath ? dashboardProfile.avatar : equippedAvatar;
  const displayFrame = dashboardProfile?.frame?.assetPath ? dashboardProfile.frame : equippedFrame;

  return (
    <div className="stack dashboard-mobile-stack">
      <section className="panel hero-panel member-home-panel member-command-panel">
        <div className="dashboard-identity">
          <div className="dashboard-identity-main">
            <CosmeticPreview
              avatar={displayAvatar}
              frame={displayFrame}
              label={displayIgn}
              className="dashboard-avatar-preview"
            />
            <div>
              <p className="eyebrow">{t('dashboard.commandCenter')}</p>
              <h3>{t('dashboard.welcome', { ign: displayIgn })}</h3>
              <p>@{displaySlug}</p>
            </div>
          </div>
          <div className="status-badge-row dashboard-status-row">
            <StatusBadge tone="success">{t(`approvalStatus.${dashboardProfile?.approvalStatus || profile?.approval_status || 'approved'}`)}</StatusBadge>
            <StatusBadge tone={rosterStatusTone(displayRosterStatus)}>{t(`roster.status.${displayRosterStatus}.label`)}</StatusBadge>
          </div>
        </div>
        {activeDiffersFromLegacy ? (
          <div className="active-profile-viewer-note" data-switched={activeDiffersFromLegacy}>
            <span>{t('accountSwitcher.viewingAs', { ign: displayIgn })}</span>
            <small>{t('accountSwitcher.limitedRolloutNote')}</small>
          </div>
        ) : null}
        {activeProfileError ? <p className="muted-line compact-state-line">{t('accountSwitcher.activeProfileLoadError')}</p> : null}
        <div className="dashboard-command-meta" aria-label={t('dashboard.overview')}>
          <div>
            <span>{t('dashboard.guild')}</span>
            <strong>{guildName}</strong>
          </div>
          <div>
            <span>{t('dashboard.role')}</span>
            <strong>{t(`roles.${displayRole}`)}</strong>
          </div>
          <div>
            <span>{t('dashboard.gvgStatus')}</span>
            <strong>{gvgStatus}</strong>
          </div>
        </div>
        <div className="member-id-badges dashboard-rank-row">
          <RankBadge compact summary={rankSummary} loading={rankLoading} error={rankError} />
          <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
        </div>
        {rosterStatus !== 'active' ? <p className="muted-copy">{t(`roster.status.${rosterStatus}.summary`)}</p> : null}
      </section>

      <section className="dashboard-command-grid" aria-label={t('dashboard.quickActions')}>
        <button
          type="button"
          className="command-card dashboard-command-card"
          onClick={() => canNavigate && onNavigate('profile')}
          disabled={!canNavigate}
        >
          <span>{t('dashboard.quickProfile')}</span>
          <strong>{t('nav.profile')}</strong>
          <small>{t('dashboard.quickProfileBody')}</small>
        </button>
        <button
          type="button"
          className="command-card dashboard-command-card"
          onClick={() => canNavigate && onNavigate('leaderboard')}
          disabled={!canNavigate}
        >
          <span>{t('dashboard.quickRanking')}</span>
          <strong>{t('nav.leaderboard')}</strong>
          <small>{t('dashboard.quickRankingBody')}</small>
        </button>
        <button
          type="button"
          className="command-card dashboard-command-card"
          onClick={() => canNavigate && onNavigate('gvg')}
          disabled={!canNavigate}
        >
          <span>{t('dashboard.quickGvg')}</span>
          <strong>{t('nav.gvg')}</strong>
          <small>{gvgStatus}</small>
        </button>
        <button
          type="button"
          className="command-card dashboard-command-card"
          onClick={() => canNavigate && onNavigate('threeVThree')}
          disabled={!canNavigate}
        >
          <span>{t('dashboard.quickThreeVThree')}</span>
          <strong>{t('nav.threeVThree')}</strong>
          <small>{t('dashboard.quickThreeVThreeBody')}</small>
        </button>
      </section>
    </div>
  );
}
