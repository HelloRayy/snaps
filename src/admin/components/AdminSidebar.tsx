import type { ProfileRow, AdminStats } from '../services/adminService';
import { UserAvatar } from './UserAvatar';

export type AdminTab =
  | 'overview'
  | 'users'
  | 'moderation'
  | 'reports'
  | 'broadcast'
  | 'devices'
  | 'meeting-points'
  | 'server';

interface AdminSidebarProps {
  activeTab: AdminTab;
  onTabChange: (tab: AdminTab) => void;
  onLogout: () => void;
  isOpenMobile?: boolean;
  onCloseMobile?: () => void;
  adminProfile?: ProfileRow | null;
  adminEmail?: string;
  stats?: AdminStats | null;
  securityAlertsCount?: number;
}

export function AdminSidebar({
  activeTab,
  onTabChange,
  onLogout,
  onCloseMobile,
  adminProfile,
  adminEmail = 'admin@snapan.id',
  stats,
  securityAlertsCount,
}: AdminSidebarProps) {
  const displayName = adminProfile?.full_name || adminEmail.split('@')[0] || 'Administrator';
  const displayUsername = adminProfile?.username ? `@${adminProfile.username}` : adminEmail;

  const handleNav = (tab: AdminTab) => {
    onTabChange(tab);
    onCloseMobile?.();
  };

  return (
    <aside className="menu-sidebar" id="main-sidebar">
      {/* Atlassian Jira / Confluence Project & Workspace Header */}
      <div className="logo d-flex align-items-center justify-content-between" style={{ height: '56px', padding: '0 18px' }}>
        <a
          href="#/admin"
          onClick={(e) => {
            e.preventDefault();
            handleNav('overview');
          }}
          className="d-flex align-items-center gap-2.5 text-decoration-none"
          title="Beranda Snaps Admin"
          style={{ height: '40px', minWidth: 0 }}
        >
          <img
            src="/snaps-logo-clean.svg"
            alt="Snaps"
            style={{
              height: '26px',
              width: 'auto',
              objectFit: 'contain',
              display: 'block',
            }}
            onError={(e) => {
              e.currentTarget.onerror = null;
              e.currentTarget.src = '/assets/logo/snaps-logo-clean.svg';
            }}
          />
          <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
            <span
              style={{
                fontSize: '13.5px',
                fontWeight: 600,
                color: '#172b4d',
                lineHeight: 1.25,
                whiteSpace: 'nowrap',
                overflow: 'hidden',
                textOverflow: 'ellipsis',
              }}
            >
              Snaps Admin
            </span>
            <span
              style={{
                fontSize: '11px',
                color: '#626f86',
                lineHeight: 1.25,
                whiteSpace: 'nowrap',
              }}
            >
              SMKN 8 Semarang
            </span>
          </div>
        </a>

        {/* Mobile close button */}
        {onCloseMobile && (
          <button
            type="button"
            className="sidebar-close d-lg-none"
            onClick={onCloseMobile}
            aria-label="Tutup navigasi"
            style={{
              background: 'transparent',
              border: 0,
              color: '#626f86',
              fontSize: '16px',
              padding: '6px',
              cursor: 'pointer',
              borderRadius: '3px',
            }}
          >
            <i className="fa-solid fa-xmark"></i>
          </button>
        )}
      </div>

      {/* Navigation List & Admin Profile */}
      <div
        className="menu-sidebar__content"
        style={{
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          minHeight: 'calc(100vh - 56px)',
        }}
      >
        <nav className="navbar-sidebar" style={{ flex: 1, padding: '8px' }}>
          <ul className="list-unstyled navbar__list mb-0">
            <li className="nav-group-label">Perencanaan & Ringkasan</li>
            <li className={activeTab === 'overview' ? 'active' : ''}>
              <a
                href="#overview"
                onClick={(e) => {
                  e.preventDefault();
                  handleNav('overview');
                }}
              >
                <i className="fa-solid fa-gauge-high"></i>
                <span style={{ flex: 1, whiteSpace: 'nowrap' }}>Ringkasan</span>
              </a>
            </li>

            <li className="nav-group-label">Manajemen Siswa & Konten</li>
            <li className={activeTab === 'users' ? 'active' : ''}>
              <a
                href="#users"
                onClick={(e) => {
                  e.preventDefault();
                  handleNav('users');
                }}
              >
                <i className="fa-solid fa-users"></i>
                <span style={{ flex: 1, whiteSpace: 'nowrap' }}>Data Siswa</span>
                {stats?.totalUsers != null && stats.totalUsers > 0 && (
                  <span
                    className={`ads-lozenge ${
                      activeTab === 'users' ? 'ads-lozenge-inprogress' : 'ads-lozenge-default'
                    }`}
                    style={{ fontSize: '10px', padding: '1px 5px' }}
                  >
                    {stats.totalUsers}
                  </span>
                )}
              </a>
            </li>

            <li className={activeTab === 'moderation' ? 'active' : ''}>
              <a
                href="#moderation"
                onClick={(e) => {
                  e.preventDefault();
                  handleNav('moderation');
                }}
              >
                <i className="fa-solid fa-shield-halved"></i>
                <span style={{ flex: 1, whiteSpace: 'nowrap' }}>Moderasi Feed</span>
                {stats?.totalPosts != null && stats.totalPosts > 0 && (
                  <span
                    className={`ads-lozenge ${
                      activeTab === 'moderation' ? 'ads-lozenge-inprogress' : 'ads-lozenge-default'
                    }`}
                    style={{ fontSize: '10px', padding: '1px 5px' }}
                  >
                    {stats.totalPosts}
                  </span>
                )}
              </a>
            </li>

            <li className={activeTab === 'reports' ? 'active' : ''}>
              <a
                href="#reports"
                onClick={(e) => {
                  e.preventDefault();
                  handleNav('reports');
                }}
              >
                <i className="fa-solid fa-flag"></i>
                <span style={{ flex: 1, whiteSpace: 'nowrap' }}>Laporan Konten</span>
              </a>
            </li>

            <li className={activeTab === 'broadcast' ? 'active' : ''}>
              <a
                href="#broadcast"
                onClick={(e) => {
                  e.preventDefault();
                  handleNav('broadcast');
                }}
              >
                <i className="fa-solid fa-bullhorn"></i>
                <span style={{ flex: 1, whiteSpace: 'nowrap' }}>Broadcast Notif</span>
              </a>
            </li>

            <li className={activeTab === 'devices' ? 'active' : ''}>
              <a
                href="#devices"
                onClick={(e) => {
                  e.preventDefault();
                  handleNav('devices');
                }}
              >
                <i className="fa-solid fa-mobile-screen"></i>
                <span style={{ flex: 1, whiteSpace: 'nowrap' }}>Keamanan Device</span>
                {securityAlertsCount != null && securityAlertsCount > 0 && (
                  <span
                    className="ads-lozenge ads-lozenge-danger"
                    style={{ fontSize: '10px', padding: '1px 5px' }}
                  >
                    {securityAlertsCount}
                  </span>
                )}
              </a>
            </li>

            <li className="nav-group-label">Operasional & Infrastruktur</li>
            <li className={activeTab === 'meeting-points' ? 'active' : ''}>
              <a
                href="#meeting-points"
                onClick={(e) => {
                  e.preventDefault();
                  handleNav('meeting-points');
                }}
              >
                <i className="fa-solid fa-map-location-dot"></i>
                <span style={{ flex: 1, whiteSpace: 'nowrap' }}>Titik COD</span>
                {stats?.totalMeetingPoints != null && stats.totalMeetingPoints > 0 && (
                  <span
                    className={`ads-lozenge ${
                      activeTab === 'meeting-points'
                        ? 'ads-lozenge-inprogress'
                        : 'ads-lozenge-default'
                    }`}
                    style={{ fontSize: '10px', padding: '1px 5px' }}
                  >
                    {stats.totalMeetingPoints}
                  </span>
                )}
              </a>
            </li>

            <li className={activeTab === 'server' ? 'active' : ''}>
              <a
                href="#server"
                onClick={(e) => {
                  e.preventDefault();
                  handleNav('server');
                }}
              >
                <i className="fa-solid fa-server"></i>
                <span style={{ flex: 1, whiteSpace: 'nowrap' }}>Status Server</span>
                <span
                  className="ads-lozenge ads-lozenge-success"
                  style={{
                    fontSize: '10px',
                    padding: '1px 5px',
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '4px',
                  }}
                >
                  <span
                    style={{
                      width: '5px',
                      height: '5px',
                      borderRadius: '50%',
                      background: '#1f845a',
                      display: 'inline-block',
                    }}
                  />
                  LIVE
                </span>
              </a>
            </li>
          </ul>
        </nav>

        {/* Bottom Section: Connected Profile Card, Live DB, Logout */}
        <div style={{ padding: '16px 14px', borderTop: '1px solid #edf0f2' }}>
          {/* Connected Admin Profile Card */}
          <div
            style={{
              padding: '10px 12px',
              borderRadius: '6px',
              background: '#f7f8f9',
              border: '1px solid #edf0f2',
              marginBottom: '10px',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
            }}
          >
            <UserAvatar
              avatarUrl={adminProfile?.avatar_url}
              name={displayName}
              size={36}
              role={adminProfile?.role || 'admin'}
              style={{
                border: '1px solid #edf0f2',
              }}
            />

            <div style={{ flex: 1, minWidth: 0 }}>
              <div
                style={{
                  fontSize: '13px',
                  fontWeight: 600,
                  color: '#172b4d',
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  lineHeight: 1.25,
                }}
              >
                {displayName}
              </div>
              <div
                style={{
                  fontSize: '11.5px',
                  color: '#626f86',
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  marginTop: '1px',
                }}
              >
                {displayUsername}
              </div>
            </div>

            <span className="ads-lozenge ads-lozenge-inprogress" style={{ fontSize: '10px', padding: '2px 5px' }}>
              Admin
            </span>
          </div>

          {/* Database Live Ping */}
          <div
            style={{
              padding: '8px 12px',
              borderRadius: '6px',
              background: '#f7f8f9',
              border: '1px solid #edf0f2',
              marginBottom: '10px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}
          >
            <span style={{ fontSize: '11.5px', color: '#626f86', fontWeight: 500 }}>
              Database PostgreSQL
            </span>
            <span
              className="ads-lozenge ads-lozenge-success"
              style={{
                fontSize: '10px',
                padding: '2px 6px',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              <i className="fa-solid fa-circle" style={{ fontSize: '5px' }}></i>
              LIVE
            </span>
          </div>

          {/* Logout Button */}
          <button
            type="button"
            onClick={onLogout}
            className="w-100 text-start ads-btn ads-btn-subtle"
            style={{
              height: '36px',
              borderRadius: '6px',
              padding: '0 12px',
              fontSize: '13px',
              fontWeight: 500,
              color: '#c9372c',
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              cursor: 'pointer',
              border: '1px solid transparent',
              background: 'transparent',
              transition: 'background-color 100ms ease, color 100ms ease',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = '#ffedeb';
              e.currentTarget.style.color = '#ae2e24';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = 'transparent';
              e.currentTarget.style.color = '#c9372c';
            }}
          >
            <i className="fa-solid fa-arrow-right-from-bracket" style={{ fontSize: '14px' }}></i>
            <span>Keluar dari Admin</span>
          </button>
        </div>
      </div>
    </aside>
  );
}
