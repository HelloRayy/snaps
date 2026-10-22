import React from 'react';
import { motion } from 'framer-motion';
import { Heart } from 'lucide-react';
import { formatCompactNumber } from '@/utils/formatters';
import { SmoothCommentIcon } from '@/ui/components/icons';
import { triggerHaptic } from '@/utils/haptics';

interface CommentActionBarProps {
  isLiked: boolean;
  likesCount: number;
  onLike?: () => void;
  onReply?: () => void;
  onShare?: () => void;
  onRepost?: () => void;
}

export const CommentActionBar: React.FC<CommentActionBarProps> = ({
  isLiked,
  likesCount,
  onLike,
  onReply,
}) => {
  return (
    <div
      onClick={(e) => e.stopPropagation()}
      className="flex items-center gap-3.5 text-slate-700 font-normal pt-1.5 select-none"
    >
      {/* 1. Suka (Like) - Flutter 1:1 CommentHeartButton */}
      <motion.button
        type="button"
        whileTap={{ scale: 0.92 }}
        onClick={(e) => {
          e.stopPropagation();
          triggerHaptic(isLiked ? 'light' : 'medium');
          onLike?.();
        }}
        className="flex items-center gap-1 cursor-pointer select-none group leading-none"
        aria-label={`Sukai komentar. ${likesCount} suka`}
      >
        <motion.div
          className="flex items-center justify-center shrink-0"
          animate={isLiked ? { scale: [1, 1.4, 0.9, 1.1, 1] } : { scale: 1 }}
          transition={{ duration: 0.3 }}
        >
          <Heart
            className={`w-4 h-4 stroke-[1.8] transition-colors duration-200 ${
              isLiked ? 'fill-rose-500 text-rose-500 stroke-rose-500' : 'text-slate-500 group-hover:text-rose-500'
            }`}
          />
        </motion.div>
        {likesCount > 0 && (
          <span
            className={`text-[12px] leading-none tabular-nums font-medium ${
              isLiked ? 'text-rose-500 font-semibold' : 'text-slate-500'
            }`}
          >
            {formatCompactNumber(likesCount)}
          </span>
        )}
      </motion.button>

      {/* 2. Balas (Comment / Reply) - Flutter 1:1 */}
      <motion.button
        type="button"
        whileTap={{ scale: 0.92 }}
        onClick={(e) => {
          e.stopPropagation();
          triggerHaptic('light');
          onReply?.();
        }}
        className="flex items-center gap-1 cursor-pointer text-slate-500 hover:text-slate-800 transition-colors group select-none leading-none"
        aria-label="Balas komentar"
      >
        <SmoothCommentIcon className="w-4 h-4 stroke-[1.8] text-slate-500 group-hover:text-slate-800 transition-colors shrink-0" />
      </motion.button>
    </div>
  );
};
