import React from 'react';
import { useLanguage } from '../context/LanguageContext.jsx';
import { createUnrankedSummary } from '../services/cpRankBadgeService.js';

const TIER_LABEL_KEYS = {
  rank_one: 'rankBadge.rankOne',
  rank_two: 'rankBadge.rankTwo',
  rank_three: 'rankBadge.rankThree',
  elite_five: 'rankBadge.eliteFive',
  top_ten: 'rankBadge.topTen',
  high_rank: 'rankBadge.highRank',
  ranked_member: 'rankBadge.rankedMember',
  unranked: 'rankBadge.unranked',
};

const RANK_MARKERS = {
  rank_1: 'I',
  rank_2: 'II',
  rank_3: 'III',
  elite_5: 'E5',
  top_10: 'T10',
  high_rank: 'HR',
  ranked_member: 'R',
  unranked: '--',
};

export function getRankTierLabelKey(rankTier) {
  return TIER_LABEL_KEYS[rankTier] ?? TIER_LABEL_KEYS.unranked;
}

export function RankBadge({ className = '', compact = false, error = '', loading = false, summary = null }) {
  const { t } = useLanguage();
  const safeSummary = summary ?? createUnrankedSummary();
  const visualKey = safeSummary.visualKey ?? 'unranked';
  const rankTier = safeSummary.rankTier ?? 'unranked';
  const ranked = Boolean(safeSummary.isRanked && safeSummary.globalRank);
  const labelKey = getRankTierLabelKey(rankTier);
  const marker = RANK_MARKERS[visualKey] ?? RANK_MARKERS.unranked;
  const classes = ['rank-badge'];

  if (compact) {
    classes.push('rank-badge-compact');
  }

  if (className) {
    classes.push(className);
  }

  let primaryText = ranked ? t('rankBadge.globalRank', { rank: safeSummary.globalRank }) : t('rankBadge.noRank');
  let tierText = t(labelKey);

  if (loading) {
    primaryText = t('common.loading');
    tierText = t('rankBadge.unranked');
  } else if (error) {
    primaryText = t('rankBadge.loadError');
    tierText = t('rankBadge.unranked');
  }

  return (
    <div className={classes.join(' ')} data-rank-visual={visualKey}>
      <span className="rank-badge-marker" aria-hidden="true">
        {marker}
      </span>
      <span className="rank-badge-copy">
        <strong>{primaryText}</strong>
        <span>{tierText}</span>
      </span>
    </div>
  );
}
