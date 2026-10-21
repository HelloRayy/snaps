import React from 'react';
import { cn } from '@/utils/cn';

interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: 'emerald' | 'indigo' | 'amber' | 'rose' | 'slate' | 'blue' | 'purple';
}

const badgeVariants = {
  emerald: 'bg-[#dffcf0] text-[#1f845a] border-[#bff7dc]',
  indigo: 'bg-[#e9f2ff] text-[#0c66e4] border-[#cce0ff]',
  amber: 'bg-[#fff7d6] text-[#974f0c] border-[#fde380]',
  rose: 'bg-[#ffedeb] text-[#c9372c] border-[#ffd2cc]',
  slate: 'bg-[#f1f2f4] text-[#44546f] border-[#dcdfe4]',
  blue: 'bg-[#e9f2ff] text-[#0c66e4] border-[#cce0ff]',
  purple: 'bg-[#f3f0ff] text-[#6e5dc6] border-[#dfd8fd]',
};

export function Badge({ variant = 'slate', className, children, ...props }: BadgeProps) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-x-1 rounded-[3px] px-1.5 py-0.5 text-[11px] font-bold uppercase tracking-wider border',
        badgeVariants[variant],
        className
      )}
      {...props}
    >
      {children}
    </span>
  );
}
