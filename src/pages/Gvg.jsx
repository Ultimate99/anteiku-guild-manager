import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  loadMemberActiveGvgEvents,
  loadOwnGvgVote,
  submitGvgVote,
} from '../services/gvgService.js';

function formatDate(value) {
  if (!value) {
    return 'Not scheduled';
  }

  return new Intl.DateTimeFormat('en', {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

function formatVoteStatus(status) {
  if (status === 'present') {
    return 'Present';
  }

  if (status === 'absent') {
    return 'Absent';
  }

  return 'Not voted';
}

export function Gvg() {
  const { membership, user } = useAuth();
  const [events, setEvents] = useState([]);
  const [selectedEventId, setSelectedEventId] = useState('');
  const [currentVote, setCurrentVote] = useState(null);
  const [voteStatus, setVoteStatus] = useState('present');
  const [absenceReason, setAbsenceReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  const selectedEvent = useMemo(
    () => events.find((event) => event.id === selectedEventId) ?? null,
    [events, selectedEventId],
  );

  const loadGvgData = useCallback(
    async ({ clearMessage = true } = {}) => {
      setLoading(true);
      setError('');

      if (clearMessage) {
        setMessage('');
      }

      try {
        const nextEvents = await loadMemberActiveGvgEvents({ guildId: membership?.guild_id });
        const nextSelectedEventId =
          nextEvents.find((event) => event.id === selectedEventId)?.id ?? nextEvents[0]?.id ?? '';
        setEvents(nextEvents);
        setSelectedEventId(nextSelectedEventId);

        if (nextSelectedEventId) {
          const nextVote = await loadOwnGvgVote({ eventId: nextSelectedEventId, profileId: user?.id });
          setCurrentVote(nextVote);
          setVoteStatus(nextVote?.vote_status ?? 'present');
          setAbsenceReason(nextVote?.vote_status === 'absent' ? nextVote.absence_reason ?? '' : '');
        } else {
          setCurrentVote(null);
          setVoteStatus('present');
          setAbsenceReason('');
        }
      } catch (gvgError) {
        setEvents([]);
        setSelectedEventId('');
        setCurrentVote(null);
        setError(gvgError.message);
      } finally {
        setLoading(false);
      }
    },
    [membership?.guild_id, selectedEventId, user?.id],
  );

  useEffect(() => {
    loadGvgData();
  }, [loadGvgData]);

  async function handleSelectEvent(eventId) {
    setSelectedEventId(eventId);
    setCurrentVote(null);
    setVoteStatus('present');
    setAbsenceReason('');
    setError('');
    setMessage('');

    if (!eventId) {
      return;
    }

    setLoading(true);

    try {
      const nextVote = await loadOwnGvgVote({ eventId, profileId: user?.id });
      setCurrentVote(nextVote);
      setVoteStatus(nextVote?.vote_status ?? 'present');
      setAbsenceReason(nextVote?.vote_status === 'absent' ? nextVote.absence_reason ?? '' : '');
    } catch (gvgError) {
      setError(gvgError.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleSubmitVote() {
    if (!selectedEventId) {
      setError('No active GvG event is available.');
      return;
    }

    if (voteStatus === 'absent' && absenceReason.length > 500) {
      setError('Absence reason cannot exceed 500 characters.');
      return;
    }

    setSaving(true);
    setError('');
    setMessage('');

    try {
      const savedVote = await submitGvgVote({
        eventId: selectedEventId,
        voteStatus,
        absenceReason,
      });
      setCurrentVote(savedVote);
      setVoteStatus(savedVote.vote_status);
      setAbsenceReason(savedVote.vote_status === 'absent' ? savedVote.absence_reason ?? '' : '');
      setMessage(`Vote saved as ${formatVoteStatus(savedVote.vote_status)}.`);
      await loadGvgData({ clearMessage: false });
    } catch (gvgError) {
      setError(gvgError.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="stack">
      <section className="panel hero-panel">
        <StatusBadge tone={selectedEvent ? 'success' : 'warning'}>GvG vote</StatusBadge>
        <h3>GvG readiness vote</h3>
        <p>
          Vote once for the active event. Changing from Present to Absent updates the same vote
          record; it does not create a duplicate.
        </p>
        <button type="button" className="secondary-action" onClick={() => loadGvgData()} disabled={loading || saving}>
          {loading ? 'Refreshing...' : 'Refresh GvG'}
        </button>
      </section>

      {error ? <p className="error-line">{error}</p> : null}
      {message ? <p className="notice-line">{message}</p> : null}

      {loading ? <p className="muted-line">Loading active GvG event...</p> : null}

      {!loading && events.length === 0 ? (
        <section className="panel hero-panel">
          <StatusBadge tone="warning">Awaiting event</StatusBadge>
          <h3>No active GvG event</h3>
          <p>When leadership opens a GvG event for your guild, your vote controls will appear here.</p>
        </section>
      ) : null}

      {events.length > 0 ? (
        <section className="panel vote-panel" aria-label="GvG voting">
          {events.length > 1 ? (
            <label>
              Active event
              <select value={selectedEventId} onChange={(event) => handleSelectEvent(event.target.value)} disabled={loading || saving}>
                {events.map((event) => (
                  <option key={event.id} value={event.id}>
                    {event.title}
                  </option>
                ))}
              </select>
            </label>
          ) : null}

          <div className="approval-meta" aria-label="Selected GvG event details">
            <div>
              <span>Event</span>
              <strong>{selectedEvent?.title ?? 'Active GvG event'}</strong>
            </div>
            <div>
              <span>Scope</span>
              <strong>{selectedEvent?.scope === 'global' ? 'Global' : selectedEvent?.guild?.name ?? 'Guild'}</strong>
            </div>
            <div>
              <span>Starts</span>
              <strong>{formatDate(selectedEvent?.starts_at)}</strong>
            </div>
            <div>
              <span>Your vote</span>
              <strong>{formatVoteStatus(currentVote?.vote_status)}</strong>
            </div>
          </div>

          <div className="vote-actions">
            <button
              type="button"
              className="primary-action"
              data-active={voteStatus === 'present'}
              onClick={() => {
                setVoteStatus('present');
                setAbsenceReason('');
              }}
              disabled={saving}
            >
              I participate
            </button>
            <button
              type="button"
              className="danger-action"
              data-active={voteStatus === 'absent'}
              onClick={() => setVoteStatus('absent')}
              disabled={saving}
            >
              Absent
            </button>
          </div>

          {voteStatus === 'absent' ? (
            <label>
              Absence reason
              <textarea
                placeholder="Optional reason, visible to authorized staff"
                value={absenceReason}
                maxLength={500}
                onChange={(event) => setAbsenceReason(event.target.value)}
                disabled={saving}
              />
            </label>
          ) : null}

          <button type="button" className="primary-action" onClick={handleSubmitVote} disabled={saving || !selectedEventId}>
            {saving ? 'Saving vote...' : 'Save vote'}
          </button>
        </section>
      ) : null}
    </div>
  );
}
