import { supabase } from '../config/supabaseClient.js';

const SAFE_TCG_ART_PREFIX = '/assets/tcg/art/';
const VALID_CARD_TYPES = new Set(['Character', 'Organization', 'Scene', 'Relic']);

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

function safeTcgArtPath(value) {
  const path = safeString(value);

  if (!path.startsWith(SAFE_TCG_ART_PREFIX) || path.includes('..')) {
    return '';
  }

  return path;
}

function mapCard(row) {
  const cardType = safeString(row?.card_type);

  return {
    cardId: row?.card_id || null,
    setKey: safeString(row?.set_key),
    setName: safeString(row?.set_name),
    cardNo: safeString(row?.card_no),
    cardKey: safeString(row?.card_key),
    cardName: safeString(row?.card_name),
    rarityKey: safeString(row?.rarity_key),
    rarityName: safeString(row?.rarity_name),
    raritySortOrder: safeNumber(row?.rarity_sort_order),
    rarityDisplayTier: safeNumber(row?.rarity_display_tier),
    rarityStyleSummary: safeString(row?.rarity_style_summary),
    rarityStylePromptPrefix: safeString(row?.rarity_style_prompt_prefix),
    cardType: VALID_CARD_TYPES.has(cardType) ? cardType : 'Character',
    subjectOrCharacter: safeString(row?.subject_or_character),
    faction: safeString(row?.faction),
    collectorValue: safeNumber(row?.collector_value),
    artPath: safeTcgArtPath(row?.art_path),
    imageUrl: safeString(row?.image_url),
    thumbnailUrl: safeString(row?.thumbnail_url),
    sortOrder: safeNumber(row?.sort_order),
    quantity: safeNumber(row?.quantity),
    isOwned: safeBoolean(row?.is_owned) || safeNumber(row?.quantity) > 0,
    isFavorite: safeBoolean(row?.is_favorite),
    isLocked: safeBoolean(row?.is_locked),
    firstAcquiredAt: row?.first_acquired_at || null,
    lastAcquiredAt: row?.last_acquired_at || null,
    inventoryUpdatedAt: row?.inventory_updated_at || null,
  };
}

export function mergeCatalogWithCollection(catalogRows, collectionRows) {
  const collectionByKey = new Map(
    collectionRows
      .filter((card) => card.cardKey)
      .map((card) => [card.cardKey, card]),
  );

  return catalogRows
    .map((catalogCard) => ({
      ...catalogCard,
      ...(collectionByKey.get(catalogCard.cardKey) ?? {}),
      cardId: catalogCard.cardId,
      cardKey: catalogCard.cardKey,
      cardNo: catalogCard.cardNo,
      cardName: catalogCard.cardName,
      setKey: catalogCard.setKey,
      setName: catalogCard.setName,
      rarityKey: catalogCard.rarityKey,
      rarityName: catalogCard.rarityName,
      raritySortOrder: catalogCard.raritySortOrder,
      rarityDisplayTier: catalogCard.rarityDisplayTier,
      rarityStyleSummary: catalogCard.rarityStyleSummary,
      rarityStylePromptPrefix: catalogCard.rarityStylePromptPrefix,
      cardType: catalogCard.cardType,
      subjectOrCharacter: catalogCard.subjectOrCharacter,
      faction: catalogCard.faction,
      collectorValue: catalogCard.collectorValue,
      artPath: catalogCard.artPath,
      imageUrl: catalogCard.imageUrl,
      thumbnailUrl: catalogCard.thumbnailUrl,
      sortOrder: catalogCard.sortOrder,
    }))
    .sort((a, b) => (a.sortOrder - b.sortOrder) || a.cardNo.localeCompare(b.cardNo));
}

export async function tcgGetCatalog() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('tcg_get_catalog');

  if (error) {
    throw error;
  }

  return Array.isArray(data) ? data.map(mapCard).filter((card) => card.cardKey) : [];
}

export async function tcgGetMyCollection() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('tcg_get_my_collection');

  if (error) {
    throw error;
  }

  return Array.isArray(data) ? data.map(mapCard).filter((card) => card.cardKey) : [];
}

export async function tcgSetCardFavorite(cardKey, isFavorite) {
  const normalizedCardKey = safeString(cardKey);

  if (!normalizedCardKey) {
    throw new Error('Card key is required.');
  }

  const client = requireSupabase();
  const { data, error } = await client.rpc('tcg_set_card_favorite', {
    p_card_key: normalizedCardKey,
    p_is_favorite: Boolean(isFavorite),
  });

  if (error) {
    throw error;
  }

  const row = Array.isArray(data) ? data[0] : data;

  return {
    cardKey: safeString(row?.card_key) || normalizedCardKey,
    isFavorite: safeBoolean(row?.is_favorite),
    updatedAt: row?.updated_at || null,
  };
}
