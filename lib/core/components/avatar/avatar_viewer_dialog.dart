import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/components/avatar/default_profile_avatar.dart';

/// Fullscreen Circle Avatar Viewer Dialog
///
/// Implements Jakob's Law (industry standard avatar inspection matching WhatsApp/Telegram)
/// with theme awareness (white background on Light Theme, dark cinema on Dark Theme):
/// - Theme-responsive backdrop and barrier (Light -> White, Dark -> Dark Cinema #0B0F17)
/// - Centered perfect-circle frame (p1: full circle) with adaptive outline and shadow
/// - Pinch-to-zoom support with gesture disambiguation
/// - Fluid swipe-down-to-dismiss and tap-outside-to-dismiss
/// - Contextual header showing user title and username in theme-contrasted typography
/// - Smooth Hero transition support
class AvatarViewerDialog extends StatefulWidget {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String? heroTag;

  const AvatarViewerDialog({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.heroTag,
  });

  static Future<void> show({
    required BuildContext context,
    required String imageUrl,
    String? title,
    String? subtitle,
    String? heroTag,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Avatar Viewer',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        return AvatarViewerDialog(
          imageUrl: imageUrl,
          title: title,
          subtitle: subtitle,
          heroTag: heroTag,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<AvatarViewerDialog> createState() => _AvatarViewerDialogState();
}

class _AvatarViewerDialogState extends State<AvatarViewerDialog>
    with TickerProviderStateMixin {
  late final TransformationController _transformController;
  late final AnimationController _springBackAnimController;
  Animation<double>? _springBackAnim;
  late final AnimationController _doubleTapAnimController;
  Animation<Matrix4>? _doubleTapAnimation;
  TapDownDetails? _doubleTapDetails;

  int _activePointerCount = 0;
  late final ValueNotifier<double> _dragOffsetNotifier;
  bool _isCurrentZoomed = false;
  bool _isDismissing = false;
  bool _isMultiTouch = false;
  bool _isInteracting = false;
  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _transformController.addListener(_handleTransform);

    _dragOffsetNotifier = ValueNotifier<double>(0.0);
    _springBackAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _doubleTapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (_doubleTapAnimation != null) {
          _transformController.value = _doubleTapAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformController.removeListener(_handleTransform);
    _transformController.dispose();
    _springBackAnimController.dispose();
    _doubleTapAnimController.dispose();
    _dragOffsetNotifier.dispose();
    super.dispose();
  }

  void _handleTransform() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.02;
    if (zoomed != _isCurrentZoomed) {
      setState(() => _isCurrentZoomed = zoomed);
    }
  }

  void _springBackToZero() {
    if (_dragOffsetNotifier.value == 0.0 || _isDismissing) return;
    _springBackAnimController.stop();
    _springBackAnimController.duration = const Duration(milliseconds: 240);
    _springBackAnim = Tween<double>(begin: _dragOffsetNotifier.value, end: 0.0).animate(
      CurvedAnimation(
        parent: _springBackAnimController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        _dragOffsetNotifier.value = _springBackAnim!.value;
      });
    _springBackAnimController.forward(from: 0.0);
  }

  void _dismissWithFlyOff(double targetY) {
    if (_isDismissing) return;
    _isDismissing = true;
    HapticFeedback.lightImpact();
    _springBackAnimController.stop();
    final currentOffset = _dragOffsetNotifier.value;
    _springBackAnim = Tween<double>(begin: currentOffset, end: targetY).animate(
      CurvedAnimation(
        parent: _springBackAnimController,
        curve: Curves.easeOutQuad,
      ),
    )..addListener(() {
        _dragOffsetNotifier.value = _springBackAnim!.value;
      });
    _springBackAnimController.duration = const Duration(milliseconds: 170);
    _springBackAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    if (_isDismissing) return;
    if (_isCurrentZoomed || _activePointerCount > 1 || _isInteracting) {
      if (_dragOffsetNotifier.value != 0.0) {
        _springBackToZero();
      }
      return;
    }
    if (_springBackAnimController.isAnimating) {
      _springBackAnimController.stop();
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    if (_isCurrentZoomed || _activePointerCount > 1 || _isInteracting) {
      if (_dragOffsetNotifier.value != 0.0) {
        _springBackToZero();
      }
      return;
    }
    _dragOffsetNotifier.value =
        (_dragOffsetNotifier.value + details.delta.dy).clamp(-900.0, 900.0);
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    if (_isCurrentZoomed || _activePointerCount > 1 || _isInteracting) {
      if (_dragOffsetNotifier.value != 0.0) {
        _springBackToZero();
      }
      return;
    }
    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffsetNotifier.value.abs() > 110.0 || velocity.abs() > 650.0) {
      final screenHeight = MediaQuery.of(context).size.height;
      final bool dismissDown = velocity > 200.0 ||
          (velocity.abs() <= 200.0 && _dragOffsetNotifier.value > 0);
      final double targetY = dismissDown ? (screenHeight + 100.0) : -(screenHeight + 100.0);
      _dismissWithFlyOff(targetY);
    } else if (_dragOffsetNotifier.value != 0.0) {
      _springBackToZero();
    }
  }

  void _animateReset() {
    if (_transformController.value == Matrix4.identity()) return;
    _doubleTapAnimController.stop();
    _doubleTapAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _doubleTapAnimController,
      curve: Curves.easeOutCubic,
    ));
    _doubleTapAnimController.forward(from: 0.0);
  }

  Widget _buildAvatarImage(double size, bool isDark) {
    final cleanUrl = widget.imageUrl.trim();
    Widget imageWidget;

    final fallbackBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final fallbackIcon = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (cleanUrl.isEmpty) {
      imageWidget = DefaultProfileAvatar(
        size: size,
        backgroundColor: fallbackBg,
        iconColor: fallbackIcon,
      );
    } else if (cleanUrl.startsWith('assets/')) {
      imageWidget = Image.asset(
        cleanUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => DefaultProfileAvatar(
          size: size,
          backgroundColor: fallbackBg,
          iconColor: fallbackIcon,
        ),
      );
    } else {
      imageWidget = Image.network(
        cleanUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            color: fallbackBg,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                strokeWidth: 2.5,
                color: const Color(0xFF008BFF),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => DefaultProfileAvatar(
          size: size,
          backgroundColor: fallbackBg,
          iconColor: fallbackIcon,
        ),
      );
    }

    if (widget.heroTag != null && widget.heroTag!.isNotEmpty) {
      imageWidget = Hero(
        tag: widget.heroTag!,
        child: imageWidget,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.55)
                : const Color(0x18000000),
            blurRadius: isDark ? 28.0 : 20.0,
            spreadRadius: isDark ? 4.0 : 2.0,
          ),
        ],
      ),
      child: ClipOval(
        child: imageWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final screenWidth = mediaQuery.size.width;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Avatar diameter: proportional full circle (~290dp)
    final double avatarSize = (screenWidth * 0.76).clamp(240.0, 320.0);
    final Color bgColor = isDark ? const Color(0xFF0B0F17) : Colors.white;

    final bool canDismiss = !_isCurrentZoomed && !_isInteracting && !_isMultiTouch;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Listener(
        onPointerDown: (_) {
          _activePointerCount++;
          if (_activePointerCount > 1) {
            if (_dragOffsetNotifier.value != 0.0) {
              _springBackToZero();
            }
            if (!_isMultiTouch) {
              setState(() => _isMultiTouch = true);
            }
          }
        },
        onPointerUp: (_) {
          _activePointerCount = (_activePointerCount - 1).clamp(0, 10);
          if (_activePointerCount < 2 && _isMultiTouch) {
            setState(() => _isMultiTouch = false);
          }
        },
        onPointerCancel: (_) {
          _activePointerCount = (_activePointerCount - 1).clamp(0, 10);
          if (_activePointerCount < 2 && _isMultiTouch) {
            setState(() => _isMultiTouch = false);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // Tap outside avatar image dismisses dialog
            Navigator.of(context).pop();
          },
          onVerticalDragStart: canDismiss ? _handleVerticalDragStart : null,
          onVerticalDragUpdate: canDismiss ? _handleVerticalDragUpdate : null,
          onVerticalDragEnd: canDismiss ? _handleVerticalDragEnd : null,
          child: ValueListenableBuilder<double>(
            valueListenable: _dragOffsetNotifier,
            builder: (context, dragOffsetY, child) {
              final double pullProgress = (dragOffsetY.abs().clamp(0.0, 300.0) / 300.0);
              final double bgOpacity = (1.0 - pullProgress * 0.85).clamp(0.0, 1.0);
              final double scale = (1.0 - pullProgress * 0.18).clamp(0.75, 1.0);
              final double controlsAlpha = (1.0 - pullProgress * 2.5).clamp(0.0, 1.0);

              return Material(
                color: bgColor.withValues(alpha: bgOpacity),
                child: Stack(
                  children: [
                    // 1. Centered Full-Circle Avatar with Zoom and Drag
                    Center(
                      child: Transform.translate(
                        offset: Offset(0.0, dragOffsetY),
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      ),
                    ),

                    // 2. Contextual Top Header (User info + Close button)
                    Positioned(
                      top: topPadding + 14.0,
                      left: 16.0,
                      right: 16.0,
                      child: IgnorePointer(
                        ignoring: controlsAlpha < 0.05,
                        child: Opacity(
                          opacity: controlsAlpha,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Circular close button (theme adaptive)
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => Navigator.of(context).pop(),
                                  child: isDark
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(20.0),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                            child: Container(
                                              width: 40.0,
                                              height: 40.0,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.12),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white.withValues(alpha: 0.16),
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: const Center(
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  size: 20.0,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 40.0,
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              width: 1.0,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 20.0,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14.0),
                              // User details (Name + Username)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.title != null && widget.title!.isNotEmpty)
                                      Text(
                                        widget.title!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                                      Text(
                                        widget.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: GestureDetector(
              onTap: () {},
              onDoubleTapDown: (details) => _doubleTapDetails = details,
              onDoubleTap: () => _handleDoubleTap(avatarSize),
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.8,
                maxScale: 3.5,
                panEnabled: _isCurrentZoomed || _isMultiTouch || _isInteracting,
                scaleEnabled: true,
                clipBehavior: Clip.none,
                onInteractionStart: (_) {
                  _isInteracting = true;
                  if (_doubleTapAnimController.isAnimating) {
                    _doubleTapAnimController.stop();
                  }
                },
                onInteractionEnd: (_) {
                  _isInteracting = false;
                  final scale = _transformController.value.getMaxScaleOnAxis();
                  if (scale <= 1.02) {
                    _animateReset();
                  }
                },
                child: _buildAvatarImage(avatarSize, isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleDoubleTap(double avatarSize) {
    HapticFeedback.lightImpact();
    final currentMatrix = _transformController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    Matrix4 targetMatrix;
    if (currentScale > 1.02) {
      targetMatrix = Matrix4.identity();
    } else {
      final tapPos = _doubleTapDetails?.localPosition ??
          Offset(avatarSize / 2, avatarSize / 2);
      const targetScale = 2.4;
      final dx = -tapPos.dx * (targetScale - 1);
      final dy = -tapPos.dy * (targetScale - 1);
      targetMatrix = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(targetScale);
    }

    _doubleTapAnimController.stop();
    _doubleTapAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _doubleTapAnimController,
      curve: Curves.easeOutCubic,
    ));

    _doubleTapAnimController.forward(from: 0.0);
  }

}
