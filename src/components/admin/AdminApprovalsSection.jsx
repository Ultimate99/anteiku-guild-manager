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
  formatMembershipStatus,
  formatApprovalStatus,
  statusTone,
  t,
}) {
  return (
    <section className="approval-list admin-section" aria-label={t('admin.approvals.aria')}>
      <div className="section-heading-row admin-section-heading">
        <div>
          <StatusBadge tone="warning">{t('admin.common.registration')}</StatusBadge>
          <h3>{t('admin.approvals.title')}</h3>
        </div>
        <button type="button" className="secondary-action compact-action" onClick={onRefresh} disabled={approvalLoading}>
          {approvalLoading ? t('common.loading') : t('common.refresh')}
        </button>
      </div>

      {approvalLoading ? <p className="muted-line">{t('admin.approvals.loading')}</p> : null}

      {!approvalLoading && queue.length === 0 ? (
        <section className="panel compact-empty-state">
          <StatusBadge>{t('admin.common.clear')}</StatusBadge>
          <h3>{t('admin.approvals.empty')}</h3>
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
                <h4>{item.profile?.ign ?? t('admin.common.unknownIgn')}</h4>
                <p>@{item.profile?.username ?? t('common.unknown')}</p>
              </div>
              <StatusBadge tone={statusTone(item.membership_status)}>
                {formatMembershipStatus(item.membership_status)}
              </StatusBadge>
            </div>

            <div className="approval-meta compact-meta" aria-label={t('admin.approvals.details')}>
              <div>
                <span>{t('admin.common.guild')}</span>
                <strong>{item.guild?.name ?? t('admin.common.unknownGuild')}</strong>
              </div>
              <div>
                <span>{t('admin.common.profileStatus')}</span>
                <strong>{formatApprovalStatus(item.profile?.approval_status)}</strong>
              </div>
              <div>
                <span>{t('admin.common.requested')}</span>
                <strong>{formatDate(item.created_at)}</strong>
              </div>
              {item.profile?.reapply_requested_at ? (
                <div>
                  <span>{t('admin.approvals.reapplyRequested')}</span>
                  <strong>{formatDate(item.profile.reapply_requested_at)}</strong>
                </div>
              ) : null}
            </div>

            {item.profile?.reapply_note ? <p className="muted-line">{item.profile.reapply_note}</p> : null}

            <label>
              {t('admin.approvals.approveAs')}
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
                {isApproving ? t('admin.approvals.approving') : t('admin.approvals.approve')}
              </button>
              <button type="button" className="danger-action" onClick={() => onReject(item)} disabled={actionDisabled}>
                {isRejecting ? t('admin.approvals.rejecting') : t('admin.approvals.reject')}
              </button>
            </div>

            <label>
              {t('admin.approvals.rejectionReason')}
              <textarea
                value={rejectReasons[item.id] ?? ''}
                maxLength={1000}
                placeholder={t('admin.approvals.optionalNote')}
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
