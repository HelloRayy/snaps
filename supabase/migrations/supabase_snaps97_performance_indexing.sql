-- ==============================================================================
-- MIGRATION: SNAPS Performance & Database Indexing Hardening (SNAPS-97)
-- Purpose:
-- 1. Indexing relasi foreign-key & lookup yang sering di-query di public.market_posts,
--    public.post_likes, public.post_comments, dan public.post_bookmarks.
-- 2. Menghilangkan sequential scan pada feed retrieval, likes check, dan comments.
-- 3. Menjamin query keyset pagination dan subquery count berjalan instan O(log N).
-- ==============================================================================

-- 1. Foreign-key & Timeline Index pada market_posts
CREATE INDEX IF NOT EXISTS idx_market_posts_seller_id 
ON public.market_posts(seller_id);

CREATE INDEX IF NOT EXISTS idx_market_posts_post_type 
ON public.market_posts(post_type);

-- 2. Index composite pada tabel interaksi post_likes
-- Sangat krusial untuk:
-- a) Count likes per postingan: post_likes(count)
-- b) Fetch liked posts per user: WHERE user_id = ...
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id 
ON public.post_likes(post_id);

CREATE INDEX IF NOT EXISTS idx_post_likes_user_id 
ON public.post_likes(user_id);

CREATE INDEX IF NOT EXISTS idx_post_likes_post_user 
ON public.post_likes(post_id, user_id);

-- 3. Index pada post_comments
-- Mempercepat subquery post_comments(count) di feed serta fetchPostComments(post_id)
CREATE INDEX IF NOT EXISTS idx_post_comments_post_id 
ON public.post_comments(post_id);

CREATE INDEX IF NOT EXISTS idx_post_comments_user_id 
ON public.post_comments(user_id);

CREATE INDEX IF NOT EXISTS idx_post_comments_parent_comment_id 
ON public.post_comments(parent_comment_id);

-- 4. Index pada post_bookmarks
-- Mempercepat fetchBookmarkedPostIds() per user
CREATE INDEX IF NOT EXISTS idx_post_bookmarks_user_id 
ON public.post_bookmarks(user_id);

CREATE INDEX IF NOT EXISTS idx_post_bookmarks_post_user 
ON public.post_bookmarks(post_id, user_id);
