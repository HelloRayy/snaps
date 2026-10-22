import React, { useState, useEffect } from 'react';
import { ArrowLeft } from 'lucide-react';
import { SnapsLogoSvg } from '@/ui/components/brand/SnapsLogoSvg';
import { MarketPostItem, PostComment } from '@/types/marketFeed';
import { MarketPostCard } from '@/ui/components/marketplace/MarketPostCard';
import { PostCommentItem } from '@/ui/components/marketplace/PostCommentItem';
import { CommentInputBar } from '@/ui/components/marketplace/CommentInputBar';
import { StickyBuyBar } from '@/ui/components/marketplace/StickyBuyBar';
import { BuyBottomSheet } from '@/ui/components/marketplace/BuyBottomSheet';
import { CommentDetailPage } from '@/ui/components/marketplace/CommentDetailPage';
import { CheckoutPage } from './CheckoutPage';
import { useAuth } from '@/ui/hooks/useAuth';
import { triggerHaptic } from '@/utils/haptics';
import { toUsernameSlug } from '@/utils/formatters';
import { getOreoAvatarUrl } from '@/utils/oreoAvatar';
import { getPostComments, mapSupabaseCommentToPostComment } from '@/services/api/commentService';

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

  const containerRef = React.useRef<HTMLDivElement>(null);

  // Determine if this post is a Marketplace Product Post
  const isProductMode = post.postType === 'product' && !!post.price && post.price > 0;

  // Smooth reset & scroll to top when opening post detail, plus live comments fetch
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
      // Nest directly inside the target parent comment or sibling sub-reply's parent!
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
      // Regular root-level comment to post
      setComments((prev) => [newComment, ...prev]);
    }

    setReplyTarget(null);
    setReplyToCommentId(null);
    setDraftText('');
    setIsCommentingActive(false);

    // Smooth auto-scroll to the newly created comment
    setTimeout(() => {
      const el = document.getElementById(`comment-${createdId}`);
      if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    }, 100);
  };

  const handleReplyClick = (username: string, commentId?: string) => {
    if (isGuest) return;
    triggerHaptic('light');
    const cleanUsername = username.replace(/^@/, '');
    const targetId = commentId || '';
    setReplyTarget({ id: targetId, username: cleanUsername });
    setReplyToCommentId(targetId);
    setIsCommentingActive(true);

    // Smooth auto-scroll to the target comment
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
    if (isGuest) return;
    triggerHaptic('light');
    setIsCommentingActive(true);
  };

  const handleBuyClick = () => {
    if (isGuest) return;
    triggerHaptic('medium');
    setIsCheckoutOpen(true);
    onAddToCart?.(post);
  };

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

  // Single Page Mode: CheckoutPage
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
      {/* Top Header Bar: [Left: ← Back Button] --- [Center: Postingan] --- [Right: Spacer] */}
      <header
        className="sticky top-0 left-0 right-0 z-40 bg-white border-b border-neutral-200/80 px-4 h-14 flex items-center justify-between max-w-xl mx-auto"
        style={{
          paddingTop: 'env(safe-area-inset-top, 0px)',
        }}
      >
        <button
          type="button"
          onClick={onBack}
          className="w-10 h-10 rounded-full hover:bg-neutral-100 flex items-center justify-center text-slate-800 transition-colors cursor-pointer active:scale-90"
          aria-label="Kembali ke Feed Utama"
        >
          <ArrowLeft className="w-5 h-5 stroke-[2.25]" />
        </button>

        <div className="flex items-center gap-2">
          <SnapsLogoSvg height={20} />
          <span className="text-neutral-300 font-light select-none">/</span>
          <h1 className="font-semibold text-[14.5px] text-slate-900">Postingan</h1>
        </div>

        {/* Spacer for center title balance */}
        <div className="w-10 h-10 pointer-events-none" />
      </header>

      {/* Smart App Banner */}
      <div className="bg-gradient-to-r from-blue-50/90 via-indigo-50/70 to-blue-50/90 border-b border-indigo-100/70 px-4 py-2.5 flex items-center justify-between gap-3 max-w-xl mx-auto select-none">
        <div className="flex items-center gap-2.5 min-w-0">
          <div className="w-8 h-8 rounded-xl bg-[#3D38F5] flex items-center justify-center shrink-0 shadow-xs text-white">
            <SnapsLogoSvg height={16} />
          </div>
          <div className="min-w-0">
            <p className="text-xs font-bold text-slate-900 truncate">Buka di Aplikasi Snaps</p>
            <p className="text-[11px] text-slate-500 truncate">Buka langsung di aplikasi ponsel Anda</p>
          </div>
        </div>
        <a
          href={`snaps://post/${post.id}`}
          onClick={() => {
            setTimeout(() => {
              window.location.href = 'https://snaps.web.id/download';
            }, 1200);
          }}
          className="shrink-0 bg-[#3D38F5] hover:bg-[#312BD9] text-white text-xs font-semibold px-3.5 py-1.5 rounded-full transition-all shadow-xs active:scale-95 cursor-pointer"
        >
          Buka di App
        </a>
      </div>

      {/* Main Content Area */}
      <main className="max-w-xl mx-auto pt-0">
        {/* Focused Main Post Card */}
        <MarketPostCard
          item={post}
          onAddToCart={onAddToCart}
          onUserClick={onUserClick}
          variant="detail"
        />

        {/* Comments Section (Includes Author Thread Continuations 2/N, 3/N at top) */}
        <section id="comments-section" className="w-full pt-1">
          {/* Section Divider Header */}
          <div className="px-3.5 py-2.5 flex items-center justify-between border-b border-neutral-100">
            <h2 className="font-semibold text-sm text-slate-900">
              {isProductMode ? 'Tanya Jawab & Diskusi' : 'Komentar'} ({post.threadChain && post.threadChain.length > 0 ? comments.length + post.threadChain.length : comments.length})
            </h2>
            <span className="text-xs text-neutral-400">Urutkan dari Terbaru</span>
          </div>

          {/* Combined Comment List: Author Thread Continuations + General Comments */}
          {(post.threadChain && post.threadChain.length > 0) || comments.length > 0 ? (
            <div className="w-full">
              {/* 1. Author Thread Continuation Comments (Part 2, Part 3, etc.) */}
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

              {/* 2. General Comments from Other Users */}
              {comments.map((comment) => (
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
            <div className="py-12 px-6 text-center max-w-[280px] mx-auto space-y-1.5 select-none">
              <p className="text-slate-800 font-semibold text-[14.5px] leading-snug">
                {isProductMode ? 'Belum ada pertanyaan' : 'Belum ada komentar'}
              </p>
              <p className="text-neutral-500 text-[12.5px] leading-relaxed">
                {isProductMode
                  ? 'Ingin tahu kondisi atau ketersediaan stok? Tanyakan langsung ke penjual.'
                  : 'Mulai percakapan dan jadilah yang pertama memberi tanggapan.'}
              </p>
            </div>
          )}
        </section>
      </main>

      {/* Bottom Action / Interaction Bar */}
      {isGuest ? (
        isProductMode ? (
          <div className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-neutral-200/80 px-4 py-3 max-w-xl mx-auto flex items-center justify-between gap-3 shadow-lg">
            <div>
              <span className="text-[11px] text-neutral-400 block font-medium">Harga</span>
              <span className="text-base font-bold text-slate-900 tracking-tight">
                Rp {post.price?.toLocaleString('id-ID')}
              </span>
            </div>
            <div
              className="flex items-center gap-1.5 bg-neutral-100 text-neutral-400 text-xs font-semibold px-4 py-2 rounded-full cursor-not-allowed select-none border border-neutral-200/60"
              title="Masuk untuk berinteraksi"
            >
              <span>Masuk untuk berinteraksi</span>
            </div>
          </div>
        ) : (
          <div className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-neutral-200/80 px-4 py-3 max-w-xl mx-auto flex items-center justify-between gap-3 shadow-lg">
            <div
              className="flex items-center gap-2 text-neutral-400 text-xs py-2 px-3.5 rounded-full bg-neutral-100 flex-1 border border-neutral-200/60 select-none cursor-not-allowed"
              title="Masuk untuk berinteraksi"
            >
              <span>Masuk untuk berinteraksi...</span>
            </div>
            <a
              href={`snaps://post/${post.id}`}
              className="shrink-0 text-xs font-semibold text-[#3D38F5] hover:underline px-2 py-1"
            >
              Buka di App
            </a>
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
        /* MODE 2: Docked Bottom Bar ala Threads / X for Discussion / Utas Posts */
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

      {/* Threads-style Sub-Thread Comment Detail Modal / Fullscreen Sub-Page */}
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
    </div>
  );
};
