import React, { useEffect, useState } from 'react';
import { Download, Sparkles, X, ShieldCheck, Zap, History, ChevronRight } from 'lucide-react';
import { supabase } from '@/services/api/supabase';

interface CustomPwaInstallModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirmInstall: () => void;
}

interface LatestReleaseInfo {
  versionName: string;
  versionCode: number;
  title?: string;
  changelog?: string;
  downloadUrl?: string;
}

export const CustomPwaInstallModal: React.FC<CustomPwaInstallModalProps> = ({
  isOpen,
  onClose,
  onConfirmInstall,
}) => {
  const [releaseInfo, setReleaseInfo] = useState<LatestReleaseInfo>({
    versionName: '1.0.8',
    versionCode: 8,
    title: 'Snaps Beta Release',
    changelog: 'Stabilitas feed, performa COD campus meeting point, dan optimasi chat realtime.',
    downloadUrl: 'https://github.com/HelloRayy/snaps/releases/latest/download/app-release.apk',
  });
  const [loadingRelease, setLoadingRelease] = useState(false);

  useEffect(() => {
    if (!isOpen) return;

    let isMounted = true;
    const fetchLatestRelease = async () => {
      try {
        setLoadingRelease(true);
        const { data, error } = await (supabase as any)
          .from('app_versions')
          .select('*')
          .eq('is_active', true)
          .order('version_code', { ascending: false })
          .limit(1);

        if (!error && data && data.length > 0 && isMounted) {
          const row = data[0];
          setReleaseInfo({
            versionName: row.version_name || '1.0.8',
            versionCode: row.version_code || 8,
            title: row.title || 'Snaps Beta Release',
            changelog: row.changelog || 'Peningkatan performa dan penambahan fitur terbaru.',
            downloadUrl: row.download_url || 'https://github.com/HelloRayy/snaps/releases/latest/download/app-release.apk',
          });
        }
      } catch (e) {
        // Fallback default gracefully retained
      } finally {
        if (isMounted) setLoadingRelease(false);
      }
    };

    fetchLatestRelease();

    return () => {
      isMounted = false;
    };
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-200 font-gt-standard select-none">
      {/* App Store / Release Card Style Bottom Sheet */}
      <div className="relative w-full max-w-sm bg-white rounded-[32px] p-6 shadow-2xl space-y-4 animate-in slide-in-from-bottom-6 duration-250 border border-neutral-100 overflow-hidden">
        {/* Decorative Top Accent Glow */}
        <div className="absolute top-0 left-0 right-0 h-2 bg-gradient-to-r from-blue-500 via-indigo-500 to-emerald-400" />
        
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-1.5 rounded-full text-neutral-400 hover:text-slate-900 hover:bg-neutral-100 transition-colors cursor-pointer"
          aria-label="Tutup Modal"
        >
          <X className="h-5 w-5" />
        </button>

        {/* App Header & Release Tag */}
        <div className="flex items-center gap-3.5 pt-1">
          <div className="relative flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-[#1d64ec] text-white shadow-lg shadow-blue-500/25 border border-blue-400/30">
            <span className="text-2xl font-black font-shopify-sans">S8</span>
            <div className="absolute -bottom-1 -right-1 h-5 w-5 rounded-full bg-emerald-500 border-2 border-white flex items-center justify-center text-white">
              <ShieldCheck className="h-3 w-3" />
            </div>
          </div>

          <div className="space-y-1">
            <div className="flex items-center gap-1.5">
              <h3 className="text-lg font-extrabold text-slate-900 font-shopify-sans leading-tight">
                sNaps Android
              </h3>
              <span className="text-[10px] font-bold text-blue-700 bg-blue-50 px-2 py-0.5 rounded-full border border-blue-200">
                Beta {releaseInfo.versionName}
              </span>
            </div>

            <p className="text-xs text-neutral-500 font-medium">
              Aplikasi Siswa SMKN 8 Semarang
            </p>

            <div className="flex items-center gap-2 text-xs">
              <span className="text-emerald-600 font-bold flex items-center gap-1 text-[11px]">
                <Zap className="h-3 w-3" /> Build #{releaseInfo.versionCode}
              </span>
              <span className="text-neutral-300">•</span>
              <span className="text-neutral-500 font-semibold">Flutter Native</span>
            </div>
          </div>
        </div>

        {/* Dynamic Changelog Box */}
        <div className="relative rounded-2xl bg-gradient-to-br from-blue-50/70 to-indigo-50/50 p-3.5 border border-blue-100/80 space-y-2">
          <div className="flex items-center justify-between">
            <div className="inline-flex items-center gap-1 text-[11px] font-bold text-blue-700">
              <Sparkles className="h-3.5 w-3.5 text-blue-600" />
              <span>{releaseInfo.title || 'Catatan Rilis Terbaru'}</span>
            </div>
            {loadingRelease && (
              <span className="text-[10px] text-blue-500 animate-pulse">Memuat info...</span>
            )}
          </div>
          
          <div className="text-xs text-slate-700 font-normal leading-relaxed line-clamp-3 bg-white/80 rounded-xl p-2.5 border border-blue-100/50">
            {releaseInfo.changelog || 'Pembaruan fitur dan performa berkala.'}
          </div>
          
          <div className="flex items-center gap-1 text-[10px] text-neutral-500 font-medium pt-0.5">
            <History className="h-3 w-3 text-neutral-400" />
            <span>Otomatis mendownload versi rilis paling mutakhir</span>
          </div>
        </div>

        {/* Primary Download CTA Button (Permanent Latest Release) */}
        <div className="space-y-2 pt-1">
          <a
            href="https://github.com/HelloRayy/snaps/releases/latest/download/app-release.apk"
            target="_blank"
            rel="noopener noreferrer"
            download="app-release.apk"
            onClick={onClose}
            className="w-full flex items-center justify-center gap-2 font-bold h-13 text-base rounded-full bg-[#1d64ec] hover:bg-blue-600 shadow-md shadow-blue-500/25 text-white active:scale-[0.98] transition-all cursor-pointer"
          >
            <Download className="h-5 w-5 text-white" />
            <span>Download APK Android (Beta)</span>
          </a>

          {/* Secondary Option: PWA Web Fallback */}
          <button
            type="button"
            onClick={onConfirmInstall}
            className="w-full flex items-center justify-center gap-1.5 font-semibold h-10 text-xs rounded-full bg-neutral-100 hover:bg-neutral-200 text-neutral-700 active:scale-[0.98] transition-all cursor-pointer"
          >
            <span>Atau pasang via Browser (PWA)</span>
            <ChevronRight className="h-3.5 w-3.5 text-neutral-400" />
          </button>

          <button
            type="button"
            onClick={onClose}
            className="w-full text-center text-xs font-medium text-neutral-400 hover:text-slate-700 py-1 cursor-pointer transition-colors"
          >
            Batal
          </button>
        </div>
      </div>
    </div>
  );
};

