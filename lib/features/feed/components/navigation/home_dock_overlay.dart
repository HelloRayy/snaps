import 'package:flutter/material.dart';
import 'package:snapan_market/core/navigation/app_slide_page_route.dart';
import 'package:snapan_market/features/create_post/models/create_post_types.dart';
import 'package:snapan_market/features/feed/components/navigation/home_bottom_nav_bar.dart';
export 'package:snapan_market/features/feed/components/navigation/home_bottom_nav_bar.dart' show HomeNavTab, HomeBottomNavBar;
import 'package:snapan_market/features/feed/components/navigation/home_feed_fab_group.dart';
import 'package:snapan_market/features/messages/services/direct_messages_service.dart';
import 'package:snapan_market/features/search/screens/search_screen.dart';

/// Overlay widget combining FAB Group, HomeBottomNavBar, and Motion Tuner HUD.
class HomeDockOverlay extends StatefulWidget {
  final HomeNavTab currentNavTab;
  final AnimationController fabAnimationController;
  final Animation<double>? fabAnimation;
  final double fabBottom;
  final void Function([PostMode mode]) onCreatePost;
  final ValueChanged<HomeNavTab> onTabSelected;
  final String? userAvatar;
  final bool hasUnreadActivity;

  const HomeDockOverlay({
    super.key,
    required this.currentNavTab,
    required this.fabAnimationController,
    required this.fabAnimation,
    required this.fabBottom,
    required this.onCreatePost,
    required this.onTabSelected,
    this.userAvatar,
    this.hasUnreadActivity = false,
  });

  @override
  State<HomeDockOverlay> createState() => _HomeDockOverlayState();
}

class _HomeDockOverlayState extends State<HomeDockOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HomeFeedFabGroup(
          currentNavTab: widget.currentNavTab,
          fabAnimationController: widget.fabAnimationController,
          fabAnimation: widget.fabAnimation,
          fabBottomVisible: 100.0,
          onCreatePost: widget.onCreatePost,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([DirectMessagesService.instance, widget.fabAnimationController]),
              builder: (context, _) {
                final unreadCount = DirectMessagesService.instance.totalUnreadCount;
                final isCollapsed = (widget.fabAnimation?.value ?? 1.0) < 0.5;
                return HomeBottomNavBar(
                  currentTab: widget.currentNavTab,
                  hasUnreadMessages: unreadCount > 0,
                  unreadMessagesCount: unreadCount,
                  hasUnreadActivity: widget.hasUnreadActivity,
                  userAvatar: widget.userAvatar,
                  isCollapsed: isCollapsed,
                  onExpandTap: () => widget.fabAnimationController.forward(),
                  onSearchTap: () => Navigator.push(
                    context,
                    AppSlidePageRoute(builder: (context) => SearchScreen(onBack: () => Navigator.pop(context))),
                  ),
                  onPostTap: widget.onCreatePost,
                  onTabSelected: widget.onTabSelected,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
