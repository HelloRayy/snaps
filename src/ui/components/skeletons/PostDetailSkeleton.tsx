import React from 'react';
import { ChevronLeft } from 'lucide-react';

interface PostDetailSkeletonProps {
  onBack?: () => void;
}

export const PostDetailSkeleton: React.FC<PostDetailSkeletonProps> = ({ onBack }) => {
  return (
    <div className="h-full w-full overflow-y-auto bg-white font-gt-standard select-none animate-pulse">
      {/* 1:1 GlassToolbarTop Skeleton */}
      <header
        className="sticky top-0 left-0 right-0 z-40 bg-white/85 backdrop-blur-2xl border-b border-slate-200/80 px-3.5 h-[52px] flex items-center justify-between max-w-xl mx-auto"
        style={{
          paddingTop: 'env(safe-area-inset-top, 0px)',
        }}
      >
        <button
          type="button"
          onClick={onBack}
          className="w-10 h-10 rounded-full flex items-center justify-center text-slate-800 hover:bg-slate-100 transition-all cursor-pointer"
          aria-label="Kembali"
        >
          <ChevronLeft className="w-5 h-5 stroke-[2.25] text-slate-800" />
        </button>

        <h1 className="font-semibold text-[17px] text-slate-900 tracking-[-0.4px]">
          Postingan
        </h1>

        <div className="w-16 h-[38px] rounded-full bg-slate-100 border border-slate-200/80" />
      </header>

      {/* Main Post Card Shimmer */}
      <main className="max-w-xl mx-auto px-4 py-4 space-y-4">
        {/* Author Header */}
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-slate-200 shrink-0" />
          <div className="space-y-1.5 flex-1 min-w-0">
            <div className="w-28 h-3.5 bg-slate-200 rounded" />
            <div className="w-20 h-2.5 bg-slate-100 rounded" />
          </div>
        </div>

        {/* Post Text */}
        <div className="space-y-2 pt-1">
          <div className="w-full h-3.5 bg-slate-200 rounded" />
          <div className="w-4/5 h-3.5 bg-slate-200 rounded" />
          <div className="w-2/3 h-3.5 bg-slate-100 rounded" />
        </div>

        {/* Media Box */}
        <div className="w-full aspect-video bg-slate-100 rounded-[18px] border border-slate-200/60" />

        {/* Action Bar */}
        <div className="flex items-center justify-between pt-2 border-t border-slate-100">
          <div className="flex items-center gap-4">
            <div className="w-10 h-6 bg-slate-100 rounded-full" />
            <div className="w-10 h-6 bg-slate-100 rounded-full" />
            <div className="w-10 h-6 bg-slate-100 rounded-full" />
          </div>
          <div className="w-12 h-5 bg-slate-100 rounded-md" />
        </div>

        {/* Comments Section Divider */}
        <div className="pt-4 border-t border-slate-100 flex items-center justify-between">
          <div className="w-24 h-4 bg-slate-200 rounded" />
          <div className="w-16 h-3 bg-slate-100 rounded" />
        </div>

        {/* Comment Items Shimmer */}
        <div className="space-y-4 pt-2">
          {[1, 2, 3].map((i) => (
            <div key={i} className="flex items-start gap-3">
              <div className="w-9 h-9 rounded-full bg-slate-100 shrink-0" />
              <div className="flex-1 space-y-1.5">
                <div className="w-24 h-3 bg-slate-200 rounded" />
                <div className="w-3/4 h-3 bg-slate-100 rounded" />
              </div>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
};
