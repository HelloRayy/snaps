import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Floating overlay button "Beli Sekarang" with right icon for product posts in feed.
/// Styled with signature Snaps Kumo Azure gradient (#269DFF -> #008BFF) matching app design system.
class PostBuyNowButton extends StatefulWidget {
  final VoidCallback onPressed;

  const PostBuyNowButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<PostBuyNowButton> createState() => _PostBuyNowButtonState();
}

class _PostBuyNowButtonState extends State<PostBuyNowButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Snaps Kumo brand signature gradient colors (matching KumoButton.primary & FloatingPlusSquircleButton)
    const primaryTop = Color(0xFF269DFF); // Light Azure Specular
    const primaryBase = Color(0xFF008BFF); // pen.dev Primary Accent Fill

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
          padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 7.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryTop,
                primaryBase,
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryBase.withValues(alpha: 0.38),
                blurRadius: 10.0,
                offset: const Offset(0, 3),
              ),
              const BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 4.0,
                offset: Offset(0, 1),
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                  height: 1.2,
                ),
              ),
              SizedBox(width: 5.0),
              Icon(
                LucideIcons.arrowRight,
                size: 13.5,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
