import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Floating overlay button "Diskusi" with right icon for product posts in feed.
/// High contrast dark surface with blur to guarantee legibility on any image.
class PostBuyNowButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PostBuyNowButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.5),
              decoration: BoxDecoration(
                color: const Color(0xCC0F172A),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Diskusi',
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
        ),
      ),
    );
  }
}
