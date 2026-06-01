import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import {
  mergeCatalogWithCollection,
  tcgAdminGrantCard,
  tcgGetCatalog,
  tcgGetMyCollection,
  tcgGetMyWallet,
  tcgOwnerOpenTestPack,
  tcgOwnerBuyTestPack,
  tcgOwnerGetTestShop,
  tcgOwnerGrantTestCoins,
  tcgSetCardFavorite,
} from '../services/tcgService.js';

const FILTERS = ['all', 'owned', 'missing', 'favorites'];
const ALL_RARITIES = 'all';
const TEST_PACK_CODE = 'season_0_test_pack';
const TEST_SHOP_ITEM_CODE = 'season_0_test_pack_shop';
const TEST_COIN_GRANT_AMOUNT = 1000;
const SMOKE_GRANT_REASON = '30C-A owner visual smoke';
const SMOKE_GRANT_CARDS = [
  { cardKey: 's0_001_20th_ward_civilian', quantity: 3 },
  { cardKey: 's0_019_anteiku_server', quantity: 2 },
  { cardKey: 's0_033_young_one_eyed_ghoul', quantity: 1 },
  { cardKey: 's0_042_half_mask_awakening', quantity: 1 },
  { cardKey: 's0_050_anteiku_origin', quantity: 1 },
];

function formatNumber(value, language) {
  const numericValue = Number(value);

  if (!Number.isFinite(numericValue)) {
    return '0';
  }

  return new Intl.NumberFormat(language).format(numericValue);
}

function getCardImage(card) {
  return card.imageUrl || card.thumbnailUrl || card.artPath || '';
}

function getDisplayError(error, fallback) {
  const message = error?.message || '';

  if (message.toLowerCase().includes('insufficient anteiku coins')) {
    return fallback;
  }

  if (
    message.includes('tcg_')
    || message.includes('function')
    || message.includes('permission')
    || message.includes('not available')
  ) {
    return fallback;
  }

  return message || fallback;
}

function getCurrencyLabel(currencyCode, t) {
  return currencyCode === 'anteiku_coins' ? t('tcg.anteikuCoins') : currencyCode;
}

function getPackResultLabel(card, t) {
  return card.isDuplicate ? t('tcg.duplicate') : t('tcg.newPull');
}

function TcgArt({ card, size = 'card' }) {
  const [failed, setFailed] = useState(false);
  const imageSrc = failed ? '' : getCardImage(card);

  useEffect(() => {
    setFailed(false);
  }, [card?.cardKey]);

  return (
    <div className="tcg-art-frame" data-size={size} data-rarity={card.rarityKey || 'common'}>
      {imageSrc ? (
        <img
          src={imageSrc}
          alt=""
          draggable="false"
          onError={() => setFailed(true)}
        />
      ) : (
        <div className="tcg-art-placeholder" aria-hidden="true">
          <span>{card.cardNo || 'S0'}</span>
          <strong>{card.rarityName || card.rarityKey}</strong>
          <em>{card.cardName}</em>
        </div>
      )}
    </div>
  );
}

function TcgPackResultCard({ card, index, language, t }) {
  const quantityDelta = Math.max(1, Number(card.quantityDelta) || 1);

  return (
    <article
      className="tcg-pack-result-card"
      data-rarity={card.rarityKey || 'common'}
      data-duplicate={card.isDuplicate}
      style={{ '--tcg-reveal-index': index }}
    >
      <TcgArt card={card} size="pack" />
      <div className="tcg-pack-result-copy">
        <div className="tcg-card-status-row">
          <span className="tcg-card-rarity">{card.rarityName || card.rarityKey}</span>
          <span className="tcg-owned-pill">{getPackResultLabel(card, t)}</span>
        </div>
        <strong>{card.cardName}</strong>
        <small>{card.cardNo}</small>
        <div className="tcg-pack-quantity-row">
          <span>{`+${formatNumber(quantityDelta, language)}`}</span>
          <span>{`x${formatNumber(card.newQuantity, language)}`}</span>
        </div>
      </div>
      <span className="tcg-pack-result-index">{`0${index + 1}`}</span>
    </article>
  );
}

function TcgPackPreviewPanel({ opening, openingError, openingLoading, language, t, onOpen }) {
  const pulledCards = opening?.results ?? [];
  const displayedCardsOpened = opening?.cardsOpened || 5;

  return (
    <section className="panel tcg-pack-panel" data-pack-mode="free" aria-label={t('tcg.testPackTitle')}>
      <div className="tcg-pack-panel-header">
        <div>
          <StatusBadge tone="warning">{t('tcg.ownerTestOnly')}</StatusBadge>
          <h3>{t('tcg.testPackTitle')}</h3>
          <p>{t('tcg.testPackSubtitle')}</p>
        </div>
        <button
          type="button"
          className="primary-action compact-action tcg-open-pack-button"
          onClick={onOpen}
          disabled={openingLoading}
          aria-busy={openingLoading}
        >
          {openingLoading ? t('tcg.openingPack') : t('tcg.openTestPack')}
        </button>
      </div>

      <div className="tcg-pack-facts" aria-label={t('tcg.packPreview')}>
        <span>{t('tcg.containsFiveCards')}</span>
        <span>{t('tcg.backendDecidesDrops')}</span>
        <span>{t('tcg.comingSoon')}</span>
      </div>

      {openingError ? (
        <p className="tcg-pack-error" role="alert">
          {openingError}
        </p>
      ) : null}

      {opening ? (
        <div className="tcg-pack-result-shell" data-revealed={pulledCards.length > 0} data-result-mode="free">
          <div className="tcg-pack-result-heading">
            <div>
              <StatusBadge tone="success">{t('tcg.packOpened')}</StatusBadge>
              <h4>{opening.packName || t('tcg.testPackTitle')}</h4>
            </div>
            <span>{`${t('tcg.cardsPulled')} ${formatNumber(displayedCardsOpened, language)}`}</span>
          </div>

          <div className="tcg-pack-results-grid" aria-label={t('tcg.cardsPulled')}>
            {pulledCards.map((card, index) => (
              <TcgPackResultCard
                key={`${opening.openingId || opening.packCode}-${card.cardKey}-${index}`}
                card={card}
                index={index}
                language={language}
                t={t}
              />
            ))}
          </div>
        </div>
      ) : (
        <p className="tcg-pack-preview-note">{t('tcg.ownerTestOnlyBody')}</p>
      )}
    </section>
  );
}

function TcgShopPreviewPanel({
  wallet,
  shopItems,
  purchase,
  loading,
  error,
  grantLoading,
  grantMessage,
  purchaseLoadingCode,
  language,
  t,
  onGrantCoins,
  onBuyPack,
}) {
  const displayedWallet = wallet ?? { balance: 0, currencyCode: 'anteiku_coins' };
  const currencyLabel = getCurrencyLabel(displayedWallet.currencyCode, t);
  const pulledCards = purchase?.opening?.results ?? [];
  const displayedCardsOpened = purchase?.opening?.cardsOpened || 5;

  return (
    <section className="panel tcg-shop-panel" data-loading={loading || grantLoading || Boolean(purchaseLoadingCode)} aria-label={t('tcg.shopTestTitle')}>
      <div className="tcg-shop-header">
        <div>
          <StatusBadge tone="warning">{t('tcg.ownerTestOnly')}</StatusBadge>
          <h3>{t('tcg.shopTestTitle')}</h3>
          <p>{t('tcg.shopTestBody')}</p>
        </div>
        <div className="tcg-wallet-card" aria-label={t('tcg.walletBalance')}>
          <i aria-hidden="true" />
          <span>{t('tcg.walletBalance')}</span>
          <strong>{formatNumber(displayedWallet.balance, language)}</strong>
          <small>{currencyLabel}</small>
        </div>
      </div>

      <div className="tcg-shop-dev-row">
        <div>
          <strong>{t('tcg.ownerShopPreview')}</strong>
          <span>{t('tcg.backendHandlesPurchaseDrops')}</span>
        </div>
        <button
          type="button"
          className="danger-action compact-action"
          onClick={onGrantCoins}
          disabled={loading || grantLoading}
          aria-busy={grantLoading}
        >
          {grantLoading ? t('common.working') : t('tcg.grantTestCoins')}
        </button>
      </div>

      {grantMessage ? <p className="success-copy">{grantMessage}</p> : null}
      {error ? <p className="tcg-pack-error" role="alert">{error}</p> : null}

      <div className="tcg-shop-list" aria-label={t('tcg.ownerShopPreview')}>
        {shopItems.length > 0 ? (
          shopItems.map((item) => (
            <article className="tcg-shop-item" key={item.shopItemCode} data-buying={purchaseLoadingCode === item.shopItemCode}>
              <div className="tcg-shop-item-main">
                <StatusBadge tone="warning">{t('tcg.ownerTestOnly')}</StatusBadge>
                <h4>{item.shopItemName || t('tcg.seasonZeroTestPack')}</h4>
                <p>{item.description || t('tcg.containsFiveBackendCards')}</p>
              </div>

              <div className="tcg-shop-item-buy">
                <span>{t('tcg.price')}</span>
                <strong>
                  {formatNumber(item.price, language)} {getCurrencyLabel(item.currencyCode, t)}
                </strong>
                <button
                  type="button"
                  className="primary-action compact-action"
                  onClick={() => onBuyPack(item.shopItemCode)}
                  disabled={loading || Boolean(purchaseLoadingCode)}
                  aria-busy={purchaseLoadingCode === item.shopItemCode}
                >
                  {purchaseLoadingCode === item.shopItemCode ? t('tcg.buyingPack') : t('tcg.buyTestPack')}
                </button>
              </div>
            </article>
          ))
        ) : (
          <p className="tcg-pack-preview-note">{loading ? t('common.loading') : t('tcg.shopComingSoon')}</p>
        )}
      </div>

      {purchase ? (
        <div className="tcg-pack-result-shell" data-revealed={pulledCards.length > 0} data-result-mode="shop">
          <div className="tcg-pack-result-heading">
            <div>
              <StatusBadge tone="success">{t('tcg.purchaseComplete')}</StatusBadge>
              <h4>{purchase.shopItemName || purchase.opening?.packName || t('tcg.seasonZeroTestPack')}</h4>
            </div>
            <span>
              {formatNumber(purchase.balanceBefore, language)} - {formatNumber(purchase.price, language)}
              {' = '}
              {formatNumber(purchase.balanceAfter, language)}
            </span>
          </div>

          <div className="tcg-pack-results-grid" aria-label={t('tcg.cardsPulled')}>
            {pulledCards.map((card, index) => (
              <TcgPackResultCard
                key={`${purchase.opening?.openingId || purchase.shopItemCode}-${card.cardKey}-${index}`}
                card={card}
                index={index}
                language={language}
                t={t}
              />
            ))}
          </div>

          <p className="tcg-pack-preview-note">
            {`${t('tcg.cardsPulled')} ${formatNumber(displayedCardsOpened, language)}`}
          </p>
        </div>
      ) : null}
    </section>
  );
}

function TcgCard({ card, language, t, onSelect, onToggleFavorite, favoriteBusy }) {
  const owned = card.isOwned && card.quantity > 0;
  const valueLabel = formatNumber(card.collectorValue, language);
  const quantityLabel = formatNumber(card.quantity, language);

  return (
    <article
      className="tcg-card"
      data-owned={owned}
      data-favorite={card.isFavorite}
      data-rarity={card.rarityKey || 'common'}
    >
      <button type="button" className="tcg-card-open" onClick={() => onSelect(card)}>
        <TcgArt card={card} />
        <span className="tcg-card-status-row">
          <span className="tcg-card-rarity">{card.rarityName || card.rarityKey}</span>
          <span className="tcg-owned-pill">{owned ? `x${quantityLabel}` : t('tcg.notOwnedYet')}</span>
        </span>
        <strong>{card.cardName}</strong>
        <small>{card.cardNo}</small>
      </button>

      <div className="tcg-card-meta">
        <span>{`${t('tcg.collectorValue')} ${valueLabel}`}</span>
      </div>

      {owned ? (
        <button
          type="button"
          className="tcg-favorite-button"
          data-active={card.isFavorite}
          disabled={favoriteBusy}
          aria-label={`${card.isFavorite ? t('tcg.favorite') : t('tcg.markFavorite')}: ${card.cardName}`}
          onClick={() => onToggleFavorite(card)}
        >
          {card.isFavorite ? t('tcg.favorite') : t('tcg.markFavorite')}
        </button>
      ) : null}
    </article>
  );
}

function TcgDetailSheet({ card, language, t, onClose, onToggleFavorite, favoriteBusy }) {
  if (!card) {
    return null;
  }

  const owned = card.isOwned && card.quantity > 0;

  return (
    <div className="tcg-detail-backdrop" role="presentation" onClick={onClose}>
      <section
        className="tcg-detail-sheet"
        data-rarity={card.rarityKey || 'common'}
        data-owned={owned}
        role="dialog"
        aria-modal="true"
        aria-label={card.cardName}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="tcg-detail-header">
          <div>
            <StatusBadge tone={owned ? 'success' : 'neutral'}>
              {owned ? `${t('tcg.quantity')} ${formatNumber(card.quantity, language)}` : t('tcg.notOwnedYet')}
            </StatusBadge>
            <h3>{card.cardName}</h3>
            <p>{card.cardNo}</p>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={onClose}>
            {t('common.close')}
          </button>
        </div>

        <TcgArt card={card} size="detail" />

        <div className="tcg-detail-stats">
          <div>
            <span>{t('tcg.rarity')}</span>
            <strong>{card.rarityName || card.rarityKey}</strong>
          </div>
          <div>
            <span>{t('tcg.type')}</span>
            <strong>{card.cardType}</strong>
          </div>
          <div>
            <span>{t('tcg.faction')}</span>
            <strong>{card.faction || t('common.notSet')}</strong>
          </div>
          <div>
            <span>{t('tcg.collectorValue')}</span>
            <strong>{formatNumber(card.collectorValue, language)}</strong>
          </div>
        </div>

        <p className="tcg-card-flavor">{card.rarityStyleSummary || t('tcg.comingSoon')}</p>

        {owned ? (
          <button
            type="button"
            className="primary-action tcg-detail-favorite"
            data-active={card.isFavorite}
            disabled={favoriteBusy}
            onClick={() => onToggleFavorite(card)}
          >
            {card.isFavorite ? t('tcg.favorite') : t('tcg.markFavorite')}
          </button>
        ) : (
          <p className="compact-state-line">{t('tcg.notOwnedYet')}</p>
        )}
      </section>
    </div>
  );
}

export function TcgCollection({ activeAdminContext, activeAdminContextLoading }) {
  const { language, t } = useLanguage();
  const [cards, setCards] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('all');
  const [rarityFilter, setRarityFilter] = useState(ALL_RARITIES);
  const [selectedCard, setSelectedCard] = useState(null);
  const [favoriteBusyKey, setFavoriteBusyKey] = useState('');
  const [smokeGrantLoading, setSmokeGrantLoading] = useState(false);
  const [smokeGrantMessage, setSmokeGrantMessage] = useState('');
  const [packOpeningLoading, setPackOpeningLoading] = useState(false);
  const [packOpening, setPackOpening] = useState(null);
  const [packOpeningError, setPackOpeningError] = useState('');
  const [wallet, setWallet] = useState(null);
  const [shopItems, setShopItems] = useState([]);
  const [economyLoading, setEconomyLoading] = useState(false);
  const [economyError, setEconomyError] = useState('');
  const [grantCoinsLoading, setGrantCoinsLoading] = useState(false);
  const [grantCoinsMessage, setGrantCoinsMessage] = useState('');
  const [purchaseLoadingCode, setPurchaseLoadingCode] = useState('');
  const [shopPurchase, setShopPurchase] = useState(null);
  const favoriteRequestKeysRef = useRef(new Set());
  const smokeGrantRequestRef = useRef(false);
  const packOpeningRequestRef = useRef(false);
  const grantCoinsRequestRef = useRef(false);
  const buyPackRequestRef = useRef(false);

  const isOwner = Boolean(activeAdminContext?.isOwner);
  const activeOwnerProfileId = isOwner ? activeAdminContext?.activeProfileId : null;

  const loadCards = useCallback(async () => {
    if (!isOwner) {
      return;
    }

    setLoading(true);
    setError('');

    try {
      const [catalogRows, collectionRows] = await Promise.all([
        tcgGetCatalog(),
        tcgGetMyCollection(),
      ]);
      setCards(mergeCatalogWithCollection(catalogRows, collectionRows));
    } catch (loadError) {
      setCards([]);
      setError(getDisplayError(loadError, t('tcg.backendUnavailable')));
    } finally {
      setLoading(false);
    }
  }, [isOwner, t]);

  useEffect(() => {
    loadCards();
  }, [loadCards]);

  const loadEconomy = useCallback(async () => {
    if (!isOwner) {
      return;
    }

    setEconomyLoading(true);
    setEconomyError('');

    try {
      const [walletRow, shopRows] = await Promise.all([
        tcgGetMyWallet(),
        tcgOwnerGetTestShop(),
      ]);
      setWallet(walletRow);
      setShopItems(shopRows);
    } catch (loadError) {
      setWallet(null);
      setShopItems([]);
      setEconomyError(getDisplayError(loadError, t('tcg.shopLoadFailed')));
    } finally {
      setEconomyLoading(false);
    }
  }, [isOwner, t]);

  useEffect(() => {
    loadEconomy();
  }, [loadEconomy]);

  const rarityOptions = useMemo(() => {
    const seen = new Map();

    cards.forEach((card) => {
      if (!card.rarityKey || seen.has(card.rarityKey)) {
        return;
      }

      seen.set(card.rarityKey, {
        key: card.rarityKey,
        label: card.rarityName || card.rarityKey,
        sortOrder: card.raritySortOrder,
      });
    });

    return Array.from(seen.values()).sort((a, b) => a.sortOrder - b.sortOrder);
  }, [cards]);

  const progress = useMemo(() => {
    const ownedCards = cards.filter((card) => card.isOwned && card.quantity > 0);

    return {
      totalCards: cards.length,
      ownedUnique: ownedCards.length,
      totalQuantity: ownedCards.reduce((sum, card) => sum + card.quantity, 0),
      favorites: ownedCards.filter((card) => card.isFavorite).length,
    };
  }, [cards]);

  const smokeGrantSatisfied = useMemo(
    () =>
      SMOKE_GRANT_CARDS.every((grant) => {
        const card = cards.find((currentCard) => currentCard.cardKey === grant.cardKey);
        return card?.quantity >= grant.quantity;
      }),
    [cards],
  );

  const visibleCards = useMemo(
    () =>
      cards.filter((card) => {
        const owned = card.isOwned && card.quantity > 0;

        if (filter === 'owned' && !owned) {
          return false;
        }

        if (filter === 'missing' && owned) {
          return false;
        }

        if (filter === 'favorites' && !card.isFavorite) {
          return false;
        }

        if (rarityFilter !== ALL_RARITIES && card.rarityKey !== rarityFilter) {
          return false;
        }

        return true;
      }),
    [cards, filter, rarityFilter],
  );

  const handleToggleFavorite = useCallback(async (card) => {
    if (!card?.cardKey || !card.isOwned || card.quantity <= 0) {
      return;
    }

    if (favoriteRequestKeysRef.current.has(card.cardKey)) {
      return;
    }

    const nextFavorite = !card.isFavorite;
    favoriteRequestKeysRef.current.add(card.cardKey);
    setFavoriteBusyKey(card.cardKey);
    setError('');

    try {
      const result = await tcgSetCardFavorite(card.cardKey, nextFavorite);
      const updateCard = (currentCard) =>
        currentCard.cardKey === result.cardKey
          ? { ...currentCard, isFavorite: result.isFavorite }
          : currentCard;

      setCards((currentCards) => currentCards.map(updateCard));
      setSelectedCard((currentCard) => (currentCard ? updateCard(currentCard) : currentCard));
    } catch (favoriteError) {
      setError(getDisplayError(favoriteError, t('tcg.backendUnavailable')));
    } finally {
      favoriteRequestKeysRef.current.delete(card.cardKey);
      setFavoriteBusyKey('');
    }
  }, [t]);

  const handleSmokeGrant = useCallback(async () => {
    if (!isOwner || !activeOwnerProfileId) {
      return;
    }

    if (smokeGrantRequestRef.current) {
      return;
    }

    smokeGrantRequestRef.current = true;
    const confirmed = window.confirm(t('tcg.smokeGrantConfirm'));

    if (!confirmed) {
      smokeGrantRequestRef.current = false;
      return;
    }

    setSmokeGrantLoading(true);
    setSmokeGrantMessage('');
    setError('');

    try {
      for (const grant of SMOKE_GRANT_CARDS) {
        await tcgAdminGrantCard({
          targetProfileId: activeOwnerProfileId,
          cardKey: grant.cardKey,
          quantity: grant.quantity,
          reason: SMOKE_GRANT_REASON,
        });
      }

      setSmokeGrantMessage(t('tcg.smokeGrantSuccess'));
      await loadCards();
      setFilter('owned');
      setRarityFilter(ALL_RARITIES);
    } catch (grantError) {
      setError(getDisplayError(grantError, t('tcg.smokeGrantError')));
    } finally {
      smokeGrantRequestRef.current = false;
      setSmokeGrantLoading(false);
    }
  }, [activeOwnerProfileId, isOwner, loadCards, t]);

  const handleOpenTestPack = useCallback(async () => {
    if (!isOwner) {
      return;
    }

    if (packOpeningRequestRef.current) {
      return;
    }

    packOpeningRequestRef.current = true;
    setPackOpeningLoading(true);
    setPackOpeningError('');
    setError('');

    try {
      const opening = await tcgOwnerOpenTestPack(TEST_PACK_CODE);
      setPackOpening(opening);
      await loadCards();
      setFilter('owned');
      setRarityFilter(ALL_RARITIES);
    } catch (openingError) {
      setPackOpeningError(getDisplayError(openingError, t('tcg.packOpeningFailed')));
    } finally {
      packOpeningRequestRef.current = false;
      setPackOpeningLoading(false);
    }
  }, [isOwner, loadCards, t]);

  const handleGrantTestCoins = useCallback(async () => {
    if (!isOwner) {
      return;
    }

    if (grantCoinsRequestRef.current) {
      return;
    }

    grantCoinsRequestRef.current = true;
    setGrantCoinsLoading(true);
    setGrantCoinsMessage('');
    setEconomyError('');

    try {
      const nextWallet = await tcgOwnerGrantTestCoins(TEST_COIN_GRANT_AMOUNT);
      setWallet(nextWallet);
      setGrantCoinsMessage(t('tcg.testCoinsGranted'));
      await loadEconomy();
    } catch (grantError) {
      setEconomyError(getDisplayError(grantError, t('tcg.grantFailed')));
    } finally {
      grantCoinsRequestRef.current = false;
      setGrantCoinsLoading(false);
    }
  }, [isOwner, loadEconomy, t]);

  const handleBuyTestPack = useCallback(async (shopItemCode = TEST_SHOP_ITEM_CODE) => {
    if (!isOwner) {
      return;
    }

    if (buyPackRequestRef.current) {
      return;
    }

    buyPackRequestRef.current = true;
    setPurchaseLoadingCode(shopItemCode);
    setEconomyError('');
    setGrantCoinsMessage('');

    try {
      const purchaseResult = await tcgOwnerBuyTestPack(shopItemCode);
      setShopPurchase(purchaseResult);
      await Promise.all([loadEconomy(), loadCards()]);
      setFilter('owned');
      setRarityFilter(ALL_RARITIES);
    } catch (purchaseError) {
      const message = purchaseError?.message?.toLowerCase() || '';
      setEconomyError(
        message.includes('insufficient anteiku coins')
          ? t('tcg.insufficientBalance')
          : getDisplayError(purchaseError, t('tcg.purchaseFailed')),
      );
    } finally {
      buyPackRequestRef.current = false;
      setPurchaseLoadingCode('');
    }
  }, [isOwner, loadCards, loadEconomy, t]);

  if (activeAdminContextLoading) {
    return (
      <div className="stack">
        <section className="panel hero-panel tcg-hero">
          <StatusBadge tone="warning">{t('tcg.ownerPreview')}</StatusBadge>
          <h3>{t('common.loading')}</h3>
          <p>{t('app.loadingBody')}</p>
        </section>
      </div>
    );
  }

  if (!isOwner) {
    return (
      <div className="stack">
        <section className="panel hero-panel tcg-hero">
          <StatusBadge tone="warning">{t('tcg.ownerPreview')}</StatusBadge>
          <h3>{t('tcg.accessDenied')}</h3>
          <p>{t('tcg.ownerOnlyBody')}</p>
        </section>
      </div>
    );
  }

  return (
    <div className="stack tcg-page">
      <section className="panel hero-panel tcg-hero">
        <div className="section-heading-row">
          <div>
            <StatusBadge tone="warning">{t('tcg.ownerPreview')}</StatusBadge>
            <h3>{t('tcg.title')}</h3>
            <p>{t('tcg.subtitle')}</p>
          </div>
          <button type="button" className="secondary-action compact-action" onClick={loadCards} disabled={loading}>
            {loading ? t('common.refreshing') : t('common.refresh')}
          </button>
        </div>
      </section>

      <section className="panel tcg-smoke-panel" aria-label={t('tcg.smokeGrantTitle')}>
        <div>
          <StatusBadge tone="warning">{t('tcg.ownerPreview')}</StatusBadge>
          <h3>{t('tcg.smokeGrantTitle')}</h3>
          <p>{t('tcg.smokeGrantBody')}</p>
        </div>
        <button
          type="button"
          className="danger-action compact-action"
          onClick={handleSmokeGrant}
          disabled={smokeGrantLoading || !activeOwnerProfileId || smokeGrantSatisfied}
        >
          {smokeGrantLoading
            ? t('common.working')
            : smokeGrantSatisfied
              ? t('tcg.smokeGrantReady')
              : t('tcg.smokeGrantButton')}
        </button>
        {smokeGrantMessage ? <p className="success-copy">{smokeGrantMessage}</p> : null}
      </section>

      <TcgPackPreviewPanel
        opening={packOpening}
        openingError={packOpeningError}
        openingLoading={packOpeningLoading}
        language={language}
        t={t}
        onOpen={handleOpenTestPack}
      />

      <TcgShopPreviewPanel
        wallet={wallet}
        shopItems={shopItems}
        purchase={shopPurchase}
        loading={economyLoading}
        error={economyError}
        grantLoading={grantCoinsLoading}
        grantMessage={grantCoinsMessage}
        purchaseLoadingCode={purchaseLoadingCode}
        language={language}
        t={t}
        onGrantCoins={handleGrantTestCoins}
        onBuyPack={handleBuyTestPack}
      />

      <section className="tcg-progress-grid" aria-label={t('tcg.collectionProgress')}>
        <div className="tcg-progress-card">
          <span>{t('tcg.uniqueOwned')}</span>
          <strong>
            {formatNumber(progress.ownedUnique, language)} / {formatNumber(progress.totalCards, language)}
          </strong>
        </div>
        <div className="tcg-progress-card">
          <span>{t('tcg.totalOwnedQuantity')}</span>
          <strong>{formatNumber(progress.totalQuantity, language)}</strong>
        </div>
        <div className="tcg-progress-card">
          <span>{t('tcg.favorites')}</span>
          <strong>{formatNumber(progress.favorites, language)}</strong>
        </div>
      </section>

      <section className="panel tcg-controls">
        <div className="tcg-filter-row" role="tablist" aria-label={t('tcg.collectionFilters')}>
          {FILTERS.map((filterKey) => (
            <button
              key={filterKey}
              type="button"
              className="tcg-filter-chip"
              data-active={filter === filterKey}
              onClick={() => setFilter(filterKey)}
            >
              {t(`tcg.filters.${filterKey}`)}
            </button>
          ))}
        </div>

        <label className="tcg-rarity-select">
          <span>{t('tcg.rarity')}</span>
          <select value={rarityFilter} onChange={(event) => setRarityFilter(event.target.value)}>
            <option value={ALL_RARITIES}>{t('tcg.filters.all')}</option>
            {rarityOptions.map((rarity) => (
              <option key={rarity.key} value={rarity.key}>
                {rarity.label}
              </option>
            ))}
          </select>
        </label>
      </section>

      {error ? (
        <section className="panel compact-empty-state" role="alert">
          <h3>{t('common.error')}</h3>
          <p>{error}</p>
        </section>
      ) : null}

      {!loading && !error && visibleCards.length === 0 ? (
        <section className="panel compact-empty-state">
          <h3>{t('tcg.noCards')}</h3>
          <p>{t('tcg.noCardsBody')}</p>
        </section>
      ) : null}

      <section className="tcg-card-grid" aria-label={t('tcg.title')}>
        {visibleCards.map((card) => (
          <TcgCard
            key={card.cardKey}
            card={card}
            language={language}
            t={t}
            favoriteBusy={favoriteBusyKey === card.cardKey}
            onSelect={setSelectedCard}
            onToggleFavorite={handleToggleFavorite}
          />
        ))}
      </section>

      <TcgDetailSheet
        card={selectedCard}
        language={language}
        t={t}
        favoriteBusy={favoriteBusyKey === selectedCard?.cardKey}
        onClose={() => setSelectedCard(null)}
        onToggleFavorite={handleToggleFavorite}
      />
    </div>
  );
}
