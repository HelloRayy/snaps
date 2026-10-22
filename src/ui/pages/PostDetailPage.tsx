import React, { useState, useEffect, useMemo, useRef } from 'react';
import { ChevronLeft, Share2, MoreHorizontal, ChevronDown, Check, MessageSquare } from 'lucide-react';
import { MarketPostItem, PostComment } from '@/types/marketFeed';
import { MarketPostCard } from '@/ui/components/marketplace/MarketPostCard';
import { PostCommentItem } from '@/ui/components/marketplace/PostCommentItem';
import { CommentInputBar } from '@/ui/components/marketplace/CommentInputBar';
import { StickyBuyBar } from '@/ui/components/marketplace/StickyBuyBar';
import { BuyBottomSheet } from '@/ui/components/marketplace/BuyBottomSheet';
import { CommentDetailPage } from '@/ui/components/marketplace/CommentDetailPage';
import { ToastNotification } from '@/ui/components/ui/ToastNotification';
import { CheckoutPage } from './CheckoutPage';
import { useAuth } from '@/ui/hooks/useAuth';
import { triggerHaptic } from '@/utils/haptics';
import { toUsernameSlug } from '@/utils/formatters';
import { getOreoAvatarUrl } from '@/utils/oreoAvatar';
import { getPostComments, mapSupabaseCommentToPostComment } from '@/services/api/commentService';

type CommentSortOrder = 'newest' | 'top' | 'oldest';

interface PostDetailPageProps {
  post: MarketPostItem;
  onBack: () => void;
  onAddToCart?: (item: MarketPostItem) => void;
  onUserClick?: (username: string) => void;
}

export const PostDetailPage: React.FC<PostDetailPageProps> = ({
  post,
  onBack,
  onAddToCart,
  onUserClick,
}) => {
  const { user, profile } = useAuth();
  const isGuest = !user;
  const [comments, setComments] = useState<PostComment[]>(post.comments || []);
  const [replyToCommentId, setReplyToCommentId] = useState<string | null>(null);
  const [replyTarget, setReplyTarget] = useState<{ id: string; username: string } | null>(null);
  const [draftText, setDraftText] = useState('');
  const [focusedComment, setFocusedComment] = useState<PostComment | null>(null);
  const [isBuySheetOpen, setIsBuySheetOpen] = useState(false);
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [isCommentingActive, setIsCommentingActive] = useState(false);
  const [selectedSort, setSelectedSort] = useState<CommentSortOrder>('newest');
  const [isSortMenuOpen, setIsSortMenuOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);

  const isProductMode = post.postType === 'product' && !!post.price && post.price > 0;

  useEffect(() => {
    let isMounted = true;
    if (containerRef.current) {
      containerRef.current.scrollTop = 0;
    }
    setComments(post.comments || []);
    setReplyToCommentId(null);
    setReplyTarget(null);
    setDraftText('');
    setFocusedComment(null);
    setIsBuySheetOpen(false);
    setIsCommentingActive(false);

    if (post.id && (!post.comments || post.comments.length === 0)) {
      getPostComments(post.id)
        .then((live) => {
          if (isMounted && live.length > 0) {
            setComments(live.map((c) => mapSupabaseCommentToPostComment(c, post.seller.id)));
          }
        })
        .catch(() => {});
    }

    return () => {
      isMounted = false;
    };
  }, [post.id, post.comments, post.seller.id]);

  const handleBack = () => {
    triggerHaptic('light');
    if (onBack) {
      onBack();
    } else {
      window.location.href = '/download';
    }
  };

  const handleShare = async () => {
    triggerHaptic('light');
    const shareUrl = window.location.href;
    const shareTitle = post.title || `Postingan oleh ${post.seller.name}`;
    if (navigator.share) {
      try {
        await navigator.share({
          title: shareTitle,
          text: post.caption,
          url: shareUrl,
        });
        return;
      } catch {}
    }

    if (navigator.clipboard) {
      try {
        await navigator.clipboard.writeText(shareUrl);
        setToastMessage('Tautan postingan berhasil disalin!');
      } catch {
        setToastMessage('Gagal menyalin tautan');
      }
    }
  };

  const handleMoreOptions = () => {
    triggerHaptic('light');
    handleShare();
  };

  const handleAddComment = (content: string, specificCommentId?: string) => {
    const targetParentId = specificCommentId || replyTarget?.id || replyToCommentId;
    const currentUsernameSlug = toUsernameSlug(profile?.full_name, 'radityarayhannnn');
    const isPostAuthor =
      (profile?.id || 'current-user') === post.seller.id ||
      post.seller.username === 'radityarayhannnn' ||
      post.seller.username === currentUsernameSlug;

    const createdId = `comment-${Date.now()}`;
    const newComment: PostComment = {
      id: createdId,
      postId: post.id,
      user: {
        id: profile?.id || 'user-current',
        name: profile?.full_name || 'Raditya Rayhan',
        username: currentUsernameSlug,
        avatar: profile?.avatar_url || getOreoAvatarUrl(currentUsernameSlug, { size: 120 }),
        classGroup: profile?.class_group || 'XII PPLG 1',
        isVerified: true,
        isAuthor: isPostAuthor,
      },
      content: content,
      timestamp: 'Baru saja',
      likesCount: 0,
      isLiked: false,
    };

    if (targetParentId) {
      setComments((prev) =>
        prev.map((c) => {
          if (c.id === targetParentId || c.replies?.some((r) => r.id === targetParentId)) {
            return {
              ...c,
              replies: [...(c.replies || []), newComment],
            };
          }
          return c;
        })
      );
    } else {
      setComments((prev) => [newComment, ...prev]);
    }

    setReplyTarget(null);
    setReplyToCommentId(null);
    setDraftText('');
    setIsCommentingActive(false);

    setTimeout(() => {
      const el = document.getElementById(`comment-${createdId}`);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    }, 100);
  };

  const handleReplyClick = (username: string, commentId?: string) => {
    if (isGuest) {
      setToastMessage('Masuk untuk berinteraksi');
      return;
    }
    triggerHaptic('light');
    const cleanUsername = username.replace(/^@/, '');
    const targetId = commentId || '';
    setReplyTarget({ id: targetId, username: cleanUsername });
    setReplyToCommentId(targetId);
    setIsCommentingActive(true);

    if (targetId) {
      setTimeout(() => {
        const el = document.getElementById(`comment-${targetId}`);
        if (el) {
          el.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      }, 80);
    }
  };

  const handleChatClick = () => {
    if (isGuest) {
      window.location.href = '/download';
      return;
    }
    triggerHaptic('light');
    setIsCommentingActive(true);
  };

  const handleBuyClick = () => {
    if (isGuest) {
      window.location.href = '/download';
      return;
    }
    triggerHaptic('medium');
    setIsCheckoutOpen(true);
    onAddToCart?.(post);
  };

  const sortedComments = useMemo(() => {
    const list = [...comments];
    switch (selectedSort) {
      case 'newest':
        return list;
      case 'top':
        return list.sort((a, b) => (b.likesCount || 0) - (a.likesCount || 0));
      case 'oldest':
        return list.reverse();
      default:
        return list;
    }
  }, [comments, selectedSort]);

  const totalCommentsCount = (post.threadChain?.length || 0) + comments.length;

  const userAvatar =
    profile?.avatar_url || getOreoAvatarUrl(profile?.full_name || 'radityarayhannnn', { size: 120 });
  const replyingToUsername = replyTarget?.username || null;

  const draftReplyObj = replyTarget
    ? {
        targetCommentId: replyTarget.id,
        text: draftText,
        userAvatar: userAvatar,
        username: profile?.full_name?.toLowerCase().replace(/\s+/g, '') || 'radityarayhannnn',
        isVerified: true,
        isAuthor: (profile?.id || 'current-user') === post.seller.id,
      }
    : null;

  if (isCheckoutOpen) {
    return (
      <CheckoutPage
        post={post}
        onBack={() => setIsCheckoutOpen(false)}
        onUserClick={onUserClick}
      />
    );
  }

  return (
    <div
      ref={containerRef}
      data-lenis-prevent
      className="h-full w-full overflow-y-auto overscroll-contain bg-white pb-36 font-gt-standard touch-pan-y"
      style={{
        WebkitOverflowScrolling: 'touch',
      }}
    >
      {/* 1:1 GlassToolbarTop Header (Flutter Parity) */}
      <header
        className="sticky top-0 left-0 right-0 z-40 bg-white/85 backdrop-blur-2xl border-b border-slate-200/80 px-3.5 h-[52px] flex items-center justify-between max-w-xl mx-auto"
        style={{
          paddingTop: 'env(safe-area-inset-top, 0px)',
        }}
      >
        <button
          type="button"
          onClick={handleBack}
          className="w-10 h-10 rounded-full flex items-center justify-center text-slate-800 hover:bg-slate-100/80 transition-all cursor-pointer active:scale-90"
          aria-label="Kembali ke Halaman Unduh"
          title="Kembali"
        >
          <ChevronLeft className="w-5 h-5 stroke-[2.25] text-slate-800" />
        </button>

        <h1 className="font-semibold text-[17px] text-slate-900 tracking-[-0.4px] select-none">
          Postingan
        </h1>

        <div className="flex items-center gap-1 h-[38px] px-1.5 rounded-full border border-slate-200/80 bg-gradient-to-b from-white to-slate-50 shadow-xs">
          <button
            type="button"
            onClick={handleShare}
            className="w-7 h-7 flex items-center justify-center rounded-full text-slate-700 hover:text-slate-900 active:scale-90 transition-all cursor-pointer"
            aria-label="Bagikan postingan"
            title="Bagikan"
          >
            <Share2 className="w-4 h-4 stroke-[2]" />
          </button>
          <div className="w-[1px] h-3.5 bg-slate-200" />
          <button
            type="button"
            onClick={handleMoreOptions}
            className="w-7 h-7 flex items-center justify-center rounded-full text-slate-700 hover:text-slate-900 active:scale-90 transition-all cursor-pointer"
            aria-label="Menu lainnya"
            title="Menu lainnya"
          >
            <MoreHorizontal className="w-4 h-4 stroke-[2]" />
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="max-w-xl mx-auto pt-0">
        <MarketPostCard
          item={post}
          onAddToCart={onAddToCart}
          onUserClick={onUserClick}
          variant="detail"
        />

        {/* 1:1 PostDetailCommentsHeader */}
        <section id="comments-section" className="w-full pt-1">
          <div className="px-3.5 py-2.5 flex items-center justify-between border-b border-neutral-100">
            <h2 className="font-semibold text-sm text-slate-900">
              {isProductMode ? 'Tanya Jawab & Diskusi' : 'Komentar'} ({totalCommentsCount})
            </h2>

            <div className="relative">
              <button
                type="button"
                onClick={() => setIsSortMenuOpen((prev) => !prev)}
                className="flex items-center gap-1 text-[12px] text-slate-500 hover:text-slate-800 font-medium px-2 py-1 rounded-md hover:bg-slate-100 transition-colors cursor-pointer select-none"
              >
                <span>
                  {selectedSort === 'newest' ? 'Terbaru' : selectedSort === 'top' ? 'Teratas' : 'Terlama'}
                </span>
                <ChevronDown className="w-3.5 h-3.5" />
              </button>

              {isSortMenuOpen && (
                <div className="absolute right-0 mt-1 w-32 bg-white rounded-xl shadow-lg border border-slate-200 py-1 z-30 animate-in fade-in zoom-in-95">
                  <button
                    onClick={() => {
                      setSelectedSort('newest');
                      setIsSortMenuOpen(false);
                    }}
                    className={`w-full text-left px-3 py-1.5 text-xs flex items-center justify-between cursor-pointer ${
                      selectedSort === 'newest' ? 'font-semibold text-slate-900 bg-slate-50' : 'text-slate-600 hover:bg-slate-50'
                    }`}
                  >
                    <span>Terbaru</span>
                    {selectedSort === 'newest' && <Check className="w-3.5 h-3.5 text-slate-900" />}
                  </button>
                  <button
                    onClick={() => {
                      setSelectedSort('top');
                      setIsSortMenuOpen(false);
                    }}
                    className={`w-full text-left px-3 py-1.5 text-xs flex items-center justify-between cursor-pointer ${
                      selectedSort === 'top' ? 'font-semibold text-slate-900 bg-slate-50' : 'text-slate-600 hover:bg-slate-50'
                    }`}
                  >
                    <span>Teratas</span>
                    {selectedSort === 'top' && <Check className="w-3.5 h-3.5 text-slate-900" />}
                  </button>
                  <button
                    onClick={() => {
                      setSelectedSort('oldest');
                      setIsSortMenuOpen(false);
                    }}
                    className={`w-full text-left px-3 py-1.5 text-xs flex items-center justify-between cursor-pointer ${
                      selectedSort === 'oldest' ? 'font-semibold text-slate-900 bg-slate-50' : 'text-slate-600 hover:bg-slate-50'
                    }`}
                  >
                    <span>Terlama</span>
                    {selectedSort === 'oldest' && <Check className="w-3.5 h-3.5 text-slate-900" />}
                  </button>
                </div>
              )}
            </div>
          </div>

          {/* Combined Comment List */}
          {(post.threadChain && post.threadChain.length > 0) || sortedComments.length > 0 ? (
            <div className="w-full">
              {post.threadChain?.map((chain) => (
                <PostCommentItem
                  key={chain.id}
                  draftReply={draftReplyObj}
                  comment={{
                    id: chain.id,
                    postId: post.id,
                    user: {
                      id: post.seller.id,
                      name: post.seller.name,
                      username: post.seller.username || post.seller.name,
                      avatar: post.seller.avatar,
                      classGroup: post.seller.classGroup,
                      isVerified: post.seller.isVerified,
                      isAuthor: true,
                    },
                    content: chain.caption,
                    images: chain.images,
                    threadPart: chain.partNumber,
                    totalParts: chain.totalParts,
                    timestamp: chain.timestamp || 'Baru saja',
                    likesCount: chain.likesCount || 0,
                    isLiked: chain.isLiked || false,
                  }}
                  onReplyClick={handleReplyClick}
                  onOpenCommentDetail={(c) => setFocusedComment(c)}
                />
              ))}

              {sortedComments.map((comment) => (
                <PostCommentItem
                  key={comment.id}
                  draftReply={draftReplyObj}
                  comment={comment}
                  onReplyClick={handleReplyClick}
                  onOpenCommentDetail={(c) => setFocusedComment(c)}
                />
              ))}
            </div>
          ) : (
            <div className="py-12 px-6 text-center max-w-[280px] mx-auto flex flex-col items-center select-none">
              <MessageSquare className="w-10 h-10 text-slate-300 stroke-[1.5] mb-3" />
              <p className="text-slate-900 font-semibold text-[15px] leading-snug mb-1">
                {isProductMode ? 'Belum ada pertanyaan' : 'Belum ada komentar'}
              </p>
              <p className="text-slate-500 text-[12.5px] leading-relaxed">
                {isProductMode
                  ? 'Ingin tahu kondisi atau ketersediaan stok? Tanyakan langsung ke penjual.'
                  : 'Mulai percakapan dan jadilah yang pertama memberi tanggapan.'}
              </p>
            </div>
          )}
        </section>
      </main>

      {/* 1:1 Floating Capsule Bottom Bar (Flutter StickyBuyBar & CommentInputBar Parity) */}
      {isGuest ? (
        isProductMode ? (
          <StickyBuyBar
            price={post.price || 0}
            stockCount={post.stock || 1}
            onBuyClick={handleBuyClick}
            onChatClick={handleChatClick}
          />
        ) : (
          <div
            className="fixed left-4 right-4 max-w-md mx-auto z-40 font-gt-standard select-none transition-all duration-200 ease-out"
            style={{
              bottom: 'max(1rem, calc(env(safe-area-inset-bottom, 0px) + 8px))',
            }}
          >
            <div
              onClick={() => {
                triggerHaptic('light');
                window.location.href = '/download';
              }}
              className="bg-white/85 backdrop-blur-2xl border border-white/90 p-1.5 rounded-[32px] shadow-[0_12px_40px_rgba(0,0,0,0.12)] flex items-center gap-2.5 cursor-pointer active:scale-[0.98] transition-transform"
            >
              <div className="w-8 h-8 rounded-full overflow-hidden shrink-0 border border-neutral-200 bg-neutral-100 flex items-center justify-center ml-0.5">
                <img
                  src={getOreoAvatarUrl('guest-user', { size: 100 })}
                  alt="Tamu"
                  className="w-full h-full object-cover"
                />
              </div>
              <span className="flex-1 text-[13px] text-neutral-400 font-normal">
                Masuk untuk berinteraksi...
              </span>
            </div>
          </div>
        )
      ) : isProductMode ? (
        isCommentingActive ? (
          <CommentInputBar
            targetAuthor={post.seller.username || post.seller.name}
            userAvatar={userAvatar}
            replyToUser={replyingToUsername}
            autoFocus={true}
            onDraftChange={(val) => setDraftText(val)}
            onClose={() => {
              setIsCommentingActive(false);
              setReplyTarget(null);
              setReplyToCommentId(null);
              setDraftText('');
            }}
            onCancelReply={() => {
              setReplyTarget(null);
              setReplyToCommentId(null);
              setDraftText('');
            }}
            onSubmitComment={(text) => handleAddComment(text, replyTarget?.id || replyToCommentId || undefined)}
            isInline={false}
          />
        ) : (
          <>
            <StickyBuyBar
              price={post.price || 0}
              stockCount={post.stock || 1}
              onBuyClick={handleBuyClick}
              onChatClick={handleChatClick}
            />

            <BuyBottomSheet
              key={`buy-${post.id}`}
              isOpen={isBuySheetOpen}
              post={post}
              onClose={() => setIsBuySheetOpen(false)}
            />
          </>
        )
      ) : (
        <CommentInputBar
          targetAuthor={post.seller.username || post.seller.name}
          userAvatar={userAvatar}
          replyToUser={replyingToUsername}
          onDraftChange={(val) => setDraftText(val)}
          onCancelReply={() => {
            setReplyTarget(null);
            setReplyToCommentId(null);
            setDraftText('');
          }}
          onSubmitComment={(text) => handleAddComment(text, replyTarget?.id || replyToCommentId || undefined)}
          isInline={false}
        />
      )}

      {/* Sub-Thread Comment Detail Modal */}
      {focusedComment && (
        <CommentDetailPage
          parentPost={post}
          focusedComment={focusedComment}
          onBack={() => setFocusedComment(null)}
          onUpdateComment={(updated) => {
            setFocusedComment(updated);
            setComments((prev) =>
              prev.map((c) => (c.id === updated.id ? updated : c))
            );
          }}
        />
      )}

      {toastMessage && (
        <ToastNotification
          message={toastMessage}
          onClose={() => setToastMessage(null)}
        />
      )}
    </div>
  );
};
