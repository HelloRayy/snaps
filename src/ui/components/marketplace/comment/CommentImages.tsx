import React from 'react';
import { ProgressiveImage } from '@/ui/components/ui/ProgressiveImage';

interface CommentImagesProps {
  images?: string[];
  onImageClick?: (images: string[], index: number) => void;
}

export const CommentImages: React.FC<CommentImagesProps> = ({
  images,
  onImageClick,
}) => {
  if (!images || images.length === 0) return null;

  // 1. Single Image: Adaptive ratio (4:5 on mobile up to 16:10, max height 360px)
  if (images.length === 1) {
    return (
      <div className="pt-2">
        <div
          onClick={(e) => {
            e.stopPropagation();
            onImageClick?.(images, 0);
          }}
          className="relative w-full rounded-2xl overflow-hidden border border-black/10 shadow-2xs max-h-[360px] aspect-[4/5] sm:aspect-[16/10] bg-neutral-100 cursor-pointer touch-pan-y"
        >
          <ProgressiveImage
            src={images[0]}
            alt="Attachment"
            className="w-full h-full object-cover hover:scale-[1.01] transition-transform duration-300 pointer-events-none select-none"
          />
          <div className="absolute inset-0 rounded-2xl ring-1 ring-inset ring-black/10 pointer-events-none z-10" />
        </div>
      </div>
    );
  }

  // 2. Dual Image: 50/50 Split layout with consistent height
  if (images.length === 2) {
    return (
      <div className="pt-2">
        <div className="grid grid-cols-2 gap-1.5 h-44 sm:h-48">
          {images.map((img, idx) => (
            <div
              key={idx}
              onClick={(e) => {
                e.stopPropagation();
                onImageClick?.(images, idx);
              }}
              className="relative w-full h-full rounded-2xl overflow-hidden border border-black/10 shadow-2xs bg-neutral-100 cursor-pointer touch-pan-y"
            >
              <ProgressiveImage
                src={img}
                alt={`Attachment ${idx + 1}`}
                className="w-full h-full object-cover hover:scale-[1.01] transition-transform duration-300 pointer-events-none select-none"
              />
              <div className="absolute inset-0 rounded-2xl ring-1 ring-inset ring-black/10 pointer-events-none z-10" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  // 3. Multi-Image (3+): Smooth horizontal scroll carousel with consistent height
  return (
    <div className="pt-2">
      <div
        className="flex gap-2 overflow-x-auto py-1 scrollbar-none overscroll-x-contain touch-pan-x"
        style={{ WebkitOverflowScrolling: 'touch' }}
      >
        {images.map((img, idx) => (
          <div
            key={idx}
            onClick={(e) => {
              e.stopPropagation();
              onImageClick?.(images, idx);
            }}
            className="relative h-44 sm:h-48 w-36 sm:w-44 rounded-2xl overflow-hidden border border-black/10 shadow-2xs shrink-0 bg-neutral-100 cursor-pointer touch-pan-y"
          >
            <ProgressiveImage
              src={img}
              alt={`Attachment ${idx + 1}`}
              className="w-full h-full object-cover hover:scale-[1.01] transition-transform duration-300 pointer-events-none select-none"
            />
            <div className="absolute inset-0 rounded-2xl ring-1 ring-inset ring-black/10 pointer-events-none z-10" />
          </div>
        ))}
      </div>
    </div>
  );
};
