import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

export function AdminMembersSection({
  memberLoading,
  filteredMembers,
  memberSearch,
  guildFilter,
  guildOptions,
  memberDrafts,
  activeGuildOptions,
  activeAction,
  confirmAction,
  canEditIgn,
  canResetSlug,
  canManageRoles,
  canTransferGuilds,
  allowedMemberRoles,
  onRefresh,
  onSearchChange,
  onGuildFilterChange,
  onUpdateDraft,
  onSetConfirmAction,
  onSaveIgn,
  onResetSlug,
  onAssignRole,
  onTransferGuild,
  formatDate,
  formatRole,
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
        </div>
      </div>

      {memberLoading ? <p className="muted-line">Loading active roster...</p> : null}

      {!memberLoading && filteredMembers.length === 0 ? (
        <section className="panel hero-panel">
          <StatusBadge>Roster empty</StatusBadge>
          <h3>No active approved members found</h3>
          <p>Only active memberships with approved profiles are shown here.</p>
        </section>
      ) : null}

      <div className="member-card-list">
        {filteredMembers.map((item) => {
          const isEditingIgn = activeAction?.id === item.id && activeAction.type === 'edit-ign';
          const isResettingSlug = activeAction?.id === item.id && activeAction.type === 'reset-slug';
          const isAssigningRole = activeAction?.id === item.id && activeAction.type === 'assign-role';
          const isTransferringGuild = activeAction?.id === item.id && activeAction.type === 'transfer-guild';
          const isConfirmingRole = confirmAction?.id === item.id && confirmAction.type === 'assign-role';
          const isConfirmingTransfer = confirmAction?.id === item.id && confirmAction.type === 'transfer-guild';
          const actionDisabled = Boolean(activeAction);
          const draft = memberDrafts[item.id] ?? {
            ign: item.profile?.ign ?? '',
            role: item.role ?? 'member',
            slug: item.profile?.profile_slug ?? item.profile?.username ?? '',
            targetGuildId: '',
          };
          const transferGuildOptions = activeGuildOptions.filter((guild) => guild.id !== item.guild_id);
          const selectedTargetGuild = transferGuildOptions.find((guild) => guild.id === draft.targetGuildId);
          const roleCanBeChanged = canManageRoles && item.role !== 'owner' && allowedMemberRoles.length > 0;
          const roleSelectValue = allowedMemberRoles.includes(draft.role)
            ? draft.role
            : allowedMemberRoles[0] ?? 'member';

          return (
            <article className="panel member-card" key={item.id}>
              <div className="approval-card-header">
                <div>
                  <h4>{item.profile?.ign ?? 'Unknown IGN'}</h4>
                  <p>@{item.profile?.username ?? 'unknown'}</p>
                </div>
                <StatusBadge tone={statusTone(item.membership_status)}>{item.membership_status}</StatusBadge>
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
