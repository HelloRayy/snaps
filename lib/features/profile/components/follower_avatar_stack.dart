import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/avatar/default_profile_avatar.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/profile/models/follower_avatar_preview.dart';

/// Overlapping Follower Avatar Stack (Facepile) matching Threads & Instagram standard.
/// Uses an outside cutout ring (2.0dp) so that the avatar photos remain 100% full size
/// without being eaten by an inside border.
class FollowerAvatarStack extends StatelessWidget {
  final List<FollowerAvatarPreview> avatars;
  final double size;

  const FollowerAvatarStack({
    super.key,
    required this.avatars,
    this.size = 28.0,
  });

  @override
  Widget build(BuildContext context) {
    final displayAvatars = avatars.take(3).toList();
    if (displayAvatars.isEmpty) return const SizedBox.shrink();

    const ringWidth = 2.0;
    final itemDiameter = size + (ringWidth * 2);
    // Overlap: ~32% of avatar photo size
    final overlap = (size * 0.32).roundToDouble();
    final step = size - overlap;
    final totalWidth = itemDiameter + (displayAvatars.length - 1) * step;
    final cutoutColor = AppColors.adaptiveCanvas(context);

    return SizedBox(
      width: totalWidth,
      height: itemDiameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Render in reverse so the first avatar (mutual/newest) sits on top of subsequent ones
          for (int i = displayAvatars.length - 1; i >= 0; i--)
            Positioned(
              left: i * step,
              top: 0,
              width: itemDiameter,
              height: itemDiameter,
              child: Container(
                width: itemDiameter,
                height: itemDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cutoutColor,
                ),
                alignment: Alignment.center,
                child: AppAvatar(
                  avatarUrl: displayAvatars[i].avatarUrl,
                  size: size,
                  name: displayAvatars[i].displayName ?? displayAvatars[i].username,
                  username: displayAvatars[i].username,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
