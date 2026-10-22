import { useState, useEffect, useRef, useCallback } from 'react';
import { MarketPostItem } from '@/types/marketFeed';
import { MOCK_MARKET_POSTS } from '@/data/mockMarketData';
import { triggerHaptic } from '@/utils/haptics';
import { getPostById, mapSupabasePostToFeedItem } from '@/services/api/marketPostsService';
import { getPostComments, mapSupabaseCommentToPostComment } from '@/services/api/commentService';

export function getPostIdFromLocation(): string | null {
  if (typeof window === 'undefined') return null;
  const path = window.location.pathname;
  const hash = window.location.hash;

  if (path.startsWith('/post/')) {
    const parts = path.split('/post/').filter(Boolean);
    const id = parts[0]?.split('/')[0];
    if (id) return decodeURIComponent(id);
  }

  if (path.startsWith('/@') && path.includes('/post/')) {
    const parts = path.split('/post/').filter(Boolean);
    const id = parts[1]?.split('/')[0];
    if (id) return decodeURIComponent(id);
  }

  if (hash.startsWith('#post-')) {
    return decodeURIComponent(hash.replace(/^#post-/, ''));
  }

  return null;
}

export function getPostFromLocation(): MarketPostItem | null {
  if (typeof window === 'undefined') return null;
  const potentialPostId = getPostIdFromLocation();
  if (potentialPostId) {
    const found = MOCK_MARKET_POSTS.find(
      (p) => p.id === potentialPostId || p.id === decodeURIComponent(potentialPostId)
    );
    if (found) return found;
  }
  return null;
}

export function getChatThreadFromLocation(): string | null {
  if (typeof window === 'undefined') return null;
  const path = window.location.pathname;
  const hash = window.location.hash;

  if (path.startsWith('/direct/t/') || path.startsWith('/messages/t/')) {
    const parts = path.split('/t/').filter(Boolean);
    const rawThreadId = parts[1]?.split('/')[0];
    if (rawThreadId) {
      return decodeURIComponent(rawThreadId);
    }
  }

  if (hash.startsWith('#chat-')) {
    return decodeURIComponent(hash.replace(/^#chat-/, ''));
  }

  return null;
}

export function useAppNavigation() {
  // Onboarding disabled per user directive - user lands directly on HomeFeed
  const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState<boolean>(true);

  const [currentRoute, setCurrentRoute] = useState<string>(() => {
    if (typeof window === 'undefined') return '/';
    const path = window.location.pathname;
    if (path === '/home' || path === '/' || path === '') return '/';
    return path;
  });
  const [selectedPost, setSelectedPost] = useState<MarketPostItem | null>(null);
  const [activeChatThreadId, setActiveChatThreadId] = useState<string | null>(() => getChatThreadFromLocation());
  const [isDrawerOpen, setIsDrawerOpen] = useState<boolean>(false);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState<boolean>(false);

  const isPostDetailActiveRef = useRef<boolean>(false);
  const postDetailOriginRouteRef = useRef<string>('/');
  const postDetailOriginScrollYRef = useRef<number>(0);
  const lastBackPressTimeRef = useRef<number>(0);

  // Auto-redirect /home to root landing page /
  useEffect(() => {
    if (typeof window !== 'undefined' && window.location.pathname === '/home') {
      window.history.replaceState({}, '', '/');
      setCurrentRoute('/');
    }
  }, []);

  const navigateToHome = useCallback(() => {
    triggerHaptic('light');
    setSelectedPost(null);
    setActiveChatThreadId(null);
    setCurrentRoute('/');
    window.history.pushState({}, '', '/');
  }, []);

  const navigateToSearch = useCallback(() => {
    triggerHaptic('light');
    setSelectedPost(null);
    setActiveChatThreadId(null);
    setCurrentRoute('/search');
    window.history.pushState({}, '', '/search');
  }, []);

  const navigateToMessages = useCallback(() => {
    triggerHaptic('light');
    setSelectedPost(null);
    setActiveChatThreadId(null);
    setCurrentRoute('/messages');
    window.history.pushState({}, '', '/messages');
  }, []);

  const navigateToProfile = useCallback((username: string) => {
    triggerHaptic('light');
    setSelectedPost(null);
    setActiveChatThreadId(null);
    const targetRoute = `/@${username}`;
    setCurrentRoute(targetRoute);
    window.history.pushState({}, '', targetRoute);
  }, []);

  const navigateToChatThread = useCallback((threadId: string) => {
    triggerHaptic('medium');
    setActiveChatThreadId(threadId);
    window.history.pushState({}, '', `/direct/t/${encodeURIComponent(threadId)}`);
  }, []);

  const handleOpenPostDetail = useCallback((post: MarketPostItem) => {
    triggerHaptic('medium');
    postDetailOriginRouteRef.current = currentRoute;
    postDetailOriginScrollYRef.current = window.scrollY || document.documentElement.scrollTop || 0;
    setSelectedPost(post);
    isPostDetailActiveRef.current = true;

    window.history.pushState({ postId: post.id }, '', `/post/${post.id}`);
  }, [currentRoute]);

  const loadPostById = useCallback(async (postId: string) => {
    // 1. Check local mock data first
    const mockFound = MOCK_MARKET_POSTS.find(
      (p) => p.id === postId || `post-${p.id}` === postId || decodeURIComponent(postId) === p.id
    );
    if (mockFound) {
      setSelectedPost(mockFound);
      isPostDetailActiveRef.current = true;
      return;
    }

    // 2. Fetch from Supabase
    try {
      const data = await getPostById(postId);
      if (data) {
        const mapped = mapSupabasePostToFeedItem(data);
        try {
          const liveComments = await getPostComments(postId);
          mapped.comments = liveComments.map((c) => mapSupabaseCommentToPostComment(c, data.seller_id));
        } catch {}
        setSelectedPost(mapped);
        isPostDetailActiveRef.current = true;
      }
    } catch (err) {
      console.warn('Failed to load shared post:', err);
    }
  }, []);

  // Initial load check for deep linked post URL (/post/:id or /@username/post/:id or #post-:id)
  useEffect(() => {
    const initialPostId = getPostIdFromLocation();
    if (initialPostId) {
      loadPostById(initialPostId);
    }
  }, [loadPostById]);

  const handleClosePostDetail = useCallback(() => {
    triggerHaptic('light');
    setSelectedPost(null);
    isPostDetailActiveRef.current = false;
    window.history.pushState({}, '', postDetailOriginRouteRef.current);
    setTimeout(() => {
      window.scrollTo({ top: postDetailOriginScrollYRef.current, behavior: 'instant' as ScrollBehavior });
    }, 10);
  }, []);

  const handleCloseChatThread = useCallback(() => {
    triggerHaptic('light');
    setActiveChatThreadId(null);
    window.history.pushState({}, '', '/messages');
  }, []);

  // Listen for browser Back/Forward (popstate)
  useEffect(() => {
    const handlePopState = () => {
      if (window.location.pathname === '/home') {
        window.history.replaceState({}, '', '/');
        setCurrentRoute('/');
        return;
      }

      const chatThread = getChatThreadFromLocation();
      setActiveChatThreadId(chatThread);

      const postId = getPostIdFromLocation();
      if (postId) {
        loadPostById(postId);
      } else {
        setSelectedPost(null);
        isPostDetailActiveRef.current = false;
      }
      setCurrentRoute(window.location.pathname);
    };

    window.addEventListener('popstate', handlePopState);
    return () => window.removeEventListener('popstate', handlePopState);
  }, [loadPostById]);

  // PWA Double-Back Exit Guard
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement;
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) {
        return;
      }
      if (currentRoute.startsWith('/admin')) {
        return;
      }
      if (e.key === 'Escape' || e.key === 'Backspace') {
        if (selectedPost) {
          handleClosePostDetail();
          return;
        }
        if (activeChatThreadId) {
          handleCloseChatThread();
          return;
        }
        if (isDrawerOpen) {
          setIsDrawerOpen(false);
          return;
        }
        if (currentRoute !== '/' && currentRoute !== '/download') {
          navigateToHome();
          return;
        }
        const now = Date.now();
        if (now - lastBackPressTimeRef.current > 2000) {
          lastBackPressTimeRef.current = now;
          triggerHaptic('medium');
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [selectedPost, activeChatThreadId, isDrawerOpen, currentRoute, handleClosePostDetail, handleCloseChatThread, navigateToHome]);

  return {
    hasCompletedOnboarding,
    setHasCompletedOnboarding,
    currentRoute,
    setCurrentRoute,
    selectedPost,
    activeChatThreadId,
    isDrawerOpen,
    setIsDrawerOpen,
    isCreateModalOpen,
    setIsCreateModalOpen,
    postDetailOriginRouteRef,
    navigateToHome,
    navigateToSearch,
    navigateToMessages,
    navigateToProfile,
    navigateToChatThread,
    handleOpenPostDetail,
    handleClosePostDetail,
    handleCloseChatThread,
  };
}
