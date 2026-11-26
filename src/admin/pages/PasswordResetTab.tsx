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
  temp_password: string | null;
  admin_note: string | null;
  created_at: string;
  isKnownDevice?: boolean;
}

interface PasswordResetTabProps {
  isActive?: boolean;
}

export function PasswordResetTab({ isActive = true }: PasswordResetTabProps) {
  const [requests, setRequests] = useState<PasswordResetRequest[]>([]);
  const [loading, setLoading] = useState(false);
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

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
        rows.map((r) => ({
          ...r,
          isKnownDevice: Boolean(
            r.device_fcm_token && knownTokensByNis[r.nis]?.has(r.device_fcm_token),
          ),
        })),
      );
    }
    setLoading(false);
  };

  useEffect(() => {
    if (isActive) {
      loadRequests();
    }
  }, [isActive]);

  const handleAction = async (requestId: string, action: 'approve' | 'reject') => {
    setProcessingId(requestId);
    setMessage(null);
    const { data, error } = await supabase.functions.invoke('admin-reset-password', {
      body: { requestId, action },
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
                  <tr key={req.id} className="border-b border-slate-100">
                    <td className="py-3 pr-4 font-semibold">
                      <div>{req.nis}</div>
                      <span
                        className={`inline-block mt-1 text-[11px] font-semibold px-2 py-0.5 rounded-full ${
                          req.isKnownDevice
                            ? 'bg-emerald-50 text-emerald-700'
                            : 'bg-amber-50 text-amber-700'
                        }`}
                      >
                        {req.isKnownDevice ? 'Perangkat Dikenal' : 'Perangkat Baru/Berbeda'}
                      </span>
                    </td>
                    <td className="py-3 pr-4">{req.full_name}</td>
                    <td className="py-3 pr-4">{req.class_group}</td>
                    <td className="py-3 pr-4 text-slate-500">{req.notes || '-'}</td>
                    <td className="py-3 pr-4">
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
                        <div className="text-xs text-emerald-700 font-mono mt-1">
                          Sandi: {req.temp_password}
                        </div>
                      )}
                    </td>
                    <td className="py-3">
                      {req.status === 'pending' ? (
                        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                          <button
                            disabled={processingId === req.id}
                            onClick={() => handleAction(req.id, 'approve')}
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
                            onClick={() => handleAction(req.id, 'reject')}
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
    </div>
  );
}
