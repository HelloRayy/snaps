import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { Card } from '../components/tremor/Card';
import { Badge } from '../components/tremor/Badge';

interface PasswordResetRequest {
  id: string;
  nis: string;
  full_name: string;
  class_group: string;
  notes: string | null;
  status: 'pending' | 'approved' | 'rejected';
  temp_password: string | null;
  admin_note: string | null;
  created_at: string;
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
      setRequests(data as PasswordResetRequest[]);
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
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-bold text-slate-900">Antrean Reset Kata Sandi</h2>
          <p className="text-sm text-slate-500">Verifikasi NIS dan nama siswa sebelum menyetujui reset.</p>
        </div>
        <button
          onClick={loadRequests}
          className="px-3 py-1.5 text-sm font-semibold rounded-lg border border-slate-200 bg-white hover:bg-slate-50"
        >
          Refresh
        </button>
      </div>

      {message && (
        <div className="p-3 rounded-lg bg-indigo-50 text-indigo-800 text-sm font-medium">
          {message}
        </div>
      )}

      <Card>
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
                    <td className="py-3 pr-4 font-semibold">{req.nis}</td>
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
                        <div className="flex gap-2">
                          <button
                            disabled={processingId === req.id}
                            onClick={() => handleAction(req.id, 'approve')}
                            className="px-2.5 py-1 text-xs font-semibold rounded bg-indigo-600 text-white hover:bg-indigo-700 disabled:opacity-50"
                          >
                            Setujui
                          </button>
                          <button
                            disabled={processingId === req.id}
                            onClick={() => handleAction(req.id, 'reject')}
                            className="px-2.5 py-1 text-xs font-semibold rounded bg-rose-50 text-rose-700 hover:bg-rose-100 disabled:opacity-50"
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
      </Card>
    </div>
  );
}
