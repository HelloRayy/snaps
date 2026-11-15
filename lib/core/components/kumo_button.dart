import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/theme/tactile_shadows.dart';

enum KumoButtonVariant { primary, secondary, outline, black }

/// Tactile Button Component (Backward-compatible with KumoButton invocations)
/// Upgraded to Tactile Design Specifications (https://www.4hands.dev/tactile-design)
///
/// Features:
/// - Calibrated ergonomic radius (10.0px instead of 1000px capsule)
/// - Height: 46.0px (balanced mobile touch target)
/// - Tactile micro-interaction: scale(0.97) squeeze physics on press (150ms)
/// - Haptic feedback: HapticFeedback.lightImpact() on touch down
/// - Surfaces: Solid Primary Ink/Brand, fine 1px ring, crisp 1px drop (zero blurry clouds)
class KumoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final KumoButtonVariant variant;
  final Widget? iconRight;
  final Widget? iconLeft;
  final double height;
  final double? width;
  final double borderRadius;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const KumoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = KumoButtonVariant.primary,
    this.iconRight,
    this.iconLeft,
    this.height = 46.0,
    this.width,
    this.borderRadius = 10.0,
    this.isLoading = false,
    this.padding,
  });

  const KumoButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.iconRight,
    this.iconLeft,
    this.height = 46.0,
    this.width,
    this.borderRadius = 10.0,
    this.isLoading = false,
    this.padding,
  }) : variant = KumoButtonVariant.primary;

  const KumoButton.black({
    super.key,
    required this.text,
    this.onPressed,
    this.iconRight,
    this.iconLeft,
    this.height = 46.0,
    this.width,
    this.borderRadius = 10.0,
    this.isLoading = false,
    this.padding,
  }) : variant = KumoButtonVariant.black;

  const KumoButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.iconRight,
    this.iconLeft,
    this.height = 46.0,
    this.width,
    this.borderRadius = 10.0,
    this.isLoading = false,
    this.padding,
  }) : variant = KumoButtonVariant.secondary;

  const KumoButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.iconRight,
    this.iconLeft,
    this.height = 46.0,
    this.width,
    this.borderRadius = 10.0,
    this.isLoading = false,
    this.padding,
  }) : variant = KumoButtonVariant.outline;

  @override
  State<KumoButton> createState() => _KumoButtonState();
}

class _KumoButtonState extends State<KumoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    final isPrimary = widget.variant == KumoButtonVariant.primary;
    final isSecondary = widget.variant == KumoButtonVariant.secondary;
    final isOutline = widget.variant == KumoButtonVariant.outline;
    final isBlack = widget.variant == KumoButtonVariant.black;

    // Background color
    final Color bgColor;
    if (!isEnabled) {
      bgColor = isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9);
    } else if (isPrimary) {
      bgColor = AppColors.primary;
    } else if (isBlack) {
      bgColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    } else if (isSecondary) {
      bgColor = isDark ? AppColors.darkSurfaceElevated : Colors.white;
    } else {
      bgColor = Colors.transparent;
    }

    // Text & icon color
    final Color fgColor;
    if (!isEnabled) {
      fgColor = isDark ? const Color(0xFF737373) : const Color(0xFF94A3B8);
    } else if (isPrimary) {
      fgColor = Colors.white;
    } else if (isBlack) {
      fgColor = isDark ? const Color(0xFF111827) : Colors.white;
    } else if (isSecondary) {
      fgColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B);
    } else {
      fgColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    }

    // Borders & Shadows (Tactile Shadows: 1px ring + 1px crisp drop)
    final Border? border;
    final List<BoxShadow>? shadow;

    if (!isEnabled) {
      border = Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0), width: 0.8);
      shadow = null;
    } else if (isSecondary) {
      border = null;
      shadow = isDark ? TactileShadows.darkRaised : TactileShadows.lightRaised;
    } else if (isPrimary || isBlack) {
      border = Border.all(
        color: isPrimary ? AppColors.primaryDark : Colors.black,
        width: 0.5,
      );
      shadow = TactileShadows.primaryButton;
    } else if (isOutline) {
      border = Border.all(color: isDark ? const Color(0x33FFFFFF) : const Color(0xFFCBD5E1), width: 1.0);
      shadow = null;
    } else {
      border = null;
      shadow = null;
    }

    return GestureDetector(
      onTapDown: isEnabled
          ? (_) {
              setState(() => _isPressed = true);
              HapticFeedback.lightImpact();
            }
          : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: border,
            boxShadow: shadow,
          ),
          child: Center(
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 18.0),
              child: widget.isLoading
                  ? SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: fgColor,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.iconLeft != null) ...[
                          IconTheme(
                            data: IconThemeData(color: fgColor, size: 18.0),
                            child: widget.iconLeft!,
                          ),
                          const SizedBox(width: 8.0),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontSize: widget.height < 40 ? 13.0 : 14.5,
                            fontWeight: FontWeight.w600,
                            color: fgColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (widget.iconRight != null) ...[
                          const SizedBox(width: 8.0),
                          IconTheme(
                            data: IconThemeData(color: fgColor, size: 18.0),
                            child: widget.iconRight!,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
