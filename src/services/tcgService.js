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

function mapPackCard(row) {
  const cardType = safeString(row?.card_type);

  return {
    cardId: row?.card_id || null,
    cardNo: safeString(row?.card_no),
    cardKey: safeString(row?.card_key),
    cardName: safeString(row?.name) || safeString(row?.card_name),
    rarityKey: safeString(row?.rarity_key),
    rarityName: safeString(row?.rarity_name),
    raritySortOrder: safeNumber(row?.rarity_sort_order),
    cardType: VALID_CARD_TYPES.has(cardType) ? cardType : 'Character',
    faction: safeString(row?.faction),
    collectorValue: safeNumber(row?.collector_value),
    artPath: safeTcgArtPath(row?.art_path),
    quantityDelta: safeNumber(row?.quantity_delta),
    previousQuantity: safeNumber(row?.previous_quantity),
    newQuantity: safeNumber(row?.new_quantity),
    isDuplicate: safeBoolean(row?.is_duplicate),
  };
}

function mapPackOpening(row) {
  const results = Array.isArray(row?.results) ? row.results : [];

  return {
    openingId: row?.opening_id || null,
    packCode: safeString(row?.pack_code),
    packName: safeString(row?.pack_name),
    cardsOpened: safeNumber(row?.cards_opened),
    createdAt: row?.created_at || null,
    results: results.map(mapPackCard).filter((card) => card.cardKey),
  };
}

function mapWallet(row) {
  return {
    profileId: row?.profile_id || null,
    currencyCode: safeString(row?.currency_code) || 'anteiku_coins',
    balance: safeNumber(row?.balance),
    updatedAt: row?.updated_at || null,
  };
}

function mapShopItem(row) {
  return {
    shopItemCode: safeString(row?.shop_item_code),
    shopItemName: safeString(row?.shop_item_name),
    description: safeString(row?.description),
    itemType: safeString(row?.item_type),
    packCode: safeString(row?.pack_code),
    packName: safeString(row?.pack_name),
    cardsPerPack: safeNumber(row?.cards_per_pack),
    currencyCode: safeString(row?.currency_code) || 'anteiku_coins',
    price: safeNumber(row?.price),
    isOwnerTestOnly: safeBoolean(row?.is_owner_test_only),
    sortOrder: safeNumber(row?.sort_order),
  };
}

function mapShopPurchase(row) {
  return {
    balanceBefore: safeNumber(row?.balance_before),
    balanceAfter: safeNumber(row?.balance_after),
    currencyCode: safeString(row?.currency_code) || 'anteiku_coins',
    shopItemCode: safeString(row?.shop_item_code),
    shopItemName: safeString(row?.shop_item_name),
    price: safeNumber(row?.price),
    opening: mapPackOpening(row),
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

export async function tcgAdminGrantCard({ targetProfileId, cardKey, quantity, reason }) {
  const normalizedTargetProfileId = safeString(targetProfileId);
  const normalizedCardKey = safeString(cardKey);
  const numericQuantity = Number(quantity);

  if (!normalizedTargetProfileId) {
    throw new Error('Target profile is required.');
  }

  if (!normalizedCardKey) {
    throw new Error('Card key is required.');
  }

  if (!Number.isInteger(numericQuantity) || numericQuantity <= 0) {
    throw new Error('Quantity must be positive.');
  }

  const client = requireSupabase();
  const { data, error } = await client.rpc('tcg_admin_grant_card', {
    p_target_profile_id: normalizedTargetProfileId,
    p_card_key: normalizedCardKey,
    p_quantity: numericQuantity,
    p_reason: safeString(reason) || null,
  });

  if (error) {
    throw error;
  }

  return Array.isArray(data)
    ? data.map((row) => ({
      profileId: row?.profile_id || normalizedTargetProfileId,
      cardKey: safeString(row?.card_key) || normalizedCardKey,
      quantityAdded: safeNumber(row?.quantity_added),
      newQuantity: safeNumber(row?.new_quantity),
      eventId: row?.event_id || null,
    }))
    : [];
}

export async function tcgOwnerOpenTestPack(packCode = 'season_0_test_pack') {
  const client = requireSupabase();
  const { data, error } = await client.rpc('tcg_owner_open_test_pack', {
    p_pack_code: safeString(packCode) || 'season_0_test_pack',
  });

  if (error) {
    throw error;
  }

  const row = Array.isArray(data) ? data[0] : data;

  return mapPackOpening(row);
}

export async function tcgGetMyWallet() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('tcg_get_my_wallet');

  if (error) {
    throw error;
  }

  const row = Array.isArray(data) ? data[0] : data;

  return mapWallet(row);
}

export async function tcgOwnerGetTestShop() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('tcg_owner_get_test_shop');

  if (error) {
    throw error;
  }

  return Array.isArray(data) ? data.map(mapShopItem).filter((item) => item.shopItemCode) : [];
}

export async function tcgOwnerGrantTestCoins(amount = 1000) {
  const numericAmount = Number(amount);

  if (!Number.isInteger(numericAmount) || numericAmount <= 0) {
    throw new Error('Grant amount must be positive.');
  }

  const client = requireSupabase();
  const { data, error } = await client.rpc('tcg_owner_grant_test_coins', {
    p_amount: numericAmount,
  });

  if (error) {
    throw error;
  }

  const row = Array.isArray(data) ? data[0] : data;

  return {
    ...mapWallet(row),
    grantedAmount: safeNumber(row?.granted_amount),
    ledgerId: row?.ledger_id || null,
  };
}

export async function tcgOwnerBuyTestPack(shopItemCode = 'season_0_test_pack_shop') {
  const client = requireSupabase();
  const { data, error } = await client.rpc('tcg_owner_buy_test_pack', {
    p_shop_item_code: safeString(shopItemCode) || 'season_0_test_pack_shop',
  });

  if (error) {
    throw error;
  }

  const row = Array.isArray(data) ? data[0] : data;

  return mapShopPurchase(row);
}
