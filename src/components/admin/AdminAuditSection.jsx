import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

function humanizeAuditLabel(value) {
  return String(value ?? '').replaceAll('Profile slug', 'Username').replaceAll('profile slug', 'username');
}

export function AdminAuditSection({
  membership,
  auditActionOptions,
  auditLoading,
  auditLogs,
  auditFilters,
  auditGuildOptions,
  auditError,
  auditNotAuthorized,
  oldestAuditCreatedAt,
  onRefresh,
  onLoadOlder,
  onUpdateFilter,
  formatDate,
  formatAuditAction,
  formatAuditActor,
  formatAuditMetadata,
  formatAuditTarget,
  formatAuditGuild,
  formatAuditEntity,
  t,
}) {
  return (
    <section className="audit-management admin-section" aria-label={t('admin.audit.aria')}>
      <div className="panel audit-management-tools admin-section-tools">
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="warning">{t('admin.common.audit')}</StatusBadge>
            <h3>{t('admin.audit.title')}</h3>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={onRefresh} disabled={auditLoading}>
            {auditLoading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>

        <div className="audit-filter-grid">
          <label>
            {t('admin.common.action')}
            <select
              value={auditFilters.action}
              onChange={(event) => onUpdateFilter('action', event.target.value)}
              disabled={auditLoading}
            >
              {auditActionOptions.map((actionOption) => (
                <option key={actionOption.value} value={actionOption.value}>
                  {humanizeAuditLabel(actionOption.label)}
                </option>
              ))}
            </select>
          </label>

          {auditGuildOptions.length > 0 ? (
            <label>
              {t('admin.common.guild')}
              <select
                value={auditFilters.guildId}
                onChange={(event) => onUpdateFilter('guildId', event.target.value)}
                disabled={auditLoading || auditGuildOptions.length <= 1}
              >
                <option value="all">
                  {membership?.role === 'owner' ? t('admin.common.allGlobalLogs') : t('admin.common.allAllowedLogs')}
                </option>
                {auditGuildOptions.map((guildOption) => (
                  <option key={guildOption.id} value={guildOption.id}>
                    {guildOption.name}
                  </option>
                ))}
              </select>
            </label>
          ) : null}

          <label>
            {t('admin.common.dateFrom')}
            <input
              type="date"
              value={auditFilters.dateFrom}
              onChange={(event) => onUpdateFilter('dateFrom', event.target.value)}
              disabled={auditLoading}
            />
          </label>

          <label>
            {t('admin.common.dateTo')}
            <input
              type="date"
              value={auditFilters.dateTo}
              onChange={(event) => onUpdateFilter('dateTo', event.target.value)}
              disabled={auditLoading}
            />
          </label>

          <label>
            {t('admin.common.limit')}
            <select
              value={auditFilters.limit}
              onChange={(event) => onUpdateFilter('limit', event.target.value)}
              disabled={auditLoading}
            >
              <option value={25}>25</option>
              <option value={50}>50</option>
              <option value={100}>100</option>
            </select>
          </label>
        </div>
      </div>

      {auditLoading && auditLogs.length === 0 ? <p className="muted-line">{t('admin.audit.loading')}</p> : null}

      {auditNotAuthorized ? (
        <section className="panel compact-empty-state audit-access-panel">
          <StatusBadge tone="danger">{t('admin.common.restricted')}</StatusBadge>
          <h3>{t('admin.audit.accessDenied')}</h3>
        </section>
      ) : null}

      {auditError ? <p className="error-line">{auditError}</p> : null}

      {!auditLoading && !auditError && !auditNotAuthorized && auditLogs.length === 0 ? (
        <section className="panel compact-empty-state">
          <StatusBadge>{t('admin.common.empty')}</StatusBadge>
          <h3>{t('admin.audit.empty')}</h3>
        </section>
      ) : null}

      <div className="audit-card-list">
        {auditLogs.map((row) => {
          const metadataItems = formatAuditMetadata(row.metadata, row.metadata_redacted);
          const targetDisplay = formatAuditTarget(row);
          const entityDisplay = formatAuditEntity(row);

          return (
            <article className="panel audit-card compact-admin-card" key={row.id}>
              <div className="approval-card-header">
                <div>
                  <h4>{humanizeAuditLabel(formatAuditAction(row.action))}</h4>
                  <p>{row.action}</p>
                </div>
                <StatusBadge tone={row.metadata_redacted ? 'warning' : 'success'}>{t('admin.common.readOnly')}</StatusBadge>
              </div>

              <div className="approval-meta compact-meta audit-meta" aria-label={t('admin.audit.details')}>
                <div>
                  <span>{t('admin.common.timestamp')}</span>
                  <strong>{formatDate(row.created_at)}</strong>
                </div>
                <div>
                  <span>{t('admin.common.actor')}</span>
                  <strong>{formatAuditActor(row)}</strong>
                </div>
                {targetDisplay ? (
                  <div>
                    <span>{t('admin.common.target')}</span>
                    <strong>{targetDisplay}</strong>
                  </div>
                ) : null}
                <div>
                  <span>{t('admin.common.guild')}</span>
                  <strong>{formatAuditGuild(row)}</strong>
                </div>
                {entityDisplay ? (
                  <div>
                    <span>{t('admin.common.entity')}</span>
                    <strong>{entityDisplay}</strong>
                  </div>
                ) : null}
              </div>

              {row.metadata_redacted ? <p className="member-warning">{t('admin.audit.sensitiveCpHidden')}</p> : null}

              {metadataItems.length > 0 ? (
                <div className="audit-metadata-list" aria-label={t('admin.audit.metadataSummary')}>
                  {metadataItems.map((item) => (
                    <div key={item.key}>
                      <span>{item.label}</span>
                      <strong>{item.value}</strong>
                    </div>
                  ))}
                </div>
              ) : row.metadata_redacted ? null : (
                <p className="muted-line">{t('admin.audit.noMetadata')}</p>
              )}
            </article>
          );
        })}
      </div>

      {auditLogs.length > 0 ? (
        <div className="audit-load-row">
          <button
            type="button"
            className="secondary-action"
            onClick={onLoadOlder}
            disabled={auditLoading || !oldestAuditCreatedAt}
          >
            {auditLoading ? t('admin.audit.loadingOlder') : t('admin.audit.loadOlder')}
          </button>
        </div>
      ) : null}
    </section>
  );
}
