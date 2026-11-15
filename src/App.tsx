import { Suspense, lazy } from 'react';
import { useAuth } from '@/ui/hooks/useAuth';
import { useSmoothScroll } from '@/ui/hooks/useSmoothScroll';
import { useAppNavigation } from '@/ui/navigation/useAppNavigation';

// Dynamic lazy imports
const OnboardingScreen = lazy(() =>
  import('@/ui/components/onboarding/OnboardingScreen').then((m) => ({ default: m.OnboardingScreen }))
);
const PwaLandingPage = lazy(() =>
  import('@/ui/components/pwa/PwaLandingPage').then((m) => ({ default: m.PwaLandingPage }))
);
const AdminDashboard = lazy(() =>
  import('@/admin/pages/AdminDashboard').then((m) => ({ default: m.AdminDashboard }))
);
const AdminLoginPage = lazy(() =>
  import('@/admin/pages/AdminLoginPage').then((m) => ({ default: m.AdminLoginPage }))
);
import { AccountSuspendedScreen } from '@/ui/components/auth/AccountSuspendedScreen';

export function App() {
  useSmoothScroll();
  const { user, profile } = useAuth();

  const {
    hasCompletedOnboarding,
    setHasCompletedOnboarding,
    currentRoute,
    setCurrentRoute,
    navigateToHome,
  } = useAppNavigation();

  // Admin Route Flags with path normalization (strips trailing slashes & supports hash routes)
  const windowPath = typeof window !== 'undefined' ? window.location.pathname.replace(/\/+$/, '').toLowerCase() : '';
  const windowHash = typeof window !== 'undefined' ? window.location.hash.toLowerCase() : '';
  const currentPath = currentRoute.replace(/\/+$/, '').toLowerCase();

  const isAdminLoginRoute =
    currentPath === '/admin/login' ||
    windowPath === '/admin/login' ||
    windowHash === '#/admin/login' ||
    windowHash === '#admin/login';

  const isAdminDashboardRoute =
    ((currentPath === '/admin' || currentPath.startsWith('/admin/')) ||
      (windowPath === '/admin' || windowPath.startsWith('/admin/')) ||
      (windowHash === '#/admin' || windowHash === '#admin' || windowHash.startsWith('#/admin/'))) &&
    !isAdminLoginRoute;

  // Check Account Suspension Status (SNAPS-16)
  const isAccountSuspended = Boolean(
    user &&
    profile?.is_suspended &&
    (!profile.suspended_until || new Date(profile.suspended_until).getTime() > Date.now()) &&
    profile.role !== 'admin'
  );

  return (
    <Suspense fallback={<div className="min-h-screen bg-white" />}>
      {/* Admin Portal Dedicated Routes (Kumo UI) */}
      {isAdminLoginRoute ? (
        <AdminLoginPage
          onSuccess={() => {
            setCurrentRoute('/admin');
            window.history.pushState({}, '', '/admin');
          }}
          onBackToApp={() => {
            navigateToHome();
          }}
        />
      ) : isAdminDashboardRoute ? (
        <AdminDashboard
          onLogout={() => {
            setCurrentRoute('/admin/login');
            window.history.pushState({}, '', '/admin/login');
          }}
          onNavigateLogin={() => {
            setCurrentRoute('/admin/login');
            window.history.pushState({}, '', '/admin/login');
          }}
        />
      ) : isAccountSuspended ? (
        <AccountSuspendedScreen
          profile={profile as any}
          onLoggedOut={() => {
            window.location.reload();
          }}
        />
      ) : (
        <>
          {/* 1. First-time User Onboarding Screen */}
          {!hasCompletedOnboarding ? (
            <OnboardingScreen
              onComplete={() => {
                try {
                  localStorage.setItem('snapan_has_onboarded', 'true');
                } catch {}
                setHasCompletedOnboarding(true);
                navigateToHome();
              }}
            />
          ) : (
            /* Dedicated Mobile App Download Showcase (Web Feed Disabled) */
            <PwaLandingPage />
          )}
        </>
      )}
    </Suspense>
  );
}

export default App;
