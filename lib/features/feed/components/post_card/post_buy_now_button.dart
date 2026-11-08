import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Floating overlay button "Beli Sekarang" with right icon for product posts in feed.
/// Styled to match the simple, clean white pill button in the Activity Page.
class PostBuyNowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isSoldOut;

  const PostBuyNowButton({
    super.key,
    required this.onPressed,
    this.isSoldOut = false,
  });

  @override
  State<PostBuyNowButton> createState() => _PostBuyNowButtonState();
}

class _PostBuyNowButtonState extends State<PostBuyNowButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isSoldOut) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F242F) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100.0),
          border: Border.all(
            color: isDark ? const Color(0x26FFFFFF) : const Color(0xFFCBD5E1),
            width: 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'Produk Habis',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
            letterSpacing: -0.2,
          ),
        ),
      );
    }

    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1);
    final contentColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100.0),
            border: Border.all(
              color: borderColor,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 8.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Beli Sekarang',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: contentColor,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 5.5),
              Icon(
                LucideIcons.arrowRight,
                size: 13.5,
                color: contentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
