import { useState } from 'react';
import type { ProfileRow } from '../services/adminService';
import { UserAvatar } from './UserAvatar';

interface AdminAccountDropdownProps {
  adminEmail: string;
  adminRole: string;
  adminProfile?: ProfileRow | null;
  onLogout?: () => void;
}

export function AdminAccountDropdown({
  adminEmail,
  adminRole,
  adminProfile,
  onLogout,
}: AdminAccountDropdownProps) {
  const [isOpen, setIsOpen] = useState(false);

  const displayName = adminProfile?.full_name || adminEmail.split('@')[0] || 'Administrator';
  const displayUsername = adminProfile?.username ? `@${adminProfile.username}` : adminEmail;

  return (
    <div className="account-wrap" style={{ position: 'relative' }}>
      <div
        className="account-item clearfix"
        role="button"
        tabIndex={0}
        onClick={() => setIsOpen((prev) => !prev)}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '8px',
          padding: '4px 8px',
          borderRadius: '4px',
          cursor: 'pointer',
          background: isOpen ? '#f1f2f4' : 'transparent',
          transition: 'background-color 100ms ease',
        }}
      >
        <UserAvatar
          avatarUrl={adminProfile?.avatar_url}
          name={displayName}
          size={32}
          borderRadius="50%"
          role={adminRole}
          style={{
            border: '1.5px solid #dcdfe4',
          }}
        />
        <div className="content d-none d-sm-block text-start">
          <span
            style={{
              fontSize: '13px',
              fontWeight: 600,
              color: '#172b4d',
              display: 'block',
              lineHeight: 1.2,
              maxWidth: '120px',
              whiteSpace: 'nowrap',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
            }}
          >
            {displayName}
          </span>
          <span
            className="ads-lozenge ads-lozenge-inprogress"
            style={{
              fontSize: '9.5px',
              padding: '0 4px',
              marginTop: '2px',
              display: 'inline-block',
            }}
          >
            {adminRole}
          </span>
        </div>
        <i
          className="fa-solid fa-chevron-down d-none d-sm-inline-block"
          style={{ fontSize: '10px', color: '#626f86', marginLeft: '4px' }}
        ></i>
      </div>

      {isOpen && (
        <div
          style={{
            position: 'absolute',
            right: 0,
            top: 'calc(100% + 4px)',
            width: '240px',
            background: '#ffffff',
            borderRadius: '4px',
            border: '1px solid #dcdfe4',
            boxShadow: '0 4px 8px -2px rgba(9, 30, 66, 0.15), 0 0 1px 1px rgba(9, 30, 66, 0.12)',
            zIndex: 1000,
            overflow: 'hidden',
          }}
        >
          {/* User info head */}
          <div
            style={{
              padding: '12px 14px',
              background: '#fafbfc',
              borderBottom: '1px solid #dcdfe4',
            }}
          >
            <div
              style={{
                fontSize: '13px',
                fontWeight: 600,
                color: '#172b4d',
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
              }}
            >
              {displayName}
            </div>
            <div
              style={{
                fontSize: '11px',
                color: '#626f86',
                marginTop: '2px',
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
              }}
            >
              {displayUsername}
            </div>
          </div>

          {/* Account details */}
          <div style={{ padding: '8px 12px', borderBottom: '1px solid #dcdfe4' }}>
            <div
              style={{
                fontSize: '11px',
                color: '#626f86',
                display: 'flex',
                justifyContent: 'space-between',
                padding: '4px 0',
              }}
            >
              <span>Otorisasi</span>
              <span className="ads-lozenge ads-lozenge-inprogress" style={{ fontSize: '10px' }}>
                {adminRole.toUpperCase()}
              </span>
            </div>
            <div
              style={{
                fontSize: '11px',
                color: '#626f86',
                display: 'flex',
                justifyContent: 'space-between',
                padding: '4px 0',
              }}
            >
              <span>Status Sistem</span>
              <span className="ads-lozenge ads-lozenge-success" style={{ fontSize: '10px' }}>
                AKTIF
              </span>
            </div>
          </div>

          {/* Action logout */}
          <div style={{ padding: '4px' }}>
            <button
              type="button"
              onClick={() => {
                setIsOpen(false);
                onLogout?.();
              }}
              style={{
                width: '100%',
                padding: '8px 10px',
                textAlign: 'left',
                background: 'transparent',
                border: 0,
                color: '#c9372c',
                fontSize: '12px',
                fontWeight: 500,
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                cursor: 'pointer',
                borderRadius: '3px',
                transition: 'background-color 100ms ease',
              }}
              onMouseEnter={(e) => (e.currentTarget.style.background = '#ffedeb')}
              onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
            >
              <i className="fa-solid fa-arrow-right-from-bracket"></i>
              <span>Keluar dari Sesi</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
