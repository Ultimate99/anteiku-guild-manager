import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

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
}) {
  return (
    <section className="audit-management" aria-label="Audit logs">
      <div className="panel audit-management-tools">
        <div className="section-heading-row">
          <div>
            <StatusBadge tone="warning">Audit</StatusBadge>
            <h3>Audit logs</h3>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={onRefresh} disabled={auditLoading}>
            {auditLoading ? 'Loading...' : 'Refresh'}
          </button>
        </div>

        <div className="audit-filter-grid">
          <label>
            Action
            <select
              value={auditFilters.action}
              onChange={(event) => onUpdateFilter('action', event.target.value)}
              disabled={auditLoading}
            >
              {auditActionOptions.map((actionOption) => (
                <option key={actionOption.value} value={actionOption.value}>
                  {actionOption.label}
                </option>
              ))}
            </select>
          </label>

          {auditGuildOptions.length > 0 ? (
            <label>
              Guild
              <select
                value={auditFilters.guildId}
                onChange={(event) => onUpdateFilter('guildId', event.target.value)}
                disabled={auditLoading || auditGuildOptions.length <= 1}
              >
                <option value="all">{membership?.role === 'owner' ? 'All/global logs' : 'All allowed logs'}</option>
                {auditGuildOptions.map((guildOption) => (
                  <option key={guildOption.id} value={guildOption.id}>
                    {guildOption.name}
                  </option>
                ))}
              </select>
            </label>
          ) : null}

          <label>
            Date from
            <input
              type="date"
              value={auditFilters.dateFrom}
              onChange={(event) => onUpdateFilter('dateFrom', event.target.value)}
              disabled={auditLoading}
            />
          </label>

          <label>
            Date to
            <input
              type="date"
              value={auditFilters.dateTo}
              onChange={(event) => onUpdateFilter('dateTo', event.target.value)}
              disabled={auditLoading}
            />
          </label>

          <label>
            Limit
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

      {auditLoading && auditLogs.length === 0 ? <p className="muted-line">Loading audit logs...</p> : null}

      {auditNotAuthorized ? (
        <section className="panel hero-panel audit-access-panel">
          <StatusBadge tone="danger">Restricted</StatusBadge>
          <h3>Not authorized to view audit logs.</h3>
          <p>The backend rejected this audit log request.</p>
        </section>
      ) : null}

      {auditError ? <p className="error-line">{auditError}</p> : null}

      {!auditLoading && !auditError && !auditNotAuthorized && auditLogs.length === 0 ? (
        <section className="panel hero-panel">
          <StatusBadge>Empty</StatusBadge>
          <h3>No audit logs found</h3>
          <p>Try another action, guild, date range, or limit.</p>
        </section>
      ) : null}

      <div className="audit-card-list">
        {auditLogs.map((row) => {
          const metadataItems = formatAuditMetadata(row.metadata, row.metadata_redacted);
          const targetDisplay = formatAuditTarget(row);
          const entityDisplay = formatAuditEntity(row);

          return (
            <article className="panel audit-card" key={row.id}>
              <div className="approval-card-header">
                <div>
                  <h4>{formatAuditAction(row.action)}</h4>
                  <p>{row.action}</p>
                </div>
                <StatusBadge tone={row.metadata_redacted ? 'warning' : 'success'}>Read-only</StatusBadge>
              </div>

              <div className="approval-meta audit-meta" aria-label="Audit log details">
                <div>
                  <span>Timestamp</span>
                  <strong>{formatDate(row.created_at)}</strong>
                </div>
                <div>
                  <span>Actor</span>
                  <strong>{formatAuditActor(row)}</strong>
                </div>
                {targetDisplay ? (
                  <div>
                    <span>Target</span>
                    <strong>{targetDisplay}</strong>
                  </div>
                ) : null}
                <div>
                  <span>Guild</span>
                  <strong>{formatAuditGuild(row)}</strong>
                </div>
                {entityDisplay ? (
                  <div>
                    <span>Entity</span>
                    <strong>{entityDisplay}</strong>
                  </div>
                ) : null}
              </div>

              {row.metadata_redacted ? <p className="member-warning">Sensitive CP metadata hidden.</p> : null}

              {metadataItems.length > 0 ? (
                <div className="audit-metadata-list" aria-label="Audit metadata summary">
                  {metadataItems.map((item) => (
                    <div key={item.key}>
                      <span>{item.label}</span>
                      <strong>{item.value}</strong>
                    </div>
                  ))}
                </div>
              ) : row.metadata_redacted ? null : (
                <p className="muted-line">No displayable metadata.</p>
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
            {auditLoading ? 'Loading older...' : 'Load older'}
          </button>
        </div>
      ) : null}
    </section>
  );
}
