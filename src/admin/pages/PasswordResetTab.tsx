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
                    <td className="py-3.5 px-4">
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
                          className="text-[11px] font-semibold text-indigo-600 hover:underline"
                        >
                          {expandedId === req.id ? 'Tutup Detail' : 'Lihat Detail'}
                        </button>
                      </div>
                      {expandedId === req.id && (
                        <div className="mt-2 rounded-xl bg-slate-50 border border-slate-200 p-2.5 text-[11px] text-slate-600 space-y-1">
                          <div>
                            <span className="font-semibold">Device Awal:</span>{' '}
                            <span className="font-mono">{req.knownTokenPreview || 'Belum ada riwayat'}</span>
                          </div>
                          <div>
                            <span className="font-semibold">Device Pengaju:</span>{' '}
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
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="w-full max-w-md rounded-2xl bg-white p-6 shadow-xl border border-slate-100 space-y-4">
            <h3 className="text-base font-bold text-slate-900">
              {confirmModal.action === 'approve'
                ? 'Konfirmasi Setujui Reset Sandi'
                : 'Konfirmasi Tolak Permintaan'}
            </h3>
            <div className="rounded-xl bg-slate-50 p-3 text-sm space-y-1">
              <div><span className="text-slate-500">NIS:</span> <span className="font-semibold">{confirmModal.req.nis}</span></div>
              <div><span className="text-slate-500">Nama:</span> <span className="font-semibold">{confirmModal.req.full_name}</span></div>
              <div><span className="text-slate-500">Kelas:</span> <span className="font-semibold">{confirmModal.req.class_group}</span></div>
              <div>
                <span className="text-slate-500">Perangkat:</span>{' '}
                <span className={confirmModal.req.isKnownDevice ? 'text-emerald-700 font-semibold' : 'text-amber-700 font-semibold'}>
                  {confirmModal.req.isKnownDevice ? 'Perangkat Dikenal' : 'Perangkat Baru/Berbeda'}
                </span>
              </div>
              {confirmModal.req.device_fcm_token && (
                <div className="text-xs text-slate-400 font-mono">
                  Token: {confirmModal.req.device_fcm_token.slice(0, 14)}...
                </div>
              )}
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-600 mb-1">Catatan Admin (Opsional)</label>
              <input
                type="text"
                value={confirmModal.note}
                onChange={(e) => setConfirmModal({ ...confirmModal, note: e.target.value })}
                placeholder="Tulis catatan jika perlu..."
                className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:border-indigo-500"
              />
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <button
                onClick={() => setConfirmModal(null)}
                className="px-4 py-2 text-sm font-semibold rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50"
              >
                Batal
              </button>
              <button
                onClick={() => {
                  const { req, action, note } = confirmModal;
                  setConfirmModal(null);
                  handleAction(req.id, action, note.trim() || undefined);
                }}
                className={`px-4 py-2 text-sm font-semibold rounded-xl text-white ${
                  confirmModal.action === 'approve'
                    ? 'bg-indigo-600 hover:bg-indigo-700'
                    : 'bg-rose-600 hover:bg-rose-700'
                }`}
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
