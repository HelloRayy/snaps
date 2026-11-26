import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../../services/api/supabase';
import { Badge } from '../components/tremor/Badge';

interface PasswordResetRequest {
  id: string;
  nis: string;
  full_name: string;
  class_group: string;
  notes: string | null;
  status: 'pending' | 'approved' | 'rejected';
  device_fcm_token: string | null;
  device_name: string | null;
  temp_password: string | null;
  admin_note: string | null;
  created_at: string;
  isKnownDevice?: boolean;
  knownTokenPreview?: string | null;
}

interface PasswordResetTabProps {
  isActive?: boolean;
}

type StatusFilter = 'all' | 'pending' | 'approved' | 'rejected';

export function PasswordResetTab({ isActive = true }: PasswordResetTabProps) {
  const [requests, setRequests] = useState<PasswordResetRequest[]>([]);
  const [loading, setLoading] = useState(false);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [message, setMessage] = useState<{ text: string; isError?: boolean } | null>(null);
  const [filter, setFilter] = useState<StatusFilter>('all');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [confirmModal, setConfirmModal] = useState<{
    req: PasswordResetRequest;
    action: 'approve' | 'reject';
    note: string;
  } | null>(null);

  const loadRequests = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('password_reset_requests')
      .select('*')
      .order('created_at', { ascending: false });

    if (!error && data) {
      const rows = data as PasswordResetRequest[];
      const nisList = [...new Set(rows.map((r) => r.nis).filter(Boolean))];
      const knownTokensByNis: Record<string, Set<string>> = {};

      if (nisList.length > 0) {
        const { data: profiles } = await supabase
          .from('profiles')
          .select('id, nis')
          .in('nis', nisList);

        if (profiles && profiles.length > 0) {
          const userIds = profiles.map((p: { id: string }) => p.id);
          const { data: tokens } = await supabase
            .from('user_fcm_tokens')
            .select('user_id, fcm_token')
            .in('user_id', userIds);

          const nisByUserId: Record<string, string> = {};
          for (const p of profiles as { id: string; nis: string }[]) {
            nisByUserId[p.id] = p.nis;
          }
          for (const t of (tokens || []) as { user_id: string; fcm_token: string }[]) {
            const nis = nisByUserId[t.user_id];
            if (nis) {
              knownTokensByNis[nis] ??= new Set<string>();
              knownTokensByNis[nis].add(t.fcm_token);
            }
          }
        }
      }

      setRequests(
        rows.map((r) => {
          const knownSet = knownTokensByNis[r.nis];
          const firstKnown = knownSet ? Array.from(knownSet)[0] : null;
          return {
            ...r,
            isKnownDevice: Boolean(r.device_fcm_token && knownSet?.has(r.device_fcm_token)),
            knownTokenPreview: firstKnown ? `${firstKnown.slice(0, 12)}...` : null,
          };
        }),
      );
    }
    setLoading(false);
  };

  useEffect(() => {
    if (isActive) loadRequests();
  }, [isActive]);

  const counts = useMemo(() => {
    let pending = 0;
    let approved = 0;
    let rejected = 0;
    for (const r of requests) {
      if (r.status === 'pending') pending++;
      else if (r.status === 'approved') approved++;
      else if (r.status === 'rejected') rejected++;
    }
    return { pending, approved, rejected };
  }, [requests]);

  const filteredRequests = useMemo(
    () => (filter === 'all' ? requests : requests.filter((r) => r.status === filter)),
    [requests, filter],
  );

  const handleAction = async (requestId: string, action: 'approve' | 'reject', adminNote?: string) => {
    setProcessingId(requestId);
    setMessage(null);
    const { data, error } = await supabase.functions.invoke('admin-reset-password', {
      body: { requestId, action, adminNote },
    });

    if (error || data?.error) {
      setMessage({ text: `Gagal: ${error?.message || data?.error}`, isError: true });
    } else {
      setMessage({
        text: action === 'approve' ? `Disetujui! Sandi sementara: ${data.tempPassword}` : 'Permintaan ditolak.',
      });
      await loadRequests();
    }
    setProcessingId(null);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px' }}>
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: 800, color: '#0F172A', margin: 0 }}>
            Antrean Reset Kata Sandi
          </h2>
          <p style={{ fontSize: '13px', color: '#64748B', margin: '4px 0 0 0' }}>
            Verifikasi NIS, nama siswa, dan perangkat sebelum menyetujui pemulihan sandi.
          </p>
        </div>
        <button
          type="button"
          onClick={loadRequests}
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '6px',
            padding: '8px 14px',
            fontSize: '13px',
            fontWeight: 600,
            borderRadius: '10px',
            border: '1px solid #E2E8F0',
            backgroundColor: '#FFFFFF',
            color: '#334155',
            cursor: 'pointer',
          }}
        >
          <i className="fa-solid fa-rotate-right" style={{ fontSize: '12px' }}></i>
          Refresh
        </button>
      </div>

      {/* KPI Summary Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '12px' }}>
        <div style={{ backgroundColor: '#FFFFFF', borderRadius: '14px', border: '1px solid #E2E8F0', padding: '14px 18px' }}>
          <div style={{ fontSize: '12px', fontWeight: 600, color: '#64748B' }}>Menunggu Verifikasi</div>
          <div style={{ fontSize: '22px', fontWeight: 800, color: '#D97706', marginTop: '2px' }}>{counts.pending}</div>
        </div>
        <div style={{ backgroundColor: '#FFFFFF', borderRadius: '14px', border: '1px solid #E2E8F0', padding: '14px 18px' }}>
          <div style={{ fontSize: '12px', fontWeight: 600, color: '#64748B' }}>Disetujui</div>
          <div style={{ fontSize: '22px', fontWeight: 800, color: '#059669', marginTop: '2px' }}>{counts.approved}</div>
        </div>
        <div style={{ backgroundColor: '#FFFFFF', borderRadius: '14px', border: '1px solid #E2E8F0', padding: '14px 18px' }}>
          <div style={{ fontSize: '12px', fontWeight: 600, color: '#64748B' }}>Ditolak</div>
          <div style={{ fontSize: '22px', fontWeight: 800, color: '#E11D48', marginTop: '2px' }}>{counts.rejected}</div>
        </div>
      </div>

      {message && (
        <div
          style={{
            padding: '10px 14px',
            borderRadius: '10px',
            fontSize: '13px',
            fontWeight: 600,
            backgroundColor: message.isError ? '#FFF1F2' : '#EEF2FF',
            color: message.isError ? '#BE123C' : '#3730A3',
            border: `1px solid ${message.isError ? '#FECDD3' : '#C7D2FE'}`,
          }}
        >
          {message.text}
        </div>
      )}

      {/* Filter Pills + Table */}
      <div style={{ backgroundColor: '#FFFFFF', borderRadius: '14px', border: '1px solid #E2E8F0', padding: '16px' }}>
        <div style={{ display: 'flex', gap: '8px', marginBottom: '14px', flexWrap: 'wrap' }}>
          {(
            [
              ['all', `Semua (${requests.length})`],
              ['pending', `Menunggu (${counts.pending})`],
              ['approved', `Disetujui (${counts.approved})`],
              ['rejected', `Ditolak (${counts.rejected})`],
            ] as [StatusFilter, string][]
          ).map(([key, label]) => {
            const active = filter === key;
            return (
              <button
                key={key}
                type="button"
                onClick={() => setFilter(key)}
                style={{
                  padding: '6px 12px',
                  fontSize: '12px',
                  fontWeight: 600,
                  borderRadius: '999px',
                  border: active ? 'none' : '1px solid #E2E8F0',
                  backgroundColor: active ? '#3D38F5' : '#FFFFFF',
                  color: active ? '#FFFFFF' : '#475569',
                  cursor: 'pointer',
                }}
              >
                {label}
              </button>
            );
          })}
        </div>

        {loading ? (
          <p style={{ fontSize: '13px', color: '#64748B', padding: '24px 0', textAlign: 'center' }}>Memuat permintaan...</p>
        ) : filteredRequests.length === 0 ? (
          <p style={{ fontSize: '13px', color: '#64748B', padding: '24px 0', textAlign: 'center' }}>Tidak ada permintaan pada filter ini.</p>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ backgroundColor: '#F8FAFC', borderBottom: '1px solid #E2E8F0', color: '#64748B', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.04em' }}>
                  <th style={{ padding: '10px 14px' }}>NIS</th>
                  <th style={{ padding: '10px 14px' }}>Nama Lengkap</th>
                  <th style={{ padding: '10px 14px' }}>Kelas</th>
                  <th style={{ padding: '10px 14px' }}>Catatan</th>
                  <th style={{ padding: '10px 14px' }}>Status</th>
                  <th style={{ padding: '10px 14px' }}>Aksi</th>
                </tr>
              </thead>
              <tbody>
                {filteredRequests.map((req) => (
                  <tr key={req.id} style={{ borderBottom: '1px solid #F1F5F9', verticalAlign: 'top' }}>
                    <td style={{ padding: '10px 12px' }}>
                      <div style={{ fontWeight: 700, color: '#0F172A' }}>{req.nis}</div>
                      <span
                        style={{
                          display: 'inline-block',
                          marginTop: '6px',
                          fontSize: '11px',
                          fontWeight: 600,
                          padding: '2px 8px',
                          borderRadius: '999px',
                          backgroundColor: req.isKnownDevice ? '#ECFDF5' : '#FFFBEB',
                          color: req.isKnownDevice ? '#047857' : '#B45309',
                        }}
                      >
                        {req.isKnownDevice ? 'Perangkat Dikenal' : 'Perangkat Baru'}
                      </span>
                    </td>
                    <td style={{ padding: '14px', fontWeight: 600, color: '#1E293B' }}>{req.full_name}</td>
                    <td style={{ padding: '14px', color: '#475569' }}>{req.class_group}</td>
                    <td style={{ padding: '14px', color: '#64748B', maxWidth: '220px' }}>{req.notes || '-'}</td>
                    <td style={{ padding: '14px', position: 'relative' }}>
                      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: '6px' }}>
                        <Badge variant={req.status === 'approved' ? 'success' : req.status === 'rejected' ? 'error' : 'warning'}>
                          {req.status}
                        </Badge>
                        {req.temp_password && (
                          <span style={{ borderRadius: '6px', backgroundColor: '#ECFDF5', padding: '2px 8px', fontSize: '12px', fontFamily: 'monospace', fontWeight: 700, color: '#047857' }}>
                            {req.temp_password}
                          </span>
                        )}
                        <button
                          type="button"
                          onClick={() => setExpandedId(expandedId === req.id ? null : req.id)}
                          style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', fontSize: '11px', fontWeight: 600, color: '#4F46E5', background: 'none', border: 'none', padding: 0, cursor: 'pointer' }}
                        >
                          <span>{expandedId === req.id ? 'Tutup Detail' : 'Lihat Detail'}</span>
                          <span style={{ fontSize: '10px' }}>{expandedId === req.id ? '▲' : '▼'}</span>
                        </button>
                      </div>
                      {expandedId === req.id && (
                        <div
                          style={{
                            position: 'absolute',
                            top: '100%',
                            left: '14px',
                            zIndex: 50,
                            minWidth: '240px',
                            marginTop: '4px',
                            borderRadius: '12px',
                            backgroundColor: '#FFFFFF',
                            border: '1px solid #E2E8F0',
                            boxShadow: '0 10px 25px -5px rgba(15, 23, 42, 0.15)',
                            padding: '10px 12px',
                            fontSize: '11px',
                            color: '#475569',
                            lineHeight: 1.6,
                          }}
                        >
                          <div>
                            <strong>Device Awal:</strong>{' '}
                            <span style={{ fontFamily: 'monospace' }}>{req.knownTokenPreview || 'Belum ada riwayat'}</span>
                          </div>
                          <div>
                            <strong>Device Pengaju:</strong>{' '}
                            <span>{req.device_name || (req.device_fcm_token ? `${req.device_fcm_token.slice(0, 12)}...` : 'Tidak tersedia')}</span>
                          </div>
                        </div>
                      )}
                    </td>
                    <td style={{ padding: '14px' }}>
                      {req.status === 'pending' ? (
                        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                          <button
                            disabled={processingId === req.id}
                            onClick={() => setConfirmModal({ req, action: 'approve', note: '' })}
                            style={{ padding: '6px 12px', fontSize: '12px', fontWeight: 600, borderRadius: '8px', border: 'none', backgroundColor: '#3D38F5', color: '#FFFFFF', cursor: processingId === req.id ? 'not-allowed' : 'pointer', opacity: processingId === req.id ? 0.5 : 1 }}
                          >
                            Setujui
                          </button>
                          <button
                            disabled={processingId === req.id}
                            onClick={() => setConfirmModal({ req, action: 'reject', note: '' })}
                            style={{ padding: '6px 12px', fontSize: '12px', fontWeight: 600, borderRadius: '8px', border: '1px solid #FECDD3', backgroundColor: '#FFF1F2', color: '#BE123C', cursor: processingId === req.id ? 'not-allowed' : 'pointer', opacity: processingId === req.id ? 0.5 : 1 }}
                          >
                            Tolak
                          </button>
                        </div>
                      ) : (
                        <span style={{ fontSize: '12px', color: '#94A3B8' }}>Selesai</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {confirmModal && (
        <div
          style={{ position: 'fixed', inset: 0, zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: 'rgba(15, 23, 42, 0.45)', padding: '16px' }}
          onClick={() => setConfirmModal(null)}
        >
          <div
            style={{ width: '100%', maxWidth: '440px', borderRadius: '16px', backgroundColor: '#FFFFFF', padding: '24px', boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.12)', border: '1px solid #E2E8F0' }}
            onClick={(e) => e.stopPropagation()}
          >
            <h3 style={{ fontSize: '17px', fontWeight: 700, color: '#0F172A', margin: '0 0 14px 0' }}>
              {confirmModal.action === 'approve' ? 'Konfirmasi Setujui Reset Sandi' : 'Konfirmasi Tolak Permintaan'}
            </h3>
            <div style={{ borderRadius: '12px', backgroundColor: '#F8FAFC', border: '1px solid #E2E8F0', padding: '12px 14px', fontSize: '13px', lineHeight: 1.6, marginBottom: '14px' }}>
              <div><span style={{ color: '#64748B' }}>NIS:</span> <strong>{confirmModal.req.nis}</strong></div>
              <div><span style={{ color: '#64748B' }}>Nama:</span> <strong>{confirmModal.req.full_name}</strong></div>
              <div><span style={{ color: '#64748B' }}>Kelas:</span> <strong>{confirmModal.req.class_group}</strong></div>
              <div>
                <span style={{ color: '#64748B' }}>Perangkat:</span>{' '}
                <strong style={{ color: confirmModal.req.isKnownDevice ? '#047857' : '#B45309' }}>
                  {confirmModal.req.isKnownDevice ? 'Perangkat Dikenal' : 'Perangkat Baru/Berbeda'}
                </strong>
              </div>
              {confirmModal.req.device_name && (
                <div><span style={{ color: '#64748B' }}>Model HP:</span> <strong>{confirmModal.req.device_name}</strong></div>
              )}
            </div>
            <div style={{ marginBottom: '18px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 600, color: '#475569', marginBottom: '6px' }}>
                Catatan Admin (Opsional)
              </label>
              <input
                type="text"
                value={confirmModal.note}
                onChange={(e) => setConfirmModal({ ...confirmModal, note: e.target.value })}
                placeholder="Tulis catatan jika perlu..."
                style={{ width: '100%', borderRadius: '10px', border: '1px solid #CBD5E1', padding: '9px 12px', fontSize: '13px', outline: 'none', boxSizing: 'border-box' }}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button
                type="button"
                onClick={() => setConfirmModal(null)}
                style={{ padding: '8px 16px', fontSize: '13px', fontWeight: 600, borderRadius: '10px', border: '1px solid #E2E8F0', backgroundColor: '#FFFFFF', color: '#334155', cursor: 'pointer' }}
              >
                Batal
              </button>
              <button
                type="button"
                onClick={() => {
                  const { req, action, note } = confirmModal;
                  setConfirmModal(null);
                  handleAction(req.id, action, note.trim() || undefined);
                }}
                style={{ padding: '8px 16px', fontSize: '13px', fontWeight: 600, borderRadius: '10px', border: 'none', backgroundColor: confirmModal.action === 'approve' ? '#3D38F5' : '#E11D48', color: '#FFFFFF', cursor: 'pointer' }}
              >
                {confirmModal.action === 'approve' ? 'Ya, Setujui' : 'Ya, Tolak'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
