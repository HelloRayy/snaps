import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Micro circular badge with Electric Indigo background and Koala mascot icon
/// indicating the availability of the Mascot Flair feature.
class MascotIndicatorBadge extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const MascotIndicatorBadge({
    super.key,
    this.size = 20.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkSurface : Colors.white;

    Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: Image.asset(
          'assets/mascots/koala/delighted.webp',
          width: size * 0.72,
          height: size * 0.72,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );

    if (onTap != null) {
      badge = GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        behavior: HitTestBehavior.opaque,
        child: badge,
      );
    }

    return badge;
  }
}
