import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { CosmeticPreview } from '../components/CosmeticPreview.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useActiveProfileSummary } from '../hooks/useActiveProfileSummary.js';
import { useAuth } from '../hooks/useAuth.js';
import {
  WALL_REACTION_TYPES,
  createWallComment,
  createWallPost,
  deleteWallComment,
  deleteWallPost,
  getReactionCount,
  hasMyReaction,
  loadReactionDetails,
  loadGuildWallFeed,
  moderateDeleteWallComment,
  moderateDeleteWallPost,
  pinWallPost,
  reactToWallComment,
  reactToWallPost,
  removeWallCommentReaction,
  removeWallPostReaction,
  unpinWallPost,
} from '../services/guildWallService.js';

const REACTION_ICONS = {
  like: '\u{1F44D}',
  fire: '\u{1F525}',
  coffee: '\u2615',
  skull: '\u{1F480}',
  trophy: '\u{1F3C6}',
};

function formatWallDate(value, language) {
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

function formatWallNumber(value, language) {
  const number = Number(value);

  if (!Number.isFinite(number)) {
    return '';
  }

  return new Intl.NumberFormat(language).format(number);
}

function authorName(author, fallback) {
  return author?.ign || author?.username || author?.profileSlug || fallback;
}

function getErrorMessage(error, t) {
  const message = String(error?.message || '');
  const lowered = message.toLowerCase();

  if (lowered.includes('approved profile')) {
    return t('wall.permissionDenied');
  }

  if (lowered.includes('not authorized')) {
    return t('wall.permissionDenied');
  }

  if (lowered.includes('content')) {
    return t('wall.contentRequired');
  }

  if (lowered.includes('locked')) {
    return t('wall.locked');
  }

  return message || t('wall.actionFailed');
}

function GhoulRepChip({ value }) {
  const { language, t } = useLanguage();

  if (value === null || value === undefined) {
    return null;
  }

  return (
    <span className="wall-ghoul-rep-chip" title={t('wall.ghoulRep')}>
      <strong>{formatWallNumber(value, language)}</strong>
      <span>{t('wall.ghoulRep')}</span>
    </span>
  );
}

function ProfileLinkButton({ profileSlug, onOpenProfile, className = '', children }) {
  const { t } = useLanguage();

  if (!profileSlug || !onOpenProfile) {
    return children;
  }

  return (
    <button
      type="button"
      className={`profile-link-button ${className}`.trim()}
      onClick={() => onOpenProfile(profileSlug)}
      aria-label={t('publicProfile.viewProfile')}
    >
      {children}
    </button>
  );
}

function ReactionButton({ type, reactions, disabled, onToggle, onShowDetails }) {
  const { t } = useLanguage();
  const count = getReactionCount(reactions, type);
  const active = hasMyReaction(reactions, type);
  const label = t(`wall.reaction.${type}`);
  const icon = REACTION_ICONS[type] ?? type;
  const detailsLabel = `${label} ${t('wall.reactionDetails')}`;

  function handleClick() {
    onToggle(type, active);
  }

  return (
    <button
      type="button"
      className="wall-reaction-button"
      data-active={active}
      disabled={disabled}
      onClick={handleClick}
      onMouseEnter={() => onShowDetails(type)}
      onFocus={() => onShowDetails(type)}
      aria-pressed={active}
      aria-label={detailsLabel}
      title={detailsLabel}
    >
      <span aria-hidden="true">{icon}</span>
      <strong>{count}</strong>
    </button>
  );
}

function ReactionDetailsPanel({ details, onClose, onOpenProfile }) {
  const { language, t } = useLanguage();

  if (!details?.open) {
    return null;
  }

  const icon = REACTION_ICONS[details.reactionType] ?? '';
  const title = icon ? `${icon} ${t('wall.reactedBy')}` : t('wall.reactionDetails');

  return (
    <aside className="wall-reaction-details-panel" role="dialog" aria-label={t('wall.reactionDetails')}>
      <div className="wall-reaction-details-header">
        <div>
          <p className="eyebrow">{t('wall.reactionDetails')}</p>
          <h3>{title}</h3>
        </div>
        <button type="button" className="inline-text-action" onClick={onClose}>
          {t('wall.close')}
        </button>
      </div>

      {details.loading ? (
        <p className="notice-line">{t('common.loading')}</p>
      ) : details.error ? (
        <p className="error-line">{details.error}</p>
      ) : details.reactions.length === 0 ? (
        <p className="notice-line">{t('wall.noReactions')}</p>
      ) : (
        <div className="wall-reaction-detail-list">
          {details.reactions.map((reaction, index) => (
            <article
              key={`${reaction.reactionType}:${reaction.username}:${reaction.profileSlug}:${reaction.reactedAt}:${index}`}
              className="wall-reaction-detail-row"
            >
              <CosmeticPreview
                avatar={reaction.avatar}
                frame={reaction.frame}
                label={authorName(reaction, t('common.unknown'))}
                size="small"
                className="wall-reaction-detail-avatar"
              />
              <div>
                <ProfileLinkButton
                  profileSlug={reaction.profileSlug}
                  onOpenProfile={onOpenProfile}
                  className="wall-author-name-button"
                >
                  <strong>{authorName(reaction, t('common.unknown'))}</strong>
                </ProfileLinkButton>
                <span>{reaction.guildName || t('wall.guildOnly')}</span>
              </div>
              <small>
                {REACTION_ICONS[reaction.reactionType] ?? reaction.reactionType}
                {reaction.reactedAt ? ` ${formatWallDate(reaction.reactedAt, language)}` : ''}
              </small>
            </article>
          ))}
        </div>
      )}
    </aside>
  );
}

function WallScopeSelector({ options, selectedScopeId, onChange }) {
  const { t } = useLanguage();

  if (options.length <= 1) {
    return null;
  }

  return (
    <section className="wall-scope-panel" aria-label={t('wall.scope')}>
      <div>
        <StatusBadge tone="crimson">{t('wall.scope')}</StatusBadge>
        <strong>{t('wall.viewing', { scope: options.find((option) => option.id === selectedScopeId)?.name ?? '-' })}</strong>
      </div>
      <div className="wall-scope-chips">
        {options.map((option) => (
          <button
            key={option.id}
            type="button"
            className="wall-scope-chip"
            data-active={selectedScopeId === option.id}
            onClick={() => onChange(option.id)}
          >
            {option.name}
          </button>
        ))}
      </div>
    </section>
  );
}

function WallComposer({ canPost, guildId, isGlobal, content, disabledReason, busy, onChange, onSubmit }) {
  const { t } = useLanguage();
  const hasScope = isGlobal || Boolean(guildId);
  const canSubmit = canPost && hasScope && content.trim().length > 0 && !busy;

  return (
    <section className="panel wall-composer-panel">
      <div className="section-heading-row">
        <div>
          <p className="eyebrow">{t('wall.createPost')}</p>
          <h3>{t('wall.title')}</h3>
        </div>
        <StatusBadge tone={canPost && hasScope ? 'success' : 'warning'}>
          {canPost && hasScope ? t('common.ready') : t('wall.permissionDenied')}
        </StatusBadge>
      </div>

      <form className="wall-composer-form" onSubmit={onSubmit}>
        <textarea
          value={content}
          onChange={(event) => onChange(event.target.value)}
          placeholder={t('wall.writePost')}
          maxLength={1000}
          disabled={!canPost || !hasScope || busy}
        />
        <div className="wall-composer-footer">
          <span>{disabledReason || t('wall.guildOnly')}</span>
          <button type="submit" className="primary-action compact-action" disabled={!canSubmit}>
            {busy ? t('common.working') : t('wall.post')}
          </button>
        </div>
      </form>
    </section>
  );
}

function WallComment({
  comment,
  viewerCanPost,
  busyAction,
  onDelete,
  onModerateDelete,
  onReactionToggle,
  onShowReactionDetails,
  onOpenProfile,
}) {
  const { language, t } = useLanguage();
  const canDelete = comment.canDelete || comment.canModerate;

  return (
    <article className="wall-comment-card">
      <div className="wall-comment-header">
        <ProfileLinkButton
          profileSlug={comment.author.profileSlug}
          onOpenProfile={onOpenProfile}
          className="wall-avatar-link"
        >
          <CosmeticPreview
            avatar={comment.author.avatar}
            frame={comment.author.frame}
            label={authorName(comment.author, t('common.unknown'))}
            size="small"
            className="wall-comment-avatar"
          />
        </ProfileLinkButton>
        <div className="wall-comment-identity">
          <div className="wall-comment-author-row">
            <ProfileLinkButton
              profileSlug={comment.author.profileSlug}
              onOpenProfile={onOpenProfile}
              className="wall-author-name-button"
            >
              <strong>{authorName(comment.author, t('common.unknown'))}</strong>
            </ProfileLinkButton>
            <GhoulRepChip value={comment.author.ghoulRep} />
          </div>
          <span>{formatWallDate(comment.createdAt, language)}</span>
        </div>
      </div>
      <p>{comment.content}</p>
      <div className="wall-card-actions">
        <div className="wall-reactions" aria-label={t('wall.reactions')}>
          {WALL_REACTION_TYPES.map((type) => (
            <ReactionButton
              key={type}
              type={type}
              reactions={comment.reactions}
              disabled={!viewerCanPost || busyAction === comment.id}
              onToggle={(reactionType, active) => onReactionToggle(comment.id, reactionType, active)}
              onShowDetails={(reactionType) => onShowReactionDetails(comment.id, reactionType)}
            />
          ))}
        </div>
        {canDelete ? (
          <div className="wall-moderation-actions">
            {comment.canDelete ? (
              <button type="button" className="inline-text-action" onClick={() => onDelete(comment.id)} disabled={busyAction === comment.id}>
                {t('wall.deleteComment')}
              </button>
            ) : null}
            {comment.canModerate && !comment.canDelete ? (
              <button
                type="button"
                className="inline-text-action danger-text-action"
                onClick={() => onModerateDelete(comment.id)}
                disabled={busyAction === comment.id}
              >
                {t('wall.moderation')}
              </button>
            ) : null}
          </div>
        ) : null}
      </div>
    </article>
  );
}

function WallPostCard({
  post,
  viewerCanPost,
  commentDraft,
  commentsExpanded,
  busyAction,
  onCommentDraftChange,
  onCommentSubmit,
  onToggleComments,
  onDeletePost,
  onModerateDeletePost,
  onTogglePin,
  onPostReactionToggle,
  onCommentDelete,
  onCommentModerateDelete,
  onCommentReactionToggle,
  onPostReactionDetails,
  onCommentReactionDetails,
  onOpenProfile,
}) {
  const { language, t } = useLanguage();
  const canModerateOnly = post.canModerate && !post.canDelete;
  const authorGuild = post.guildName || post.authorGuildName || t('wall.guildOnly');
  const scopeLabel = post.isGlobal ? `${t('wall.global')} - ${authorGuild}` : authorGuild;
  const commentCount = post.comments.length;
  const commentsId = `wall-comments-${post.id}`;

  return (
    <article className="panel wall-post-card" data-pinned={post.isPinned} data-global={post.isGlobal}>
      <header className="wall-post-header">
        <ProfileLinkButton profileSlug={post.author.profileSlug} onOpenProfile={onOpenProfile} className="wall-avatar-link">
          <CosmeticPreview
            avatar={post.author.avatar}
            frame={post.author.frame}
            label={authorName(post.author, t('common.unknown'))}
            size="medium"
            className="wall-post-avatar"
          />
        </ProfileLinkButton>
        <div className="wall-post-identity">
          <div className="wall-post-author-row">
            <ProfileLinkButton
              profileSlug={post.author.profileSlug}
              onOpenProfile={onOpenProfile}
              className="wall-author-name-button"
            >
              <strong>{authorName(post.author, t('common.unknown'))}</strong>
            </ProfileLinkButton>
            <GhoulRepChip value={post.author.ghoulRep} />
            {post.isGlobal ? <StatusBadge tone="crimson">{t('wall.globalBadge')}</StatusBadge> : null}
            {post.isPinned ? <StatusBadge tone="crimson">{t('wall.pinned')}</StatusBadge> : null}
          </div>
          <div className="wall-post-meta-row">
            <span>{scopeLabel}</span>
            <span>{formatWallDate(post.createdAt, language)}</span>
          </div>
        </div>
      </header>

      <p className="wall-post-content">{post.content}</p>

      <div className="wall-card-actions">
        <div className="wall-reactions" aria-label={t('wall.reactions')}>
          {WALL_REACTION_TYPES.map((type) => (
            <ReactionButton
              key={type}
              type={type}
              reactions={post.reactions}
              disabled={!viewerCanPost || busyAction === post.id}
              onToggle={(reactionType, active) => onPostReactionToggle(post.id, reactionType, active)}
              onShowDetails={(reactionType) => onPostReactionDetails(post.id, reactionType)}
            />
          ))}
        </div>

        <button
          type="button"
          className="wall-comment-toggle"
          data-active={commentsExpanded ? 'true' : 'false'}
          aria-expanded={commentsExpanded}
          aria-controls={commentsId}
          aria-label={
            commentsExpanded
              ? t('wall.hideComments', { count: commentCount })
              : t('wall.showComments', { count: commentCount })
          }
          onClick={() => onToggleComments(post.id)}
        >
          <span aria-hidden="true">💬</span>
          <strong>{formatWallNumber(commentCount, language)}</strong>
        </button>

        <div className="wall-moderation-actions">
          {post.canDelete ? (
            <button type="button" className="inline-text-action" onClick={() => onDeletePost(post.id)} disabled={busyAction === post.id}>
              {t('wall.deletePost')}
            </button>
          ) : null}
          {post.canModerate ? (
            <button type="button" className="inline-text-action" onClick={() => onTogglePin(post)} disabled={busyAction === post.id}>
              {post.isPinned ? t('wall.unpinPost') : t('wall.pinPost')}
            </button>
          ) : null}
          {canModerateOnly ? (
            <button
              type="button"
              className="inline-text-action danger-text-action"
              onClick={() => onModerateDeletePost(post.id)}
              disabled={busyAction === post.id}
            >
              {t('wall.moderation')}
            </button>
          ) : null}
        </div>
      </div>

      {commentsExpanded ? (
        <section className="wall-comments" id={commentsId}>
          <div className="wall-comments-title">
            <strong>{t('wall.comment')}</strong>
            <span>{formatWallNumber(commentCount, language)}</span>
          </div>

          {commentCount > 0 ? (
            <div className="wall-comment-list">
              {post.comments.map((comment) => (
                <WallComment
                  key={comment.id}
                  comment={comment}
                  viewerCanPost={viewerCanPost}
                  busyAction={busyAction}
                  onDelete={onCommentDelete}
                  onModerateDelete={onCommentModerateDelete}
                  onReactionToggle={onCommentReactionToggle}
                  onShowReactionDetails={onCommentReactionDetails}
                  onOpenProfile={onOpenProfile}
                />
              ))}
            </div>
          ) : null}

          {viewerCanPost && !post.isLocked ? (
            <form className="wall-comment-form" onSubmit={(event) => onCommentSubmit(event, post.id)}>
              <input
                type="text"
                value={commentDraft}
                onChange={(event) => onCommentDraftChange(post.id, event.target.value)}
                placeholder={t('wall.addComment')}
                maxLength={500}
              />
              <button type="submit" className="secondary-action compact-action" disabled={!commentDraft.trim() || busyAction === post.id}>
                {t('wall.comment')}
              </button>
            </form>
          ) : post.isLocked ? (
            <p className="notice-line">{t('wall.locked')}</p>
          ) : null}
        </section>
      ) : null}
    </article>
  );
}

export function GuildWall({ onNavigate }) {
  const { guild } = useAuth();
  const { activeProfile } = useActiveProfileSummary();
  const { t } = useLanguage();
  const [selectedScopeId, setSelectedScopeId] = useState('global');
  const [viewer, setViewer] = useState(null);
  const [posts, setPosts] = useState([]);
  const [postDraft, setPostDraft] = useState('');
  const [commentDrafts, setCommentDrafts] = useState({});
  const [expandedCommentPostIds, setExpandedCommentPostIds] = useState(() => new Set());
  const [loading, setLoading] = useState(false);
  const [loadingOlder, setLoadingOlder] = useState(false);
  const [busyAction, setBusyAction] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [reactionDetails, setReactionDetails] = useState({
    open: false,
    loading: false,
    error: '',
    targetKey: '',
    reactionType: '',
    reactions: [],
  });

  const activeGuildId = activeProfile?.guildId ?? guild?.id ?? null;

  const scopeOptions = useMemo(() => {
    return [
      {
        id: 'global',
        name: t('wall.global'),
        guildId: null,
        isGlobal: true,
      },
      {
        id: 'guild',
        name: t('wall.myOrg'),
        guildId: activeGuildId,
        isGlobal: false,
      },
    ];
  }, [activeGuildId, t]);

  const selectedScope = useMemo(
    () => scopeOptions.find((option) => option.id === selectedScopeId) ?? scopeOptions[0] ?? null,
    [scopeOptions, selectedScopeId],
  );
  const selectedGuildId = selectedScope?.isGlobal ? null : selectedScope?.guildId ?? activeGuildId ?? null;
  const composerGuildId = selectedScope?.isGlobal ? null : selectedGuildId;
  const viewerCanPost = Boolean(viewer?.canPost && (selectedScope?.isGlobal || composerGuildId));
  const openPublicProfile = useCallback((profileSlug) => {
    if (profileSlug) {
      onNavigate?.('publicProfile', { profileSlug });
    }
  }, [onNavigate]);

  const refreshFeed = useCallback(async ({ append = false, before = null } = {}) => {
    if (!selectedScope || (!selectedScope.isGlobal && !selectedGuildId)) {
      setViewer(null);
      setPosts([]);
      return;
    }

    setError('');
    if (append) {
      setLoadingOlder(true);
    } else {
      setLoading(true);
    }

    try {
      const data = await loadGuildWallFeed({
        guildId: selectedScope.isGlobal ? null : selectedGuildId,
        before,
      });

      setViewer(data.viewer);
      setPosts((current) => {
        if (!append) {
          return data.posts;
        }

        const seenIds = new Set(current.map((post) => post.id));
        return [...current, ...data.posts.filter((post) => !seenIds.has(post.id))];
      });
    } catch (loadError) {
      setError(getErrorMessage(loadError, t));
    } finally {
      setLoading(false);
      setLoadingOlder(false);
    }
  }, [selectedScope, selectedGuildId, t]);

  useEffect(() => {
    setSelectedScopeId((current) =>
      current && scopeOptions.some((option) => option.id === current) ? current : scopeOptions[0]?.id ?? '',
    );
  }, [scopeOptions]);

  useEffect(() => {
    setMessage('');
    setPostDraft('');
    setCommentDrafts({});
    setExpandedCommentPostIds(new Set());
    setReactionDetails((current) => ({
      ...current,
      open: false,
      loading: false,
      error: '',
    }));
    refreshFeed();
  }, [refreshFeed]);

  async function runAction(actionId, action, successMessage = '') {
    setBusyAction(actionId);
    setError('');
    setMessage('');

    try {
      await action();
      if (successMessage) {
        setMessage(successMessage);
      }
      await refreshFeed();
    } catch (actionError) {
      setError(getErrorMessage(actionError, t));
    } finally {
      setBusyAction('');
    }
  }

  async function openReactionDetails({ targetType, targetId, reactionType }) {
    const targetKey = `${targetType}:${targetId}:${reactionType}`;

    setReactionDetails({
      open: true,
      loading: true,
      error: '',
      targetKey,
      reactionType,
      reactions: [],
    });

    try {
      const details = await loadReactionDetails({ targetType, targetId, reactionType });
      setReactionDetails({
        open: true,
        loading: false,
        error: '',
        targetKey,
        reactionType: details.reactionType || reactionType,
        reactions: details.reactions,
      });
    } catch (detailsError) {
      setReactionDetails({
        open: true,
        loading: false,
        error: getErrorMessage(detailsError, t),
        targetKey,
        reactionType,
        reactions: [],
      });
    }
  }

  async function handlePostReactionToggle(postId, reactionType, active) {
    await runAction(
      `${postId}:${reactionType}`,
      () =>
        active
          ? removeWallPostReaction({ postId, reactionType })
          : reactToWallPost({ postId, reactionType }),
    );
    await openReactionDetails({ targetType: 'post', targetId: postId, reactionType });
  }

  async function handleCommentReactionToggle(commentId, reactionType, active) {
    await runAction(
      `${commentId}:${reactionType}`,
      () =>
        active
          ? removeWallCommentReaction({ commentId, reactionType })
          : reactToWallComment({ commentId, reactionType }),
    );
    await openReactionDetails({ targetType: 'comment', targetId: commentId, reactionType });
  }

  function handlePostSubmit(event) {
    event.preventDefault();
    const content = postDraft.trim();

    if (!content || (!selectedScope?.isGlobal && !composerGuildId)) {
      return;
    }

    runAction(
      'create-post',
      async () => {
        await createWallPost({ guildId: selectedScope?.isGlobal ? null : composerGuildId, content });
        setPostDraft('');
      },
      t('wall.postCreated'),
    );
  }

  function togglePostComments(postId) {
    setExpandedCommentPostIds((current) => {
      const next = new Set(current);

      if (next.has(postId)) {
        next.delete(postId);
      } else {
        next.add(postId);
      }

      return next;
    });
  }

  function handleCommentSubmit(event, postId) {
    event.preventDefault();
    const content = (commentDrafts[postId] ?? '').trim();

    if (!content) {
      return;
    }

    runAction(
      postId,
      async () => {
        await createWallComment({ postId, content });
        setCommentDrafts((current) => ({ ...current, [postId]: '' }));
        setExpandedCommentPostIds((current) => {
          const next = new Set(current);
          next.add(postId);
          return next;
        });
      },
      t('wall.commentCreated'),
    );
  }

  function handleLoadOlder() {
    const lastPost = posts[posts.length - 1];
    if (!lastPost?.createdAt) {
      return;
    }

    refreshFeed({ append: true, before: lastPost.createdAt });
  }

  function closeReactionDetails() {
    setReactionDetails((current) => ({
      ...current,
      open: false,
      loading: false,
    }));
  }

  const disabledReason = viewer?.canPost
    ? selectedScope?.isGlobal
      ? t('wall.postToGlobal')
      : t('wall.postToGuild')
    : t('wall.viewOnly');

  return (
    <div className="stack guild-wall-page">
      <section className="panel guild-wall-hero">
        <div className="section-heading-row">
          <div>
            <p className="eyebrow">{t('wall.guildWall')}</p>
            <h2>{t('wall.title')}</h2>
            <p>{t('wall.heroBody')}</p>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={() => refreshFeed()} disabled={loading}>
            {loading ? t('common.refreshing') : t('wall.refresh')}
          </button>
        </div>
      </section>

      <WallScopeSelector options={scopeOptions} selectedScopeId={selectedScope?.id ?? ''} onChange={setSelectedScopeId} />

      <WallComposer
        canPost={Boolean(viewer?.canPost)}
        guildId={composerGuildId}
        isGlobal={Boolean(selectedScope?.isGlobal)}
        content={postDraft}
        disabledReason={disabledReason}
        busy={busyAction === 'create-post'}
        onChange={setPostDraft}
        onSubmit={handlePostSubmit}
      />

      {message ? <p className="notice-line">{message}</p> : null}
      {error ? <p className="error-line">{error}</p> : null}

      <section className="guild-wall-feed" aria-label={t('wall.title')}>
        {loading && posts.length === 0 ? (
          <section className="panel guild-wall-empty-panel">
            <h3>{t('common.loading')}</h3>
            <p>{t('wall.loadingFeed')}</p>
          </section>
        ) : posts.length === 0 ? (
          <section className="panel guild-wall-empty-panel">
            <h3>{t('wall.noPosts')}</h3>
            <p>{t('wall.noPostsBody')}</p>
          </section>
        ) : (
          posts.map((post) => (
            <WallPostCard
              key={post.id}
              post={post}
              viewerCanPost={viewerCanPost}
              commentDraft={commentDrafts[post.id] ?? ''}
              commentsExpanded={expandedCommentPostIds.has(post.id)}
              busyAction={busyAction}
              onCommentDraftChange={(postId, value) => setCommentDrafts((current) => ({ ...current, [postId]: value }))}
              onCommentSubmit={handleCommentSubmit}
              onToggleComments={togglePostComments}
              onDeletePost={(postId) => runAction(postId, () => deleteWallPost(postId), t('wall.postDeleted'))}
              onModerateDeletePost={(postId) =>
                runAction(postId, () => moderateDeleteWallPost(postId), t('wall.postDeleted'))
              }
              onTogglePin={(targetPost) =>
                runAction(
                  targetPost.id,
                  () => (targetPost.isPinned ? unpinWallPost(targetPost.id) : pinWallPost(targetPost.id)),
                  targetPost.isPinned ? t('wall.postUnpinned') : t('wall.postPinned'),
                )
              }
              onCommentDelete={(commentId) => runAction(commentId, () => deleteWallComment(commentId), t('wall.commentDeleted'))}
              onCommentModerateDelete={(commentId) =>
                runAction(commentId, () => moderateDeleteWallComment(commentId), t('wall.commentDeleted'))
              }
              onPostReactionToggle={handlePostReactionToggle}
              onCommentReactionToggle={handleCommentReactionToggle}
              onPostReactionDetails={(postId, reactionType) =>
                openReactionDetails({ targetType: 'post', targetId: postId, reactionType })
              }
              onCommentReactionDetails={(commentId, reactionType) =>
                openReactionDetails({ targetType: 'comment', targetId: commentId, reactionType })
              }
              onOpenProfile={openPublicProfile}
            />
          ))
        )}
      </section>

      {posts.length > 0 ? (
        <button type="button" className="secondary-action compact-action wall-load-older" onClick={handleLoadOlder} disabled={loadingOlder}>
          {loadingOlder ? t('common.loading') : t('wall.loadOlder')}
        </button>
      ) : null}

      <ReactionDetailsPanel details={reactionDetails} onClose={closeReactionDetails} onOpenProfile={openPublicProfile} />
    </div>
  );
}
