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

export function AdminCpSection({
  cpLoading,
  cpSearch,
  selectedCpGuildId,
  cpGuildOptions,
  selectedCpGuild,
  filteredCpRoster,
  cpLeaderboard,
  cpLeaderboardScope,
  cpLeaderboardError,
  cpDrafts,
  cpWindow,
  cpWindowNote,
  activeAction,
  canUpdateCpValues,
  canViewGlobalCpLeaderboard,
  onRefresh,
  onSearchChange,
  onSelectedGuildChange,
  onLeaderboardScopeChange,
  onUpdateCpDraft,
  onResetCpDraft,
  onUpdateCp,
  onWindowNoteChange,
  onOpenWindow,
  onCloseWindow,
  formatDate,
  formatCpValue,
  t,
}) {
  const actionDisabled = Boolean(activeAction);
  const windowIsOpen = cpWindow?.status === 'open';
  const openingWindow = activeAction?.type === 'open-cp-window';
  const closingWindow = activeAction?.type === 'close-cp-window';

  return (
    <section className="cp-management admin-section" aria-label={t('admin.cp.aria')}>
      <div className="panel cp-management-tools admin-section-tools">
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="success">CP</StatusBadge>
            <h3>{t('admin.cp.title')}</h3>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={onRefresh} disabled={cpLoading}>
            {cpLoading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>

        <div className="member-filter-grid">
          <label>
            {t('admin.common.search')}
            <input
              type="search"
              value={cpSearch}
              placeholder={t('admin.common.usernameIgnGuild')}
              onChange={(event) => onSearchChange(event.target.value)}
            />
          </label>
          <label>
            {t('admin.common.guild')}
            <select
              value={selectedCpGuildId}
              onChange={(event) => onSelectedGuildChange(event.target.value)}
              disabled={cpLoading || cpGuildOptions.length <= 1}
            >
              {cpGuildOptions.length === 0 ? <option value="">{t('admin.cp.noGuildScope')}</option> : null}
              {cpGuildOptions.map((guild) => (
                <option key={guild.id} value={guild.id}>
                  {guild.name}
                </option>
              ))}
            </select>
          </label>
        </div>
      </div>

      <section className="panel cp-window-panel compact-admin-card" aria-label={t('admin.cp.updateWindow')}>
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone={windowIsOpen ? 'success' : 'warning'}>
              {windowIsOpen ? t('admin.cp.windowOpen') : t('admin.cp.windowClosed')}
            </StatusBadge>
            <h3>{t('admin.cp.updateWindow')}</h3>
          </div>
          <p className="muted-copy">{selectedCpGuild?.name ?? t('admin.common.selectedGuild')}</p>
        </div>

        <div className="approval-meta compact-meta cp-window-meta">
          <div>
            <span>{t('admin.cp.windowStatus')}</span>
            <strong>{windowIsOpen ? t('admin.cp.windowOpen') : t('admin.cp.windowClosed')}</strong>
          </div>
          <div>
            <span>{t('admin.common.updated')}</span>
            <strong>{formatDate(cpWindow?.updated_at)}</strong>
          </div>
        </div>

        {canUpdateCpValues ? (
          <div className="cp-window-controls">
            {!windowIsOpen ? (
              <label>
                {t('admin.cp.windowNote')}
                <input
                  type="text"
                  value={cpWindowNote}
                  placeholder={t('admin.cp.windowNotePlaceholder')}
                  onChange={(event) => onWindowNoteChange(event.target.value)}
                  disabled={cpLoading || actionDisabled || !selectedCpGuildId}
                  maxLength={1000}
                />
              </label>
            ) : null}

            <div className="member-action-row">
              <button
                type="button"
                className="primary-action"
                onClick={onOpenWindow}
                disabled={cpLoading || actionDisabled || !selectedCpGuildId || windowIsOpen}
              >
                {openingWindow ? t('common.working') : t('admin.cp.openWindow')}
              </button>
              <button
                type="button"
                className="secondary-action"
                onClick={onCloseWindow}
                disabled={cpLoading || actionDisabled || !windowIsOpen}
              >
                {closingWindow ? t('common.working') : t('admin.cp.closeWindow')}
              </button>
            </div>
          </div>
        ) : (
          <p className="muted-line compact-state-line">{t('admin.cp.windowReadOnly')}</p>
        )}
      </section>

      {cpLoading ? <p className="muted-line">{t('admin.cp.loading')}</p> : null}

      {!cpLoading && selectedCpGuildId && filteredCpRoster.length === 0 ? (
        <section className="panel compact-empty-state">
          <StatusBadge>{t('admin.common.empty')}</StatusBadge>
          <h3>{t('admin.cp.empty')}</h3>
        </section>
      ) : null}

      {!cpLoading && !selectedCpGuildId ? (
        <section className="panel compact-empty-state">
          <StatusBadge tone="warning">{t('admin.cp.noGuildScope')}</StatusBadge>
          <h3>{t('admin.common.chooseGuild')}</h3>
        </section>
      ) : null}

      <div className="cp-card-list">
        {filteredCpRoster.map((item) => {
          const isUpdatingCp = activeAction?.id === item.profile_id && activeAction.type === 'update-cp';
          const draftValue = cpDrafts[item.profile_id] ?? '';
          const originalValue = item.cp_value === null || item.cp_value === undefined ? '' : String(item.cp_value);
          const cpChanged = draftValue.trim() !== originalValue;

          return (
            <article className="panel cp-card compact-admin-card" key={item.profile_id}>
              <div className="approval-card-header">
                <div>
                  <h4>{item.ign ?? t('admin.common.unknownIgn')}</h4>
                  <p>@{item.username ?? t('common.unknown')}</p>
                </div>
                <StatusBadge tone={item.cp_value === null || item.cp_value === undefined ? 'warning' : 'success'}>
                  {formatCpValue(item.cp_value)}
                </StatusBadge>
              </div>

              <div className="approval-meta compact-meta" aria-label={t('admin.cp.memberDetails')}>
                <div>
                  <span>{t('admin.common.guild')}</span>
                  <strong>{selectedCpGuild?.name ?? t('admin.common.selectedGuild')}</strong>
                </div>
                <div>
                  <span>{t('admin.cp.currentCp')}</span>
                  <strong>{formatCpValue(item.cp_value)}</strong>
                </div>
                <div>
                  <span>{t('admin.common.updated')}</span>
                  <strong>{formatDate(item.updated_at)}</strong>
                </div>
              </div>

              {canUpdateCpValues ? (
                <div className="cp-edit-row">
                  <label>
                    {t('admin.cp.cpValue')}
                    <input
                      type="text"
                      inputMode="numeric"
                      pattern="[0-9]*"
                      value={draftValue}
                      placeholder={t('admin.common.notEntered')}
                      onChange={(event) => onUpdateCpDraft(item.profile_id, event.target.value)}
                      disabled={actionDisabled}
                    />
                  </label>
                  <div className="member-action-row">
                    <button
                      type="button"
                      className="primary-action"
                      onClick={() => onUpdateCp(item)}
                      disabled={actionDisabled || !cpChanged}
                    >
                      {isUpdatingCp ? t('admin.cp.savingCp') : t('admin.cp.saveCp')}
                    </button>
                    <button
                      type="button"
                      className="secondary-action"
                      onClick={() => onResetCpDraft(item)}
                      disabled={actionDisabled || !cpChanged}
                    >
                      {t('common.cancel')}
                    </button>
                  </div>
                </div>
              ) : (
                <p className="muted-line compact-state-line">{t('admin.cp.readOnly')}</p>
              )}
            </article>
          );
        })}
      </div>

      <section className="panel cp-leaderboard compact-admin-card" aria-label={t('admin.cp.leaderboardTitle')}>
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="success">{t('admin.cp.leaderboard')}</StatusBadge>
            <h3>{t('admin.cp.leaderboardTitle')}</h3>
          </div>
          <p className="muted-copy">
            {cpLeaderboardScope === 'global'
              ? t('admin.cp.globalLeaderboard')
              : selectedCpGuild?.name ?? t('admin.common.selectedGuild')}
          </p>
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
