import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/theme/tactile_shadows.dart';

enum TactileButtonVariant { primary, secondary, black, outline, destructive }

/// Tactile Button Component
/// Complies with Tactile Design System (https://www.4hands.dev/tactile-design)
/// 
/// Replaces legacy Kumo capsule button:
/// - Measured physical radius (10px default or 6px compact, not 100px capsule)
/// - Height: 46px mobile default (compact 36px, utility 28px)
/// - Micro-interaction: scale(0.97) physical squeeze on press (150ms easeOutCubic)
/// - Haptic feedback: HapticFeedback.lightImpact() on touch down
/// - Shadows: Fine 1px ring + crisp 1px drop (zero blurry clouds)
class TactileButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final TactileButtonVariant variant;
  final Widget? iconRight;
  final Widget? iconLeft;
  final double height;
  final double? width;
  final double borderRadius;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;

  const TactileButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = TactileButtonVariant.primary,
    this.iconRight,
    this.iconLeft,
    this.height = 46.0,
    this.width,
    this.borderRadius = 10.0,
    this.isLoading = false,
    this.padding,
  });

  const TactileButton.primary({
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
  }) : variant = TactileButtonVariant.primary;

  const TactileButton.black({
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
  }) : variant = TactileButtonVariant.black;

  const TactileButton.secondary({
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
  }) : variant = TactileButtonVariant.secondary;

  const TactileButton.outline({
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
  }) : variant = TactileButtonVariant.outline;

  const TactileButton.destructive({
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
  }) : variant = TactileButtonVariant.destructive;

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    final isPrimary = widget.variant == TactileButtonVariant.primary;
    final isBlack = widget.variant == TactileButtonVariant.black;
    final isSecondary = widget.variant == TactileButtonVariant.secondary;
    final isOutline = widget.variant == TactileButtonVariant.outline;
    final isDestructive = widget.variant == TactileButtonVariant.destructive;

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
    } else if (isDestructive) {
      bgColor = const Color(0xFFE11D48); // red-9
    } else {
      bgColor = Colors.transparent;
    }

    // Text & icon color
    final Color fgColor;
    if (!isEnabled) {
      fgColor = isDark ? const Color(0xFF737373) : const Color(0xFF94A3B8);
    } else if (isPrimary || isDestructive) {
      fgColor = Colors.white;
    } else if (isBlack) {
      fgColor = isDark ? const Color(0xFF111827) : Colors.white;
    } else if (isSecondary) {
      fgColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B);
    } else {
      fgColor = isDark ? AppColors.darkTextPrimary : AppColors.primary;
    }

    // Borders & Shadows
    final Border? border;
    final List<BoxShadow>? shadow;

    if (!isEnabled) {
      border = Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0), width: 0.8);
      shadow = null;
    } else if (isSecondary) {
      border = null;
      shadow = isDark ? TactileShadows.darkRaised : TactileShadows.lightRaised;
    } else if (isPrimary || isBlack || isDestructive) {
      border = Border.all(
        color: isPrimary ? AppColors.primaryDark : (isBlack ? Colors.black : const Color(0xFFBE123C)),
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
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: fgColor,
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
