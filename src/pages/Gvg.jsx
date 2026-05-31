import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  loadMemberActiveGvgEvents,
  loadOwnGvgVote,
  submitGvgVote,
} from '../services/gvgService.js';
import { useActiveProfileSummary } from '../hooks/useActiveProfileSummary.js';
import {
  isGvgLimitedRosterStatus,
  isHardBlockedRosterStatus,
  rosterStatusTone,
} from '../services/adminMemberService.js';

function formatDate(value, language, t) {
  if (!value) {
    return t('gvg.notScheduled');
  }

  return new Intl.DateTimeFormat(language, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value));
}

function formatVoteStatus(status, t) {
  if (status === 'present') {
    return t('gvg.present');
  }

  if (status === 'absent') {
    return t('gvg.absent');
  }

  return t('gvg.notVoted');
}

export function Gvg() {
  const { language, t } = useLanguage();
  const { membership } = useAuth();
  const { activeProfile, activeProfileLoading, activeProfileError } = useActiveProfileSummary();
  const activeProfileId = activeProfile?.profileId ?? '';
  const activeProfileReady = !activeProfileLoading && Boolean(activeProfileId);
  const activeProfilePending = Boolean(membership?.id) && !activeProfileReady && !activeProfileError;
  const rosterStatus = activeProfile?.rosterStatus ?? membership?.roster_status ?? 'active';
  const membershipStatus = activeProfile?.membershipStatus ?? membership?.membership_status ?? '';
  const isMembershipBlocked = membershipStatus ? membershipStatus !== 'active' : false;
  const isRosterBlocked =
    isMembershipBlocked || isHardBlockedRosterStatus(rosterStatus);
  const isGvgLimited = isGvgLimitedRosterStatus(rosterStatus);
  const canUseGvg = activeProfileReady && !isRosterBlocked && !isGvgLimited;
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

      if (activeProfileLoading || activeProfilePending) {
        setEvents([]);
        setSelectedEventId('');
        setCurrentVote(null);
        setVoteStatus('present');
        setAbsenceReason('');
        setLoading(false);
        return;
      }

      if (activeProfileError || !activeProfileReady) {
        setEvents([]);
        setSelectedEventId('');
        setCurrentVote(null);
        setVoteStatus('present');
        setAbsenceReason('');
        setError(t('accountSwitcher.activeProfileLoadError'));
        setLoading(false);
        return;
      }

      if (!canUseGvg) {
        setEvents([]);
        setSelectedEventId('');
        setCurrentVote(null);
        setVoteStatus('present');
        setAbsenceReason('');
        setLoading(false);
        return;
      }

      try {
        const nextEvents = await loadMemberActiveGvgEvents();
        const nextSelectedEventId =
          nextEvents.find((event) => event.id === selectedEventId)?.id ?? nextEvents[0]?.id ?? '';
        setEvents(nextEvents);
        setSelectedEventId(nextSelectedEventId);

        if (nextSelectedEventId) {
          const nextVote = await loadOwnGvgVote({ eventId: nextSelectedEventId });
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
    [activeProfileError, activeProfileLoading, activeProfilePending, activeProfileReady, canUseGvg, selectedEventId, t],
  );

  useEffect(() => {
    setEvents([]);
    setSelectedEventId('');
    setCurrentVote(null);
    setVoteStatus('present');
    setAbsenceReason('');
    setError('');
    setMessage('');
  }, [activeProfileId]);

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
      const nextVote = await loadOwnGvgVote({ eventId });
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
    if (!canUseGvg) {
      setError(t('gvg.notEligible'));
      return;
    }

    if (!selectedEventId) {
      setError(t('gvg.noEventAvailable'));
      return;
    }

    if (voteStatus === 'absent' && absenceReason.length > 500) {
      setError(t('gvg.absenceTooLong'));
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
      setMessage(t('gvg.voteSaved', { status: formatVoteStatus(savedVote.vote_status, t) }));
      await loadGvgData({ clearMessage: false });
    } catch (gvgError) {
      setError(gvgError.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="stack gvg-member-page">
      <section className="panel hero-panel gvg-hero-panel member-compact-panel">
        <div className="section-heading-row gvg-mobile-heading">
          <div>
            <div className="status-badge-row">
              <StatusBadge tone={selectedEvent ? 'success' : 'warning'}>{t('gvg.voteBadge')}</StatusBadge>
              <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
            </div>
            <h3>{t('gvg.readinessTitle')}</h3>
            <p>{t('gvg.readinessBody')}</p>
          </div>
          <button
            type="button"
            className="secondary-action compact-action gvg-refresh-action"
            onClick={() => loadGvgData()}
            disabled={loading || saving || !canUseGvg}
          >
            {loading ? t('gvg.refreshing') : t('gvg.refresh')}
          </button>
        </div>
      </section>

      {error ? <p className="error-line">{error}</p> : null}
      {message ? <p className="notice-line">{message}</p> : null}

      {activeProfileReady && !canUseGvg ? (
        <section className="panel restricted-panel gate-panel member-compact-panel">
          <StatusBadge tone={rosterStatusTone(rosterStatus)}>{t(`roster.status.${rosterStatus}.label`)}</StatusBadge>
          <h3>{isRosterBlocked ? t('gvg.accessUnavailable') : t('gvg.notExpected')}</h3>
          <p>{t(`roster.status.${rosterStatus}.summary`)}</p>
        </section>
      ) : null}

      {(activeProfileLoading || activeProfilePending || (canUseGvg && loading)) ? <p className="muted-line">{t('gvg.loadingActive')}</p> : null}

      {canUseGvg && !loading && events.length === 0 ? (
        <section className="panel hero-panel gvg-empty-panel member-compact-panel">
          <StatusBadge tone="warning">{t('gvg.awaitingEvent')}</StatusBadge>
          <h3>{t('gvg.noActiveEvent')}</h3>
          <p>{t('gvg.votingOpens')}</p>
        </section>
      ) : null}

      {canUseGvg && events.length > 0 ? (
        <section className="panel vote-panel compact-vote-panel gvg-vote-card" aria-label={t('gvg.votingLabel')}>
          {events.length > 1 ? (
            <label>
              {t('gvg.activeEvent')}
              <select value={selectedEventId} onChange={(event) => handleSelectEvent(event.target.value)} disabled={loading || saving}>
                {events.map((event) => (
                  <option key={event.id} value={event.id}>
                    {event.title}
                  </option>
                ))}
              </select>
            </label>
          ) : null}

          <div className="gvg-vote-card-heading">
            <div>
              <p className="eyebrow">{t('gvg.event')}</p>
              <h3>{selectedEvent?.title ?? t('gvg.activeEventFallback')}</h3>
            </div>
            <StatusBadge tone={currentVote?.vote_status ? 'success' : 'warning'}>
              {formatVoteStatus(currentVote?.vote_status, t)}
            </StatusBadge>
          </div>

          <div className="approval-meta compact-meta gvg-event-meta" aria-label={t('gvg.eventDetails')}>
            <div>
              <span>{t('gvg.scope')}</span>
              <strong>{selectedEvent?.scope === 'global' ? t('gvg.global') : selectedEvent?.guild?.name ?? t('gvg.guild')}</strong>
            </div>
            <div>
              <span>{t('gvg.starts')}</span>
              <strong>{formatDate(selectedEvent?.starts_at, language, t)}</strong>
            </div>
            <div>
              <span>{t('gvg.yourVote')}</span>
              <strong>{formatVoteStatus(currentVote?.vote_status, t)}</strong>
            </div>
          </div>

          <div className="vote-actions gvg-vote-segment">
            <button
              type="button"
              className="primary-action gvg-vote-option"
              data-active={voteStatus === 'present'}
              onClick={() => {
                setVoteStatus('present');
                setAbsenceReason('');
              }}
              disabled={saving}
            >
              {t('gvg.participate')}
            </button>
            <button
              type="button"
              className="danger-action gvg-vote-option"
              data-active={voteStatus === 'absent'}
              onClick={() => setVoteStatus('absent')}
              disabled={saving}
            >
              {t('gvg.absent')}
            </button>
          </div>

          {voteStatus === 'absent' ? (
            <label>
              {t('gvg.absenceReason')}
              <textarea
                placeholder={t('gvg.absenceReasonPlaceholder')}
                value={absenceReason}
                maxLength={500}
                onChange={(event) => setAbsenceReason(event.target.value)}
                disabled={saving}
              />
            </label>
          ) : null}

          <button type="button" className="primary-action compact-action gvg-save-action" onClick={handleSubmitVote} disabled={saving || !selectedEventId}>
            {saving ? t('gvg.savingVote') : t('gvg.saveVote')}
          </button>
        </section>
      ) : null}
    </div>
  );
}
