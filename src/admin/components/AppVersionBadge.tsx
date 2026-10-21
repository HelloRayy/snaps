import React from 'react';
import { isAppVersionOutdated } from '../utils/versionUtils';

interface AppVersionBadgeProps {
  version?: string | null;
  latestVersion?: string | null;
  size?: 'sm' | 'md';
  emptyLabel?: string;
  className?: string;
  style?: React.CSSProperties;
}

export function AppVersionBadge({
  version,
  latestVersion,
  size = 'sm',
  emptyLabel = '-',
  className = '',
  style = {},
}: AppVersionBadgeProps) {
  if (!version || version.trim() === '' || version === '-' || version.toLowerCase() === 'null') {
    return (
      <span
        style={{ color: '#94a3b8', fontSize: size === 'md' ? '12px' : '11.5px', ...style }}
        title="Belum terdeteksi / belum pernah membuka aplikasi"
        className={className}
      >
        {emptyLabel}
      </span>
    );
  }

  const isOutdated = isAppVersionOutdated(version, latestVersion);

  const badgeStyle: React.CSSProperties = isOutdated
    ? {
        display: 'inline-flex',
        alignItems: 'center',
        gap: size === 'md' ? '5.5px' : '4.5px',
        padding: size === 'md' ? '3.5px 9px' : '2.5px 7.5px',
        borderRadius: '5px',
        fontSize: size === 'md' ? '12px' : '11px',
        fontWeight: 700,
        background: '#fff7d6',
        color: '#974f0c',
        border: '1px solid #fde380',
        lineHeight: 1.2,
        letterSpacing: '0.01em',
        fontVariantNumeric: 'tabular-nums',
        ...style,
      }
    : {
        display: 'inline-flex',
        alignItems: 'center',
        gap: size === 'md' ? '5.5px' : '4.5px',
        padding: size === 'md' ? '3.5px 9px' : '2.5px 7.5px',
        borderRadius: '5px',
        fontSize: size === 'md' ? '12px' : '11px',
        fontWeight: 700,
        background: '#dffcf0',
        color: '#1f845a',
        border: '1px solid #bff7dc',
        lineHeight: 1.2,
        letterSpacing: '0.01em',
        fontVariantNumeric: 'tabular-nums',
        ...style,
      };

  const tooltipText = isOutdated
    ? `Versi lama: ${version}${latestVersion ? ` (Tersedia rilis terbaru ${latestVersion})` : ' (Perlu pembaruan)'}`
    : `Versi terbaru terpasang di HP: ${version}`;

  return (
    <span
      className={`ads-lozenge ${isOutdated ? 'ads-lozenge-warning' : 'ads-lozenge-success'} ${className}`}
      style={badgeStyle}
      title={tooltipText}
    >
      <i
        className={`fa-solid ${isOutdated ? 'fa-triangle-exclamation' : 'fa-mobile-screen'}`}
        style={{
          fontSize: size === 'md' ? '11px' : '9.5px',
          color: isOutdated ? '#b65c0b' : '#1f845a',
          flexShrink: 0,
        }}
      ></i>
      <span>{version}</span>
    </span>
  );
}
