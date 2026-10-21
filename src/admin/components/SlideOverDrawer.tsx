import React, { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';

interface SlideOverDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  width?: string;
}

export function SlideOverDrawer({
  isOpen,
  onClose,
  title,
  subtitle,
  children,
  footer,
  width = 'max-w-lg',
}: SlideOverDrawerProps) {
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        onClose();
      }
    }
    if (isOpen) {
      document.addEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'hidden';
      document.body.classList.add('admin-has-overlay');
    }
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = '';
      document.body.classList.remove('admin-has-overlay');
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return createPortal(
    <div className="fixed inset-0 overflow-hidden" style={{ zIndex: 100000 }}>
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-[rgba(9,30,66,0.49)] backdrop-blur-xs transition-opacity animate-in fade-in duration-200"
        onClick={onClose}
        aria-hidden="true"
      />

      <div className="fixed inset-y-0 right-0 flex pl-10 max-w-full">
        <div
          className={`w-screen ${width} bg-white border-l border-[#e4e7ec] shadow-[0_8px_16px_-4px_rgba(9,30,66,0.16),0_0_1px_1px_rgba(9,30,66,0.10)] flex flex-col transform transition-transform ease-out duration-300 animate-in slide-in-from-right`}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-[#edf0f2] bg-white sticky top-0 z-10">
            <div>
              <h2 className="text-[15px] font-semibold tracking-tight text-[#172b4d]">
                {title}
              </h2>
              {subtitle && (
                <p className="text-xs text-[#626f86] mt-0.5">{subtitle}</p>
              )}
            </div>
            <button
              onClick={onClose}
              className="h-8 w-8 rounded-[3px] flex items-center justify-center text-[#626f86] hover:text-[#172b4d] hover:bg-[#f1f2f4] transition-colors cursor-pointer"
              aria-label="Tutup panel"
            >
              <X className="h-4 w-4" />
            </button>
          </div>

          {/* Body */}
          <div className="flex-1 overflow-y-auto p-6 space-y-6 text-[#172b4d]">
            {children}
          </div>

          {/* Optional Footer */}
          {footer && (
            <div className="px-6 py-3.5 border-t border-[#dcdfe4] bg-[#fafbfc] flex items-center justify-end gap-2.5">
              {footer}
            </div>
          )}
        </div>
      </div>
    </div>,
    document.body
  );
}
