import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/navigation/app_slide_page_route.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/feed/components/media/media_lightbox_dialog.dart';
import 'package:snapan_market/features/feed/components/post_card/market_post_card.dart';
import 'package:snapan_market/features/feed/models/market_post_model.dart';
import 'package:snapan_market/features/feed/screens/post_detail_screen.dart';
import 'package:snapan_market/features/profile/screens/profile_screen.dart';
import 'package:snapan_market/features/search/screens/search_screen.dart';

/// Single page showing all posts & products liked by the current user.
class LikedPostsScreen extends StatefulWidget {
  const LikedPostsScreen({super.key});

  @override
  State<LikedPostsScreen> createState() => _LikedPostsScreenState();
}

class _LikedPostsScreenState extends State<LikedPostsScreen> {
  List<MarketPostModel> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedPosts();
  }

  Future<void> _loadLikedPosts() async {
    final uid = SupabaseService.instance.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final result = await SupabaseService.instance.fetchUserLikedPosts(uid);
    if (mounted) {
      setState(() {
        _posts = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLikeToggle(MarketPostModel post) async {
    final nextLiked = !post.isLiked;
    setState(() {
      _posts = _posts.map((p) {
        if (p.id != post.id) return p;
        return p.copyWith(
          isLiked: nextLiked,
          likesCount: (p.likesCount + (nextLiked ? 1 : -1)).clamp(0, 999999),
        );
      }).toList();
    });
    await SupabaseService.instance.togglePostLike(post.id, post.isLiked);
  }

  void _openPostDetail(MarketPostModel post) {
    Navigator.push(
      context,
      AppSlidePageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveSurface(context),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text(
          'Disukai',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadLikedPosts,
              child: _posts.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.65,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.heart,
                                  size: 44,
                                  color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada utas yang disukai',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap ikon hati pada utas atau produk untuk menyimpannya di sini.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return MarketPostCard(
                          key: ValueKey('liked_${post.id}'),
                          item: post,
                          onLikeToggle: _handleLikeToggle,
                          onRepostToggle: (_) {},
                          onPostClick: _openPostDetail,
                          onTopicClick: (tag) => Navigator.push(
                            context,
                            AppSlidePageRoute(
                              builder: (_) => SearchScreen(
                                initialQuery: tag,
                                onBack: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          onUserClick: (u) => Navigator.push(
                            context,
                            AppSlidePageRoute(
                              builder: (_) => ProfileScreen(
                                username: u,
                                onBack: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          onImageClick: (item, idx) => MediaLightboxDialog.show(
                            context: context,
                            images: item.images,
                            initialIndex: idx,
                            post: item,
                            onLikeToggle: _handleLikeToggle,
                            onRepostToggle: (_) {},
                            onPostClick: _openPostDetail,
                          ),
                          onDeletePost: (_) {},
                        );
                      },
                    ),
            ),
    );
  }
}
