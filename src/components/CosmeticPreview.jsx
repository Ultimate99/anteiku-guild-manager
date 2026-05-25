import React from 'react';

export function CosmeticPreview({ avatar, frame, label, size = 'medium', className = '' }) {
  const previewLabel = label || 'Selected cosmetics';

  return (
    <div className={`cosmetic-preview ${className}`.trim()} data-size={size} aria-label={previewLabel}>
      <div className="cosmetic-preview-stage">
        {avatar?.assetPath ? (
          <img className="cosmetic-preview-avatar" src={avatar.assetPath} alt="" draggable="false" />
        ) : (
          <span className="cosmetic-preview-fallback" aria-hidden="true">
            AG
          </span>
        )}
        {frame?.assetPath ? (
          <img className="cosmetic-preview-frame" src={frame.assetPath} alt="" draggable="false" />
        ) : null}
      </div>
    </div>
  );
}
