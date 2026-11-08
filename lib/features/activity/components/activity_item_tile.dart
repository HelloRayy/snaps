import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:snapan_market/core/theme/app_colors.dart";
import "package:snapan_market/core/utils/mention_text_span_helper.dart";
import "package:snapan_market/features/activity/components/activity_avatar_badge.dart";
import "package:snapan_market/features/activity/components/activity_follow_button.dart";
import "package:snapan_market/features/activity/models/activity_notification_model.dart";

class ActivityItemTile extends StatelessWidget {
  final ActivityNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onActionTap;

  const ActivityItemTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onAvatarTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSystem = notification.type == ActivityType.system ||
        notification.actorName.toLowerCase().startsWith('admin');
    final hasCustomTitle = notification.title.isNotEmpty &&
        notification.title != 'Notifikasi baru' &&
        notification.title != 'Pengumuman Baru';

    final Color tileBackground = notification.isRead
        ? (isDark ? AppColors.darkCanvas : Colors.white)
        : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC));

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: tileBackground,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Actor Avatar with Action Icon Badge ala Threads
            ActivityAvatarBadge(
              notification: notification,
              onTap: onAvatarTap ?? onTap,
            ),
            const SizedBox(width: 12.0),

            // Notification Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row: Sender + Verified Seal + Dot Time Ago
                  GestureDetector(
                    onTap: onAvatarTap ?? onTap,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            isSystem ? 'Snaps' : notification.actorName,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.adaptiveText(context),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSystem) ...[
                          const SizedBox(width: 4.0),
                          const Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 13.0,
                            color: Color(0xFF0283F3),
                          ),
                        ],
                        const SizedBox(width: 6.0),
                        Text(
                          "• ${notification.timeAgo}",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Title (Clean, no cramped badge)
                  if (isSystem || hasCustomTitle) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.adaptiveText(context),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Body Message
                  const SizedBox(height: 2.5),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w500,
                        color: notification.isRead
                            ? (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B))
                            : (isDark ? Colors.white : const Color(0xFF334155)),
                        height: 1.35,
                      ),
                      children: MentionTextSpanHelper.buildSpans(
                        context: context,
                        text: notification.message,
                        defaultStyle: TextStyle(
                          fontSize: 13.0,
                          fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.w500,
                          color: notification.isRead
                              ? (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B))
                              : (isDark ? Colors.white : const Color(0xFF334155)),
                          height: 1.35,
                        ),
                      ),
                    ),
                    maxLines: isSystem ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Direct Inline Action Button (White Pill style with subtle border)
                  if (notification.hasAction) ...[
                    const SizedBox(height: 8.0),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (onActionTap != null) {
                          onActionTap!();
                        } else if (onTap != null) {
                          onTap!();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(100.0),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getActionIcon(notification.actionType),
                              size: 13.5,
                              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                            ),
                            const SizedBox(width: 5.5),
                            Text(
                              notification.actionButtonLabel?.isNotEmpty == true
                                  ? notification.actionButtonLabel!
                                  : _getDefaultActionLabel(notification.actionType),
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Trailing Section: Follow Button / Post Thumbnail / Unread Indicator
            if (notification.type == ActivityType.follow) ...[
              const SizedBox(width: 10.0),
              ActivityFollowButton(
                targetUserId: notification.actorId,
                targetUsername: notification.actorUsername,
              ),
            ] else if (notification.postThumbnail != null) ...[
              const SizedBox(width: 10.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  notification.postThumbnail!,
                  width: 44.0,
                  height: 44.0,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ] else if (!notification.isRead) ...[
              const SizedBox(width: 8.0),
              Container(
                width: 8.0,
                height: 8.0,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String? actionType) => switch (actionType) {
        'update_app' => CupertinoIcons.arrow_down_to_line,
        'external_url' => CupertinoIcons.link,
        'post_link' => CupertinoIcons.doc_text,
        _ => CupertinoIcons.arrow_right,
      };

  String _getDefaultActionLabel(String? actionType) => switch (actionType) {
        'update_app' => 'Perbarui Aplikasi',
        'external_url' => 'Buka Tautan',
        'post_link' => 'Lihat Postingan',
        _ => 'Lihat Rincian',
      };
}
