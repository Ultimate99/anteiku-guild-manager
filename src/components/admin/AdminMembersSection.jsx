import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

function roleTone(role) {
  if (role === 'owner') {
    return 'danger';
  }

  if (role === 'leader' || role === 'vice') {
    return 'warning';
  }

  if (role === 'admin') {
    return 'info';
  }

  return 'muted';
}

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
  formatMembershipStatus,
  formatApprovalStatus,
  getAllowedRosterStatusOptions,
  rosterStatusTone,
  statusTone,
  t,
}) {
  return (
    <section className="member-management admin-section" aria-label={t('admin.members.aria')}>
      <div className="panel member-management-tools admin-section-tools">
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="success">{t('admin.common.members')}</StatusBadge>
            <h3>{t('admin.members.title')}</h3>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={onRefresh} disabled={memberLoading}>
            {memberLoading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>

        <div className="member-filter-grid">
          <label>
            {t('admin.common.search')}
            <input
              type="search"
              value={memberSearch}
              placeholder={t('admin.common.usernameIgnGuild')}
              onChange={(event) => onSearchChange(event.target.value)}
            />
          </label>
          <label>
            {t('admin.common.guild')}
            <select value={guildFilter} onChange={(event) => onGuildFilterChange(event.target.value)}>
              <option value="all">{t('admin.common.allVisibleGuilds')}</option>
              {guildOptions.map((guild) => (
                <option key={guild.id} value={guild.id}>
                  {guild.name}
                </option>
              ))}
            </select>
          </label>
          <label>
            {t('admin.common.rosterStatus')}
            <select value={memberStatusFilter} onChange={(event) => onMemberStatusFilterChange(event.target.value)}>
              <option value="all">{t('admin.common.allRosterStatuses')}</option>
              {visibleRosterStatusOptions.map((statusOption) => (
                <option key={statusOption.value} value={statusOption.value}>
                  {statusOption.label}
                </option>
              ))}
            </select>
          </label>
        </div>
      </div>

      {memberLoading ? <p className="muted-line">{t('admin.members.loading')}</p> : null}

      {!memberLoading && filteredMembers.length === 0 ? (
        <section className="panel compact-empty-state">
          <StatusBadge>{t('admin.members.emptyBadge')}</StatusBadge>
          <h3>{t('admin.members.empty')}</h3>
        </section>
      ) : null}

      <div className="member-card-list compact-roster-list">
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
          const hasManagementControls =
            canEditIgn || canResetSlug || canManageRosterStatuses || canManageRoles || canTransferGuilds;

          return (
            <article className="panel member-card compact-admin-card compact-member-card" key={item.id}>
              <div className="member-row-main">
                <div className="member-identity">
                  <h4>{item.profile?.ign ?? t('admin.common.unknownIgn')}</h4>
                  <p>@{item.profile?.username ?? t('common.unknown')}</p>
                </div>
                <div className="status-badge-row member-row-badges">
                  <StatusBadge tone={roleTone(item.role)}>{formatRole(item.role)}</StatusBadge>
                  <StatusBadge tone={rosterStatusTone(currentRosterStatus)}>
                    {formatRosterStatus(currentRosterStatus)}
                  </StatusBadge>
                </div>
              </div>

              <div className="member-row-meta" aria-label={t('admin.members.details')}>
                <span>{item.guild?.name ?? t('admin.common.unknownGuild')}</span>
                <span>{formatMembershipStatus(item.membership_status)}</span>
                <span>{formatApprovalStatus(item.profile?.approval_status)}</span>
                <span>{t('admin.common.updated')} {formatDate(item.profile?.updated_at ?? item.updated_at)}</span>
              </div>

              {hasManagementControls ? (
                <details className="member-manage-details">
                  <summary>{t('admin.members.manage')}</summary>
                  <div className="member-manage-body">
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
                            <button
                              type="button"
                              className="primary-action"
                              onClick={() => onSaveIgn(item)}
                              disabled={actionDisabled}
                            >
                              {isEditingIgn ? t('admin.members.savingIgn') : t('admin.members.saveIgn')}
                            </button>
                          </div>
                        ) : null}

                        {canResetSlug ? (
                          <div className="member-edit-block">
                            <label>
                              {t('admin.members.username')}
                              <input
                                type="text"
                                value={draft.slug}
                                onChange={(event) => onUpdateDraft(item.id, 'slug', event.target.value)}
                                disabled={actionDisabled}
                              />
                            </label>
                            <button
                              type="button"
                              className="danger-action"
                              onClick={() => onResetSlug(item)}
                              disabled={actionDisabled}
                            >
                              {isResettingSlug ? t('admin.members.resettingUsername') : t('admin.members.resetUsername')}
                            </button>
                          </div>
                        ) : null}
                      </div>
                    ) : null}

                    {canManageRosterStatuses ? (
                      <div className="member-admin-actions compact-admin-actions">
                        <div className="member-edit-block roster-status-control compact-control-block">
                          <div>
                            <h4>{t('admin.common.rosterStatus')}</h4>
                          </div>

                          {rosterStatusCanBeChanged ? (
                            <>
                              <label>
                                {t('admin.members.newStatus')}
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
                                {t('admin.members.reason')}
                                <textarea
                                  value={rosterReason}
                                  maxLength={1000}
                                  placeholder={
                                    rosterStatusRequiresReason
                                      ? t('admin.members.requiredReason')
                                      : t('admin.members.optionalPrivateNote')
                                  }
                                  onChange={(event) => onUpdateDraft(item.id, 'statusReason', event.target.value)}
                                  disabled={actionDisabled}
                                />
                              </label>

                              {rosterStatusRequiresReason && !rosterReason.trim() ? (
                                <p className="member-warning">{t('admin.members.hardBlockReason')}</p>
                              ) : null}

                              {isConfirmingRosterStatus ? (
                                <p className="member-warning">
                                  {t('admin.members.confirmStatusChange', {
                                    from: formatRosterStatus(currentRosterStatus),
                                    to: formatRosterStatus(rosterStatusSelectValue),
                                  })}
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
                                      {isUpdatingRosterStatus ? t('admin.members.savingStatus') : t('admin.members.confirmStatus')}
                                    </button>
                                    <button
                                      type="button"
                                      className="secondary-action"
                                      onClick={() => onSetConfirmAction(null)}
                                      disabled={actionDisabled}
                                    >
                                      {t('common.cancel')}
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
                                    {rosterStatusRequiresReason
                                      ? t('admin.members.reviewStatusChange')
                                      : t('admin.members.saveStatus')}
                                  </button>
                                )}
                              </div>
                            </>
                          ) : (
                            <p className="muted-line compact-state-line">{t('admin.members.statusLocked')}</p>
                          )}
                        </div>
                      </div>
                    ) : null}

                    {canManageRoles || canTransferGuilds ? (
                      <div className="member-admin-actions compact-admin-actions">
                        {canManageRoles ? (
                          <div className="member-edit-block compact-control-block">
                            <div>
                              <h4>{t('admin.members.roleManagement')}</h4>
                              <p className="muted-copy">{t('admin.members.ownerChangesLocked')}</p>
                            </div>

                            {item.role === 'owner' ? (
                              <p className="muted-line compact-state-line">{t('admin.members.ownerRoleLocked')}</p>
                            ) : (
                              <>
                                <label>
                                  {t('admin.members.newRole')}
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
                                    {t('admin.members.confirmRoleChange', {
                                      from: formatRole(item.role),
                                      to: formatRole(roleSelectValue),
                                    })}
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
                                        {isAssigningRole ? t('admin.members.savingRole') : t('admin.members.confirmRole')}
                                      </button>
                                      <button
                                        type="button"
                                        className="secondary-action"
                                        onClick={() => onSetConfirmAction(null)}
                                        disabled={actionDisabled}
                                      >
                                        {t('common.cancel')}
                                      </button>
                                    </>
                                  ) : (
                                    <button
                                      type="button"
                                      className="primary-action"
                                      onClick={() => onSetConfirmAction({ id: item.id, type: 'assign-role' })}
                                      disabled={actionDisabled || !roleCanBeChanged || roleSelectValue === item.role}
                                    >
                                      {t('admin.members.reviewRoleChange')}
                                    </button>
                                  )}
                                </div>
                              </>
                            )}
                          </div>
                        ) : null}

                        {canTransferGuilds ? (
                          <div className="member-edit-block compact-control-block">
                            <div>
                              <h4>{t('admin.members.guildTransfer')}</h4>
                              <p className="muted-copy">{t('admin.members.transferResetsRole')}</p>
                            </div>

                            <label>
                              {t('admin.members.targetGuild')}
                              <select
                                value={draft.targetGuildId}
                                onChange={(event) => onUpdateDraft(item.id, 'targetGuildId', event.target.value)}
                                disabled={actionDisabled || transferGuildOptions.length === 0}
                              >
                                <option value="">{t('admin.members.selectActiveGuild')}</option>
                                {transferGuildOptions.map((guild) => (
                                  <option key={guild.id} value={guild.id}>
                                    {guild.name}
                                  </option>
                                ))}
                              </select>
                            </label>

                            <p className="member-warning">{t('admin.members.transferWarning')}</p>

                            {isConfirmingTransfer ? (
                              <p className="muted-line">
                                {t('admin.members.confirmTransfer', {
                                  from: item.guild?.name ?? t('admin.common.currentGuild'),
                                  to: selectedTargetGuild?.name ?? t('admin.common.selectedGuildLower'),
                                })}
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
                                    {isTransferringGuild
                                      ? t('admin.members.transferring')
                                      : t('admin.members.confirmTransferAction')}
                                  </button>
                                  <button
                                    type="button"
                                    className="secondary-action"
                                    onClick={() => onSetConfirmAction(null)}
                                    disabled={actionDisabled}
                                  >
                                    {t('common.cancel')}
                                  </button>
                                </>
                              ) : (
                                <button
                                  type="button"
                                  className="danger-action"
                                  onClick={() => onSetConfirmAction({ id: item.id, type: 'transfer-guild' })}
                                  disabled={actionDisabled || !draft.targetGuildId || draft.targetGuildId === item.guild_id}
                                >
                                  {t('admin.members.reviewTransfer')}
                                </button>
                              )}
                            </div>
                          </div>
                        ) : null}
                      </div>
                    ) : null}
                  </div>
                </details>
              ) : null}
            </article>
          );
        })}
      </div>
    </section>
  );
}
