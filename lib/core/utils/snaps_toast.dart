import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/navigation/navigation_service.dart';

/// Contextual toast presentation types
enum SnapsToastType {
  normal,
  success,
  error,
  info,
}

/// Centralized Snaps native bottom capsule toast helper (<250 lines).
/// Renders an ergonomic, content-hugging pill floating cleanly above bottom docks,
/// sheets, and keyboards with spring transitions and tactile haptics.
class SnapsToast {
  SnapsToast._();

  static OverlayEntry? _activeEntry;
  static Timer? _activeTimer;
  static final GlobalKey<_SnapsToastWidgetState> _toastKey = GlobalKey<_SnapsToastWidgetState>();

  /// Calculate safe floating bottom margin based on bottom nav and screen safe area
  static double getBottomMargin(BuildContext context, {bool hasBottomNav = true}) {
    final mediaQuery = MediaQuery.maybeOf(context);
    final bottomInset = mediaQuery?.viewInsets.bottom ?? 0.0;
    final bottomPadding = mediaQuery?.padding.bottom ?? 0.0;

    if (bottomInset > 0) {
      return bottomInset + 16.0;
    }
    if (hasBottomNav) {
      return (bottomPadding > 0 ? bottomPadding + 8.0 : 18.0) + 62.0 + 14.0;
    }
    return bottomPadding > 0 ? bottomPadding + 16.0 : 22.0;
  }

  /// Display a floating native capsule toast safely above bottom nav bars
  static void show(
    BuildContext? context,
    String message, {
    SnapsToastType type = SnapsToastType.normal,
    IconData? customIcon,
    bool hasBottomNav = true,
    Duration duration = const Duration(milliseconds: 2200),
    String? actionLabel,
    VoidCallback? onAction,
    Color? backgroundColor,
    Color? textColor,
    SnackBarAction? action,
  }) {
    final effectiveContext = context ?? NavigationService.currentContext;
    if (effectiveContext == null) return;

    final overlayState = Overlay.maybeOf(effectiveContext, rootOverlay: true) ??
        NavigationService.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _dismissActiveImmediate();

    HapticFeedback.lightImpact();

    _activeEntry = OverlayEntry(
      builder: (ctx) => _SnapsToastWidget(
        key: _toastKey,
        message: message,
        type: type,
        customIcon: customIcon,
        hasBottomNav: hasBottomNav,
        actionLabel: actionLabel ?? action?.label,
        onAction: onAction ?? action?.onPressed,
        backgroundColor: backgroundColor,
        textColor: textColor,
        onDismissed: _removeActiveEntry,
      ),
    );

    overlayState.insert(_activeEntry!);

    _activeTimer = Timer(duration, () {
      _toastKey.currentState?.dismiss();
    });
  }

  /// Convenience helper for success toasts (e.g. copy link, saved, created)
  static void success(
    BuildContext? context,
    String message, {
    bool hasBottomNav = true,
    Duration duration = const Duration(milliseconds: 2200),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message,
      type: SnapsToastType.success,
      hasBottomNav: hasBottomNav,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Convenience helper for error toasts
  static void error(
    BuildContext? context,
    String message, {
    bool hasBottomNav = true,
    Duration duration = const Duration(milliseconds: 2600),
  }) {
    show(
      context,
      message,
      type: SnapsToastType.error,
      hasBottomNav: hasBottomNav,
      duration: duration,
    );
  }

  /// Convenience helper for informational toasts
  static void info(
    BuildContext? context,
    String message, {
    bool hasBottomNav = true,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    show(
      context,
      message,
      type: SnapsToastType.info,
      hasBottomNav: hasBottomNav,
      duration: duration,
    );
  }

  /// Dismiss currently active toast with exit animation
  static void dismiss() {
    _toastKey.currentState?.dismiss();
  }

  static void _dismissActiveImmediate() {
    _activeTimer?.cancel();
    _activeTimer = null;
    try {
      _activeEntry?.remove();
    } catch (_) {}
    _activeEntry = null;
  }

  static void _removeActiveEntry() {
    _activeTimer?.cancel();
    _activeTimer = null;
    try {
      _activeEntry?.remove();
    } catch (_) {}
    _activeEntry = null;
  }
}

class _SnapsToastWidget extends StatefulWidget {
  final String message;
  final SnapsToastType type;
  final IconData? customIcon;
  final bool hasBottomNav;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback onDismissed;

  const _SnapsToastWidget({
    super.key,
    required this.message,
    required this.type,
    this.customIcon,
    required this.hasBottomNav,
    this.actionLabel,
    this.onAction,
    this.backgroundColor,
    this.textColor,
    required this.onDismissed,
  });

  @override
  State<_SnapsToastWidget> createState() => _SnapsToastWidgetState();
}

class _SnapsToastWidgetState extends State<_SnapsToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.45),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _scaleAnim = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> dismiss() async {
    if (!mounted || _isDismissing) return;
    _isDismissing = true;
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomMargin = SnapsToast.getBottomMargin(context, hasBottomNav: widget.hasBottomNav);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Positioned(
      bottom: bottomMargin,
      left: 16.0,
      right: 16.0,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: GestureDetector(
                  onTap: dismiss,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null && details.primaryVelocity! > 60) {
                      dismiss();
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth * 0.88,
                      minHeight: 42.0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: widget.backgroundColor ?? const Color(0xF218181B),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.75,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 18.0,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLeadingIcon(),
                        const SizedBox(width: 8.5),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: widget.textColor ?? const Color(0xFFF8FAFC),
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.actionLabel != null && widget.actionLabel!.isNotEmpty) ...[
                          const SizedBox(width: 10.0),
                          Container(
                            height: 20.0,
                            width: 0.8,
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          const SizedBox(width: 10.0),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onAction?.call();
                              dismiss();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Text(
                                widget.actionLabel!,
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (widget.customIcon != null) {
      return Icon(widget.customIcon, size: 16.5, color: const Color(0xFF38BDF8));
    }
    return switch (widget.type) {
      SnapsToastType.success => const Icon(LucideIcons.circleCheck, size: 16.5, color: Color(0xFF10B981)),
      SnapsToastType.error => const Icon(LucideIcons.alertCircle, size: 16.5, color: Color(0xFFEF4444)),
      SnapsToastType.info => const Icon(LucideIcons.info, size: 16.5, color: Color(0xFF38BDF8)),
      SnapsToastType.normal => const Icon(LucideIcons.check, size: 15.0, color: Color(0xFF10B981)),
    };
  }
}
