import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

export function AdminCpSection({
  cpLoading,
  cpSearch,
  selectedCpGuildId,
  cpGuildOptions,
  selectedCpGuild,
  filteredCpRoster,
  cpLeaderboard,
  cpDrafts,
  activeAction,
  canUpdateCpValues,
  onRefresh,
  onSearchChange,
  onSelectedGuildChange,
  onUpdateCpDraft,
  onResetCpDraft,
  onUpdateCp,
  formatDate,
  formatCpValue,
}) {
  return (
    <section className="cp-management" aria-label="CP management">
      <div className="panel cp-management-tools">
        <div className="section-heading-row">
          <div>
            <StatusBadge tone="success">CP</StatusBadge>
            <h3>CP management</h3>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={onRefresh} disabled={cpLoading}>
            {cpLoading ? 'Loading...' : 'Refresh'}
          </button>
        </div>

        <div className="member-filter-grid">
          <label>
            Search
            <input
              type="search"
              value={cpSearch}
              placeholder="Username, IGN, guild"
              onChange={(event) => onSearchChange(event.target.value)}
            />
          </label>
          <label>
            Guild
            <select
              value={selectedCpGuildId}
              onChange={(event) => onSelectedGuildChange(event.target.value)}
              disabled={cpLoading || cpGuildOptions.length <= 1}
            >
              {cpGuildOptions.length === 0 ? <option value="">No CP guild scope</option> : null}
              {cpGuildOptions.map((guild) => (
                <option key={guild.id} value={guild.id}>
                  {guild.name}
                </option>
              ))}
            </select>
          </label>
        </div>
      </div>

      {cpLoading ? <p className="muted-line">Loading CP roster...</p> : null}

      {!cpLoading && selectedCpGuildId && filteredCpRoster.length === 0 ? (
        <section className="panel hero-panel">
          <StatusBadge>CP roster empty</StatusBadge>
          <h3>No CP rows found</h3>
          <p>Active approved members for the selected guild will appear here, including missing CP entries.</p>
        </section>
      ) : null}

      {!cpLoading && !selectedCpGuildId ? (
        <section className="panel hero-panel">
          <StatusBadge tone="warning">No guild scope</StatusBadge>
          <h3>CP scope unavailable</h3>
          <p>Choose an active guild scope before loading CP data.</p>
        </section>
      ) : null}

      <div className="cp-card-list">
        {filteredCpRoster.map((item) => {
          const isUpdatingCp = activeAction?.id === item.profile_id && activeAction.type === 'update-cp';
          const draftValue = cpDrafts[item.profile_id] ?? '';
          const originalValue = item.cp_value === null || item.cp_value === undefined ? '' : String(item.cp_value);
          const cpChanged = draftValue.trim() !== originalValue;
          const actionDisabled = Boolean(activeAction);

          return (
            <article className="panel cp-card" key={item.profile_id}>
              <div className="approval-card-header">
                <div>
                  <h4>{item.ign ?? 'Unknown IGN'}</h4>
                  <p>@{item.username ?? 'unknown'}</p>
                </div>
                <StatusBadge tone={item.cp_value === null || item.cp_value === undefined ? 'warning' : 'success'}>
                  {formatCpValue(item.cp_value)}
                </StatusBadge>
              </div>

              <div className="approval-meta" aria-label="CP member details">
                <div>
                  <span>Guild</span>
                  <strong>{selectedCpGuild?.name ?? 'Selected guild'}</strong>
                </div>
                <div>
                  <span>Current CP</span>
                  <strong>{formatCpValue(item.cp_value)}</strong>
                </div>
                <div>
                  <span>Updated</span>
                  <strong>{formatDate(item.updated_at)}</strong>
                </div>
              </div>

              {canUpdateCpValues ? (
                <div className="cp-edit-row">
                  <label>
                    CP value
                    <input
                      type="text"
                      inputMode="numeric"
                      pattern="[0-9]*"
                      value={draftValue}
                      placeholder="Not entered"
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
                      {isUpdatingCp ? 'Saving CP...' : 'Save CP'}
                    </button>
                    <button
                      type="button"
                      className="secondary-action"
                      onClick={() => onResetCpDraft(item)}
                      disabled={actionDisabled || !cpChanged}
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              ) : (
                <p className="muted-line">Read-only CP access. Update permission is required to edit CP.</p>
              )}
            </article>
          );
        })}
      </div>

      <section className="panel cp-leaderboard" aria-label="CP leaderboard">
        <div className="section-heading-row">
          <div>
            <StatusBadge tone="success">Leaderboard</StatusBadge>
            <h3>CP leaderboard</h3>
          </div>
          <p className="muted-copy">{selectedCpGuild?.name ?? 'Selected guild'}</p>
        </div>

        {cpLeaderboard.length === 0 ? (
          <p className="muted-line">No ranked CP entries yet.</p>
        ) : (
          <div className="cp-leaderboard-list">
            {cpLeaderboard.map((item) => (
              <article className="cp-leaderboard-row" key={item.profile_id}>
                <strong>#{item.leaderboard_rank}</strong>
                <div>
                  <h4>{item.ign ?? 'Unknown IGN'}</h4>
                  <p>@{item.username ?? 'unknown'} - {selectedCpGuild?.name ?? 'Selected guild'}</p>
                </div>
                <span>{formatCpValue(item.cp_value)}</span>
              </article>
            ))}
          </div>
        )}
      </section>
    </section>
  );
}
