import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/ui/default_profile_avatar.dart';
import 'package:snapan_market/features/feed/models/market_post_model.dart';
import 'package:snapan_market/features/profile/models/profile_user_model.dart';

/// Compact Reply Card for "Balasan" Tab in ProfileScreen.
class ProfileReplyThreadCard extends StatelessWidget {
  final ProfileReplyThreadModel thread;
  final ValueChanged<MarketPostModel>? onPostClick;
  final Function(List<String> images, int index)? onImageClick;

  const ProfileReplyThreadCard({
    super.key,
    required this.thread,
    this.onPostClick,
    this.onImageClick,
  });

  @override
  Widget build(BuildContext context) {
    final parent = thread.parentPost;
    final reply = thread.reply;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final mutedText = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final parentUsername = (parent.seller.username ?? parent.seller.name).replaceAll('@', '');

    return InkWell(
      onTap: () => onPostClick?.call(parent),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 14.0),
        decoration: BoxDecoration(
          color: AppColors.adaptiveSurface(context),
          border: Border(
            bottom: BorderSide(color: AppColors.adaptiveDivider(context), width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(reply.user.avatar),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          reply.user.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (reply.user.isVerified) ...[
                        const SizedBox(width: 4.0),
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          size: 14.0,
                          color: AppColors.verifiedBlue,
                        ),
                      ],
                      const SizedBox(width: 6.0),
                      Text(
                        reply.timestamp,
                        style: TextStyle(fontSize: 12.5, color: mutedText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2.0),
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(fontSize: 12.5, color: mutedText),
                      children: [
                        const TextSpan(text: 'Membalas '),
                        TextSpan(
                          text: '@$parentUsername',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    reply.content,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      color: primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String avatarUrl) {
    if (avatarUrl.trim().isEmpty) {
      return const DefaultProfileAvatar(size: 38.0);
    }
    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: 38.0,
        height: 38.0,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const DefaultProfileAvatar(size: 38.0),
      ),
    );
  }
}
