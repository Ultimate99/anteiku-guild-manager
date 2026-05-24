import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

function humanizePermissionCopy(value) {
  return String(value ?? '')
    .replaceAll('Profile slug', 'Username')
    .replaceAll('profile slug', 'username')
    .replaceAll('Username/Username', 'Username')
    .replaceAll('username/username', 'username')
    .replaceAll('reset_profile_slug', 'reset username');
}

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
}) {
  return (
    <section className="permission-management admin-section" aria-label="Admin permission management">
      <div className="panel permission-management-tools admin-section-tools">
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="warning">Permissions</StatusBadge>
            <h3>Admin permissions</h3>
          </div>
          <button
            type="button"
            className="secondary-action compact-action"
            onClick={onRefresh}
            disabled={adminPermissionLoading || Boolean(activeAction)}
          >
            {adminPermissionLoading ? 'Loading...' : 'Refresh'}
          </button>
        </div>
      </div>

      {adminPermissionLoading ? <p className="muted-line">Loading Admin permission targets...</p> : null}

      {!adminPermissionLoading && adminPermissionTargets.length === 0 ? (
        <section className="panel compact-empty-state">
          <StatusBadge>Empty</StatusBadge>
          <h3>No admin targets.</h3>
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
                  <h4>{target.profile?.ign ?? 'Unknown IGN'}</h4>
                  <p>@{target.profile?.username ?? 'unknown'}</p>
                </div>
                <StatusBadge tone="success">Admin</StatusBadge>
              </div>

              <div className="approval-meta compact-meta" aria-label="Admin permission target details">
                <div>
                  <span>Guild</span>
                  <strong>{target.guild?.name ?? 'Unknown guild'}</strong>
                </div>
                <div>
                  <span>Membership</span>
                  <strong>{target.membership_status}</strong>
                </div>
                <div>
                  <span>Profile status</span>
                  <strong>{target.profile?.approval_status ?? 'unknown'}</strong>
                </div>
              </div>

              {cpPermissionLocked ? <p className="member-warning">CP permissions are Owner-only.</p> : null}

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
                          {humanizePermissionCopy(permission.label ?? permission.key)}
                          {sensitive ? <em>Sensitive</em> : null}
                        </span>
                      </span>
                      <small>
                        {cpPermission && !canToggle
                          ? 'CP permissions are Owner-only.'
                          : humanizePermissionCopy(permission.description ?? permission.key)}
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
                  {isSavingPermissions ? 'Saving permissions...' : 'Save permissions'}
                </button>
                <button
                  type="button"
                  className="secondary-action"
                  onClick={() => onResetDraft(target)}
                  disabled={actionDisabled || !hasChanges}
                >
                  Cancel
                </button>
              </div>
            </article>
          );
        })}
      </div>
    </section>
  );
}
