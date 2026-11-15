import { useState, useEffect } from 'react';
import { BadgeCheck, Sparkles } from 'lucide-react';
import { adminService, type ProfileRow } from '../services/adminService';
import { UserAvatar } from './UserAvatar';
import { AdminModalPortal } from './AdminModalPortal';
import { RoleSelectDropdown, type UserRole } from './RoleSelectDropdown';
import { AdminTooltip } from './AdminTooltip';
import { AppVersionBadge } from './AppVersionBadge';

interface UserDetailModalProps {
  user: ProfileRow | null;
  isOpen: boolean;
  onClose: () => void;
  onToggleVerify: (userId: string, currentStatus: boolean) => Promise<void>;
  onChangeRole: (user: ProfileRow, newRole: UserRole) => void;
  onToggleMascotAccess?: (userId: string, currentStatus: boolean) => Promise<void>;
  onRequestSuspend?: (user: ProfileRow) => void;
  onRequestUnsuspend?: (user: ProfileRow) => void;
  onRequestDelete?: (user: ProfileRow) => void;
  onUpdateNis?: (userId: string, newNis: string | null, oldNis?: string | null) => Promise<void>;
  isUpdating: boolean;
  latestVersion?: string | null;
}

export function UserDetailModal({
  user,
  isOpen,
  onClose,
  onToggleVerify,
  onChangeRole,
  onToggleMascotAccess,
  onRequestSuspend,
  onRequestUnsuspend,
  onRequestDelete,
  onUpdateNis,
  isUpdating,
  latestVersion,
}: UserDetailModalProps) {
  const [copiedId, setCopiedId] = useState(false);
  const [copiedNis, setCopiedNis] = useState(false);
  const [copiedEmail, setCopiedEmail] = useState(false);

  // State Edit NIS Inline
  const [isEditingNis, setIsEditingNis] = useState(false);
  const [inputNis, setInputNis] = useState('');
  const [isSavingNis, setIsSavingNis] = useState(false);
  const [nisErrorMsg, setNisErrorMsg] = useState<string | null>(null);

  // State Registry Info
  const [registryInfo, setRegistryInfo] = useState<any>(null);
  const [isLoadingRegistry, setIsLoadingRegistry] = useState(false);

  // Muat detail buku induk siswa setiap kali modal dibuka / berganti siswa
  useEffect(() => {
    if (!isOpen || !user) {
      setRegistryInfo(null);
      setIsEditingNis(false);
      setInputNis('');
      setNisErrorMsg(null);
      return;
    }

    const currentUser = user;
    setInputNis(currentUser.nis || '');
    setIsEditingNis(false);
    setNisErrorMsg(null);

    let isMounted = true;
    async function loadRegistry() {
      setIsLoadingRegistry(true);
      try {
        const targetLookup = currentUser.nis || currentUser.id;
        const info = await adminService.getStudentRegistryInfo(targetLookup);
        if (isMounted) setRegistryInfo(info);
      } catch (e) {
        console.warn('Gagal memuat info buku induk:', e);
      } finally {
        if (isMounted) setIsLoadingRegistry(false);
      }
    }

    loadRegistry();
    return () => {
      isMounted = false;
    };
  }, [isOpen, user]);

  if (!isOpen || !user) return null;

  const handleCopyId = () => {
    navigator.clipboard.writeText(user.id);
    setCopiedId(true);
    setTimeout(() => setCopiedId(false), 2000);
  };

  const handleCopyNis = () => {
    if (!user.nis) return;
    navigator.clipboard.writeText(user.nis);
    setCopiedNis(true);
    setTimeout(() => setCopiedNis(false), 2000);
  };

  const syntheticEmail = user.nis ? `${user.nis}@snapan.id` : `${user.username || user.id.slice(0, 8)}@snapan.id`;

  const handleCopyEmail = () => {
    navigator.clipboard.writeText(syntheticEmail);
    setCopiedEmail(true);
    setTimeout(() => setCopiedEmail(false), 2000);
  };

  const handleSaveNis = async () => {
    if (!onUpdateNis) return;
    setNisErrorMsg(null);
    setIsSavingNis(true);
    try {
      await onUpdateNis(user.id, inputNis.trim() || null, user.nis);
      setIsEditingNis(false);
      // Refresh registry info
      const updatedInfo = await adminService.getStudentRegistryInfo(inputNis.trim() || user.id);
      setRegistryInfo(updatedInfo);
    } catch (err: any) {
      setNisErrorMsg(err?.message || 'Gagal memperbarui NIS.');
    } finally {
      setIsSavingNis(false);
    }
  };

  return (
    <AdminModalPortal isOpen={isOpen} onClose={onClose}>
      <div
        style={{
          width: '100%',
          maxWidth: '820px',
          background: '#ffffff',
          borderRadius: '8px',
          border: '1px solid #e4e7ec',
          boxShadow: '0 8px 16px -4px rgba(9, 30, 66, 0.16), 0 0 1px 1px rgba(9, 30, 66, 0.10)',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          maxHeight: '90vh',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div
          style={{
            padding: '16px 24px',
            borderBottom: '1px solid #edf0f2',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            background: '#ffffff',
          }}
        >
          <div>
            <h3 style={{ margin: 0, fontSize: '16px', fontWeight: 700, color: '#1f2937' }}>
              Inspeksi Profil Siswa
            </h3>
            <p style={{ margin: '2px 0 0', fontSize: '12px', color: '#64748b' }}>
              Bergabung sejak{' '}
              {new Date(user.created_at).toLocaleDateString('id-ID', {
                day: 'numeric',
                month: 'long',
                year: 'numeric',
              })}
            </p>
          </div>
          <AdminTooltip content="Tutup" placement="bottom">
            <button
              type="button"
              onClick={onClose}
              aria-label="Tutup modal"
              style={{
                width: '32px',
                height: '32px',
                borderRadius: '6px',
                background: '#f8fafc',
                border: '1px solid #e4e7ec',
                color: '#64748b',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                fontSize: '14px',
              }}
            >
              <i className="fa-solid fa-xmark"></i>
            </button>
          </AdminTooltip>
        </div>

        {/* Modal Body - 2 Columns Layout */}
        <div
          style={{
            padding: '22px 24px',
            overflowY: 'auto',
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))',
            gap: '20px',
            alignItems: 'start',
          }}
        >
          {/* Kolom 1 (Kiri): Profil & Data Akademik */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Hero Profile Card */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '14px',
                padding: '14px 16px',
                borderRadius: '8px',
                background: '#f8fafc',
                border: '1px solid #e4e7ec',
              }}
            >
              <UserAvatar
                avatarUrl={user.avatar_url}
                name={user.full_name}
                size={54}
                borderRadius="10px"
                role={user.role}
                style={{
                  fontSize: '20px',
                  border: '1px solid rgba(66, 114, 215, 0.2)',
                }}
              />

              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', flexWrap: 'wrap' }}>
                  <h4
                    style={{
                      margin: 0,
                      fontSize: '15px',
                      fontWeight: 700,
                      color: '#1f2937',
                    }}
                  >
                    {user.full_name || 'Siswa SMKN 8'}
                  </h4>
                  {user.is_verified && (
                    <span style={{ display: 'inline-flex', alignItems: 'center' }} title="Akun Terverifikasi (Verified Biru)">
                      <BadgeCheck size={16} fill="#1d64ec" color="#ffffff" className="shrink-0" />
                    </span>
                  )}
                </div>
                <p style={{ margin: '2px 0 6px', fontSize: '12px', color: '#64748b' }}>
                  @{user.username || 'username'}
                </p>

                <div style={{ display: 'flex', gap: '6px', alignItems: 'center', flexWrap: 'wrap' }}>
                  <span
                    style={{
                      display: 'inline-block',
                      padding: '1px 8px',
                      borderRadius: '4px',
                      fontSize: '10.5px',
                      fontWeight: 700,
                      textTransform: 'uppercase',
                      background: user.role === 'admin' ? '#eff6ff' : '#f1f5f9',
                      color: user.role === 'admin' ? '#2563eb' : '#475569',
                      border: `1px solid ${user.role === 'admin' ? '#bfdbfe' : '#e2e8f0'}`,
                    }}
                  >
                    {user.role}
                  </span>

                  <span
                    style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '4px',
                      padding: '1.5px 8px',
                      borderRadius: '4px',
                      fontSize: '10.5px',
                      fontWeight: 600,
                      background: user.is_verified ? '#eff6ff' : '#fff7ed',
                      color: user.is_verified ? '#1d4ed8' : '#ea580c',
                      border: `1px solid ${user.is_verified ? '#bfdbfe' : '#fed7aa'}`,
                    }}
                  >
                    {user.is_verified ? (
                      <BadgeCheck size={12} fill="#1d64ec" color="#ffffff" className="shrink-0" />
                    ) : (
                      <i
                        className="fa-solid fa-circle-exclamation"
                        style={{ fontSize: '9px' }}
                      ></i>
                    )}
                    {user.is_verified ? 'Verified Biru' : 'Belum Verifikasi'}
                  </span>
                </div>
              </div>
            </div>

            {/* Informasi Akademik Card */}
            <div>
              <div
                style={{
                  fontSize: '11px',
                  fontWeight: 700,
                  textTransform: 'uppercase',
                  letterSpacing: '0.06em',
                  color: '#64748b',
                  marginBottom: '8px',
                }}
              >
                Informasi Akademik & Kejuruan
              </div>

              <div
                style={{
                  background: '#ffffff',
                  border: '1px solid #e4e7ec',
                  borderRadius: '8px',
                  overflow: 'hidden',
                }}
              >
                {/* 1. Baris Nomor Induk Siswa (NIS) dengan Tombol Salin & Edit Inline */}
                <div
                  style={{
                    padding: '10px 14px',
                    borderBottom: '1px solid #f1f3f5',
                    fontSize: '12.5px',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <i className="fa-solid fa-id-card" style={{ width: '14px', color: '#94a3b8' }}></i>
                      Nomor Induk Siswa (NIS)
                    </span>

                    {!isEditingNis ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span
                          style={{
                            fontWeight: 700,
                            fontFamily: 'monospace',
                            color: user.nis ? '#1f2937' : '#94a3b8',
                            fontSize: '13px',
                          }}
                        >
                          {user.nis || 'Belum Ditautkan'}
                        </span>

                        {user.nis && (
                          <AdminTooltip content={copiedNis ? 'NIS Tersalin!' : 'Salin NIS'} placement="top">
                            <button
                              type="button"
                              onClick={handleCopyNis}
                              style={{
                                background: '#f8fafc',
                                border: '1px solid #e2e8f0',
                                borderRadius: '4px',
                                padding: '3px 6px',
                                color: '#475569',
                                cursor: 'pointer',
                                fontSize: '11px',
                                display: 'inline-flex',
                                alignItems: 'center',
                              }}
                            >
                              <i className={`fa-solid ${copiedNis ? 'fa-check text-success' : 'fa-copy'}`}></i>
                            </button>
                          </AdminTooltip>
                        )}

                        {onUpdateNis && (
                          <AdminTooltip content="Ubah NIS Siswa" placement="top">
                            <button
                              type="button"
                              onClick={() => {
                                setInputNis(user.nis || '');
                                setIsEditingNis(true);
                                setNisErrorMsg(null);
                              }}
                              style={{
                                background: '#eff6ff',
                                border: '1px solid #bfdbfe',
                                borderRadius: '4px',
                                padding: '3px 8px',
                                color: '#2563eb',
                                cursor: 'pointer',
                                fontSize: '11px',
                                fontWeight: 600,
                                display: 'inline-flex',
                                alignItems: 'center',
                                gap: '4px',
                              }}
                            >
                              <i className="fa-solid fa-pen-to-square"></i>
                              <span>Ubah</span>
                            </button>
                          </AdminTooltip>
                        )}
                      </div>
                    ) : (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <input
                          type="text"
                          value={inputNis}
                          onChange={(e) => setInputNis(e.target.value)}
                          placeholder="Masukkan nomor NIS..."
                          disabled={isSavingNis}
                          style={{
                            padding: '4px 8px',
                            borderRadius: '4px',
                            border: '1px solid #93c5fd',
                            fontSize: '12px',
                            fontFamily: 'monospace',
                            width: '130px',
                            outline: 'none',
                          }}
                        />
                        <button
                          type="button"
                          onClick={handleSaveNis}
                          disabled={isSavingNis}
                          style={{
                            background: '#2563eb',
                            color: '#ffffff',
                            border: 0,
                            borderRadius: '4px',
                            padding: '4px 8px',
                            fontSize: '11px',
                            fontWeight: 600,
                            cursor: isSavingNis ? 'not-allowed' : 'pointer',
                          }}
                        >
                          {isSavingNis ? 'Menyimpan...' : 'Simpan'}
                        </button>
                        <button
                          type="button"
                          onClick={() => {
                            setIsEditingNis(false);
                            setInputNis(user.nis || '');
                            setNisErrorMsg(null);
                          }}
                          disabled={isSavingNis}
                          style={{
                            background: '#f1f5f9',
                            color: '#475569',
                            border: '1px solid #cbd5e1',
                            borderRadius: '4px',
                            padding: '4px 8px',
                            fontSize: '11px',
                            cursor: 'pointer',
                          }}
                        >
                          Batal
                        </button>
                      </div>
                    )}
                  </div>

                  {/* Pesan Error Validasi NIS jika ada */}
                  {nisErrorMsg && (
                    <div
                      style={{
                        marginTop: '6px',
                        padding: '6px 8px',
                        borderRadius: '4px',
                        background: '#fef2f2',
                        border: '1px solid #fecaca',
                        color: '#b91c1c',
                        fontSize: '11px',
                      }}
                    >
                      <i className="fa-solid fa-circle-exclamation" style={{ marginRight: '4px' }}></i>
                      {nisErrorMsg}
                    </div>
                  )}
                </div>

                {/* 2. Baris Status Klaim Buku Induk */}
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    borderBottom: '1px solid #f1f3f5',
                    fontSize: '12.5px',
                  }}
                >
                  <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <i className="fa-solid fa-book-bookmark" style={{ width: '14px', color: '#94a3b8' }}></i>
                    Status Buku Induk
                  </span>
                  <div>
                    {isLoadingRegistry ? (
                      <span style={{ color: '#94a3b8', fontSize: '11px' }}>Memeriksa...</span>
                    ) : registryInfo ? (
                      <span
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '5px',
                          padding: '1.5px 8px',
                          borderRadius: '4px',
                          fontSize: '11px',
                          fontWeight: 600,
                          background: '#ecfdf5',
                          color: '#047857',
                          border: '1px solid #a7f3d0',
                        }}
                      >
                        <i className="fa-solid fa-circle-check" style={{ fontSize: '10px' }}></i>
                        Terdaftar di Buku Induk ({registryInfo.class_group})
                      </span>
                    ) : (
                      <span
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '5px',
                          padding: '1.5px 8px',
                          borderRadius: '4px',
                          fontSize: '11px',
                          fontWeight: 600,
                          background: '#fef3c7',
                          color: '#b45309',
                          border: '1px solid #fde68a',
                        }}
                      >
                        <i className="fa-solid fa-triangle-exclamation" style={{ fontSize: '10px' }}></i>
                        Akun Manual / NIS Belum Terindeks
                      </span>
                    )}
                  </div>
                </div>

                {/* 3. Baris Tanggal Sinkronisasi / Klaim NIS */}
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    borderBottom: '1px solid #f1f3f5',
                    fontSize: '12.5px',
                  }}
                >
                  <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <i className="fa-solid fa-clock-rotate-left" style={{ width: '14px', color: '#94a3b8' }}></i>
                    Waktu Klaim NIS
                  </span>
                  <span style={{ fontWeight: 600, color: '#334155', fontSize: '12px' }}>
                    {registryInfo?.claimed_at
                      ? new Date(registryInfo.claimed_at).toLocaleString('id-ID', {
                          day: 'numeric',
                          month: 'short',
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit',
                        })
                      : user.nis
                      ? 'Terikat Langsung'
                      : 'Belum Ada Klaim'}
                  </span>
                </div>

                {/* 4. Baris Email Sintetis Sistem */}
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    borderBottom: '1px solid #f1f3f5',
                    fontSize: '12.5px',
                  }}
                >
                  <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <i className="fa-solid fa-envelope" style={{ width: '14px', color: '#94a3b8' }}></i>
                    Email Autentikasi Sintetis
                  </span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <span
                      style={{
                        fontWeight: 600,
                        fontFamily: 'monospace',
                        color: '#2563eb',
                        fontSize: '11.5px',
                      }}
                    >
                      {syntheticEmail}
                    </span>
                    <AdminTooltip content={copiedEmail ? 'Email Tersalin!' : 'Salin Email'} placement="top">
                      <button
                        type="button"
                        onClick={handleCopyEmail}
                        style={{
                          background: '#f8fafc',
                          border: '1px solid #e2e8f0',
                          borderRadius: '4px',
                          padding: '2px 6px',
                          color: '#475569',
                          cursor: 'pointer',
                          fontSize: '10.5px',
                          display: 'inline-flex',
                          alignItems: 'center',
                        }}
                      >
                        <i className={`fa-solid ${copiedEmail ? 'fa-check text-success' : 'fa-copy'}`}></i>
                      </button>
                    </AdminTooltip>
                  </div>
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    borderBottom: '1px solid #f1f3f5',
                    fontSize: '12.5px',
                  }}
                >
                  <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <i className="fa-solid fa-graduation-cap" style={{ width: '14px', color: '#94a3b8' }}></i>
                    Kelas & Jurusan
                  </span>
                  <span style={{ fontWeight: 600, color: '#1f2937' }}>
                    {user.class_group || 'Umum'}
                  </span>
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    borderBottom: '1px solid #f1f3f5',
                    fontSize: '12.5px',
                  }}
                >
                  <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <i className="fa-solid fa-mobile-screen-button" style={{ width: '14px', color: '#94a3b8' }}></i>
                    Versi Aplikasi di HP
                  </span>
                  <span style={{ fontWeight: 600 }}>
                    <AppVersionBadge
                      version={user.last_app_version}
                      latestVersion={latestVersion}
                      emptyLabel="Belum Tersinkron"
                      size="md"
                    />
                  </span>
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    borderBottom: '1px solid #f1f3f5',
                    fontSize: '12.5px',
                  }}
                >
                  <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <i className="fa-solid fa-bag-shopping" style={{ width: '14px', color: '#94a3b8' }}></i>
                    Transaksi COD
                  </span>
                  <span style={{ fontWeight: 600, color: '#1f2937', fontVariantNumeric: 'tabular-nums' }}>
                    {user.verified_sales_count || 0} order
                  </span>
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    borderBottom: '1px solid #f1f3f5',
                    fontSize: '12.5px',
                  }}
                >
                  <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <i className="fa-solid fa-chart-line" style={{ width: '14px', color: '#94a3b8' }}></i>
                    Total Perputaran
                  </span>
                  <span style={{ fontWeight: 700, color: '#4272d7', fontVariantNumeric: 'tabular-nums' }}>
                    Rp {(user.total_revenue_idr || 0).toLocaleString('id-ID')}
                  </span>
                </div>

                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '10px 14px',
                    fontSize: '12.5px',
                  }}
                >
                  <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <i className="fa-solid fa-fingerprint" style={{ width: '14px', color: '#94a3b8' }}></i>
                    User UUID
                  </span>
                  <AdminTooltip content={copiedId ? 'UUID tersalin!' : 'Salin UUID'} placement="left">
                    <button
                      type="button"
                      onClick={handleCopyId}
                      style={{
                        background: '#f8fafc',
                        border: '1px solid #e4e7ec',
                        borderRadius: '4px',
                        padding: '2px 8px',
                        fontFamily: 'monospace',
                        fontSize: '11px',
                        color: '#4272d7',
                        cursor: 'pointer',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '5px',
                      }}
                    >
                      <span>{user.id.slice(0, 8)}...</span>
                      <span style={{ fontSize: '10px', color: '#64748b' }}>
                        {copiedId ? 'Disalin' : 'Salin'}
                      </span>
                    </button>
                  </AdminTooltip>
                </div>
              </div>
            </div>
          </div>

          {/* Kolom 2 (Kanan): Otorisasi & Kontrol Akses */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Otorisasi Hak Akses (Dropdown Input) */}
            <div>
              <div
                style={{
                  fontSize: '11px',
                  fontWeight: 700,
                  textTransform: 'uppercase',
                  letterSpacing: '0.06em',
                  color: '#64748b',
                  marginBottom: '8px',
                }}
              >
                Otorisasi Hak Akses (RBAC)
              </div>

              <RoleSelectDropdown
                currentRole={user.role as UserRole}
                onChangeRole={(newRole) => onChangeRole(user, newRole)}
                disabled={isUpdating}
              />

              <p style={{ margin: '6px 0 0', fontSize: '11px', color: '#94a3b8' }}>
                Perubahan hak akses diterapkan langsung ke baris database akun.
              </p>
            </div>

            {/* Status Verifikasi Resmi Card */}
            <div>
              <div
                style={{
                  fontSize: '11px',
                  fontWeight: 700,
                  textTransform: 'uppercase',
                  letterSpacing: '0.06em',
                  color: '#64748b',
                  marginBottom: '8px',
                }}
              >
                Tindakan Status Verifikasi
              </div>

              <div
                style={{
                  padding: '14px 16px',
                  background: user.is_verified ? '#f0f7ff' : '#fafaf9',
                  border: user.is_verified ? '1px solid #bfdbfe' : '1px solid #e7e5e4',
                  borderRadius: '8px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '10px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  {user.is_verified ? (
                    <BadgeCheck size={18} fill="#1d64ec" color="#ffffff" className="shrink-0" />
                  ) : (
                    <i
                      className="fa-solid fa-circle-question"
                      style={{
                        color: '#78716c',
                        fontSize: '15px',
                      }}
                    ></i>
                  )}
                  <span
                    style={{
                      fontSize: '13px',
                      fontWeight: 700,
                      color: user.is_verified ? '#1d4ed8' : '#44403c',
                    }}
                  >
                    {user.is_verified ? 'Lencana Verified Biru Aktif' : 'Status Belum Terverifikasi'}
                  </span>
                </div>

                <p
                  style={{
                    margin: 0,
                    fontSize: '11.5px',
                    lineHeight: 1.45,
                    color: user.is_verified ? '#1e40af' : '#78716c',
                  }}
                >
                  {user.is_verified
                    ? 'Akun telah divalidasi sebagai siswa/staff resmi SMKN 8 Semarang dengan lencana verified biru terpercaya.'
                    : 'Berikan lencana verified biru resmi setelah memeriksa identitas dan NIS/NISN siswa.'}
                </p>

                <button
                  type="button"
                  disabled={isUpdating}
                  onClick={() => onToggleVerify(user.id, user.is_verified)}
                  style={{
                    width: '100%',
                    height: '36px',
                    marginTop: '4px',
                    padding: '0 14px',
                    borderRadius: '6px',
                    fontSize: '12.5px',
                    fontWeight: 600,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '7px',
                    cursor: isUpdating ? 'not-allowed' : 'pointer',
                    border: user.is_verified ? '1px solid #fca5a5' : '1px solid #1d64ec',
                    background: user.is_verified ? '#fef2f2' : '#1d64ec',
                    color: user.is_verified ? '#dc2626' : '#ffffff',
                    boxShadow: user.is_verified ? 'none' : '0 2px 6px rgba(29, 100, 236, 0.28)',
                    transition: 'all 120ms ease',
                  }}
                >
                  {isUpdating ? (
                    <i className="fa-solid fa-arrows-rotate fa-spin"></i>
                  ) : user.is_verified ? (
                    <i className="fa-solid fa-ban"></i>
                  ) : (
                    <BadgeCheck size={15} fill="#ffffff" color="#1d64ec" />
                  )}
                  <span>
                    {isUpdating
                      ? 'Memproses...'
                      : user.is_verified
                      ? 'Cabut Lencana Verified Biru'
                      : 'Beri Lencana Verified Biru'}
                  </span>
                </button>
              </div>
            </div>

            {/* Akses Ikon Maskot (Mascot Flair) */}
            <div>
              <div
                style={{
                  fontSize: '11px',
                  fontWeight: 700,
                  textTransform: 'uppercase',
                  letterSpacing: '0.06em',
                  color: '#64748b',
                  marginBottom: '8px',
                }}
              >
                Akses Ikon Maskot (Mascot Flair)
              </div>

              <div
                style={{
                  padding: '14px 16px',
                  background: (user.can_use_mascot ?? true) ? '#f0fdf4' : '#fafaf9',
                  border: (user.can_use_mascot ?? true) ? '1px solid #bbf7d0' : '1px solid #e7e5e4',
                  borderRadius: '8px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '10px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  {(user.can_use_mascot ?? true) ? (
                    <Sparkles size={18} className="text-emerald-600 shrink-0" />
                  ) : (
                    <i
                      className="fa-solid fa-ban"
                      style={{
                        color: '#78716c',
                        fontSize: '15px',
                      }}
                    ></i>
                  )}
                  <span
                    style={{
                      fontSize: '13px',
                      fontWeight: 700,
                      color: (user.can_use_mascot ?? true) ? '#15803d' : '#44403c',
                    }}
                  >
                    {(user.can_use_mascot ?? true) ? 'Akses Maskot Aktif' : 'Akses Maskot Dicabut'}
                  </span>
                </div>

                <p
                  style={{
                    margin: 0,
                    fontSize: '11.5px',
                    lineHeight: 1.45,
                    color: (user.can_use_mascot ?? true) ? '#166534' : '#78716c',
                  }}
                >
                  {(user.can_use_mascot ?? true)
                    ? 'Siswa ini diizinkan memilih dan menampilkan lencana maskot profil & postingan.'
                    : 'Akses fitur maskot untuk siswa ini sedang dinonaktifkan oleh administrator.'}
                </p>

                <button
                  type="button"
                  disabled={isUpdating}
                  onClick={() => onToggleMascotAccess?.(user.id, user.can_use_mascot ?? true)}
                  style={{
                    width: '100%',
                    height: '36px',
                    marginTop: '4px',
                    padding: '0 14px',
                    borderRadius: '6px',
                    fontSize: '12.5px',
                    fontWeight: 600,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '7px',
                    cursor: isUpdating ? 'not-allowed' : 'pointer',
                    border: (user.can_use_mascot ?? true) ? '1px solid #fca5a5' : '1px solid #16a34a',
                    background: (user.can_use_mascot ?? true) ? '#fef2f2' : '#16a34a',
                    color: (user.can_use_mascot ?? true) ? '#dc2626' : '#ffffff',
                    boxShadow: (user.can_use_mascot ?? true) ? 'none' : '0 2px 6px rgba(22, 163, 74, 0.28)',
                    transition: 'all 120ms ease',
                  }}
                >
                  {isUpdating ? (
                    <i className="fa-solid fa-arrows-rotate fa-spin"></i>
                  ) : (user.can_use_mascot ?? true) ? (
                    <i className="fa-solid fa-ban"></i>
                  ) : (
                    <Sparkles size={15} />
                  )}
                  <span>
                    {isUpdating
                      ? 'Memproses...'
                      : (user.can_use_mascot ?? true)
                      ? 'Cabut Akses Maskot'
                      : 'Beri Akses Maskot'}
                  </span>
                </button>
              </div>
            </div>

            {/* Status Penangguhan / Suspend Akun (Pelanggaran) */}
            <div>
              <div
                style={{
                  fontSize: '11px',
                  fontWeight: 700,
                  textTransform: 'uppercase',
                  letterSpacing: '0.06em',
                  color: '#64748b',
                  marginBottom: '8px',
                }}
              >
                Pengawasan & Penangguhan Akun
              </div>

              <div
                style={{
                  padding: '14px 16px',
                  background: Boolean(user.is_suspended && (!user.suspended_until || new Date(user.suspended_until) > new Date())) ? '#fff1f2' : '#f8fafc',
                  border: Boolean(user.is_suspended && (!user.suspended_until || new Date(user.suspended_until) > new Date())) ? '1px solid #fecdd3' : '1px solid #e2e8f0',
                  borderRadius: '8px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '10px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <i
                      className={`fa-solid ${
                        Boolean(user.is_suspended && (!user.suspended_until || new Date(user.suspended_until) > new Date())) ? 'fa-triangle-exclamation' : 'fa-shield-halved'
                      }`}
                      style={{
                        color: Boolean(user.is_suspended && (!user.suspended_until || new Date(user.suspended_until) > new Date())) ? '#e11d48' : '#0284c7',
                        fontSize: '15px',
                      }}
                    ></i>
                    <span
                      style={{
                        fontSize: '13px',
                        fontWeight: 700,
                        color: Boolean(user.is_suspended && (!user.suspended_until || new Date(user.suspended_until) > new Date())) ? '#be123c' : '#1e293b',
                      }}
                    >
                      {Boolean(user.is_suspended && (!user.suspended_until || new Date(user.suspended_until) > new Date())) ? 'Akun Ditangguhkan' : 'Status Akun Normal'}
                    </span>
                  </div>
                  {Boolean(user.is_suspended && (!user.suspended_until || new Date(user.suspended_until) > new Date())) && (
                    <span
                      style={{
                        fontSize: '10px',
                        fontWeight: 700,
                        padding: '2px 6px',
                        borderRadius: '4px',
                        background: '#e11d48',
                        color: '#ffffff',
                      }}
                    >
                      SUSPENDED
                    </span>
                  )}
                </div>

                {Boolean(user.is_suspended && (!user.suspended_until || new Date(user.suspended_until) > new Date())) ? (
                  <div style={{ fontSize: '11.5px', color: '#881337', lineHeight: 1.45 }}>
                    <p style={{ margin: '0 0 4px', fontWeight: 600 }}>
                      Alasan: <span style={{ fontWeight: 400 }}>{user.suspend_reason || 'Pelanggaran aturan transaksi'}</span>
                    </p>
                    <p style={{ margin: 0, fontSize: '11px', color: '#9f1239' }}>
                      Batas Waktu:{' '}
                      <b>
                        {user.suspended_until
                          ? new Date(user.suspended_until).toLocaleString('id-ID', {
                              dateStyle: 'medium',
                              timeStyle: 'short',
                            })
                          : 'Permanen (Tanpa batas)'}
                      </b>
                    </p>
                  </div>
                ) : (
                  <p style={{ margin: 0, fontSize: '11.5px', lineHeight: 1.45, color: '#64748b' }}>
                    Pengguna ini bebas beraktivitas, mempublikasikan postingan feed, dan bertransaksi di marketplace.
                  </p>
                )}

                {Boolean(user.is_suspended && (!user.suspended_until || new Date(user.suspended_until) > new Date())) ? (
                  <button
                    type="button"
                    disabled={isUpdating}
                    onClick={() => onRequestUnsuspend?.(user)}
                    style={{
                      width: '100%',
                      height: '36px',
                      marginTop: '4px',
                      padding: '0 14px',
                      borderRadius: '6px',
                      fontSize: '12.5px',
                      fontWeight: 600,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '7px',
                      cursor: isUpdating ? 'not-allowed' : 'pointer',
                      border: '1px solid #10b981',
                      background: '#10b981',
                      color: '#ffffff',
                      boxShadow: '0 2px 6px rgba(16, 185, 129, 0.28)',
                      transition: 'all 120ms ease',
                    }}
                  >
                    <i className="fa-solid fa-lock-open"></i>
                    <span>Pulihkan & Buka Blokir Akun</span>
                  </button>
                ) : (
                  <button
                    type="button"
                    disabled={isUpdating || user.role === 'admin'}
                    onClick={() => onRequestSuspend?.(user)}
                    style={{
                      width: '100%',
                      height: '36px',
                      marginTop: '4px',
                      padding: '0 14px',
                      borderRadius: '6px',
                      fontSize: '12.5px',
                      fontWeight: 600,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '7px',
                      cursor: isUpdating || user.role === 'admin' ? 'not-allowed' : 'pointer',
                      border: '1px solid #fecdd3',
                      background: '#fff1f2',
                      color: '#e11d48',
                      opacity: user.role === 'admin' ? 0.5 : 1,
                      transition: 'all 120ms ease',
                    }}
                    title={user.role === 'admin' ? 'Akun admin tidak dapat disuspen' : 'Tangguhkan akun siswa'}
                  >
                    <i className="fa-solid fa-ban"></i>
                    <span>Tangguhkan / Suspen Akun</span>
                  </button>
                )}
              </div>
            </div>

            {/* Zona Bahaya: Hapus Akun Permanen */}
            <div>
              <div
                style={{
                  fontSize: '11px',
                  fontWeight: 700,
                  textTransform: 'uppercase',
                  letterSpacing: '0.06em',
                  color: '#dc2626',
                  marginBottom: '8px',
                }}
              >
                Zona Bahaya (Tindakan Permanen)
              </div>

              <div
                style={{
                  padding: '12px 16px',
                  background: '#fef2f2',
                  border: '1px solid #fee2e2',
                  borderRadius: '8px',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '8px',
                }}
              >
                <p style={{ margin: 0, fontSize: '11.5px', color: '#991b1b', lineHeight: 1.4 }}>
                  Menghapus akun akan membersihkan semua postingan produk, obrolan, dan relasi, serta membebaskan kembali username dan NIS.
                </p>

                <button
                  type="button"
                  disabled={isUpdating || user.role === 'admin'}
                  onClick={() => onRequestDelete?.(user)}
                  style={{
                    width: '100%',
                    height: '34px',
                    padding: '0 14px',
                    borderRadius: '6px',
                    fontSize: '12px',
                    fontWeight: 600,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '7px',
                    cursor: isUpdating || user.role === 'admin' ? 'not-allowed' : 'pointer',
                    border: '1px solid #f87171',
                    background: '#dc2626',
                    color: '#ffffff',
                    opacity: user.role === 'admin' ? 0.5 : 1,
                    transition: 'all 120ms ease',
                  }}
                  title={user.role === 'admin' ? 'Akun admin tidak dapat dihapus' : 'Hapus akun siswa secara permanen'}
                >
                  <i className="fa-solid fa-trash-can"></i>
                  <span>Hapus Akun Pengguna Secara Permanen</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Modal Footer */}
        <div
          style={{
            padding: '12px 24px',
            borderTop: '1px solid #f1f3f5',
            background: '#f8fafc',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'flex-end',
          }}
        >
          <button
            type="button"
            onClick={onClose}
            style={{
              height: '36px',
              padding: '0 18px',
              fontSize: '13px',
              fontWeight: 600,
              background: '#ffffff',
              border: '1px solid #e4e7ec',
              color: '#475569',
              borderRadius: '6px',
              cursor: 'pointer',
            }}
          >
            Selesai
          </button>
        </div>
      </div>
    </AdminModalPortal>
  );
}
