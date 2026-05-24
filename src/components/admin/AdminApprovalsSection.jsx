import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

export function AdminApprovalsSection({
  queue,
  allowedRoles,
  selectedRoles,
  rejectReasons,
  approvalLoading,
  activeAction,
  onRefresh,
  onRoleChange,
  onRejectReasonChange,
  onApprove,
  onReject,
  formatDate,
  formatRole,
  statusTone,
}) {
  return (
    <section className="approval-list admin-section" aria-label="Registration approval queue">
      <div className="section-heading-row admin-section-heading">
        <div>
          <StatusBadge tone="warning">Registration</StatusBadge>
          <h3>Approvals</h3>
        </div>
        <button type="button" className="secondary-action compact-action" onClick={onRefresh} disabled={approvalLoading}>
          {approvalLoading ? 'Loading...' : 'Refresh'}
        </button>
      </div>

      {approvalLoading ? <p className="muted-line">Loading approval queue...</p> : null}

      {!approvalLoading && queue.length === 0 ? (
        <section className="panel compact-empty-state">
          <StatusBadge>Clear</StatusBadge>
          <h3>No pending approvals.</h3>
        </section>
      ) : null}

      {queue.map((item) => {
        const selectedRole = selectedRoles[item.id] ?? allowedRoles[0] ?? 'member';
        const isApproving = activeAction?.id === item.id && activeAction.type === 'approve';
        const isRejecting = activeAction?.id === item.id && activeAction.type === 'reject';
        const actionDisabled = Boolean(activeAction);

        return (
          <article className="panel approval-card compact-admin-card" key={item.id}>
            <div className="approval-card-header">
              <div>
                <h4>{item.profile?.ign ?? 'Unknown IGN'}</h4>
                <p>@{item.profile?.username ?? 'unknown'}</p>
              </div>
              <StatusBadge tone={statusTone(item.membership_status)}>{item.membership_status}</StatusBadge>
            </div>

            <div className="approval-meta compact-meta" aria-label="Approval request details">
              <div>
                <span>Guild</span>
                <strong>{item.guild?.name ?? 'Unknown guild'}</strong>
              </div>
              <div>
                <span>Profile status</span>
                <strong>{item.profile?.approval_status ?? 'unknown'}</strong>
              </div>
              <div>
                <span>Requested</span>
                <strong>{formatDate(item.created_at)}</strong>
              </div>
              {item.profile?.reapply_requested_at ? (
                <div>
                  <span>Reapply requested</span>
                  <strong>{formatDate(item.profile.reapply_requested_at)}</strong>
                </div>
              ) : null}
            </div>

            {item.profile?.reapply_note ? <p className="muted-line">{item.profile.reapply_note}</p> : null}

            <label>
              Approve as
              <select value={selectedRole} onChange={(event) => onRoleChange(item.id, event.target.value)} disabled={actionDisabled}>
                {allowedRoles.map((role) => (
                  <option key={role} value={role}>
                    {formatRole(role)}
                  </option>
                ))}
              </select>
            </label>

            <div className="approval-actions">
              <button type="button" className="primary-action" onClick={() => onApprove(item)} disabled={actionDisabled}>
                {isApproving ? 'Approving...' : 'Approve'}
              </button>
              <button type="button" className="danger-action" onClick={() => onReject(item)} disabled={actionDisabled}>
                {isRejecting ? 'Rejecting...' : 'Reject'}
              </button>
            </div>

            <label>
              Rejection reason
              <textarea
                value={rejectReasons[item.id] ?? ''}
                maxLength={1000}
                placeholder="Optional note"
                onChange={(event) => onRejectReasonChange(item.id, event.target.value)}
                disabled={actionDisabled}
              />
            </label>
          </article>
        );
      })}
    </section>
  );
}
