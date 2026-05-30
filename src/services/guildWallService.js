import { supabase } from '../config/supabaseClient.js';

const SAFE_AVATAR_PREFIX = '/cosmetics/avatars/';
const SAFE_FRAME_PREFIX = '/cosmetics/frames/';
export const WALL_REACTION_TYPES = ['like', 'fire', 'coffee', 'skull', 'trophy'];

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function safeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function safeNumber(value) {
  if (value === null || value === undefined || value === '') {
    return 0;
  }

  const nextValue = Number(value);
  return Number.isFinite(nextValue) ? nextValue : 0;
}

function safeBoolean(value) {
  return Boolean(value);
}

function safeAssetPath(value, type) {
  const path = safeString(value);
  const prefix = type === 'frame' ? SAFE_FRAME_PREFIX : SAFE_AVATAR_PREFIX;

  if (!path.startsWith(prefix) || path.includes('..')) {
    return '';
  }

  return path;
}

function mapCosmetics(row) {
  return {
    avatar: {
      key: safeString(row?.avatar_key),
      assetPath: safeAssetPath(row?.avatar_asset_path, 'avatar'),
    },
    frame: {
      key: safeString(row?.frame_key),
      assetPath: safeAssetPath(row?.frame_asset_path, 'frame'),
    },
  };
}

function mapReaction(row) {
  const type = safeString(row?.type);

  return {
    type: WALL_REACTION_TYPES.includes(type) ? type : '',
    count: safeNumber(row?.count),
    reactedByMe: safeBoolean(row?.reacted_by_me),
  };
}

function mapAuthor(row) {
  return {
    profileId: row?.author_profile_id || null,
    username: safeString(row?.author_username),
    profileSlug: safeString(row?.author_profile_slug),
    ign: safeString(row?.author_ign),
    ...mapCosmetics(row),
  };
}

function mapComment(row) {
  return {
    id: row?.id || null,
    postId: row?.post_id || null,
    guildId: row?.guild_id || null,
    content: safeString(row?.content),
    createdAt: row?.created_at || null,
    updatedAt: row?.updated_at || null,
    canDelete: safeBoolean(row?.can_delete),
    canModerate: safeBoolean(row?.can_moderate),
    author: mapAuthor(row),
    reactions: Array.isArray(row?.reactions) ? row.reactions.map(mapReaction).filter((reaction) => reaction.type) : [],
  };
}

function mapPost(row) {
  return {
    id: row?.id || null,
    guildId: row?.guild_id || null,
    guildName: safeString(row?.guild_name),
    guildSlug: safeString(row?.guild_slug),
    authorGuildId: row?.author_guild_id || null,
    authorGuildName: safeString(row?.author_guild_name),
    authorGuildSlug: safeString(row?.author_guild_slug),
    isGlobal: safeBoolean(row?.is_global),
    content: safeString(row?.content),
    isPinned: safeBoolean(row?.is_pinned),
    isLocked: safeBoolean(row?.is_locked),
    createdAt: row?.created_at || null,
    updatedAt: row?.updated_at || null,
    canDelete: safeBoolean(row?.can_delete),
    canModerate: safeBoolean(row?.can_moderate),
    author: mapAuthor(row),
    reactions: Array.isArray(row?.reactions) ? row.reactions.map(mapReaction).filter((reaction) => reaction.type) : [],
    comments: Array.isArray(row?.comments) ? row.comments.map(mapComment).filter((comment) => comment.id) : [],
  };
}

function mapViewer(row) {
  return {
    profileId: row?.profile_id || null,
    scopeGuildId: row?.scope_guild_id || null,
    scopeGuildName: safeString(row?.scope_guild_name),
    scopeGuildSlug: safeString(row?.scope_guild_slug),
    isGlobal: safeBoolean(row?.is_global),
    canPost: safeBoolean(row?.can_post),
    canModerate: safeBoolean(row?.can_moderate),
  };
}

export function getReactionCount(reactions, type) {
  return reactions.find((reaction) => reaction.type === type)?.count ?? 0;
}

export function hasMyReaction(reactions, type) {
  return Boolean(reactions.find((reaction) => reaction.type === type)?.reactedByMe);
}

export async function loadGuildWallFeed({ guildId = null, limit = 20, before = null } = {}) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_guild_wall_feed', {
    p_guild_id: guildId || null,
    p_limit: limit,
    p_before: before || null,
  });

  if (error) {
    throw error;
  }

  return {
    viewer: mapViewer(data?.viewer),
    posts: Array.isArray(data?.posts) ? data.posts.map(mapPost).filter((post) => post.id) : [],
  };
}

export async function createWallPost({ guildId, content }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('create_wall_post', {
    p_guild_id: guildId || null,
    p_content: content,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function deleteWallPost(postId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('delete_wall_post', {
    p_post_id: postId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function moderateDeleteWallPost(postId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('moderate_delete_wall_post', {
    p_post_id: postId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function pinWallPost(postId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('pin_wall_post', {
    p_post_id: postId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function unpinWallPost(postId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('unpin_wall_post', {
    p_post_id: postId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function createWallComment({ postId, content }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('create_wall_comment', {
    p_post_id: postId,
    p_content: content,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function deleteWallComment(commentId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('delete_wall_comment', {
    p_comment_id: commentId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function moderateDeleteWallComment(commentId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('moderate_delete_wall_comment', {
    p_comment_id: commentId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function reactToWallPost({ postId, reactionType }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('react_to_wall_post', {
    p_post_id: postId,
    p_reaction_type: reactionType,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function removeWallPostReaction({ postId, reactionType }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('remove_wall_post_reaction', {
    p_post_id: postId,
    p_reaction_type: reactionType,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function reactToWallComment({ commentId, reactionType }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('react_to_wall_comment', {
    p_comment_id: commentId,
    p_reaction_type: reactionType,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function removeWallCommentReaction({ commentId, reactionType }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('remove_wall_comment_reaction', {
    p_comment_id: commentId,
    p_reaction_type: reactionType,
  });

  if (error) {
    throw error;
  }

  return data;
}
