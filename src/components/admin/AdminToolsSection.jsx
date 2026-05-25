import React, { useEffect, useMemo, useState } from 'react';
import { StatusBadge } from '../StatusBadge.jsx';
import {
  formatCosmeticLabel,
  grantCosmeticBySlug,
  loadGrantableCosmetics,
} from '../../services/cosmeticsService.js';

function formatCosmeticType(t, type) {
  if (type === 'avatar') {
    return t('ownerCosmetics.typeAvatar');
  }

  if (type === 'frame') {
    return t('ownerCosmetics.typeFrame');
  }

  return type;
}

function formatUnlockType(t, unlockType) {
  return unlockType === 'free' ? t('ownerCosmetics.unlockFree') : t('ownerCosmetics.unlockManual');
}

export function AdminToolsSection({ membership, plannedSections, t }) {
  const isOwner = membership?.role === 'owner';
  const [cosmetics, setCosmetics] = useState([]);
  const [cosmeticsLoading, setCosmeticsLoading] = useState(false);
  const [cosmeticsError, setCosmeticsError] = useState('');
  const [profileSlug, setProfileSlug] = useState('');
  const [cosmeticKey, setCosmeticKey] = useState('');
  const [reason, setReason] = useState('');
  const [grantLoading, setGrantLoading] = useState(false);
  const [grantMessage, setGrantMessage] = useState('');
  const [grantError, setGrantError] = useState('');

  useEffect(() => {
    let active = true;

    async function loadCosmetics() {
      if (!isOwner) {
        setCosmetics([]);
        return;
      }

      setCosmeticsLoading(true);
      setCosmeticsError('');

      try {
        const nextCosmetics = await loadGrantableCosmetics();

        if (active) {
          setCosmetics(nextCosmetics);
        }
      } catch (error) {
        if (active) {
          setCosmeticsError(error.message || t('ownerCosmetics.grantError'));
        }
      } finally {
        if (active) {
          setCosmeticsLoading(false);
        }
      }
    }

    loadCosmetics();

    return () => {
      active = false;
    };
  }, [isOwner, t]);

  const selectedCosmetic = useMemo(
    () => cosmetics.find((cosmetic) => cosmetic.key === cosmeticKey) ?? null,
    [cosmeticKey, cosmetics],
  );

  const handleGrant = async (event) => {
    event.preventDefault();
    const normalizedSlug = profileSlug.trim();

    setGrantMessage('');
    setGrantError('');

    if (!normalizedSlug) {
      setGrantError(t('ownerCosmetics.memberSlugRequired'));
      return;
    }

    if (!cosmeticKey) {
      setGrantError(t('ownerCosmetics.cosmeticRequired'));
      return;
    }

    setGrantLoading(true);

    try {
      const result = await grantCosmeticBySlug({
        profileSlug: normalizedSlug,
        cosmeticKey,
        reason: reason.trim(),
      });

      setGrantMessage(
        t('ownerCosmetics.granted', {
          cosmetic: result?.cosmetic_key ?? cosmeticKey,
          profileSlug: result?.profile_slug ?? normalizedSlug,
        }),
      );
      setReason('');
    } catch (error) {
      setGrantError(error.message || t('ownerCosmetics.grantError'));
    } finally {
      setGrantLoading(false);
    }
  };

  return (
    <div className="admin-tools-stack">
      {isOwner ? (
        <section className="panel owner-cosmetics-panel compact-admin-card" aria-label={t('ownerCosmetics.title')}>
          <div className="section-heading-row admin-section-heading">
            <div>
              <StatusBadge tone="warning">{t('ownerCosmetics.ownerOnly')}</StatusBadge>
              <h3>{t('ownerCosmetics.title')}</h3>
              <p>{t('ownerCosmetics.useSlugNotIgn')}</p>
            </div>
          </div>

          {cosmeticsError ? <p className="error-line">{cosmeticsError}</p> : null}
          {grantError ? <p className="error-line">{grantError}</p> : null}
          {grantMessage ? <p className="notice-line">{grantMessage}</p> : null}

          <form className="owner-cosmetics-form" onSubmit={handleGrant}>
            <label>
              {t('ownerCosmetics.memberSlug')}
              <input
                type="text"
                value={profileSlug}
                onChange={(event) => setProfileSlug(event.target.value)}
                placeholder="profile_slug"
                disabled={grantLoading}
              />
              <small>{t('ownerCosmetics.memberSlugHelp')}</small>
            </label>

            <label>
              {t('ownerCosmetics.cosmetic')}
              <select
                value={cosmeticKey}
                onChange={(event) => setCosmeticKey(event.target.value)}
                disabled={cosmeticsLoading || grantLoading}
              >
                <option value="">
                  {cosmeticsLoading ? t('common.loading') : t('ownerCosmetics.chooseCosmetic')}
                </option>
                {cosmetics.map((cosmetic) => (
                  <option key={cosmetic.key} value={cosmetic.key}>
                    {formatUnlockType(t, cosmetic.unlockType)} | {formatCosmeticType(t, cosmetic.type)} |{' '}
                    {formatCosmeticLabel(cosmetic, cosmetic.key)}
                  </option>
                ))}
              </select>
              {selectedCosmetic ? (
                <small>
                  {selectedCosmetic.key} - {formatUnlockType(t, selectedCosmetic.unlockType)}
                </small>
              ) : null}
            </label>

            <label>
              {t('ownerCosmetics.reason')}
              <input
                type="text"
                value={reason}
                onChange={(event) => setReason(event.target.value)}
                placeholder={t('ownerCosmetics.reasonPlaceholder')}
                disabled={grantLoading}
              />
            </label>

            <button
              type="submit"
              className="danger-action compact-action owner-cosmetics-grant"
              disabled={grantLoading || cosmeticsLoading}
            >
              {grantLoading ? t('common.working') : t('ownerCosmetics.grant')}
            </button>
          </form>
        </section>
      ) : null}

      <section className="panel admin-list compact-admin-card" aria-label={t('admin.tools.aria')}>
        {plannedSections.map((section) => (
          <article key={section}>
            <div>
              <h4>{section}</h4>
              <p>{t('admin.tools.comingLater')}</p>
            </div>
            <StatusBadge>{t('admin.common.later')}</StatusBadge>
          </article>
        ))}
      </section>
    </div>
  );
}
