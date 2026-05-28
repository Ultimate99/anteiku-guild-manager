import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { CosmeticPreview } from '../components/CosmeticPreview.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import {
  approveRequest,
  cancelRequest,
  closeTeam,
  createTeam,
  declineRequest,
  disbandTeam,
  formatCombinedCp,
  formatDiscordUsername,
  loadMy3v3Status,
  loadTeams,
  parseCombinedCpInput,
  removeMember,
  reopenTeam,
  requestJoinTeam,
  updateCombinedCp,
  updateDiscordUsername,
} from '../services/threeVThreeService.js';

const TABS = ['findTeam', 'createTeam', 'myRequests'];

function statusTone(status) {
  if (status === 'open' || status === 'approved') {
    return 'success';
  }

  if (status === 'pending' || status === 'closed') {
    return 'warning';
  }

  if (status === 'full') {
    return 'info';
  }

  if (status === 'declined' || status === 'cancelled' || status === 'disbanded') {
    return 'muted';
  }

  return 'crimson';
}

function formatDate(value, language) {
  if (!value) {
    return '';
  }

  const date = new Date(value);

  if (Number.isNaN(date.getTime())) {
    return '';
  }

  return new Intl.DateTimeFormat(language, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

function displayCp(value, language, fallback) {
  const formatted = formatCombinedCp(value, language);
  return formatted ? `${formatted} CP` : fallback;
}

function resolveRequestBlockReason(reason, t) {
  const key = reason || 'not_eligible';
  const mappedKey = `threeVThree.blockReasons.${key}`;
  const translated = t(mappedKey);

  return translated === mappedKey ? t('threeVThree.blockReasons.not_eligible') : translated;
}

function formatErrorMessage(error, t) {
  const message = String(error?.message || '').toLowerCase();

  if (message.includes('discord username')) {
    return t('threeVThree.discordRequired');
  }

  if (message.includes('combined cp')) {
    return t('threeVThree.invalidCombinedCp');
  }

  if (message.includes('team name')) {
    return t('threeVThree.teamNameLength');
  }

  if (message.includes('already in an active')) {
    return t('threeVThree.alreadyInTeam');
  }

  if (message.includes('request limit')) {
    return t('threeVThree.maxAttempts');
  }

  if (message.includes('wait before requesting')) {
    return t('threeVThree.cooldown');
  }

  if (message.includes('pending request')) {
    return t('threeVThree.alreadyRequested');
  }

  if (message.includes('team is full')) {
    return t('threeVThree.teamFull');
  }

  if (message.includes('not accepting')) {
    return t('threeVThree.teamClosed');
  }

  return error?.message || t('threeVThree.actionFailed');
}

function ThreeVThreeProfileCard({
  profile,
  discordDraft,
  cpDraft,
  isEditing,
  savingField,
  message,
  error,
  onDiscordDraftChange,
  onCpDraftChange,
  onEditSetup,
  onCancelSetup,
  onSaveSetup,
}) {
  const { language, t } = useLanguage();
  const hasSavedSetup = Boolean(profile?.discordUsername) && profile?.combinedCp !== null && profile?.combinedCp !== undefined;
  const showForm = !hasSavedSetup || isEditing;

  return (
    <section className="panel three-v-three-profile-card three-v-three-setup-card">
      <div className="section-heading-row">
        <div>
          <p className="eyebrow">{t('threeVThree.playerSetup')}</p>
          <h3>{t('threeVThree.title')}</h3>
        </div>
        <StatusBadge tone={profile?.canCreateOrRequest ? 'success' : 'warning'}>
          {profile?.canCreateOrRequest ? t('threeVThree.eligible') : t('threeVThree.viewOnly')}
        </StatusBadge>
      </div>

      {showForm ? (
        <form className="three-v-three-setup-form" onSubmit={onSaveSetup}>
          <div className="three-v-three-setup-grid">
            <label>
              <span>{t('threeVThree.discordUsername')}</span>
              <input
                type="text"
                value={discordDraft}
                onChange={(event) => onDiscordDraftChange(event.target.value)}
                placeholder={t('threeVThree.discordPlaceholder')}
                autoComplete="off"
              />
              <small>{t('threeVThree.discordHelp')}</small>
            </label>

            <label>
              <span>{t('threeVThree.publicCombinedCp')}</span>
              <input
                type="text"
                inputMode="numeric"
                value={cpDraft}
                onChange={(event) => onCpDraftChange(event.target.value)}
                placeholder={t('threeVThree.combinedCpPlaceholder')}
              />
              <small>
                {profile?.combinedCp !== null && profile?.combinedCp !== undefined
                  ? displayCp(profile.combinedCp, language, t('common.notSet'))
                  : t('threeVThree.combinedCpHelp')}
              </small>
            </label>
          </div>

          <div className="three-v-three-setup-actions">
            <button type="submit" className="secondary-action compact-action three-v-three-save-setup" disabled={savingField === 'setup'}>
              {savingField === 'setup' ? t('common.working') : t('threeVThree.saveSetup')}
            </button>
            {hasSavedSetup ? (
              <button type="button" className="inline-text-action" onClick={onCancelSetup} disabled={savingField === 'setup'}>
                {t('common.cancel')}
              </button>
            ) : null}
          </div>
        </form>
      ) : (
        <div className="three-v-three-setup-summary">
          <div>
            <span>{t('threeVThree.discordUsername')}</span>
            <strong>{formatDiscordUsername(profile.discordUsername)}</strong>
          </div>
          <div>
            <span>{t('threeVThree.publicCombinedCp')}</span>
            <strong>{displayCp(profile.combinedCp, language, t('common.notSet'))}</strong>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={onEditSetup}>
            {t('threeVThree.editSetup')}
          </button>
        </div>
      )}

      {message ? <p className="notice-line">{message}</p> : null}
      {error ? <p className="error-line">{error}</p> : null}
    </section>
  );
}

function PlayerSlot({ slot, team, canManage, onRemove }) {
  const { language, t } = useLanguage();

  if (slot.isEmpty) {
    return (
      <div className="three-v-three-slot three-v-three-empty-slot">
        <span className="three-v-three-plus" aria-hidden="true">
          +
        </span>
        <strong>{t('threeVThree.openSlot')}</strong>
      </div>
    );
  }

  const removable = canManage && slot.role !== 'owner' && slot.profileId;

  return (
    <article className="three-v-three-slot" data-role={slot.role || 'member'}>
      <span className="three-v-three-slot-number">{slot.slotNumber}</span>
      <CosmeticPreview avatar={slot.avatar} frame={slot.frame} size="small" label={slot.ign || t('common.unknown')} />
      <div className="three-v-three-slot-copy">
        <strong>{slot.ign || t('common.unknown')}</strong>
        <small>{formatDiscordUsername(slot.discordUsername) || t('threeVThree.discordMissing')}</small>
        <span>{displayCp(slot.combinedCp, language, t('common.notSet'))}</span>
      </div>
      {removable ? (
        <button
          type="button"
          className="inline-text-action three-v-three-remove"
          onClick={() => onRemove({ teamId: team.id, profileId: slot.profileId })}
        >
          {t('threeVThree.removeMember')}
        </button>
      ) : null}
    </article>
  );
}

function JoinRequestPanel({ team, profile, draft, busy, onDraftChange, onSubmit, onCancel }) {
  const { t } = useLanguage();
  const hasDiscord = Boolean(profile?.discordUsername);

  return (
    <form className="three-v-three-request-panel" onSubmit={(event) => onSubmit(event, team)}>
      <div>
        <strong>{t('threeVThree.requestJoin')}</strong>
        <p>{hasDiscord ? t('threeVThree.requestJoinBody') : t('threeVThree.discordRequired')}</p>
      </div>
      <label>
        <span>{t('threeVThree.publicCombinedCp')}</span>
        <input
          type="text"
          inputMode="numeric"
          value={draft}
          onChange={(event) => onDraftChange(team.id, event.target.value)}
          placeholder={t('threeVThree.combinedCpPlaceholder')}
        />
      </label>
      <div className="three-v-three-action-row">
        <button type="submit" className="primary-action compact-action" disabled={busy || !hasDiscord}>
          {busy ? t('common.working') : t('threeVThree.requestJoin')}
        </button>
        <button type="button" className="secondary-action compact-action" onClick={onCancel} disabled={busy}>
          {t('common.cancel')}
        </button>
      </div>
    </form>
  );
}

function TeamCard({
  team,
  profile,
  requestDraft,
  requestingTeamId,
  busyKey,
  canManage = false,
  onRequestOpen,
  onRequestDraftChange,
  onRequestSubmit,
  onRequestCancel,
  onRemoveMember,
  onCloseTeam,
  onReopenTeam,
  onDisbandTeam,
  showRequestAction = true,
  compact = false,
  hideHeader = false,
  hideRequestBlockReason = false,
}) {
  const { t } = useLanguage();
  const emptySlots = team.slots.filter((slot) => slot.isEmpty);
  const isRequesting = requestingTeamId === team.id;
  const canShowPlus = emptySlots.length > 0 && team.status === 'open';
  const shouldShowRequestLine = !canManage && showRequestAction && canShowPlus && (team.canRequest || !hideRequestBlockReason);

  return (
    <article className="three-v-three-team-card" data-status={team.status} data-compact={compact ? 'true' : 'false'}>
      {!hideHeader ? (
        <header className="three-v-three-team-header">
          <div>
            <p className="eyebrow">{t('threeVThree.team')}</p>
            <h3>{team.name || t('threeVThree.unnamedTeam')}</h3>
          </div>
          <StatusBadge tone={statusTone(team.status)}>{t(`threeVThree.status.${team.status}`)}</StatusBadge>
        </header>
      ) : null}

      <div className="three-v-three-slots" aria-label={t('threeVThree.slots')}>
        {team.slots.map((slot) => (
          <PlayerSlot
            key={`${team.id}-${slot.slotNumber}`}
            slot={slot}
            team={team}
            canManage={canManage}
            onRemove={onRemoveMember}
          />
        ))}
      </div>

      {shouldShowRequestLine ? (
        <div className="three-v-three-request-line">
          {team.canRequest ? (
            <button
              type="button"
              className="three-v-three-plus-button"
              onClick={() => onRequestOpen(team)}
              disabled={Boolean(busyKey)}
            >
              <span aria-hidden="true">+</span>
              {t('threeVThree.requestOpenSlot')}
            </button>
          ) : hideRequestBlockReason ? null : (
            <p className="muted-line">{resolveRequestBlockReason(team.requestBlockReason, t)}</p>
          )}
        </div>
      ) : null}

      {!canManage && showRequestAction && isRequesting ? (
        <JoinRequestPanel
          team={team}
          profile={profile}
          draft={requestDraft}
          busy={busyKey === `request:${team.id}`}
          onDraftChange={onRequestDraftChange}
          onSubmit={onRequestSubmit}
          onCancel={onRequestCancel}
        />
      ) : null}

      {canManage ? (
        <div className="three-v-three-owner-actions">
          {team.status === 'closed' ? (
            <button
              type="button"
              className="secondary-action compact-action"
              onClick={() => onReopenTeam(team.id)}
              disabled={Boolean(busyKey)}
            >
              {t('threeVThree.reopenTeam')}
            </button>
          ) : team.status === 'open' ? (
            <button
              type="button"
              className="secondary-action compact-action"
              onClick={() => onCloseTeam(team.id)}
              disabled={Boolean(busyKey)}
            >
              {t('threeVThree.closeTeam')}
            </button>
          ) : null}
          <button
            type="button"
            className="danger-action compact-action"
            onClick={() => onDisbandTeam(team.id)}
            disabled={Boolean(busyKey)}
          >
            {t('threeVThree.disbandTeam')}
          </button>
        </div>
      ) : null}
    </article>
  );
}

function FindTeamTab({
  teams,
  profile,
  isAlreadyInTeam,
  requestDrafts,
  requestingTeamId,
  busyKey,
  onRequestOpen,
  onRequestDraftChange,
  onRequestSubmit,
  onRequestCancel,
}) {
  const { t } = useLanguage();

  return (
    <section className="three-v-three-tab-panel">
      {isAlreadyInTeam ? (
        <p className="muted-line compact-state-line three-v-three-global-note">{t('threeVThree.alreadyInTeam')}</p>
      ) : null}

      {teams.length ? (
        <div className="three-v-three-team-grid">
          {teams.map((team) => (
            <TeamCard
              key={team.id}
              team={team}
              profile={profile}
              requestDraft={requestDrafts[team.id] ?? ''}
              requestingTeamId={requestingTeamId}
              busyKey={busyKey}
              onRequestOpen={onRequestOpen}
              onRequestDraftChange={onRequestDraftChange}
              onRequestSubmit={onRequestSubmit}
              onRequestCancel={onRequestCancel}
              hideRequestBlockReason={isAlreadyInTeam}
            />
          ))}
        </div>
      ) : (
        <section className="panel three-v-three-empty-panel compact-empty-state">
          <h3>{t('threeVThree.noTeams')}</h3>
          <p>{t('threeVThree.noTeamsBody')}</p>
        </section>
      )}
    </section>
  );
}

function CreateTeamTab({
  profile,
  hasActiveTeam,
  teamName,
  cpDraft,
  busyKey,
  onTeamNameChange,
  onCpDraftChange,
  onGoToMyTeam,
  onSubmit,
}) {
  const { t } = useLanguage();
  const cannotCreateReason = !profile?.canCreateOrRequest
    ? t('threeVThree.viewOnlyCreate')
    : !profile?.discordUsername
      ? t('threeVThree.discordRequired')
      : '';

  if (hasActiveTeam) {
    return (
      <section className="panel three-v-three-create-panel three-v-three-blocked-panel compact-empty-state">
        <StatusBadge tone="warning">{t('threeVThree.alreadyInTeam')}</StatusBadge>
        <h3>{t('threeVThree.alreadyInTeamCreateBlocked')}</h3>
        <p>{t('threeVThree.leaveOrDisbandFirst')}</p>
        <button type="button" className="secondary-action compact-action" onClick={onGoToMyTeam}>
          {t('threeVThree.goToMyTeam')}
        </button>
      </section>
    );
  }

  return (
    <section className="panel three-v-three-create-panel">
      <div className="section-heading-row">
        <div>
          <p className="eyebrow">{t('threeVThree.createTeam')}</p>
          <h3>{t('threeVThree.teamBuilder')}</h3>
        </div>
        <StatusBadge tone={cannotCreateReason ? 'warning' : 'success'}>
          {cannotCreateReason ? t('threeVThree.setupNeeded') : t('common.ready')}
        </StatusBadge>
      </div>

      {cannotCreateReason ? <p className="muted-line">{cannotCreateReason}</p> : null}

      <form className="three-v-three-form-grid" onSubmit={onSubmit}>
        <label>
          <span>{t('threeVThree.teamName')}</span>
          <input
            type="text"
            value={teamName}
            onChange={(event) => onTeamNameChange(event.target.value)}
            placeholder={t('threeVThree.teamNamePlaceholder')}
            maxLength={50}
          />
        </label>
        <label>
          <span>{t('threeVThree.publicCombinedCp')}</span>
          <input
            type="text"
            inputMode="numeric"
            value={cpDraft}
            onChange={(event) => onCpDraftChange(event.target.value)}
            placeholder={t('threeVThree.combinedCpPlaceholder')}
          />
        </label>
        <button
          type="submit"
          className="primary-action"
          disabled={Boolean(busyKey) || Boolean(cannotCreateReason)}
        >
          {busyKey === 'create' ? t('common.working') : t('threeVThree.createTeam')}
        </button>
      </form>
    </section>
  );
}

function RequesterCard({ request, busyKey, onApprove, onDecline }) {
  const { language, t } = useLanguage();

  return (
    <article className="three-v-three-request-card">
      <CosmeticPreview
        avatar={request.avatar}
        frame={request.frame}
        size="small"
        label={request.requesterIgn || request.requesterUsername || t('common.unknown')}
      />
      <div>
        <strong>{request.requesterIgn || t('common.unknown')}</strong>
        <small>{formatDiscordUsername(request.requesterDiscordUsername) || t('threeVThree.discordMissing')}</small>
        <span>{displayCp(request.combinedCp, language, t('common.notSet'))}</span>
      </div>
      <div className="three-v-three-request-actions">
        <button
          type="button"
          className="primary-action compact-action"
          onClick={() => onApprove(request.id)}
          disabled={Boolean(busyKey)}
        >
          {t('threeVThree.approve')}
        </button>
        <button
          type="button"
          className="secondary-action compact-action"
          onClick={() => onDecline(request.id)}
          disabled={Boolean(busyKey)}
        >
          {t('threeVThree.decline')}
        </button>
      </div>
    </article>
  );
}

function OutgoingRequestCard({ request, busyKey, onCancel }) {
  const { language, t } = useLanguage();
  const canCancel = request.status === 'pending';

  return (
    <article className="three-v-three-outgoing-card">
      <div>
        <strong>{request.teamName || t('threeVThree.unnamedTeam')}</strong>
        <small>{formatDate(request.createdAt, language)}</small>
      </div>
      <div className="status-badge-row">
        <StatusBadge tone={statusTone(request.status)}>{t(`threeVThree.requestStatus.${request.status}`)}</StatusBadge>
        <span>{displayCp(request.combinedCp, language, t('common.notSet'))}</span>
      </div>
      {canCancel ? (
        <button
          type="button"
          className="secondary-action compact-action"
          onClick={() => onCancel(request.id)}
          disabled={Boolean(busyKey)}
        >
          {t('threeVThree.cancelRequest')}
        </button>
      ) : null}
    </article>
  );
}

function MyRequestsTab({
  status,
  busyKey,
  onCancelRequest,
  onApproveRequest,
  onDeclineRequest,
  onRemoveMember,
  onCloseTeam,
  onReopenTeam,
  onDisbandTeam,
}) {
  const { t } = useLanguage();
  const ownedTeam = status?.ownedTeam;
  const currentTeam = status?.currentTeam;
  const incomingRequests = status?.incomingRequests ?? [];
  const outgoingRequests = status?.outgoingRequests ?? [];

  return (
    <section className="three-v-three-tab-panel three-v-three-requests-layout">
      <section className="panel three-v-three-request-section">
        <div className="section-heading-row">
          <div>
            <p className="eyebrow">{t('threeVThree.myTeam')}</p>
            <h3>{currentTeam?.name || t('threeVThree.noActiveTeam')}</h3>
          </div>
          {currentTeam ? (
            <StatusBadge tone={statusTone(currentTeam.status)}>{t(`threeVThree.status.${currentTeam.status}`)}</StatusBadge>
          ) : null}
        </div>

        {ownedTeam ? (
          <TeamCard
            team={ownedTeam}
            canManage
            busyKey={busyKey}
            onRemoveMember={onRemoveMember}
            onCloseTeam={onCloseTeam}
            onReopenTeam={onReopenTeam}
            onDisbandTeam={onDisbandTeam}
            showRequestAction={false}
            compact
            hideHeader
          />
        ) : currentTeam ? (
          <TeamCard team={currentTeam} canManage={false} showRequestAction={false} compact hideHeader />
        ) : (
          <p className="muted-line compact-state-line">{t('threeVThree.noActiveTeamBody')}</p>
        )}
      </section>

      <section className="panel three-v-three-request-section">
        <div className="section-heading-row">
          <div>
            <p className="eyebrow">{t('threeVThree.incomingRequests')}</p>
            <h3>{t('threeVThree.ownerQueue')}</h3>
          </div>
          <StatusBadge tone={incomingRequests.length ? 'warning' : 'muted'}>{incomingRequests.length}</StatusBadge>
        </div>
        {incomingRequests.length ? (
          <div className="three-v-three-request-list">
            {incomingRequests.map((request) => (
              <RequesterCard
                key={request.id}
                request={request}
                busyKey={busyKey}
                onApprove={onApproveRequest}
                onDecline={onDeclineRequest}
              />
            ))}
          </div>
        ) : (
          <p className="muted-line compact-state-line">{t('threeVThree.noIncomingRequests')}</p>
        )}
      </section>

      <section className="panel three-v-three-request-section">
        <div className="section-heading-row">
          <div>
            <p className="eyebrow">{t('threeVThree.outgoingRequests')}</p>
            <h3>{t('threeVThree.sentRequests')}</h3>
          </div>
          <StatusBadge tone={outgoingRequests.length ? 'info' : 'muted'}>{outgoingRequests.length}</StatusBadge>
        </div>
        {outgoingRequests.length ? (
          <div className="three-v-three-request-list">
            {outgoingRequests.map((request) => (
              <OutgoingRequestCard
                key={request.id}
                request={request}
                busyKey={busyKey}
                onCancel={onCancelRequest}
              />
            ))}
          </div>
        ) : (
          <p className="muted-line compact-state-line">{t('threeVThree.noOutgoingRequests')}</p>
        )}
      </section>
    </section>
  );
}

export function ThreeVThree() {
  const { language, t } = useLanguage();
  const [activeTab, setActiveTab] = useState('findTeam');
  const [teamsState, setTeamsState] = useState({ viewer: null, teams: [] });
  const [myStatus, setMyStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [busyKey, setBusyKey] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [discordDraft, setDiscordDraft] = useState('');
  const [profileCpDraft, setProfileCpDraft] = useState('');
  const [teamNameDraft, setTeamNameDraft] = useState('');
  const [createCpDraft, setCreateCpDraft] = useState('');
  const [requestingTeamId, setRequestingTeamId] = useState('');
  const [requestDrafts, setRequestDrafts] = useState({});
  const [setupEditing, setSetupEditing] = useState(false);

  const threeVThreeProfile = myStatus?.profile ?? teamsState.viewer;
  const teams = teamsState.teams;
  const hasActiveTeam = Boolean(myStatus?.currentTeam);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError('');

    try {
      const [nextTeams, nextStatus] = await Promise.all([loadTeams(), loadMy3v3Status()]);
      setTeamsState(nextTeams);
      setMyStatus(nextStatus);
    } catch (loadError) {
      setError(formatErrorMessage(loadError, t));
      setTeamsState({ viewer: null, teams: [] });
      setMyStatus(null);
    } finally {
      setLoading(false);
    }
  }, [t]);

  useEffect(() => {
    refresh();
  }, [refresh]);

  useEffect(() => {
    const nextProfile = myStatus?.profile ?? teamsState.viewer;

    setDiscordDraft(nextProfile?.discordUsername ? formatDiscordUsername(nextProfile.discordUsername) : '');

    const nextCp = formatCombinedCp(nextProfile?.combinedCp, language);
    setProfileCpDraft(nextCp);

    if (!createCpDraft && nextCp) {
      setCreateCpDraft(nextCp);
    }
  }, [language, myStatus?.profile, teamsState.viewer]); // eslint-disable-line react-hooks/exhaustive-deps

  const runAction = async (key, action, successKey, onSuccess) => {
    setBusyKey(key);
    setMessage('');
    setError('');

    try {
      await action();
      setMessage(t(successKey));
      if (onSuccess) {
        onSuccess();
      }
      await refresh();
    } catch (actionError) {
      setError(formatErrorMessage(actionError, t));
    } finally {
      setBusyKey('');
    }
  };

  const handleSaveSetup = (event) => {
    event.preventDefault();
    const parsedCp = parseCombinedCpInput(profileCpDraft);

    if (parsedCp === null) {
      setError(t('threeVThree.invalidCombinedCp'));
      return;
    }

    runAction(
      'setup',
      async () => {
        await updateDiscordUsername(discordDraft);
        await updateCombinedCp(parsedCp);
      },
      'threeVThree.setupSaved',
      () => setSetupEditing(false),
    );
  };

  const handleCancelSetup = () => {
    setDiscordDraft(threeVThreeProfile?.discordUsername ? formatDiscordUsername(threeVThreeProfile.discordUsername) : '');
    setProfileCpDraft(formatCombinedCp(threeVThreeProfile?.combinedCp, language));
    setSetupEditing(false);
    setError('');
  };

  const handleCreateTeam = (event) => {
    event.preventDefault();
    const parsedCp = parseCombinedCpInput(createCpDraft);

    if (!teamNameDraft.trim()) {
      setError(t('threeVThree.teamNameRequired'));
      return;
    }

    if (parsedCp === null) {
      setError(t('threeVThree.invalidCombinedCp'));
      return;
    }

    runAction(
      'create',
      async () => {
        await createTeam({ teamName: teamNameDraft, combinedCp: parsedCp });
        setTeamNameDraft('');
      },
      'threeVThree.teamCreated',
    );
  };

  const handleRequestOpen = (team) => {
    const currentCp = formatCombinedCp(threeVThreeProfile?.combinedCp, language);
    setRequestingTeamId(team.id);
    setRequestDrafts((current) => ({
      ...current,
      [team.id]: current[team.id] ?? currentCp,
    }));
    setMessage('');
    setError('');
  };

  const handleRequestDraftChange = (teamId, value) => {
    setRequestDrafts((current) => ({
      ...current,
      [teamId]: value,
    }));
  };

  const handleRequestSubmit = (event, team) => {
    event.preventDefault();
    const parsedCp = parseCombinedCpInput(requestDrafts[team.id] ?? '');

    if (parsedCp === null) {
      setError(t('threeVThree.invalidCombinedCp'));
      return;
    }

    runAction(
      `request:${team.id}`,
      async () => {
        await requestJoinTeam({ teamId: team.id, combinedCp: parsedCp });
        setRequestingTeamId('');
      },
      'threeVThree.requestSent',
    );
  };

  const handleCancelRequest = (requestId) =>
    runAction(`cancel:${requestId}`, () => cancelRequest(requestId), 'threeVThree.requestCancelled');

  const handleApproveRequest = (requestId) =>
    runAction(`approve:${requestId}`, () => approveRequest(requestId), 'threeVThree.requestApproved');

  const handleDeclineRequest = (requestId) =>
    runAction(`decline:${requestId}`, () => declineRequest(requestId), 'threeVThree.requestDeclined');

  const handleRemoveMember = ({ teamId, profileId }) =>
    runAction(`remove:${profileId}`, () => removeMember({ teamId, profileId }), 'threeVThree.memberRemoved');

  const handleCloseTeam = (teamId) => runAction(`close:${teamId}`, () => closeTeam(teamId), 'threeVThree.teamClosedMessage');

  const handleReopenTeam = (teamId) =>
    runAction(`reopen:${teamId}`, () => reopenTeam(teamId), 'threeVThree.teamReopened');

  const handleDisbandTeam = (teamId) =>
    runAction(`disband:${teamId}`, () => disbandTeam(teamId), 'threeVThree.teamDisbanded');

  const teamCounts = useMemo(
    () => ({
      open: teams.filter((team) => team.status === 'open').length,
      full: teams.filter((team) => team.status === 'full').length,
      closed: teams.filter((team) => team.status === 'closed').length,
    }),
    [teams],
  );

  return (
    <div className="stack three-v-three-page">
      <section className="panel hero-panel three-v-three-hero">
        <div className="section-heading-row">
          <div>
            <p className="eyebrow">{t('threeVThree.title')}</p>
            <h3>{t('threeVThree.heroTitle')}</h3>
          </div>
          <button type="button" className="secondary-action compact-action three-v-three-refresh-action" onClick={refresh} disabled={loading || Boolean(busyKey)}>
            {loading ? t('common.loading') : t('common.refresh')}
          </button>
        </div>
        <p>{t('threeVThree.heroBody')}</p>
        <div className="three-v-three-summary-row">
          <article>
            <span>{t('threeVThree.status.open')}</span>
            <strong>{teamCounts.open}</strong>
          </article>
          <article>
            <span>{t('threeVThree.status.full')}</span>
            <strong>{teamCounts.full}</strong>
          </article>
          <article>
            <span>{t('threeVThree.status.closed')}</span>
            <strong>{teamCounts.closed}</strong>
          </article>
        </div>
      </section>

      <ThreeVThreeProfileCard
        profile={threeVThreeProfile}
        discordDraft={discordDraft}
        cpDraft={profileCpDraft}
        isEditing={setupEditing}
        savingField={busyKey}
        message={message}
        error={error}
        onDiscordDraftChange={setDiscordDraft}
        onCpDraftChange={setProfileCpDraft}
        onEditSetup={() => setSetupEditing(true)}
        onCancelSetup={handleCancelSetup}
        onSaveSetup={handleSaveSetup}
      />

      <div className="three-v-three-tabs" role="tablist" aria-label={t('threeVThree.title')}>
        {TABS.map((tab) => (
          <button
            key={tab}
            type="button"
            className="three-v-three-tab"
            data-active={activeTab === tab}
            onClick={() => setActiveTab(tab)}
          >
            {t(`threeVThree.${tab}`)}
          </button>
        ))}
      </div>

      {loading ? (
        <section className="panel">
          <p>{t('common.loading')}</p>
        </section>
      ) : null}

      {!loading && activeTab === 'findTeam' ? (
        <FindTeamTab
          teams={teams}
          profile={threeVThreeProfile}
          isAlreadyInTeam={hasActiveTeam}
          requestDrafts={requestDrafts}
          requestingTeamId={requestingTeamId}
          busyKey={busyKey}
          onRequestOpen={handleRequestOpen}
          onRequestDraftChange={handleRequestDraftChange}
          onRequestSubmit={handleRequestSubmit}
          onRequestCancel={() => setRequestingTeamId('')}
        />
      ) : null}

      {!loading && activeTab === 'createTeam' ? (
        <CreateTeamTab
          profile={threeVThreeProfile}
          hasActiveTeam={hasActiveTeam}
          teamName={teamNameDraft}
          cpDraft={createCpDraft}
          busyKey={busyKey}
          onTeamNameChange={setTeamNameDraft}
          onCpDraftChange={setCreateCpDraft}
          onGoToMyTeam={() => setActiveTab('myRequests')}
          onSubmit={handleCreateTeam}
        />
      ) : null}

      {!loading && activeTab === 'myRequests' ? (
        <MyRequestsTab
          status={myStatus}
          busyKey={busyKey}
          onCancelRequest={handleCancelRequest}
          onApproveRequest={handleApproveRequest}
          onDeclineRequest={handleDeclineRequest}
          onRemoveMember={handleRemoveMember}
          onCloseTeam={handleCloseTeam}
          onReopenTeam={handleReopenTeam}
          onDisbandTeam={handleDisbandTeam}
        />
      ) : null}
    </div>
  );
}
