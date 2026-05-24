import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

export function AdminPermissionsSection({
  membership,
  adminPermissionLoading,
  permissionCatalog,
  adminPermissionTargets,
  adminPermissionDrafts,
  activeAction,
  onRefresh,
  onUpdateDraft,
  onSavePermissions,
  onResetDraft,
  canToggleAdminPermission,
  isSensitivePermissionKey,
  isCpPermissionKey,
  hasPermissionDraftChanges,
  formatPermissionLabel,
  formatPermissionDescription,
  formatMembershipStatus,
  formatApprovalStatus,
  t,
}) {
  return (
    <section className="permission-management admin-section" aria-label={t('admin.permissions.aria')}>
      <div className="panel permission-management-tools admin-section-tools">
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="warning">{t('admin.common.permissions')}</StatusBadge>
            <h3>{t('admin.permissions.title')}</h3>
          </div>
          <button
            type="button"
            className="secondary-action compact-action"
            onClick={onRefresh}
            disabled={adminPermissionLoading || Boolean(activeAction)}
          >
            {adminPermissionLoading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>
      </div>

      {adminPermissionLoading ? <p className="muted-line">{t('admin.permissions.loading')}</p> : null}

      {!adminPermissionLoading && adminPermissionTargets.length === 0 ? (
        <section className="panel compact-empty-state">
          <StatusBadge>{t('admin.common.empty')}</StatusBadge>
          <h3>{t('admin.permissions.empty')}</h3>
        </section>
      ) : null}

      <div className="permission-card-list">
        {adminPermissionTargets.map((target) => {
          const draft = adminPermissionDrafts[target.id] ?? {};
          const actionDisabled = Boolean(activeAction);
          const isSavingPermissions = activeAction?.id === target.id && activeAction.type === 'save-permissions';
          const hasChanges = hasPermissionDraftChanges({
            catalog: permissionCatalog,
            target,
            draft,
            membership,
          });
          const cpPermissionLocked = ['leader', 'vice'].includes(membership?.role);

          return (
            <article className="panel permission-card compact-admin-card" key={target.id}>
              <div className="approval-card-header">
                <div>
                  <h4>{target.profile?.ign ?? t('admin.common.unknownIgn')}</h4>
                  <p>@{target.profile?.username ?? t('common.unknown')}</p>
                </div>
                <StatusBadge tone="success">{t('roles.admin')}</StatusBadge>
              </div>

              <div className="approval-meta compact-meta" aria-label={t('admin.permissions.targetDetails')}>
                <div>
                  <span>{t('admin.common.guild')}</span>
                  <strong>{target.guild?.name ?? t('admin.common.unknownGuild')}</strong>
                </div>
                <div>
                  <span>{t('admin.common.membership')}</span>
                  <strong>{formatMembershipStatus(target.membership_status)}</strong>
                </div>
                <div>
                  <span>{t('admin.common.profileStatus')}</span>
                  <strong>{formatApprovalStatus(target.profile?.approval_status)}</strong>
                </div>
              </div>

              {cpPermissionLocked ? <p className="member-warning">{t('admin.permissions.cpOwnerOnly')}</p> : null}

              <div className="permission-checkbox-grid">
                {permissionCatalog.map((permission) => {
                  const canToggle = canToggleAdminPermission({
                    membership,
                    permissionKey: permission.key,
                  });
                  const checked = Boolean(draft[permission.key]);
                  const sensitive = isSensitivePermissionKey(permission.key);
                  const cpPermission = isCpPermissionKey(permission.key);

                  return (
                    <label className="permission-checkbox" key={permission.key}>
                      <span className="permission-checkbox-control">
                        <input
                          type="checkbox"
                          checked={checked}
                          onChange={(event) => onUpdateDraft(target.id, permission.key, event.target.checked)}
                          disabled={actionDisabled || !canToggle}
                        />
                      <span>
                          {formatPermissionLabel(permission)}
                          {sensitive ? <em>{t('admin.permissions.sensitive')}</em> : null}
                        </span>
                      </span>
                      <small>
                        {cpPermission && !canToggle
                          ? t('admin.permissions.cpOwnerOnly')
                          : formatPermissionDescription(permission)}
                      </small>
                    </label>
                  );
                })}
              </div>

              <div className="member-action-row">
                <button
                  type="button"
                  className="primary-action"
                  onClick={() => onSavePermissions(target)}
                  disabled={actionDisabled || !hasChanges}
                >
                  {isSavingPermissions ? t('admin.permissions.savingPermissions') : t('admin.permissions.savePermissions')}
                </button>
                <button
                  type="button"
                  className="secondary-action"
                  onClick={() => onResetDraft(target)}
                  disabled={actionDisabled || !hasChanges}
                >
                  {t('common.cancel')}
                </button>
              </div>
            </article>
          );
        })}
      </div>
    </section>
  );
}
