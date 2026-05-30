import React, { useEffect, useMemo, useState } from 'react';
import { CosmeticPreview } from '../components/CosmeticPreview.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { loadMemberCpRankings, normalizeLeaderboardScope } from '../services/cpLeaderboardService.js';

const SCOPES = ['guild', 'global'];

function getDisplayError(error, fallback) {
  const message = error?.message ?? '';

  if (message.includes('private CP field') || message.includes('get_member_cp_rankings')) {
    return fallback;
  }

  return message || fallback;
}

function getRankTier(rank) {
  if (rank === 1) {
    return 'first';
  }

  if (rank === 2) {
    return 'second';
  }

  if (rank === 3) {
    return 'third';
  }

  if (rank <= 5) {
    return 'elite';
  }

  if (rank <= 10) {
    return 'top';
  }

  return 'standard';
}

function getRankLabelKey(rank) {
  if (rank === 1) {
    return 'leaderboard.topRank';
  }

  if (rank === 2) {
    return 'leaderboard.silverRank';
  }

  if (rank === 3) {
    return 'leaderboard.bronzeRank';
  }

  if (rank <= 5) {
    return 'leaderboard.eliteFive';
  }

  if (rank <= 10) {
    return 'leaderboard.topTen';
  }

  return 'leaderboard.ranked';
}

function getRankMarker(rank) {
  if (rank === 1) {
    return 'TOP';
  }

  if (rank === 2) {
    return 'II';
  }

  if (rank === 3) {
    return 'III';
  }

  return `#${rank}`;
}

function LeaderboardCompetitorCard({ row, scope, t, variant = 'row' }) {
  const rankLabelKey = getRankLabelKey(row.rank);
  const isGlobal = scope === 'global';

  return (
    <>
      <CosmeticPreview
        avatar={row.avatar}
        frame={row.frame}
        label={row.ign}
        size={variant === 'podium' && row.rank === 1 ? 'medium' : 'small'}
        className={variant === 'podium' ? 'leaderboard-podium-cosmetic' : 'leaderboard-cosmetic'}
      />
      <div className="leaderboard-member">
        <div className="leaderboard-member-line">
          <strong>{row.ign}</strong>
          {row.isCurrentUser ? <StatusBadge tone="info">{t('leaderboard.currentUser')}</StatusBadge> : null}
        </div>
        <div className="leaderboard-meta">
          <span>{t(rankLabelKey)}</span>
          {isGlobal && row.guildName ? (
            <span>
              {t('leaderboard.guild')}: {row.guildName}
            </span>
          ) : null}
        </div>
      </div>
    </>
  );
}

export function Leaderboard({ onNavigate }) {
  const { t } = useLanguage();
  const [scope, setScope] = useState('guild');
  const [rankings, setRankings] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [reloadTick, setReloadTick] = useState(0);

  const normalizedScope = normalizeLeaderboardScope(scope);
  const scopeLabel = useMemo(
    () => (normalizedScope === 'global' ? t('leaderboard.global') : t('leaderboard.myGuild')),
    [normalizedScope, t],
  );
  const currentUserRanking = useMemo(() => rankings.find((row) => row.isCurrentUser) ?? null, [rankings]);
  const podiumRankings = rankings.length >= 3 ? rankings.slice(0, 3) : [];
  const listRankings = podiumRankings.length === 3 ? rankings.slice(3) : rankings;
  const handleOpenProfile = (profileSlug) => {
    if (!profileSlug) {
      return;
    }

    onNavigate?.('publicProfile', { profileSlug });
  };
  const getProfileNavigationProps = (row) => {
    if (!row.profileSlug) {
      return {};
    }

    return {
      role: 'link',
      tabIndex: 0,
      'aria-label': `${t('leaderboard.viewProfile')}: ${row.ign}`,
      'data-has-profile-link': 'true',
      onClick: () => handleOpenProfile(row.profileSlug),
      onKeyDown: (event) => {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          handleOpenProfile(row.profileSlug);
        }
      },
    };
  };

  useEffect(() => {
    let cancelled = false;

    async function loadRankings() {
      setLoading(true);
      setError('');

      try {
        const nextRankings = await loadMemberCpRankings(normalizedScope);

        if (!cancelled) {
          setRankings(nextRankings);
        }
      } catch (loadError) {
        if (!cancelled) {
          setRankings([]);
          setError(getDisplayError(loadError, t('leaderboard.loadError')));
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    loadRankings();

    return () => {
      cancelled = true;
    };
  }, [normalizedScope, reloadTick, t]);

  return (
    <div className="stack leaderboard-page">
      <section className="panel member-compact-panel leaderboard-hero">
        <div>
          <h3>{t('leaderboard.title')}</h3>
          <p className="leaderboard-privacy-note">{t('leaderboard.cpHidden')}</p>
        </div>
      </section>

      <section className="panel member-compact-panel leaderboard-panel" aria-label={t('leaderboard.title')}>
        <div className="leaderboard-tabs" role="tablist" aria-label={t('leaderboard.title')}>
          {SCOPES.map((scopeId) => (
            <button
              key={scopeId}
              type="button"
              role="tab"
              aria-selected={normalizedScope === scopeId}
              className="leaderboard-tab"
              data-active={normalizedScope === scopeId}
              onClick={() => setScope(scopeId)}
            >
              {scopeId === 'global' ? t('leaderboard.global') : t('leaderboard.myGuild')}
            </button>
          ))}
        </div>

        <div className="section-heading-row leaderboard-heading">
          <div>
            <span className="eyebrow">{scopeLabel}</span>
            <h3>{t('leaderboard.rank')}</h3>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={() => setReloadTick((tick) => tick + 1)} disabled={loading}>
            {loading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>

        {error ? <p className="error-line">{error}</p> : null}

        {!loading && !error && rankings.length === 0 ? (
          <div className="compact-empty-state leaderboard-empty">
            <h3>{t('leaderboard.noRankings')}</h3>
            <p>{t('leaderboard.rankingsAfterCp')}</p>
          </div>
        ) : null}

        {!loading && !error && rankings.length > 0 ? (
          currentUserRanking ? (
            <article
              className="leaderboard-your-rank"
              data-rank-tier={getRankTier(currentUserRanking.rank)}
              {...getProfileNavigationProps(currentUserRanking)}
            >
              <div>
                <span className="eyebrow">{t('leaderboard.yourRank')}</span>
                <div className="rank-marker" aria-label={`${t('leaderboard.rank')} ${currentUserRanking.rank}`}>
                  <span>{getRankMarker(currentUserRanking.rank)}</span>
                </div>
              </div>
              <LeaderboardCompetitorCard
                row={currentUserRanking}
                scope={normalizedScope}
                t={t}
              />
            </article>
          ) : (
            <p className="muted-line leaderboard-not-ranked">{t('leaderboard.notRankedYet')}</p>
          )
        ) : null}

        {podiumRankings.length === 3 ? (
          <section className="leaderboard-podium" aria-label={t('leaderboard.podium')}>
            <span className="eyebrow">{t('leaderboard.podium')}</span>
            <div className="leaderboard-podium-grid">
              {podiumRankings.map((row) => (
                <article
                  key={`podium-${normalizedScope}-${row.rank}-${row.ign}-${row.guildSlug ?? 'guild'}`}
                  className="leaderboard-podium-card"
                  data-rank-tier={getRankTier(row.rank)}
                  data-rank={row.rank}
                  data-current-user={row.isCurrentUser ? 'true' : 'false'}
                  {...getProfileNavigationProps(row)}
                >
                  <div className="rank-marker" aria-label={`${t('leaderboard.rank')} ${row.rank}`}>
                    <span>{getRankMarker(row.rank)}</span>
                  </div>
                  <LeaderboardCompetitorCard
                    row={row}
                    scope={normalizedScope}
                    t={t}
                    variant="podium"
                  />
                </article>
              ))}
            </div>
          </section>
        ) : null}

        <div className="leaderboard-list" aria-live="polite">
          {listRankings.map((row) => {
            const tier = getRankTier(row.rank);

            return (
              <article
                key={`${normalizedScope}-${row.rank}-${row.ign}-${row.guildSlug ?? 'guild'}`}
                className="leaderboard-row"
                data-rank-tier={tier}
                data-current-user={row.isCurrentUser ? 'true' : 'false'}
                {...getProfileNavigationProps(row)}
              >
                <div className="rank-marker" aria-label={`${t('leaderboard.rank')} ${row.rank}`}>
                  <span>{getRankMarker(row.rank)}</span>
                </div>
                <LeaderboardCompetitorCard row={row} scope={normalizedScope} t={t} />
              </article>
            );
          })}
        </div>
      </section>
    </div>
  );
}
