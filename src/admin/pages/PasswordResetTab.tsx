import { useEffect, useState } from 'react';
import { supabase } from '../../services/api/supabase';
import { Card } from '../components/tremor/Card';
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

export function PasswordResetTab({ isActive = true }: PasswordResetTabProps) {
  const [requests, setRequests] = useState<PasswordResetRequest[]>([]);
  const [loading, setLoading] = useState(false);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);
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
      let knownTokensByNis: Record<string, Set<string>> = {};

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
    if (isActive) {
      loadRequests();
    }
  }, [isActive]);

  const handleAction = async (requestId: string, action: 'approve' | 'reject', adminNote?: string) => {
    setProcessingId(requestId);
    setMessage(null);
    const { data, error } = await supabase.functions.invoke('admin-reset-password', {
      body: { requestId, action, adminNote },
    });

    if (error || data?.error) {
      setMessage(`Gagal: ${error?.message || data?.error}`);
    } else {
      setMessage(
        action === 'approve'
          ? `Disetujui! Sandi sementara: ${data.tempPassword}`
          : 'Permintaan ditolak.',
      );
      await loadRequests();
    }
    setProcessingId(null);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between" style={{ marginBottom: '20px' }}>
        <div>
          <h2 className="text-lg font-bold text-slate-900" style={{ marginBottom: '4px' }}>Antrean Reset Kata Sandi</h2>
          <p className="text-sm text-slate-500">Verifikasi NIS dan nama siswa sebelum menyetujui reset.</p>
        </div>
        <button
          onClick={loadRequests}
          style={{
            padding: '8px 14px',
            fontSize: '13px',
            fontWeight: 600,
            borderRadius: '8px',
            border: '1px solid #E2E8F0',
            backgroundColor: '#FFFFFF',
            color: '#334155',
            cursor: 'pointer',
          }}
        >
          Refresh
        </button>
      </div>

      {message && (
        <div className="p-3 rounded-lg bg-indigo-50 text-indigo-800 text-sm font-medium">
          {message}
        </div>
      )}

      <div style={{ backgroundColor: '#FFFFFF', borderRadius: '10px', border: '1px solid #E4E7EC', padding: '4px 12px' }}>
        {loading ? (
          <p className="text-sm text-slate-500 py-6 text-center">Memuat permintaan...</p>
        ) : requests.length === 0 ? (
          <p className="text-sm text-slate-500 py-6 text-center">Belum ada permintaan reset kata sandi.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-slate-200 text-slate-500">
                  <th className="py-2 pr-4">NIS</th>
                  <th className="py-2 pr-4">Nama Lengkap</th>
                  <th className="py-2 pr-4">Kelas</th>
                  <th className="py-2 pr-4">Catatan</th>
                  <th className="py-2 pr-4">Status</th>
                  <th className="py-2">Aksi</th>
                </tr>
              </thead>
              <tbody>
                {requests.map((req) => (
                  <tr key={req.id} className="border-b border-slate-100 hover:bg-slate-50/60 transition-colors align-top">
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-slate-900 tabular-nums">{req.nis}</div>
                      <span
                        className={`inline-block mt-1.5 text-[11px] font-semibold px-2 py-0.5 rounded-full ${
                          req.isKnownDevice
                            ? 'bg-emerald-50 text-emerald-700'
                            : 'bg-amber-50 text-amber-700'
                        }`}
                      >
                        {req.isKnownDevice ? 'Perangkat Dikenal' : 'Perangkat Baru'}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-medium text-slate-800">{req.full_name}</td>
                    <td className="py-3.5 px-4 text-slate-600">{req.class_group}</td>
                    <td className="py-3.5 px-4 text-slate-500 max-w-[200px]">{req.notes || '-'}</td>
                    <td className="py-3.5 px-4" style={{ position: 'relative' }}>
                      <div className="flex flex-col items-start gap-1.5">
                        <Badge
                          variant={
                            req.status === 'approved'
                              ? 'success'
                              : req.status === 'rejected'
                              ? 'error'
                              : 'warning'
                          }
                        >
                          {req.status}
                        </Badge>
                        {req.temp_password && (
                          <span className="inline-block rounded-md bg-emerald-50 px-2 py-0.5 text-xs font-mono font-semibold text-emerald-700">
                            {req.temp_password}
                          </span>
                        )}
                        <button
                          type="button"
                          onClick={() => setExpandedId(expandedId === req.id ? null : req.id)}
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '4px',
                            fontSize: '11px',
                            fontWeight: 600,
                            color: '#4F46E5',
                            background: 'none',
                            border: 'none',
                            padding: 0,
                            cursor: 'pointer',
                          }}
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
                            left: '16px',
                            zIndex: 50,
                            minWidth: '230px',
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
                    <td className="py-3.5 px-4">
                      {req.status === 'pending' ? (
                        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                          <button
                            disabled={processingId === req.id}
                            onClick={() => setConfirmModal({ req, action: 'approve', note: '' })}
                            style={{
                              padding: '6px 12px',
                              fontSize: '12px',
                              fontWeight: 600,
                              borderRadius: '8px',
                              border: 'none',
                              backgroundColor: '#3D38F5',
                              color: '#FFFFFF',
                              cursor: processingId === req.id ? 'not-allowed' : 'pointer',
                              opacity: processingId === req.id ? 0.5 : 1,
                            }}
                          >
                            Setujui
                          </button>
                          <button
                            disabled={processingId === req.id}
                            onClick={() => setConfirmModal({ req, action: 'reject', note: '' })}
                            style={{
                              padding: '6px 12px',
                              fontSize: '12px',
                              fontWeight: 600,
                              borderRadius: '8px',
                              border: '1px solid #FECDD3',
                              backgroundColor: '#FFF1F2',
                              color: '#BE123C',
                              cursor: processingId === req.id ? 'not-allowed' : 'pointer',
                              opacity: processingId === req.id ? 0.5 : 1,
                            }}
                          >
                            Tolak
                          </button>
                        </div>
                      ) : (
                        <span className="text-xs text-slate-400">Selesai</span>
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
          style={{
            position: 'fixed',
            inset: 0,
            zIndex: 9999,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: 'rgba(15, 23, 42, 0.45)',
            padding: '16px',
          }}
          onClick={() => setConfirmModal(null)}
        >
          <div
            style={{
              width: '100%',
              maxWidth: '440px',
              borderRadius: '16px',
              backgroundColor: '#FFFFFF',
              padding: '24px',
              boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.12)',
              border: '1px solid #E2E8F0',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <h3 style={{ fontSize: '17px', fontWeight: 700, color: '#0F172A', margin: '0 0 14px 0' }}>
              {confirmModal.action === 'approve'
                ? 'Konfirmasi Setujui Reset Sandi'
                : 'Konfirmasi Tolak Permintaan'}
            </h3>
            <div
              style={{
                borderRadius: '12px',
                backgroundColor: '#F8FAFC',
                border: '1px solid #E2E8F0',
                padding: '12px 14px',
                fontSize: '13px',
                lineHeight: 1.6,
                marginBottom: '14px',
              }}
            >
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
                style={{
                  width: '100%',
                  borderRadius: '10px',
                  border: '1px solid #CBD5E1',
                  padding: '9px 12px',
                  fontSize: '13px',
                  outline: 'none',
                  boxSizing: 'border-box',
                }}
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button
                type="button"
                onClick={() => setConfirmModal(null)}
                style={{
                  padding: '8px 16px',
                  fontSize: '13px',
                  fontWeight: 600,
                  borderRadius: '10px',
                  border: '1px solid #E2E8F0',
                  backgroundColor: '#FFFFFF',
                  color: '#334155',
                  cursor: 'pointer',
                }}
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
                style={{
                  padding: '8px 16px',
                  fontSize: '13px',
                  fontWeight: 600,
                  borderRadius: '10px',
                  border: 'none',
                  backgroundColor: confirmModal.action === 'approve' ? '#3D38F5' : '#E11D48',
                  color: '#FFFFFF',
                  cursor: 'pointer',
                }}
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
