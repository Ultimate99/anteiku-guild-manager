import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { CosmeticPreview } from '../components/CosmeticPreview.jsx';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import { useAuth } from '../hooks/useAuth.js';
import {
  WALL_REACTION_TYPES,
  createWallComment,
  createWallPost,
  deleteWallComment,
  deleteWallPost,
  getReactionCount,
  hasMyReaction,
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

const CORE_GUILD_OPTIONS = [
  { id: '00000000-0000-0000-0000-000000000101', name: 'Anteiku', slug: 'anteiku' },
  { id: '00000000-0000-0000-0000-000000000102', name: 'Anteiku:Re', slug: 'anteiku-re' },
  { id: '00000000-0000-0000-0000-000000000103', name: 'Anteiku:Rose', slug: 'anteiku-rose' },
  { id: '00000000-0000-0000-0000-000000000104', name: 'Anteiku:Goat', slug: 'anteiku-goat' },
];

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

function ReactionButton({ type, reactions, disabled, onToggle }) {
  const { t } = useLanguage();
  const count = getReactionCount(reactions, type);
  const active = hasMyReaction(reactions, type);

  return (
    <button
      type="button"
      className="wall-reaction-button"
      data-active={active}
      disabled={disabled}
      onClick={() => onToggle(type, active)}
      aria-pressed={active}
    >
      <span>{t(`wall.reaction.${type}`)}</span>
      <strong>{count}</strong>
    </button>
  );
}

function WallScopeSelector({ options, selectedScopeId, onChange }) {
  const { t } = useLanguage();

  if (options.length <= 1) {
    return null;
  }

  return (
    <section className="wall-scope-panel" aria-label={t('wall.guildOnly')}>
      <div>
        <StatusBadge tone="crimson">{t('wall.guildOnly')}</StatusBadge>
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

function WallComposer({ canPost, guildId, content, disabledReason, busy, onChange, onSubmit }) {
  const { t } = useLanguage();
  const canSubmit = canPost && guildId && content.trim().length > 0 && !busy;

  return (
    <section className="panel wall-composer-panel">
      <div className="section-heading-row">
        <div>
          <p className="eyebrow">{t('wall.createPost')}</p>
          <h3>{t('wall.title')}</h3>
        </div>
        <StatusBadge tone={canPost && guildId ? 'success' : 'warning'}>
          {canPost && guildId ? t('common.ready') : t('wall.permissionDenied')}
        </StatusBadge>
      </div>

      <form className="wall-composer-form" onSubmit={onSubmit}>
        <textarea
          value={content}
          onChange={(event) => onChange(event.target.value)}
          placeholder={t('wall.writePost')}
          maxLength={1000}
          disabled={!canPost || !guildId || busy}
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

function WallComment({ comment, viewerCanPost, busyAction, onDelete, onModerateDelete, onReactionToggle }) {
  const { language, t } = useLanguage();
  const canDelete = comment.canDelete || comment.canModerate;

  return (
    <article className="wall-comment-card">
      <div className="wall-comment-header">
        <CosmeticPreview
          avatar={comment.author.avatar}
          frame={comment.author.frame}
          label={authorName(comment.author, t('common.unknown'))}
          size="small"
          className="wall-comment-avatar"
        />
        <div>
          <strong>{authorName(comment.author, t('common.unknown'))}</strong>
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
  busyAction,
  onCommentDraftChange,
  onCommentSubmit,
  onDeletePost,
  onModerateDeletePost,
  onTogglePin,
  onPostReactionToggle,
  onCommentDelete,
  onCommentModerateDelete,
  onCommentReactionToggle,
}) {
  const { language, t } = useLanguage();
  const canModerateOnly = post.canModerate && !post.canDelete;

  return (
    <article className="panel wall-post-card" data-pinned={post.isPinned}>
      <header className="wall-post-header">
        <CosmeticPreview
          avatar={post.author.avatar}
          frame={post.author.frame}
          label={authorName(post.author, t('common.unknown'))}
          size="medium"
          className="wall-post-avatar"
        />
        <div className="wall-post-identity">
          <div>
            <strong>{authorName(post.author, t('common.unknown'))}</strong>
            {post.isPinned ? <StatusBadge tone="crimson">{t('wall.pinned')}</StatusBadge> : null}
          </div>
          <span>{post.guildName || t('wall.guildOnly')} · {formatWallDate(post.createdAt, language)}</span>
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
            />
          ))}
        </div>

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

      <section className="wall-comments">
        <div className="wall-comments-title">
          <strong>{t('wall.comment')}</strong>
          <span>{post.comments.length}</span>
        </div>

        {post.comments.length > 0 ? (
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
    </article>
  );
}

export function GuildWall() {
  const { guild, membership } = useAuth();
  const { t } = useLanguage();
  const isOwner = membership?.role === 'owner';
  const [selectedScopeId, setSelectedScopeId] = useState(() => (isOwner ? 'global' : guild?.id ?? ''));
  const [viewer, setViewer] = useState(null);
  const [posts, setPosts] = useState([]);
  const [postDraft, setPostDraft] = useState('');
  const [commentDrafts, setCommentDrafts] = useState({});
  const [loading, setLoading] = useState(false);
  const [loadingOlder, setLoadingOlder] = useState(false);
  const [busyAction, setBusyAction] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');

  const scopeOptions = useMemo(() => {
    if (isOwner) {
      return [{ id: 'global', name: t('wall.globalScope'), guildId: null }, ...CORE_GUILD_OPTIONS.map((option) => ({
        id: option.id,
        name: option.name,
        guildId: option.id,
      }))];
    }

    if (!guild?.id) {
      return [];
    }

    return [{ id: guild.id, name: guild.name ?? t('wall.guildOnly'), guildId: guild.id }];
  }, [guild?.id, guild?.name, isOwner, t]);

  const selectedScope = useMemo(
    () => scopeOptions.find((option) => option.id === selectedScopeId) ?? scopeOptions[0] ?? null,
    [scopeOptions, selectedScopeId],
  );
  const selectedGuildId = selectedScope?.guildId ?? null;
  const composerGuildId = selectedGuildId || (!isOwner ? guild?.id : null);
  const viewerCanPost = Boolean(viewer?.canPost && composerGuildId && selectedScope?.id !== 'global');

  const refreshFeed = useCallback(async ({ append = false, before = null } = {}) => {
    if (!selectedScope) {
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
        guildId: selectedScope.guildId,
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
  }, [selectedScope, t]);

  useEffect(() => {
    setSelectedScopeId((current) =>
      current && scopeOptions.some((option) => option.id === current) ? current : scopeOptions[0]?.id ?? '',
    );
  }, [scopeOptions]);

  useEffect(() => {
    setMessage('');
    setPostDraft('');
    setCommentDrafts({});
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

  function handlePostSubmit(event) {
    event.preventDefault();
    const content = postDraft.trim();

    if (!content || !composerGuildId) {
      return;
    }

    runAction(
      'create-post',
      async () => {
        await createWallPost({ guildId: composerGuildId, content });
        setPostDraft('');
      },
      t('wall.postCreated'),
    );
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

  const disabledReason = selectedScope?.id === 'global'
    ? t('wall.selectGuildToPost')
    : viewer?.canPost
      ? t('wall.guildOnly')
      : t('wall.viewOnly');

  return (
    <div className="stack guild-wall-page">
      <section className="panel guild-wall-hero">
        <div className="section-heading-row">
          <div>
            <p className="eyebrow">{t('wall.guildOnly')}</p>
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
              busyAction={busyAction}
              onCommentDraftChange={(postId, value) => setCommentDrafts((current) => ({ ...current, [postId]: value }))}
              onCommentSubmit={handleCommentSubmit}
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
              onPostReactionToggle={(postId, reactionType, active) =>
                runAction(
                  `${postId}:${reactionType}`,
                  () =>
                    active
                      ? removeWallPostReaction({ postId, reactionType })
                      : reactToWallPost({ postId, reactionType }),
                )
              }
              onCommentDelete={(commentId) => runAction(commentId, () => deleteWallComment(commentId), t('wall.commentDeleted'))}
              onCommentModerateDelete={(commentId) =>
                runAction(commentId, () => moderateDeleteWallComment(commentId), t('wall.commentDeleted'))
              }
              onCommentReactionToggle={(commentId, reactionType, active) =>
                runAction(
                  `${commentId}:${reactionType}`,
                  () =>
                    active
                      ? removeWallCommentReaction({ commentId, reactionType })
                      : reactToWallComment({ commentId, reactionType }),
                )
              }
            />
          ))
        )}
      </section>

      {posts.length > 0 ? (
        <button type="button" className="secondary-action compact-action wall-load-older" onClick={handleLoadOlder} disabled={loadingOlder}>
          {loadingOlder ? t('common.loading') : t('wall.loadOlder')}
        </button>
      ) : null}
    </div>
  );
}
