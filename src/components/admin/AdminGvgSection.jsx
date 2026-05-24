import React from 'react';
import { StatusBadge } from '../StatusBadge.jsx';

export function AdminGvgSection({
  membership,
  gvgLoading,
  gvgEvents,
  gvgSummary,
  gvgGuildOptions,
  selectedGvgEventId,
  selectedGvgEvent,
  gvgDraft,
  activeAction,
  onRefresh,
  onUpdateDraft,
  onCreateEvent,
  onSetStatus,
  onSelectEvent,
  formatDate,
  formatGvgStatus,
  t,
}) {
  return (
    <section className="gvg-management admin-section" aria-label={t('admin.gvg.aria')}>
      <div className="panel gvg-management-tools admin-section-tools">
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="success">GvG</StatusBadge>
            <h3>{t('admin.gvg.title')}</h3>
          </div>
          <button
            type="button"
            className="secondary-action compact-action"
            onClick={onRefresh}
            disabled={gvgLoading || Boolean(activeAction)}
          >
            {gvgLoading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>

      </div>

      <section className="panel gvg-create-panel compact-admin-card" aria-label={t('admin.gvg.createAria')}>
        <StatusBadge tone="warning">{t('admin.gvg.createBadge')}</StatusBadge>
        <h3>{t('admin.gvg.createEvent')}</h3>
        <label>
          {t('admin.gvg.eventTitle')}
          <input
            type="text"
            value={gvgDraft.title}
            placeholder={t('admin.gvg.titlePlaceholder')}
            onChange={(event) => onUpdateDraft('title', event.target.value)}
            disabled={gvgLoading || Boolean(activeAction)}
          />
        </label>

        {membership?.role === 'owner' ? (
          <label>
            {t('admin.common.scope')}
            <select
              value={gvgDraft.scope}
              onChange={(event) => onUpdateDraft('scope', event.target.value)}
              disabled={gvgLoading || Boolean(activeAction)}
            >
              <option value="guild">{t('admin.common.guildScope')}</option>
              <option value="global">{t('admin.common.global')}</option>
            </select>
          </label>
        ) : null}

        {gvgDraft.scope === 'guild' || membership?.role !== 'owner' ? (
          <label>
            {t('admin.common.guild')}
            <select
              value={gvgDraft.guildId}
              onChange={(event) => onUpdateDraft('guildId', event.target.value)}
              disabled={gvgLoading || Boolean(activeAction) || gvgGuildOptions.length <= 1}
            >
              {gvgGuildOptions.length === 0 ? <option value="">{t('admin.common.noGuildScope')}</option> : null}
              {gvgGuildOptions.map((guild) => (
                <option key={guild.id} value={guild.id}>
                  {guild.name}
                </option>
              ))}
            </select>
          </label>
        ) : null}

        <div className="gvg-date-grid">
          <label>
            {t('admin.common.starts')}
            <input
              type="datetime-local"
              value={gvgDraft.startsAt}
              onChange={(event) => onUpdateDraft('startsAt', event.target.value)}
              disabled={gvgLoading || Boolean(activeAction)}
            />
          </label>
          <label>
            {t('admin.common.ends')}
            <input
              type="datetime-local"
              value={gvgDraft.endsAt}
              onChange={(event) => onUpdateDraft('endsAt', event.target.value)}
              disabled={gvgLoading || Boolean(activeAction)}
            />
          </label>
        </div>

        <button type="button" className="primary-action" onClick={onCreateEvent} disabled={gvgLoading || Boolean(activeAction)}>
          {activeAction?.type === 'gvg-create' ? t('admin.gvg.creating') : t('admin.gvg.createDraft')}
        </button>
      </section>

      {gvgLoading ? <p className="muted-line">{t('admin.gvg.loading')}</p> : null}

      {!gvgLoading && gvgEvents.length === 0 ? (
        <section className="panel compact-empty-state">
          <StatusBadge>{t('admin.common.empty')}</StatusBadge>
          <h3>{t('admin.gvg.empty')}</h3>
        </section>
      ) : null}

      {gvgEvents.length > 0 ? (
        <section className="panel gvg-results-panel compact-admin-card" aria-label={t('admin.gvg.resultsAria')}>
          <div className="section-heading-row admin-section-heading">
            <div>
              <StatusBadge tone="success">{t('admin.gvg.results')}</StatusBadge>
              <h3>{t('admin.gvg.results')}</h3>
            </div>
          </div>
          <label>
            {t('admin.common.event')}
            <select
              value={selectedGvgEventId}
              onChange={(event) => onSelectEvent(event.target.value)}
              disabled={gvgLoading || Boolean(activeAction)}
            >
              {gvgEvents.map((event) => (
                <option key={event.id} value={event.id}>
                  {event.title} - {formatGvgStatus(event.status)}
                </option>
              ))}
            </select>
          </label>

          {selectedGvgEvent ? (
            <>
              <div className="approval-meta compact-meta" aria-label={t('admin.gvg.eventDetails')}>
                <div>
                  <span>{t('admin.common.status')}</span>
                  <strong>{formatGvgStatus(selectedGvgEvent.status)}</strong>
                </div>
                <div>
                  <span>{t('admin.common.scope')}</span>
                  <strong>
                    {selectedGvgEvent.scope === 'global'
                      ? t('admin.common.global')
                      : selectedGvgEvent.guild?.name ?? t('admin.common.guildScope')}
                  </strong>
                </div>
                <div>
                  <span>{t('admin.common.starts')}</span>
                  <strong>{formatDate(selectedGvgEvent.starts_at)}</strong>
                </div>
                <div>
                  <span>{t('admin.common.updated')}</span>
                  <strong>{formatDate(selectedGvgEvent.updated_at)}</strong>
                </div>
              </div>

              <div className="member-action-row">
                <button
                  type="button"
                  className="primary-action"
                  onClick={() => onSetStatus(selectedGvgEvent.id, 'active')}
                  disabled={Boolean(activeAction) || selectedGvgEvent.status === 'active'}
                >
                  {activeAction?.id === selectedGvgEvent.id && activeAction?.type === 'gvg-active'
                    ? t('admin.gvg.opening')
                    : t('admin.gvg.openVoting')}
                </button>
                <button
                  type="button"
                  className="danger-action"
                  onClick={() => onSetStatus(selectedGvgEvent.id, 'closed')}
                  disabled={Boolean(activeAction) || selectedGvgEvent.status === 'closed'}
                >
                  {activeAction?.id === selectedGvgEvent.id && activeAction?.type === 'gvg-closed'
                    ? t('admin.gvg.closing')
                    : t('admin.gvg.closeVoting')}
                </button>
              </div>

              <div className="gvg-summary-grid">
                <article>
                  <span>{t('admin.gvg.present')}</span>
                  <strong>{gvgSummary.present.length}</strong>
                </article>
                <article>
                  <span>{t('admin.gvg.absent')}</span>
                  <strong>{gvgSummary.absent.length}</strong>
                </article>
              </div>

              <div className="gvg-results-grid">
                <section>
                  <h4>{t('admin.gvg.present')}</h4>
                  {gvgSummary.present.length === 0 ? (
                    <p className="muted-line">{t('admin.gvg.noPresent')}</p>
                  ) : (
                    gvgSummary.present.map((vote) => (
                      <article className="gvg-vote-row" key={vote.profile_id}>
                        <strong>{vote.ign ?? t('admin.common.unknownIgn')}</strong>
                        <span>@{vote.username ?? t('common.unknown')}</span>
                      </article>
                    ))
                  )}
                </section>

                <section>
                  <h4>{t('admin.gvg.absenceLog')}</h4>
                  {gvgSummary.absent.length === 0 ? (
                    <p className="muted-line">{t('admin.gvg.noAbsent')}</p>
                  ) : (
                    gvgSummary.absent.map((vote) => (
                      <article className="gvg-vote-row" key={vote.profile_id}>
                        <strong>{vote.ign ?? t('admin.common.unknownIgn')}</strong>
                        <span>@{vote.username ?? t('common.unknown')}</span>
                        {vote.absence_reason ? <p>{vote.absence_reason}</p> : null}
                      </article>
                    ))
                  )}
                </section>
              </div>
            </>
          ) : null}
        </section>
      ) : null}
    </section>
  );
}
