import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

export function AdminMembersSection({
  memberLoading,
  filteredMembers,
  memberSearch,
  guildFilter,
  memberStatusFilter,
  guildOptions,
  memberDrafts,
  activeGuildOptions,
  activeAction,
  confirmAction,
  canEditIgn,
  canResetSlug,
  canManageRoles,
  canTransferGuilds,
  canManageRosterStatuses,
  allowedMemberRoles,
  visibleRosterStatusOptions,
  onRefresh,
  onSearchChange,
  onGuildFilterChange,
  onMemberStatusFilterChange,
  onUpdateDraft,
  onSetConfirmAction,
  onSaveIgn,
  onResetSlug,
  onAssignRole,
  onTransferGuild,
  onUpdateRosterStatus,
  formatDate,
  formatRole,
  formatRosterStatus,
  getAllowedRosterStatusOptions,
  rosterStatusTone,
  statusTone,
}) {
  return (
    <section className="member-management" aria-label="Member management">
      <div className="panel member-management-tools">
        <div className="section-heading-row">
          <div>
            <StatusBadge tone="success">Members</StatusBadge>
            <h3>Active roster</h3>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={onRefresh} disabled={memberLoading}>
            {memberLoading ? 'Loading...' : 'Refresh'}
          </button>
        </div>

        <div className="member-filter-grid">
          <label>
            Search
            <input
              type="search"
              value={memberSearch}
              placeholder="Username, IGN, guild"
              onChange={(event) => onSearchChange(event.target.value)}
            />
          </label>
          <label>
            Guild
            <select value={guildFilter} onChange={(event) => onGuildFilterChange(event.target.value)}>
              <option value="all">All visible guilds</option>
              {guildOptions.map((guild) => (
                <option key={guild.id} value={guild.id}>
                  {guild.name}
                </option>
              ))}
            </select>
          </label>
          <label>
            Roster status
            <select value={memberStatusFilter} onChange={(event) => onMemberStatusFilterChange(event.target.value)}>
              <option value="all">All roster statuses</option>
              {visibleRosterStatusOptions.map((statusOption) => (
                <option key={statusOption.value} value={statusOption.value}>
                  {statusOption.label}
                </option>
              ))}
            </select>
          </label>
        </div>
      </div>

      {memberLoading ? <p className="muted-line">Loading roster...</p> : null}

      {!memberLoading && filteredMembers.length === 0 ? (
        <section className="panel hero-panel">
          <StatusBadge>Roster empty</StatusBadge>
          <h3>No approved members found</h3>
          <p>Approved primary memberships are shown here when they match the current filters.</p>
        </section>
      ) : null}

      <div className="member-card-list">
        {filteredMembers.map((item) => {
          const isEditingIgn = activeAction?.id === item.id && activeAction.type === 'edit-ign';
          const isResettingSlug = activeAction?.id === item.id && activeAction.type === 'reset-slug';
          const isAssigningRole = activeAction?.id === item.id && activeAction.type === 'assign-role';
          const isTransferringGuild = activeAction?.id === item.id && activeAction.type === 'transfer-guild';
          const isUpdatingRosterStatus = activeAction?.id === item.id && activeAction.type === 'roster-status';
          const isConfirmingRole = confirmAction?.id === item.id && confirmAction.type === 'assign-role';
          const isConfirmingTransfer = confirmAction?.id === item.id && confirmAction.type === 'transfer-guild';
          const isConfirmingRosterStatus = confirmAction?.id === item.id && confirmAction.type === 'roster-status';
          const actionDisabled = Boolean(activeAction);
          const draft = memberDrafts[item.id] ?? {
            ign: item.profile?.ign ?? '',
            role: item.role ?? 'member',
            rosterStatus: item.roster_status ?? 'active',
            statusReason: '',
            slug: item.profile?.profile_slug ?? item.profile?.username ?? '',
            targetGuildId: '',
          };
          const transferGuildOptions = activeGuildOptions.filter((guild) => guild.id !== item.guild_id);
          const selectedTargetGuild = transferGuildOptions.find((guild) => guild.id === draft.targetGuildId);
          const roleCanBeChanged = canManageRoles && item.role !== 'owner' && allowedMemberRoles.length > 0;
          const roleSelectValue = allowedMemberRoles.includes(draft.role)
            ? draft.role
            : allowedMemberRoles[0] ?? 'member';
          const allowedRosterStatusOptions = getAllowedRosterStatusOptions(item);
          const allowedRosterStatusValues = allowedRosterStatusOptions.map((statusOption) => statusOption.value);
          const rosterStatusCanBeChanged = canManageRosterStatuses && allowedRosterStatusOptions.length > 0;
          const currentRosterStatus = item.roster_status ?? 'active';
          const rosterStatusSelectValue = allowedRosterStatusValues.includes(draft.rosterStatus)
            ? draft.rosterStatus
            : allowedRosterStatusValues[0] ?? currentRosterStatus;
          const rosterStatusRequiresReason = ['suspended', 'left', 'kicked'].includes(rosterStatusSelectValue);
          const rosterReason = draft.statusReason ?? '';
          const rosterStatusChanged = rosterStatusSelectValue !== currentRosterStatus;
          const rosterStatusSubmitDisabled =
            actionDisabled ||
            !rosterStatusCanBeChanged ||
            !rosterStatusChanged ||
            (rosterStatusRequiresReason && !rosterReason.trim());

          return (
            <article className="panel member-card" key={item.id}>
              <div className="approval-card-header">
                <div>
                  <h4>{item.profile?.ign ?? 'Unknown IGN'}</h4>
                  <p>@{item.profile?.username ?? 'unknown'}</p>
                </div>
                <div className="status-badge-row">
                  <StatusBadge tone={statusTone(item.membership_status)}>{item.membership_status}</StatusBadge>
                  <StatusBadge tone={rosterStatusTone(currentRosterStatus)}>
                    {formatRosterStatus(currentRosterStatus)}
                  </StatusBadge>
                </div>
              </div>

              <div className="approval-meta" aria-label="Member details">
                <div>
                  <span>Guild</span>
                  <strong>{item.guild?.name ?? 'Unknown guild'}</strong>
                </div>
                <div>
                  <span>Role</span>
                  <strong>{formatRole(item.role)}</strong>
                </div>
                <div>
                  <span>Roster status</span>
                  <strong>{formatRosterStatus(currentRosterStatus)}</strong>
                </div>
                <div>
                  <span>Profile status</span>
                  <strong>{item.profile?.approval_status ?? 'unknown'}</strong>
                </div>
                <div>
                  <span>Updated</span>
                  <strong>{formatDate(item.profile?.updated_at ?? item.updated_at)}</strong>
                </div>
              </div>

              {canEditIgn || canResetSlug ? (
                <div className="member-edit-grid">
                  {canEditIgn ? (
                    <div className="member-edit-block">
                      <label>
                        IGN
                        <input
                          type="text"
                          value={draft.ign}
                          onChange={(event) => onUpdateDraft(item.id, 'ign', event.target.value)}
                          disabled={actionDisabled}
                        />
                      </label>
                      <button type="button" className="primary-action" onClick={() => onSaveIgn(item)} disabled={actionDisabled}>
                        {isEditingIgn ? 'Saving IGN...' : 'Save IGN'}
                      </button>
                    </div>
                  ) : null}

                  {canResetSlug ? (
                    <div className="member-edit-block">
                      <label>
                        Username / profile slug
                        <input
                          type="text"
                          value={draft.slug}
                          onChange={(event) => onUpdateDraft(item.id, 'slug', event.target.value)}
                          disabled={actionDisabled}
                        />
                      </label>
                      <button type="button" className="danger-action" onClick={() => onResetSlug(item)} disabled={actionDisabled}>
                        {isResettingSlug ? 'Resetting...' : 'Reset slug'}
                      </button>
                    </div>
                  ) : null}
                </div>
              ) : (
                <p className="muted-line">Roster visibility only. No edit action is available for this permission set.</p>
              )}

              {canManageRosterStatuses ? (
                <div className="member-admin-actions">
                  <div className="member-edit-block roster-status-control">
                    <div>
                      <h4>Roster status</h4>
                      <p className="muted-copy">
                        Status changes use the backend RPC and keep private reasons out of this roster.
                      </p>
                    </div>

                    {rosterStatusCanBeChanged ? (
                      <>
                        <label>
                          New status
                          <select
                            value={rosterStatusSelectValue}
                            onChange={(event) => onUpdateDraft(item.id, 'rosterStatus', event.target.value)}
                            disabled={actionDisabled}
                          >
                            {allowedRosterStatusOptions.map((statusOption) => (
                              <option key={statusOption.value} value={statusOption.value}>
                                {statusOption.label}
                              </option>
                            ))}
                          </select>
                        </label>

                        <label>
                          Reason
                          <textarea
                            value={rosterReason}
                            maxLength={1000}
                            placeholder={
                              rosterStatusRequiresReason
                                ? 'Required for suspended, left, or kicked'
                                : 'Optional staff note, stored privately'
                            }
                            onChange={(event) => onUpdateDraft(item.id, 'statusReason', event.target.value)}
                            disabled={actionDisabled}
                          />
                        </label>

                        {rosterStatusRequiresReason && !rosterReason.trim() ? (
                          <p className="member-warning">A private reason is required for this hard-block status.</p>
                        ) : null}

                        {isConfirmingRosterStatus ? (
                          <p className="member-warning">
                            Confirm roster status change from {formatRosterStatus(currentRosterStatus)} to{' '}
                            {formatRosterStatus(rosterStatusSelectValue)}.
                          </p>
                        ) : null}

                        <div className="member-action-row">
                          {isConfirmingRosterStatus ? (
                            <>
                              <button
                                type="button"
                                className="danger-action"
                                onClick={() => onUpdateRosterStatus(item)}
                                disabled={actionDisabled}
                              >
                                {isUpdatingRosterStatus ? 'Saving status...' : 'Confirm status'}
                              </button>
                              <button
                                type="button"
                                className="secondary-action"
                                onClick={() => onSetConfirmAction(null)}
                                disabled={actionDisabled}
                              >
                                Cancel
                              </button>
                            </>
                          ) : (
                            <button
                              type="button"
                              className={rosterStatusRequiresReason ? 'danger-action' : 'primary-action'}
                              onClick={() =>
                                rosterStatusRequiresReason
                                  ? onSetConfirmAction({ id: item.id, type: 'roster-status' })
                                  : onUpdateRosterStatus(item)
                              }
                              disabled={rosterStatusSubmitDisabled}
                            >
                              {rosterStatusRequiresReason ? 'Review status change' : 'Save status'}
                            </button>
                          )}
                        </div>
                      </>
                    ) : (
                      <p className="muted-line">Roster status changes are not available for this target.</p>
                    )}
                  </div>
                </div>
              ) : null}

              {canManageRoles || canTransferGuilds ? (
                <div className="member-admin-actions">
                  {canManageRoles ? (
                    <div className="member-edit-block">
                      <div>
                        <h4>Role management</h4>
                        <p className="muted-copy">Owner assignment is manual-only and is never available here.</p>
                      </div>

                      {item.role === 'owner' ? (
                        <p className="muted-line">Owner role changes are manual-only.</p>
                      ) : (
                        <>
                          <label>
                            New role
                            <select
                              value={roleSelectValue}
                              onChange={(event) => onUpdateDraft(item.id, 'role', event.target.value)}
                              disabled={actionDisabled || !roleCanBeChanged}
                            >
                              {allowedMemberRoles.map((role) => (
                                <option key={role} value={role}>
                                  {formatRole(role)}
                                </option>
                              ))}
                            </select>
                          </label>

                          {isConfirmingRole ? (
                            <p className="member-warning">
                              Confirm role change from {formatRole(item.role)} to {formatRole(roleSelectValue)}.
                            </p>
                          ) : null}

                          <div className="member-action-row">
                            {isConfirmingRole ? (
                              <>
                                <button
                                  type="button"
                                  className="primary-action"
                                  onClick={() => onAssignRole(item)}
                                  disabled={actionDisabled}
                                >
                                  {isAssigningRole ? 'Saving role...' : 'Confirm role'}
                                </button>
                                <button
                                  type="button"
                                  className="secondary-action"
                                  onClick={() => onSetConfirmAction(null)}
                                  disabled={actionDisabled}
                                >
                                  Cancel
                                </button>
                              </>
                            ) : (
                              <button
                                type="button"
                                className="primary-action"
                                onClick={() => onSetConfirmAction({ id: item.id, type: 'assign-role' })}
                                disabled={actionDisabled || !roleCanBeChanged || roleSelectValue === item.role}
                              >
                                Review role change
                              </button>
                            )}
                          </div>
                        </>
                      )}
                    </div>
                  ) : null}

                  {canTransferGuilds ? (
                    <div className="member-edit-block">
                      <div>
                        <h4>Guild transfer</h4>
                        <p className="muted-copy">Owner-only. Moving guild resets this member's role to Member.</p>
                      </div>

                      <label>
                        Target guild
                        <select
                          value={draft.targetGuildId}
                          onChange={(event) => onUpdateDraft(item.id, 'targetGuildId', event.target.value)}
                          disabled={actionDisabled || transferGuildOptions.length === 0}
                        >
                          <option value="">Select active guild</option>
                          {transferGuildOptions.map((guild) => (
                            <option key={guild.id} value={guild.id}>
                              {guild.name}
                            </option>
                          ))}
                        </select>
                      </label>

                      <p className="member-warning">Moving guild resets this member's role to Member.</p>

                      {isConfirmingTransfer ? (
                        <p className="muted-line">
                          Confirm transfer from {item.guild?.name ?? 'current guild'} to{' '}
                          {selectedTargetGuild?.name ?? 'selected guild'}.
                        </p>
                      ) : null}

                      <div className="member-action-row">
                        {isConfirmingTransfer ? (
                          <>
                            <button
                              type="button"
                              className="danger-action"
                              onClick={() => onTransferGuild(item)}
                              disabled={actionDisabled}
                            >
                              {isTransferringGuild ? 'Transferring...' : 'Confirm transfer'}
                            </button>
                            <button
                              type="button"
                              className="secondary-action"
                              onClick={() => onSetConfirmAction(null)}
                              disabled={actionDisabled}
                            >
                              Cancel
                            </button>
                          </>
                        ) : (
                          <button
                            type="button"
                            className="danger-action"
                            onClick={() => onSetConfirmAction({ id: item.id, type: 'transfer-guild' })}
                            disabled={actionDisabled || !draft.targetGuildId || draft.targetGuildId === item.guild_id}
                          >
                            Review transfer
                          </button>
                        )}
                      </div>
                    </div>
                  ) : null}
                </div>
              ) : null}
            </article>
          );
        })}
      </div>
    </section>
  );
}
