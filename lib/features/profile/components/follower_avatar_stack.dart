import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/avatar/default_profile_avatar.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/profile/models/follower_avatar_preview.dart';

/// Overlapping Follower Avatar Stack (Facepile) matching Threads & Instagram standard.
/// Displays up to 3 follower avatars in a compact, view-only overlapping row.
class FollowerAvatarStack extends StatelessWidget {
  final List<FollowerAvatarPreview> avatars;
  final double size;

  const FollowerAvatarStack({
    super.key,
    required this.avatars,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final displayAvatars = avatars.take(3).toList();
    if (displayAvatars.isEmpty) return const SizedBox.shrink();

    final overlap = (size * 0.32).clamp(4.0, 12.0);
    final step = size - overlap;
    final totalWidth = size + (displayAvatars.length - 1) * step;
    final cutoutColor = AppColors.adaptiveCanvas(context);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Render in reverse so the first avatar (mutual/newest) is on top of subsequent ones
          for (int i = displayAvatars.length - 1; i >= 0; i--)
            Positioned(
              left: i * step,
              top: 0,
              width: size,
              height: size,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cutoutColor,
                ),
                child: AppAvatar(
                  avatarUrl: displayAvatars[i].avatarUrl,
                  size: size,
                  name: displayAvatars[i].displayName ?? displayAvatars[i].username,
                  username: displayAvatars[i].username,
                  border: Border.all(
                    color: cutoutColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
