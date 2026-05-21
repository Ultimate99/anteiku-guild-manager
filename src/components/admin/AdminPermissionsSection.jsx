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
}) {
  return (
    <section className="permission-management" aria-label="Admin permission management">
      <div className="panel permission-management-tools">
        <div className="section-heading-row">
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

        <p className="muted-line">
          Permission checkboxes apply only to active Admin memberships. CP permissions are Owner-only.
        </p>
      </div>

      {adminPermissionLoading ? <p className="muted-line">Loading Admin permission targets...</p> : null}

      {!adminPermissionLoading && adminPermissionTargets.length === 0 ? (
        <section className="panel hero-panel">
          <StatusBadge>Empty</StatusBadge>
          <h3>No active Admin memberships found</h3>
          <p>Only approved active Admin memberships in your allowed scope appear here.</p>
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
            <article className="panel permission-card" key={target.id}>
              <div className="approval-card-header">
                <div>
                  <h4>{target.profile?.ign ?? 'Unknown IGN'}</h4>
                  <p>@{target.profile?.username ?? 'unknown'}</p>
                </div>
                <StatusBadge tone="success">Admin</StatusBadge>
              </div>

              <div className="approval-meta" aria-label="Admin permission target details">
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
                          {permission.label ?? permission.key}
                          {sensitive ? <em>Sensitive</em> : null}
                        </span>
                      </span>
                      <small>
                        {cpPermission && !canToggle
                          ? 'CP permissions are Owner-only.'
                          : permission.description ?? permission.key}
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
