import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:snapan_market/core/components/snaps_logo.dart";
import "package:snapan_market/core/theme/app_colors.dart";
import "package:snapan_market/core/ui/default_profile_avatar.dart";
import "package:snapan_market/features/activity/models/activity_notification_model.dart";

/// Threads-style avatar with micro action badge on the bottom-right corner.
class ActivityAvatarBadge extends StatelessWidget {
  final ActivityNotification notification;
  final VoidCallback? onTap;

  const ActivityAvatarBadge({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSystem = notification.type == ActivityType.system ||
        notification.actorName.toLowerCase().startsWith('admin');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22.0),
            child: isSystem
                ? Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(7.0),
                    child: const Center(
                      child: SnapsLogo(height: 18.0),
                    ),
                  )
                : AppAvatar(
                    avatarUrl: notification.actorAvatar,
                    size: 44.0,
                    name: notification.actorName,
                  ),
          ),
          Positioned(
            right: -2.0,
            bottom: -2.0,
            child: Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                color: _getBadgeColor(notification.type),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkCanvas : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getBadgeIcon(notification.type),
                size: 11.0,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(ActivityType type) => switch (type) {
        ActivityType.like => const Color(0xFFF43F5E),
        ActivityType.comment => const Color(0xFF3B82F6),
        ActivityType.mention => AppColors.primary,
        ActivityType.follow => const Color(0xFF6366F1),
        ActivityType.order => const Color(0xFF10B981),
        ActivityType.system => const Color(0xFF3D38F5),
      };

  IconData _getBadgeIcon(ActivityType type) => switch (type) {
        ActivityType.like => CupertinoIcons.heart_fill,
        ActivityType.comment => CupertinoIcons.chat_bubble_fill,
        ActivityType.mention => CupertinoIcons.at,
        ActivityType.follow => CupertinoIcons.person_badge_plus_fill,
        ActivityType.order => CupertinoIcons.bag_fill,
        ActivityType.system => CupertinoIcons.speaker_2_fill,
      };
}
