import React from 'react';
import { CosmeticPreview } from '../CosmeticPreview.jsx';
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

function AdminRankingIdentity({ item, selectedCpGuild, formatDate, t, variant = 'row' }) {
  const rankLabelKey = getRankLabelKey(item.rank);

  return (
    <>
      <CosmeticPreview
        avatar={item.avatar}
        frame={item.frame}
        label={item.ign ?? item.username ?? t('admin.common.unknownIgn')}
        size={variant === 'podium' && item.rank === 1 ? 'medium' : 'small'}
        className={variant === 'podium' ? 'leaderboard-podium-cosmetic' : 'leaderboard-cosmetic'}
      />
      <div className="leaderboard-member admin-cp-rank-main">
        <div className="leaderboard-member-line">
          <strong>{item.ign ?? t('admin.common.unknownIgn')}</strong>
          <StatusBadge tone="crimson">{t(rankLabelKey)}</StatusBadge>
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
    </>
  );
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
  const podiumRankings = cpLeaderboard.length >= 3 ? cpLeaderboard.slice(0, 3) : [];
  const listRankings = podiumRankings.length === 3 ? cpLeaderboard.slice(3) : cpLeaderboard;

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
            <>
              {podiumRankings.length === 3 ? (
                <section className="leaderboard-podium admin-cp-podium" aria-label={t('leaderboard.podium')}>
                  <span className="eyebrow">{t('leaderboard.podium')}</span>
                  <div className="leaderboard-podium-grid">
                    {podiumRankings.map((item) => (
                      <article
                        className="leaderboard-podium-card admin-cp-podium-card"
                        data-rank-tier={getRankTier(item.rank)}
                        data-rank={item.rank}
                        key={item.profileId ?? `podium-${item.rank}-${item.ign}-${item.guildId ?? 'guild'}`}
                      >
                        <div className="rank-marker" aria-label={`${t('admin.cp.rank')} ${item.rank}`}>
                          <span>{getRankMarker(item.rank)}</span>
                        </div>
                        <AdminRankingIdentity
                          item={item}
                          selectedCpGuild={selectedCpGuild}
                          formatDate={formatDate}
                          t={t}
                          variant="podium"
                        />
                        <div className="admin-cp-rank-value">
                          <span>{t('admin.cp.cpValue')}</span>
                          <strong>{formatCpValue(item.cpValue)}</strong>
                        </div>
                      </article>
                    ))}
                  </div>
                </section>
              ) : null}
              <div className="leaderboard-list admin-cp-rank-list">
                {listRankings.map((item) => {
                  const tier = getRankTier(item.rank);

                  return (
                    <article
                      className="leaderboard-row admin-cp-rank-row"
                      data-rank-tier={tier}
                      key={item.profileId ?? `${item.rank}-${item.ign}-${item.guildId ?? 'guild'}`}
                    >
                      <div className="rank-marker" aria-label={`${t('admin.cp.rank')} ${item.rank}`}>
                        <span>{getRankMarker(item.rank)}</span>
                      </div>
                      <AdminRankingIdentity
                        item={item}
                        selectedCpGuild={selectedCpGuild}
                        formatDate={formatDate}
                        t={t}
                      />
                      <div className="admin-cp-rank-value">
                        <span>{t('admin.cp.cpValue')}</span>
                        <strong>{formatCpValue(item.cpValue)}</strong>
                      </div>
                    </article>
                  );
                })}
              </div>
            </>
          )
        ) : null}
      </section>
    </section>
  );
}
