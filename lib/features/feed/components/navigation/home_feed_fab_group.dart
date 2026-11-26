import 'package:flutter/material.dart';
import 'package:snapan_market/features/create_post/models/create_post_types.dart';
import 'package:snapan_market/features/feed/components/navigation/floating_plus_squircle_button.dart';
import 'package:snapan_market/features/feed/components/navigation/home_bottom_nav_bar.dart';

class HomeFeedFabGroup extends StatelessWidget {
  final HomeNavTab currentNavTab;
  final AnimationController fabAnimationController;
  final Animation<double>? fabAnimation;
  final double fabBottomVisible;
  final double fabRight;
  final double fabCollapsedBottom;
  final ValueChanged<PostMode> onCreatePost;

  const HomeFeedFabGroup({
    super.key,
    required this.currentNavTab,
    required this.fabAnimationController,
    required this.fabAnimation,
    required this.fabBottomVisible,
    this.fabRight = 16.0,
    this.fabCollapsedBottom = 40.0,
    required this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: fabRight,
      bottom: fabBottomVisible,
      child: AnimatedBuilder(
        animation: fabAnimationController,
        builder: (context, _) {
          final double fabProgress = CurvedAnimation(
            parent: fabAnimationController,
            curve: Curves.easeOutCubic,
          ).value;
          final double bottomPadding = MediaQuery.paddingOf(context).bottom;
          final double collapsedBottom = bottomPadding > 0 ? bottomPadding + 8.0 : fabCollapsedBottom;
          final double travelDistance = (fabBottomVisible - collapsedBottom).clamp(0.0, 120.0);
          final double fabOffsetY = (1.0 - fabProgress) * travelDistance;
          final bool isHomeTab = currentNavTab == HomeNavTab.home;

          return AnimatedOpacity(
            opacity: isHomeTab ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: isHomeTab ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomRight,
              child: Transform.translate(
                offset: Offset(0, fabOffsetY),
                child: IgnorePointer(
                  ignoring: !isHomeTab,
                  child: FloatingPlusSquircleButton(
                    onTap: () => onCreatePost(PostMode.thread),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
