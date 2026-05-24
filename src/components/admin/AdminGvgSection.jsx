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
}) {
  return (
    <section className="gvg-management admin-section" aria-label="GvG management">
      <div className="panel gvg-management-tools admin-section-tools">
        <div className="section-heading-row admin-section-heading">
          <div>
            <StatusBadge tone="success">GvG</StatusBadge>
            <h3>Events</h3>
          </div>
          <button
            type="button"
            className="secondary-action compact-action"
            onClick={onRefresh}
            disabled={gvgLoading || Boolean(activeAction)}
          >
            {gvgLoading ? 'Loading...' : 'Refresh'}
          </button>
        </div>

      </div>

      <section className="panel gvg-create-panel compact-admin-card" aria-label="Create GvG event">
        <StatusBadge tone="warning">Create event</StatusBadge>
        <h3>Create event</h3>
        <label>
          Event title
          <input
            type="text"
            value={gvgDraft.title}
            placeholder="GvG readiness check"
            onChange={(event) => onUpdateDraft('title', event.target.value)}
            disabled={gvgLoading || Boolean(activeAction)}
          />
        </label>

        {membership?.role === 'owner' ? (
          <label>
            Scope
            <select
              value={gvgDraft.scope}
              onChange={(event) => onUpdateDraft('scope', event.target.value)}
              disabled={gvgLoading || Boolean(activeAction)}
            >
              <option value="guild">Guild</option>
              <option value="global">Global</option>
            </select>
          </label>
        ) : null}

        {gvgDraft.scope === 'guild' || membership?.role !== 'owner' ? (
          <label>
            Guild
            <select
              value={gvgDraft.guildId}
              onChange={(event) => onUpdateDraft('guildId', event.target.value)}
              disabled={gvgLoading || Boolean(activeAction) || gvgGuildOptions.length <= 1}
            >
              {gvgGuildOptions.length === 0 ? <option value="">No guild scope</option> : null}
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
            Starts
            <input
              type="datetime-local"
              value={gvgDraft.startsAt}
              onChange={(event) => onUpdateDraft('startsAt', event.target.value)}
              disabled={gvgLoading || Boolean(activeAction)}
            />
          </label>
          <label>
            Ends
            <input
              type="datetime-local"
              value={gvgDraft.endsAt}
              onChange={(event) => onUpdateDraft('endsAt', event.target.value)}
              disabled={gvgLoading || Boolean(activeAction)}
            />
          </label>
        </div>

        <button type="button" className="primary-action" onClick={onCreateEvent} disabled={gvgLoading || Boolean(activeAction)}>
          {activeAction?.type === 'gvg-create' ? 'Creating...' : 'Create draft event'}
        </button>
      </section>

      {gvgLoading ? <p className="muted-line">Loading GvG events...</p> : null}

      {!gvgLoading && gvgEvents.length === 0 ? (
        <section className="panel compact-empty-state">
          <StatusBadge>Empty</StatusBadge>
          <h3>No GvG events.</h3>
        </section>
      ) : null}

      {gvgEvents.length > 0 ? (
        <section className="panel gvg-results-panel compact-admin-card" aria-label="GvG results">
          <div className="section-heading-row admin-section-heading">
            <div>
              <StatusBadge tone="success">Results</StatusBadge>
              <h3>Results</h3>
            </div>
          </div>
          <label>
            Event
            <select
              value={selectedGvgEventId}
              onChange={(event) => onSelectEvent(event.target.value)}
              disabled={gvgLoading || Boolean(activeAction)}
            >
              {gvgEvents.map((event) => (
                <option key={event.id} value={event.id}>
                  {event.title} - {event.status}
                </option>
              ))}
            </select>
          </label>

          {selectedGvgEvent ? (
            <>
              <div className="approval-meta compact-meta" aria-label="Selected GvG event details">
                <div>
                  <span>Status</span>
                  <strong>{selectedGvgEvent.status}</strong>
                </div>
                <div>
                  <span>Scope</span>
                  <strong>
                    {selectedGvgEvent.scope === 'global' ? 'Global' : selectedGvgEvent.guild?.name ?? 'Guild'}
                  </strong>
                </div>
                <div>
                  <span>Starts</span>
                  <strong>{formatDate(selectedGvgEvent.starts_at)}</strong>
                </div>
                <div>
                  <span>Updated</span>
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
                    ? 'Opening...'
                    : 'Open voting'}
                </button>
                <button
                  type="button"
                  className="danger-action"
                  onClick={() => onSetStatus(selectedGvgEvent.id, 'closed')}
                  disabled={Boolean(activeAction) || selectedGvgEvent.status === 'closed'}
                >
                  {activeAction?.id === selectedGvgEvent.id && activeAction?.type === 'gvg-closed'
                    ? 'Closing...'
                    : 'Close voting'}
                </button>
              </div>

              <div className="gvg-summary-grid">
                <article>
                  <span>Present</span>
                  <strong>{gvgSummary.present.length}</strong>
                </article>
                <article>
                  <span>Absent</span>
                  <strong>{gvgSummary.absent.length}</strong>
                </article>
              </div>

              <div className="gvg-results-grid">
                <section>
                  <h4>Present</h4>
                  {gvgSummary.present.length === 0 ? (
                    <p className="muted-line">No present votes yet.</p>
                  ) : (
                    gvgSummary.present.map((vote) => (
                      <article className="gvg-vote-row" key={vote.profile_id}>
                        <strong>{vote.ign ?? 'Unknown IGN'}</strong>
                        <span>@{vote.username ?? 'unknown'}</span>
                      </article>
                    ))
                  )}
                </section>

                <section>
                  <h4>Absence log</h4>
                  {gvgSummary.absent.length === 0 ? (
                    <p className="muted-line">No absent votes yet.</p>
                  ) : (
                    gvgSummary.absent.map((vote) => (
                      <article className="gvg-vote-row" key={vote.profile_id}>
                        <strong>{vote.ign ?? 'Unknown IGN'}</strong>
                        <span>@{vote.username ?? 'unknown'}</span>
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
