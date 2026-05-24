import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

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

  if (rank <= 5) {
    return 'leaderboard.eliteFive';
  }

  if (rank <= 10) {
    return 'leaderboard.topTen';
  }

  return null;
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

export function AdminCpLeaderboardSection({
  cpLoading,
  selectedCpGuild,
  cpLeaderboard,
  cpLeaderboardScope,
  cpLeaderboardError,
  canViewGlobalCpLeaderboard,
  onRefresh,
  onLeaderboardScopeChange,
  formatDate,
  formatCpValue,
  t,
}) {
  return (
    <section className="admin-section" aria-label={t('admin.cp.leaderboardTitle')}>
      <section className="panel cp-leaderboard compact-admin-card" aria-label={t('admin.cp.leaderboardTitle')}>
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="success">{t('admin.cp.leaderboard')}</StatusBadge>
            <h3>{t('admin.cp.leaderboardTitle')}</h3>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={onRefresh} disabled={cpLoading}>
            {cpLoading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>

        <div className="section-heading-row leaderboard-heading">
          <div>
            <span className="eyebrow">
              {cpLeaderboardScope === 'global'
                ? t('admin.cp.globalLeaderboard')
                : selectedCpGuild?.name ?? t('admin.common.selectedGuild')}
            </span>
            <h3>{t('admin.cp.rank')}</h3>
          </div>
        </div>

        <div className="leaderboard-tabs admin-cp-leaderboard-tabs" role="tablist" aria-label={t('admin.cp.leaderboardTitle')}>
          <button
            type="button"
            role="tab"
            aria-selected={cpLeaderboardScope === 'guild'}
            className="leaderboard-tab"
            data-active={cpLeaderboardScope === 'guild'}
            onClick={() => onLeaderboardScopeChange('guild')}
            disabled={cpLoading}
          >
            {t('admin.cp.guildLeaderboard')}
          </button>
          {canViewGlobalCpLeaderboard ? (
            <button
              type="button"
              role="tab"
              aria-selected={cpLeaderboardScope === 'global'}
              className="leaderboard-tab"
              data-active={cpLeaderboardScope === 'global'}
              onClick={() => onLeaderboardScopeChange('global')}
              disabled={cpLoading}
            >
              {t('admin.cp.globalLeaderboard')}
            </button>
          ) : null}
        </div>

        {cpLeaderboardError ? <p className="error-line">{cpLeaderboardError}</p> : null}

        {!cpLeaderboardError ? (
          cpLeaderboard.length === 0 ? (
            <p className="muted-line">{t('admin.cp.noRankings')}</p>
          ) : (
            <div className="leaderboard-list admin-cp-rank-list">
              {cpLeaderboard.map((item) => {
                const tier = getRankTier(item.rank);
                const rankLabelKey = getRankLabelKey(item.rank);

                return (
                  <article
                    className="leaderboard-row admin-cp-rank-row"
                    data-rank-tier={tier}
                    key={item.profileId ?? `${item.rank}-${item.ign}-${item.guildId ?? 'guild'}`}
                  >
                    <div className="rank-marker" aria-label={`${t('admin.cp.rank')} ${item.rank}`}>
                      <span>{getRankMarker(item.rank)}</span>
                    </div>
                    <div className="leaderboard-member admin-cp-rank-main">
                      <div className="leaderboard-member-line">
                        <strong>{item.ign ?? t('admin.common.unknownIgn')}</strong>
                        {rankLabelKey ? <StatusBadge tone="crimson">{t(rankLabelKey)}</StatusBadge> : null}
                      </div>
                      <div className="leaderboard-meta admin-cp-rank-meta">
                        <span>@{item.username ?? t('common.unknown')}</span>
                        <span>
                          {t('admin.cp.guild')}: {item.guildName ?? selectedCpGuild?.name ?? t('admin.common.selectedGuild')}
                        </span>
                        <span>
                          {t('admin.cp.lastUpdated')}: {formatDate(item.updatedAt)}
                        </span>
                      </div>
                    </div>
                    <div className="admin-cp-rank-value">
                      <span>{t('admin.cp.cpValue')}</span>
                      <strong>{formatCpValue(item.cpValue)}</strong>
                    </div>
                  </article>
                );
              })}
            </div>
          )
        ) : null}
      </section>
    </section>
  );
}
