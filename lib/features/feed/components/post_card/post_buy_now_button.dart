import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Floating translucent overlay button "Beli Sekarang" with right icon (SNAPS-99 & SNAPS-100).
/// Features an elegant frosted translucent pill surface over feed product images
/// with crisp white text and a subtle backdrop blur.
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
    if (widget.isSoldOut) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.5),
            decoration: BoxDecoration(
              color: const Color(0x99334155), // Translucent muted slate
              borderRadius: BorderRadius.circular(100.0),
              border: Border.all(
                color: const Color(0x26FFFFFF),
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 6.0,
                  offset: Offset(0, 1.5),
                ),
              ],
            ),
            child: const Text(
              'Produk Habis',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: Color(0xFFCBD5E1),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      );
    }

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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.5),
              decoration: BoxDecoration(
                color: const Color(0xCC0F172A), // 80% translucent deep slate
                borderRadius: BorderRadius.circular(100.0),
                border: Border.all(
                  color: const Color(0x33FFFFFF), // 20% subtle white outline
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 6.0,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Beli Sekarang',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(width: 5.5),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 13.5,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
