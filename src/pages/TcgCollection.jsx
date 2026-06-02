import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import {
  mergeCatalogWithCollection,
  tcgAdminGrantCard,
  tcgGetCatalog,
  tcgGetMyCollection,
  tcgGetMyPacks,
  tcgGetMyWallet,
  tcgOwnerOpenTestPack,
  tcgOwnerBuyTestPackToInventory,
  tcgOwnerGetTestShop,
  tcgOwnerGrantTestCoins,
  tcgOwnerOpenOwnedPack,
  tcgSetCardFavorite,
} from '../services/tcgService.js';

const FILTERS = ['all', 'owned', 'missing', 'favorites'];
const HUB_WINDOWS = ['album', 'packs', 'shop', 'ownerLab'];
const ALL_RARITIES = 'all';
const TEST_PACK_CODE = 'season_0_test_pack';
const TEST_SHOP_ITEM_CODE = 'season_0_test_pack_shop';
const TEST_COIN_GRANT_AMOUNT = 1000;
const PACK_ANIMATION_STORAGE_KEY = 'anteiku.tcg.packAnimationsEnabled';
const PACK_FRONT_ASSET_PATH = '/assets/tcg/packs/season0_test_pack_front.png';
const CARD_BACK_ASSET_PATH = '/assets/tcg/cards/tcg_card_back_season0.png';
const transparentPackAssetCache = new Map();
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

function readPackAnimationSetting() {
  if (typeof window === 'undefined') {
    return true;
  }

  return window.localStorage.getItem(PACK_ANIMATION_STORAGE_KEY) !== 'false';
}

function isEdgeBlackPixel(data, offset) {
  return data[offset + 3] > 0
    && data[offset] <= 14
    && data[offset + 1] <= 14
    && data[offset + 2] <= 14;
}

function useEdgeTransparentImage(src) {
  const [processedSrc, setProcessedSrc] = useState('');

  useEffect(() => {
    if (!src || typeof window === 'undefined') {
      setProcessedSrc('');
      return undefined;
    }

    const cached = transparentPackAssetCache.get(src);
    if (cached) {
      setProcessedSrc(cached);
      return undefined;
    }

    let cancelled = false;
    const image = new Image();

    image.onload = () => {
      try {
        const canvas = document.createElement('canvas');
        canvas.width = image.naturalWidth;
        canvas.height = image.naturalHeight;
        const context = canvas.getContext('2d', { willReadFrequently: true });

        if (!context) {
          throw new Error('Canvas unavailable');
        }

        context.drawImage(image, 0, 0);
        const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
        const { data } = imageData;
        const { width, height } = canvas;
        const visited = new Uint8Array(width * height);
        const stack = [];
        const pushPixel = (x, y) => {
          if (x < 0 || y < 0 || x >= width || y >= height) {
            return;
          }

          const index = y * width + x;
          if (visited[index]) {
            return;
          }

          const offset = index * 4;
          if (!isEdgeBlackPixel(data, offset)) {
            return;
          }

          visited[index] = 1;
          stack.push(index);
        };

        for (let x = 0; x < width; x += 1) {
          pushPixel(x, 0);
          pushPixel(x, height - 1);
        }

        for (let y = 0; y < height; y += 1) {
          pushPixel(0, y);
          pushPixel(width - 1, y);
        }

        while (stack.length > 0) {
          const index = stack.pop();
          const offset = index * 4;
          data[offset + 3] = 0;
          const x = index % width;
          const y = Math.floor(index / width);
          pushPixel(x + 1, y);
          pushPixel(x - 1, y);
          pushPixel(x, y + 1);
          pushPixel(x, y - 1);
        }

        context.putImageData(imageData, 0, 0);
        const nextSrc = canvas.toDataURL('image/png');
        transparentPackAssetCache.set(src, nextSrc);

        if (!cancelled) {
          setProcessedSrc(nextSrc);
        }
      } catch {
        transparentPackAssetCache.set(src, src);

        if (!cancelled) {
          setProcessedSrc(src);
        }
      }
    };

    image.onerror = () => {
      if (!cancelled) {
        setProcessedSrc(src);
      }
    };

    image.src = src;

    return () => {
      cancelled = true;
    };
  }, [src]);

  return processedSrc || src;
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

function TcgPackSprite({ pack, t, compact = false }) {
  const [failed, setFailed] = useState(false);
  const packFrontSrc = useEdgeTransparentImage(PACK_FRONT_ASSET_PATH);

  useEffect(() => {
    setFailed(false);
  }, [pack?.packCode]);

  return (
    <div className="tcg-pack-sprite" data-compact={compact} data-has-image={!failed}>
      <div className="tcg-pack-sprite-inner">
        {!failed ? (
          <img
            src={packFrontSrc}
            alt=""
            draggable="false"
            onError={() => setFailed(true)}
          />
        ) : (
          <>
            <span>{t('tcg.seasonZero')}</span>
            <strong>{pack?.packName || t('tcg.seasonZeroTestPack')}</strong>
            <small>{t('tcg.ownerTestOnly')}</small>
          </>
        )}
      </div>
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

function TcgRevealCard({ card, index, revealed, language, t, onReveal }) {
  const [cardBackFailed, setCardBackFailed] = useState(false);

  useEffect(() => {
    setCardBackFailed(false);
  }, [card?.cardKey, index]);

  if (!revealed) {
    return (
      <button
        type="button"
        className="tcg-pack-hidden-card"
        data-has-image={!cardBackFailed}
        style={{ '--tcg-reveal-index': index }}
        onClick={() => onReveal(index)}
      >
        {!cardBackFailed ? (
          <img
            className="tcg-card-back-image"
            src={CARD_BACK_ASSET_PATH}
            alt=""
            draggable="false"
            onError={() => setCardBackFailed(true)}
          />
        ) : null}
        <span className="tcg-card-back-index">{`0${index + 1}`}</span>
        {cardBackFailed ? (
          <span className="tcg-card-back-emblem" aria-hidden="true">
            <i />
            <b />
          </span>
        ) : null}
        <strong>{t('tcg.tapToReveal')}</strong>
      </button>
    );
  }

  return (
    <TcgPackResultCard
      card={card}
      index={index}
      language={language}
      t={t}
    />
  );
}

function TcgPackOpeningOverlay({
  overlay,
  language,
  t,
  onRip,
  onClose,
  onRevealCard,
  onRevealAll,
  onPointerDown,
  onPointerUp,
}) {
  if (!overlay) {
    return null;
  }

  const resultCards = overlay.opening?.results ?? [];
  const canClose = overlay.stage !== 'opening';
  const revealedCount = overlay.revealedIndexes?.size ?? 0;
  const stageTone = overlay.stage === 'results' ? 'success' : 'warning';
  const stageLabel = overlay.stage === 'results' ? t('tcg.packOpened') : t('tcg.openPack');
  const stageCopy = overlay.stage === 'ready'
    ? t('tcg.swipeToRip')
    : overlay.stage === 'opening'
      ? t('tcg.openingPack')
      : t('tcg.tapCardsToReveal');

  return (
    <div className="tcg-pack-overlay" role="presentation">
      <section
        className="tcg-pack-overlay-card"
        role="dialog"
        aria-modal="true"
        aria-label={overlay.pack?.packName || t('tcg.openPack')}
        data-stage={overlay.stage}
      >
        <div className="tcg-pack-overlay-header">
          <div>
            <StatusBadge tone={stageTone}>{stageLabel}</StatusBadge>
            <h3>{overlay.pack?.packName || t('tcg.seasonZeroTestPack')}</h3>
            <p>{stageCopy}</p>
          </div>
          <div className="tcg-pack-overlay-actions">
            {overlay.stage === 'results' ? (
              <span>
                {t('tcg.packQuantity')} {formatNumber(overlay.opening?.remainingPackQuantity ?? 0, language)}
              </span>
            ) : null}
            {canClose ? (
              <button type="button" className="secondary-action compact-action" onClick={onClose}>
                {t('common.close')}
              </button>
            ) : null}
          </div>
        </div>

        {overlay.stage === 'ready' || overlay.stage === 'opening' ? (
          <div className="tcg-pack-rip-stage">
            <button
              type="button"
              className="tcg-pack-rip-target"
              data-opening={overlay.stage === 'opening'}
              onPointerDown={onPointerDown}
              onPointerUp={onPointerUp}
              onClick={() => {
                if (overlay.stage === 'ready') {
                  onRip();
                }
              }}
              disabled={overlay.stage === 'opening'}
            >
              <TcgPackSprite pack={overlay.pack} t={t} />
              <span>{overlay.stage === 'opening' ? t('tcg.openingPack') : t('tcg.ripOpen')}</span>
            </button>
            <p>{t('tcg.backendConsumesPack')}</p>
          </div>
        ) : null}

        {overlay.error ? (
          <p className="tcg-pack-error" role="alert">{overlay.error}</p>
        ) : null}

        {overlay.stage === 'results' ? (
          <div className="tcg-pack-reveal-shell">
            <div className="tcg-reveal-toolbar">
              <span>{`${formatNumber(revealedCount, language)} / ${formatNumber(resultCards.length, language)}`}</span>
              {revealedCount < resultCards.length ? (
                <button type="button" className="secondary-action compact-action" onClick={onRevealAll}>
                  {t('tcg.revealAll')}
                </button>
              ) : null}
            </div>

            <div className="tcg-pack-results-grid" aria-label={t('tcg.tapCardsToReveal')}>
              {resultCards.map((card, index) => (
                <TcgRevealCard
                  key={`${overlay.opening?.openingId || overlay.pack?.packCode}-${card.cardKey}-${index}`}
                  card={card}
                  index={index}
                  revealed={overlay.revealedIndexes.has(index)}
                  language={language}
                  t={t}
                  onReveal={onRevealCard}
                />
              ))}
            </div>
          </div>
        ) : null}
      </section>
    </div>
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

function TcgOwnedPacksPanel({
  packs,
  loading,
  error,
  openingBusy,
  animationsEnabled,
  language,
  t,
  onOpenPack,
  onToggleAnimations,
}) {
  const seasonPack = packs.find((pack) => pack.packCode === TEST_PACK_CODE) ?? {
    packCode: TEST_PACK_CODE,
    packName: t('tcg.seasonZeroTestPack'),
    description: t('tcg.containsFiveCards'),
    cardsPerPack: 5,
    quantity: 0,
    isOwnerTestOnly: true,
  };
  const quantity = Math.max(0, Number(seasonPack.quantity) || 0);

  return (
    <section className="panel tcg-pack-panel" data-pack-mode="owned" aria-label={t('tcg.packInventory')}>
      <div className="tcg-pack-panel-header">
        <div>
          <StatusBadge tone="warning">{t('tcg.ownerTestOnly')}</StatusBadge>
          <h3>{t('tcg.ownedPacks')}</h3>
          <p>{t('tcg.packInventoryBody')}</p>
        </div>
        <label className="tcg-animation-toggle">
          <input
            type="checkbox"
            checked={animationsEnabled}
            onChange={(event) => onToggleAnimations(event.target.checked)}
          />
          <span>{t('tcg.packAnimations')}</span>
          <small>{animationsEnabled ? t('tcg.animationsEnabled') : t('tcg.animationsDisabled')}</small>
        </label>
      </div>

      {error ? (
        <p className="tcg-pack-error" role="alert">{error}</p>
      ) : null}

      <article className="tcg-owned-pack-card" data-empty={quantity <= 0}>
        <div className="tcg-owned-pack-visual">
          <div className="tcg-owned-pack-stage" aria-hidden="true">
            <TcgPackSprite pack={seasonPack} t={t} />
          </div>
          <strong>{`x${formatNumber(quantity, language)}`}</strong>
          <button
            type="button"
            className="primary-action compact-action tcg-open-pack-button tcg-owned-open-button"
            onClick={() => onOpenPack(seasonPack)}
            disabled={loading || openingBusy || quantity <= 0}
            aria-busy={openingBusy}
          >
            {openingBusy ? t('tcg.openingPack') : t('tcg.openPack')}
          </button>
        </div>
        <div className="tcg-owned-pack-copy">
          <StatusBadge tone={quantity > 0 ? 'success' : 'neutral'}>
            {t('tcg.ownerTestOnly')}
          </StatusBadge>
          <h4>{seasonPack.packName || t('tcg.seasonZeroTestPack')}</h4>
          <p>{seasonPack.description || t('tcg.containsFiveCards')}</p>
          <div className="tcg-pack-facts" aria-label={t('tcg.packInventory')}>
            <span>{seasonPack.cardsPerPack ? `${formatNumber(seasonPack.cardsPerPack, language)} ${t('tcg.cardsPulled')}` : t('tcg.containsFiveCards')}</span>
            <span>{t('tcg.backendConsumesPack')}</span>
          </div>
        </div>
      </article>

      {!loading && quantity <= 0 ? (
        <p className="tcg-pack-preview-note">{t('tcg.noPacksOwned')}</p>
      ) : null}
    </section>
  );
}

function TcgShopPreviewPanel({
  wallet,
  shopItems,
  purchase,
  loading,
  error,
  purchaseLoadingCode,
  language,
  t,
  onBuyPack,
  onGoToPacks,
}) {
  const displayedWallet = wallet ?? { balance: 0, currencyCode: 'anteiku_coins' };
  const currencyLabel = getCurrencyLabel(displayedWallet.currencyCode, t);

  return (
    <section className="panel tcg-shop-panel" data-loading={loading || Boolean(purchaseLoadingCode)} aria-label={t('tcg.shopTestTitle')}>
      <div className="tcg-shop-header">
        <div>
          <StatusBadge tone="warning">{t('tcg.ownerTestOnly')}</StatusBadge>
          <h3>{t('tcg.shopTestTitle')}</h3>
          <p>{t('tcg.shopInventoryBody')}</p>
        </div>
        <div className="tcg-wallet-card" aria-label={t('tcg.walletBalance')}>
          <i aria-hidden="true" />
          <span>{t('tcg.walletBalance')}</span>
          <strong>{formatNumber(displayedWallet.balance, language)}</strong>
          <small>{currencyLabel}</small>
        </div>
      </div>

      {error ? <p className="tcg-pack-error" role="alert">{error}</p> : null}

      <div className="tcg-shop-list" aria-label={t('tcg.ownerShopPreview')}>
        {shopItems.length > 0 ? (
          shopItems.map((item) => (
            <article className="tcg-shop-item" key={item.shopItemCode} data-buying={purchaseLoadingCode === item.shopItemCode}>
              <div className="tcg-shop-pack-preview" aria-hidden="true">
                <TcgPackSprite
                  pack={{
                    packCode: item.packCode || TEST_PACK_CODE,
                    packName: item.packName || item.shopItemName || t('tcg.seasonZeroTestPack'),
                  }}
                  t={t}
                  compact
                />
              </div>
              <div className="tcg-shop-item-main">
                <StatusBadge tone="warning">{t('tcg.ownerTestOnly')}</StatusBadge>
                <h4>{item.shopItemName || t('tcg.seasonZeroTestPack')}</h4>
                <p>{item.description || t('tcg.packAddedNoReveal')}</p>
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
        <div className="tcg-pack-result-shell" data-revealed="true" data-result-mode="shop">
          <div className="tcg-pack-result-heading">
            <div>
              <StatusBadge tone="success">{t('tcg.purchaseComplete')}</StatusBadge>
              <h4>{purchase.shopItemName || purchase.packName || t('tcg.seasonZeroTestPack')}</h4>
            </div>
            <span>
              {formatNumber(purchase.balanceBefore, language)} - {formatNumber(purchase.price, language)}
              {' = '}
              {formatNumber(purchase.balanceAfter, language)}
            </span>
          </div>

          <p className="tcg-pack-preview-note">
            {`${t('tcg.packAddedToInventory')} ${t('tcg.packQuantity')} ${formatNumber(purchase.ownedPackQuantity, language)}`}
          </p>
          <div className="tcg-shop-success-actions">
            <button type="button" className="secondary-action compact-action" onClick={onGoToPacks}>
              {t('tcg.goToPacks')}
            </button>
          </div>
        </div>
      ) : null}
    </section>
  );
}

function TcgOwnerLabPanel({
  activeOwnerProfileId,
  smokeGrantLoading,
  smokeGrantMessage,
  smokeGrantSatisfied,
  grantCoinsLoading,
  grantCoinsMessage,
  grantCoinsError,
  wallet,
  language,
  t,
  onSmokeGrant,
  onGrantCoins,
}) {
  const displayedWallet = wallet ?? { balance: 0, currencyCode: 'anteiku_coins' };
  const currencyLabel = getCurrencyLabel(displayedWallet.currencyCode, t);

  return (
    <section className="tcg-owner-lab-section" aria-label={t('tcg.ownerLab')}>
      <div className="tcg-owner-lab-heading">
        <StatusBadge tone="warning">{t('tcg.ownerTestOnly')}</StatusBadge>
        <div>
          <h3>{t('tcg.ownerLab')}</h3>
          <p>{t('tcg.ownerLabBody')}</p>
        </div>
      </div>

      <div className="tcg-owner-lab-grid">
        <article className="tcg-owner-lab-card" data-lab-card="smoke">
          <div>
            <StatusBadge tone="warning">{t('tcg.ownerPreview')}</StatusBadge>
            <h3>{t('tcg.smokeGrantTitle')}</h3>
            <p>{t('tcg.smokeGrantBody')}</p>
          </div>
          <button
            type="button"
            className="danger-action compact-action"
            onClick={onSmokeGrant}
            disabled={smokeGrantLoading || !activeOwnerProfileId || smokeGrantSatisfied}
            aria-busy={smokeGrantLoading}
          >
            {smokeGrantLoading
              ? t('common.working')
              : smokeGrantSatisfied
                ? t('tcg.smokeGrantReady')
                : t('tcg.smokeGrantButton')}
          </button>
          {smokeGrantMessage ? <p className="success-copy">{smokeGrantMessage}</p> : null}
        </article>

        <article className="tcg-owner-lab-card" data-lab-card="coins">
          <div>
            <StatusBadge tone="warning">{t('tcg.ownerTestOnly')}</StatusBadge>
            <h3>{t('tcg.ownerLabWalletTitle')}</h3>
          </div>
          <div className="tcg-owner-lab-wallet">
            <span>{t('tcg.walletBalance')}</span>
            <strong>{formatNumber(displayedWallet.balance, language)}</strong>
            <small>{currencyLabel}</small>
          </div>
          <button
            type="button"
            className="danger-action compact-action"
            onClick={onGrantCoins}
            disabled={grantCoinsLoading}
            aria-busy={grantCoinsLoading}
          >
            {grantCoinsLoading ? t('common.working') : t('tcg.grantTestCoins')}
          </button>
          {grantCoinsMessage ? <p className="success-copy">{grantCoinsMessage}</p> : null}
          {grantCoinsError ? <p className="tcg-pack-error" role="alert">{grantCoinsError}</p> : null}
        </article>
      </div>
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
  const [activeWindow, setActiveWindow] = useState('album');
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
  const [ownedPacks, setOwnedPacks] = useState([]);
  const [packInventoryLoading, setPackInventoryLoading] = useState(false);
  const [packInventoryError, setPackInventoryError] = useState('');
  const [packAnimationsEnabled, setPackAnimationsEnabled] = useState(readPackAnimationSetting);
  const [packOverlay, setPackOverlay] = useState(null);
  const [economyLoading, setEconomyLoading] = useState(false);
  const [economyError, setEconomyError] = useState('');
  const [grantCoinsLoading, setGrantCoinsLoading] = useState(false);
  const [grantCoinsMessage, setGrantCoinsMessage] = useState('');
  const [grantCoinsError, setGrantCoinsError] = useState('');
  const [purchaseLoadingCode, setPurchaseLoadingCode] = useState('');
  const [shopPurchase, setShopPurchase] = useState(null);
  const favoriteRequestKeysRef = useRef(new Set());
  const smokeGrantRequestRef = useRef(false);
  const packOpeningRequestRef = useRef(false);
  const ownedPackOpeningRequestRef = useRef(false);
  const grantCoinsRequestRef = useRef(false);
  const buyPackRequestRef = useRef(false);
  const ripPointerStartRef = useRef(null);

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

  const loadPackInventory = useCallback(async () => {
    if (!isOwner) {
      return;
    }

    setPackInventoryLoading(true);
    setPackInventoryError('');

    try {
      const packRows = await tcgGetMyPacks();
      setOwnedPacks(packRows);
    } catch (loadError) {
      setOwnedPacks([]);
      setPackInventoryError(getDisplayError(loadError, t('tcg.packInventoryLoadFailed')));
    } finally {
      setPackInventoryLoading(false);
    }
  }, [isOwner, t]);

  useEffect(() => {
    loadPackInventory();
  }, [loadPackInventory]);

  const handleRefreshAll = useCallback(() => {
    loadCards();
    loadEconomy();
    loadPackInventory();
  }, [loadCards, loadEconomy, loadPackInventory]);

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
      setActiveWindow('album');
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
      await Promise.all([loadCards(), loadPackInventory()]);
      setFilter('owned');
      setRarityFilter(ALL_RARITIES);
      setActiveWindow('ownerLab');
    } catch (openingError) {
      setPackOpeningError(getDisplayError(openingError, t('tcg.packOpeningFailed')));
    } finally {
      packOpeningRequestRef.current = false;
      setPackOpeningLoading(false);
    }
  }, [isOwner, loadCards, loadPackInventory, t]);

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
    setGrantCoinsError('');

    try {
      const nextWallet = await tcgOwnerGrantTestCoins(TEST_COIN_GRANT_AMOUNT);
      setWallet(nextWallet);
      setGrantCoinsMessage(t('tcg.testCoinsGranted'));
      await loadEconomy();
    } catch (grantError) {
      setGrantCoinsError(getDisplayError(grantError, t('tcg.grantFailed')));
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
    setShopPurchase(null);
    setGrantCoinsMessage('');
    setGrantCoinsError('');

    try {
      const purchaseResult = await tcgOwnerBuyTestPackToInventory(shopItemCode);
      setShopPurchase(purchaseResult);
      await Promise.all([loadEconomy(), loadPackInventory()]);
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
  }, [isOwner, loadEconomy, loadPackInventory, t]);

  const handleTogglePackAnimations = useCallback((enabled) => {
    setPackAnimationsEnabled(enabled);

    if (typeof window !== 'undefined') {
      window.localStorage.setItem(PACK_ANIMATION_STORAGE_KEY, enabled ? 'true' : 'false');
    }
  }, []);

  const performOwnedPackOpen = useCallback(async (pack) => {
    if (!isOwner || !pack?.packCode) {
      return;
    }

    if (ownedPackOpeningRequestRef.current) {
      return;
    }

    ownedPackOpeningRequestRef.current = true;
    setPackInventoryError('');
    setPackOverlay((currentOverlay) => ({
      ...(currentOverlay ?? { pack }),
      pack,
      stage: 'opening',
      opening: null,
      error: '',
      revealedIndexes: new Set(),
    }));

    try {
      const opening = await tcgOwnerOpenOwnedPack(pack.packCode);
      setPackOverlay({
        pack,
        stage: 'results',
        opening,
        error: '',
        revealedIndexes: new Set(),
      });
      await Promise.all([loadPackInventory(), loadCards(), loadEconomy()]);
      setFilter('owned');
      setRarityFilter(ALL_RARITIES);
      setActiveWindow('packs');
    } catch (openError) {
      const message = getDisplayError(openError, t('tcg.packOpeningFailed'));
      setPackInventoryError(message);
      setPackOverlay((currentOverlay) => ({
        ...(currentOverlay ?? { pack }),
        pack,
        stage: 'ready',
        opening: null,
        error: message,
        revealedIndexes: new Set(),
      }));
    } finally {
      ownedPackOpeningRequestRef.current = false;
    }
  }, [isOwner, loadCards, loadEconomy, loadPackInventory, t]);

  const handleOpenOwnedPack = useCallback((pack) => {
    if (!pack || Number(pack.quantity) <= 0) {
      return;
    }

    if (packAnimationsEnabled) {
      setPackOverlay({
        pack,
        stage: 'ready',
        opening: null,
        error: '',
        revealedIndexes: new Set(),
      });
      return;
    }

    performOwnedPackOpen(pack);
  }, [packAnimationsEnabled, performOwnedPackOpen]);

  const handleRipOpen = useCallback(() => {
    if (!packOverlay?.pack || packOverlay.stage !== 'ready') {
      return;
    }

    performOwnedPackOpen(packOverlay.pack);
  }, [packOverlay, performOwnedPackOpen]);

  const handleRevealPackCard = useCallback((index) => {
    setPackOverlay((currentOverlay) => {
      if (!currentOverlay || currentOverlay.stage !== 'results') {
        return currentOverlay;
      }

      const nextIndexes = new Set(currentOverlay.revealedIndexes);
      nextIndexes.add(index);

      return {
        ...currentOverlay,
        revealedIndexes: nextIndexes,
      };
    });
  }, []);

  const handleRevealAllPackCards = useCallback(() => {
    setPackOverlay((currentOverlay) => {
      if (!currentOverlay || currentOverlay.stage !== 'results') {
        return currentOverlay;
      }

      return {
        ...currentOverlay,
        revealedIndexes: new Set((currentOverlay.opening?.results ?? []).map((_, index) => index)),
      };
    });
  }, []);

  const handleRipPointerDown = useCallback((event) => {
    ripPointerStartRef.current = {
      x: event.clientX,
      y: event.clientY,
    };
  }, []);

  const handleRipPointerUp = useCallback((event) => {
    const start = ripPointerStartRef.current;
    ripPointerStartRef.current = null;

    if (!start || !packOverlay || packOverlay.stage !== 'ready') {
      return;
    }

    const deltaX = event.clientX - start.x;
    const deltaY = event.clientY - start.y;

    if (Math.abs(deltaX) >= 48 && Math.abs(deltaX) > Math.abs(deltaY)) {
      handleRipOpen();
    }
  }, [handleRipOpen, packOverlay]);

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
      <section className="panel hero-panel tcg-hero tcg-hub-hero">
        <div className="tcg-hub-header">
          <div>
            <StatusBadge tone="warning">{t('tcg.ownerPreview')}</StatusBadge>
            <h3>{t('tcg.title')}</h3>
            <p>{t('tcg.subtitle')}</p>
          </div>
          <button
            type="button"
            className="secondary-action compact-action"
            onClick={handleRefreshAll}
            disabled={loading || economyLoading || packInventoryLoading}
          >
            {loading || economyLoading || packInventoryLoading ? t('common.refreshing') : t('common.refresh')}
          </button>
        </div>

        <div className="tcg-hub-stats" aria-label={t('tcg.collectionProgress')}>
          <div className="tcg-hub-stat">
            <span>{t('tcg.uniqueOwned')}</span>
            <strong>
              {formatNumber(progress.ownedUnique, language)} / {formatNumber(progress.totalCards, language)}
            </strong>
          </div>
          <div className="tcg-hub-stat">
            <span>{t('tcg.totalOwnedQuantity')}</span>
            <strong>{formatNumber(progress.totalQuantity, language)}</strong>
          </div>
          <div className="tcg-hub-stat">
            <span>{t('tcg.favorites')}</span>
            <strong>{formatNumber(progress.favorites, language)}</strong>
          </div>
          <div className="tcg-hub-stat" data-stat="coins">
            <span>{t('tcg.anteikuCoins')}</span>
            <strong>{formatNumber(wallet?.balance ?? 0, language)}</strong>
          </div>
        </div>
      </section>

      <nav className="tcg-hub-tabs" aria-label={t('tcg.hubNavigation')}>
        {HUB_WINDOWS.map((windowKey) => (
          <button
            key={windowKey}
            type="button"
            className="tcg-hub-tab"
            data-active={activeWindow === windowKey}
            onClick={() => setActiveWindow(windowKey)}
          >
            {t(`tcg.hub.${windowKey}`)}
          </button>
        ))}
      </nav>

      <section className="tcg-hub-window" data-window={activeWindow}>
        {activeWindow === 'album' ? (
          <>
            <div className="tcg-window-heading">
              <div>
                <StatusBadge tone="neutral">{t('tcg.seasonZero')}</StatusBadge>
                <h3>{t('tcg.hub.album')}</h3>
                <p>{t('tcg.albumWindowBody')}</p>
              </div>
            </div>

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
          </>
        ) : null}

        {activeWindow === 'packs' ? (
          <TcgOwnedPacksPanel
            packs={ownedPacks}
            loading={packInventoryLoading}
            error={packInventoryError}
            openingBusy={ownedPackOpeningRequestRef.current || packOverlay?.stage === 'opening'}
            animationsEnabled={packAnimationsEnabled}
            language={language}
            t={t}
            onOpenPack={handleOpenOwnedPack}
            onToggleAnimations={handleTogglePackAnimations}
          />
        ) : null}

        {activeWindow === 'shop' ? (
          <TcgShopPreviewPanel
            wallet={wallet}
            shopItems={shopItems}
            purchase={shopPurchase}
            loading={economyLoading}
            error={economyError}
            purchaseLoadingCode={purchaseLoadingCode}
            language={language}
            t={t}
            onBuyPack={handleBuyTestPack}
            onGoToPacks={() => setActiveWindow('packs')}
          />
        ) : null}

        {activeWindow === 'ownerLab' ? (
          <>
            <TcgOwnerLabPanel
              activeOwnerProfileId={activeOwnerProfileId}
              smokeGrantLoading={smokeGrantLoading}
              smokeGrantMessage={smokeGrantMessage}
              smokeGrantSatisfied={smokeGrantSatisfied}
              grantCoinsLoading={grantCoinsLoading}
              grantCoinsMessage={grantCoinsMessage}
              grantCoinsError={grantCoinsError}
              wallet={wallet}
              language={language}
              t={t}
              onSmokeGrant={handleSmokeGrant}
              onGrantCoins={handleGrantTestCoins}
            />
            <TcgPackPreviewPanel
              opening={packOpening}
              openingError={packOpeningError}
              openingLoading={packOpeningLoading}
              language={language}
              t={t}
              onOpen={handleOpenTestPack}
            />
          </>
        ) : null}
      </section>

      {error && activeWindow !== 'album' ? (
        <section className="panel compact-empty-state" role="alert">
          <h3>{t('common.error')}</h3>
          <p>{error}</p>
        </section>
      ) : null}

      <TcgDetailSheet
        card={selectedCard}
        language={language}
        t={t}
        favoriteBusy={favoriteBusyKey === selectedCard?.cardKey}
        onClose={() => setSelectedCard(null)}
        onToggleFavorite={handleToggleFavorite}
      />
      <TcgPackOpeningOverlay
        overlay={packOverlay}
        language={language}
        t={t}
        onRip={handleRipOpen}
        onClose={() => setPackOverlay(null)}
        onRevealCard={handleRevealPackCard}
        onRevealAll={handleRevealAllPackCards}
        onPointerDown={handleRipPointerDown}
        onPointerUp={handleRipPointerUp}
      />
    </div>
  );
}
