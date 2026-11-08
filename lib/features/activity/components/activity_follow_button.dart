import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:snapan_market/core/services/follow_service.dart";
import "package:snapan_market/core/theme/app_colors.dart";

/// Compact, reactive follow button for activity items.
/// Optimistically toggles follow state via FollowService.
class ActivityFollowButton extends StatelessWidget {
  final String? targetUserId;
  final String targetUsername;

  const ActivityFollowButton({
    super.key,
    this.targetUserId,
    required this.targetUsername,
  });

  @override
  Widget build(BuildContext context) {
    if (targetUsername.isEmpty) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: FollowService.instance,
      builder: (context, _) {
        final isMe = FollowService.instance.isCurrentUser(
          targetUserId,
          targetUsername,
        );
        if (isMe) return const SizedBox.shrink();

        final following = FollowService.instance.isFollowing(
          targetUserId,
          targetUsername,
        );
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            FollowService.instance.toggleFollow(
              targetUserId: targetUserId,
              targetUsername: targetUsername,
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: following
                  ? (isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9))
                  : (isDark ? AppColors.primary.withValues(alpha: 0.15) : Colors.white),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: following
                    ? (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))
                    : (isDark ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFFCBD5E1)),
                width: 1.0,
              ),
            ),
            child: Text(
              following ? "Mengikuti" : "Ikuti Balik",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: following
                    ? (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B))
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                letterSpacing: -0.2,
              ),
            ),
          ),
        );
      },
    );
  }
}
