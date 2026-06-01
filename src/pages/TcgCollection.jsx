import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { StatusBadge } from '../components/StatusBadge.jsx';
import { useLanguage } from '../context/LanguageContext.jsx';
import {
  mergeCatalogWithCollection,
  tcgAdminGrantCard,
  tcgGetCatalog,
  tcgGetMyCollection,
  tcgSetCardFavorite,
} from '../services/tcgService.js';

const FILTERS = ['all', 'owned', 'missing', 'favorites'];
const ALL_RARITIES = 'all';
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

    const nextFavorite = !card.isFavorite;
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
      setFavoriteBusyKey('');
    }
  }, [t]);

  const handleSmokeGrant = useCallback(async () => {
    if (!isOwner || !activeOwnerProfileId) {
      return;
    }

    const confirmed = window.confirm(t('tcg.smokeGrantConfirm'));

    if (!confirmed) {
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
      setSmokeGrantLoading(false);
    }
  }, [activeOwnerProfileId, isOwner, loadCards, t]);

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
