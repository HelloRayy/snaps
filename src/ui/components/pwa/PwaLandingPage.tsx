import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { popSiteHtml } from './popSiteHtml';
import { popSiteMobileHtml } from './popSiteMobileHtml';
import { usePwaLandingEffects } from './usePwaLandingEffects';
import './pwaLanding.css';

interface PwaLandingPageProps {
  onProceedToWeb?: () => void;
}

export const PwaLandingPage: React.FC<PwaLandingPageProps> = ({ onProceedToWeb }) => {
  const [isMobile, setIsMobile] = useState(() => (typeof window !== 'undefined' ? window.innerWidth < 810 : false));
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleResize = () => {
      setIsMobile(window.innerWidth < 810);
    };
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  usePwaLandingEffects({
    containerRef,
    isMobile,
    onProceedToWeb,
  });

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
      className="min-h-screen w-full bg-white font-gt-standard overflow-x-clip antialiased select-none relative"
    >
      <div
        ref={containerRef}
        dangerouslySetInnerHTML={{ __html: isMobile ? popSiteMobileHtml : popSiteHtml }}
      />
    </motion.div>
  );
};
