import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/utils/share_helper.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/feed/components/lightbox/lightbox_action_bar.dart';
import 'package:snapan_market/features/feed/components/lightbox/lightbox_image_viewer.dart';
import 'package:snapan_market/features/feed/components/lightbox/lightbox_nav_arrows.dart';
import 'package:snapan_market/features/feed/components/lightbox/lightbox_top_header.dart';
import 'package:snapan_market/features/feed/models/market_post_model.dart';

/// Clean, Light-Themed Fullscreen Media Lightbox Dialog
///
/// Full-width edge-to-edge image presentation with pinch-to-zoom,
/// swipe navigation, and interactive social controls.
/// Supports fluid swipe-down-to-dismiss with spring physics.
class MediaLightboxDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final MarketPostModel? post;
  final ValueChanged<MarketPostModel>? onLikeToggle;
  final ValueChanged<MarketPostModel>? onRepostToggle;
  final ValueChanged<MarketPostModel>? onPostClick;

  const MediaLightboxDialog({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.post,
    this.onLikeToggle,
    this.onRepostToggle,
    this.onPostClick,
  });

  static Future<void> show({
    required BuildContext context,
    required List<String> images,
    int initialIndex = 0,
    MarketPostModel? post,
    ValueChanged<MarketPostModel>? onLikeToggle,
    ValueChanged<MarketPostModel>? onRepostToggle,
    ValueChanged<MarketPostModel>? onPostClick,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Media Lightbox',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) {
        return MediaLightboxDialog(
          images: images,
          initialIndex: initialIndex,
          post: post,
          onLikeToggle: onLikeToggle,
          onRepostToggle: onRepostToggle,
          onPostClick: onPostClick,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<MediaLightboxDialog> createState() => _MediaLightboxDialogState();
}

class _MediaLightboxDialogState extends State<MediaLightboxDialog>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  bool _isLiked = false;
  int _likesCount = 0;
  bool _isReposted = false;
  int _repostsCount = 0;

  late AnimationController _likeAnimController;
  late Animation<double> _likeScaleAnim;

  // Swipe-to-dismiss state
  int _activePointerCount = 0;
  late final ValueNotifier<double> _dragOffsetNotifier;
  bool _isCurrentZoomed = false;
  bool _isDismissing = false;
  bool _isInteractingWithViewer = false;
  bool _isMultiTouch = false;
  late AnimationController _springBackAnimController;
  Animation<double>? _springBackAnim;
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _dragOffsetNotifier = ValueNotifier<double>(0.0);
    if (widget.post != null) {
      _isLiked = widget.post!.isLiked;
      _likesCount = widget.post!.likesCount;
      _isReposted = widget.post!.isReposted;
      _repostsCount = widget.post!.repostsCount;
    }

    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _likeAnimController,
      curve: Curves.easeInOut,
    ));

    _springBackAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimController.dispose();
    _springBackAnimController.dispose();
    _dragOffsetNotifier.dispose();
    super.dispose();
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
    if (_isCurrentZoomed || _activePointerCount > 1 || _isInteractingWithViewer) {
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
    if (_isCurrentZoomed || _activePointerCount > 1 || _isInteractingWithViewer) {
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
    if (_isCurrentZoomed || _activePointerCount > 1 || _isInteractingWithViewer) {
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

  void _handleLikeToggle() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likesCount = (_likesCount - 1).clamp(0, 999999);
      } else {
        _isLiked = true;
        _likesCount += 1;
        _likeAnimController.forward(from: 0.0);
      }
    });

    if (widget.post != null) {
      final updated = widget.post!.copyWith(
        isLiked: _isLiked,
        likesCount: _likesCount,
      );
      widget.onLikeToggle?.call(updated);
    }
  }

  void _handleRepostToggle() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_isReposted) {
        _isReposted = false;
        _repostsCount = (_repostsCount - 1).clamp(0, 999999);
      } else {
        _isReposted = true;
        _repostsCount += 1;
      }
    });

    if (widget.post != null) {
      final updated = widget.post!.copyWith(
        isReposted: _isReposted,
        repostsCount: _repostsCount,
      );
      widget.onRepostToggle?.call(updated);
    }
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    final postId = widget.post?.id ?? 'preview';
    Clipboard.setData(ClipboardData(text: ShareHelper.getPostShareUrl(postId)));
    SnapsToast.success(context, 'Tautan disalin ke papan klip', hasBottomNav: false);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0B0F17) : Colors.white;

    final bool canDismiss = !_isCurrentZoomed && !_isInteractingWithViewer && !_isMultiTouch;

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
          onVerticalDragStart: canDismiss ? _handleVerticalDragStart : null,
          onVerticalDragUpdate: canDismiss ? _handleVerticalDragUpdate : null,
          onVerticalDragEnd: canDismiss ? _handleVerticalDragEnd : null,
          child: ValueListenableBuilder<double>(
            valueListenable: _dragOffsetNotifier,
            builder: (context, dragOffsetY, child) {
              final double pullProgress = (dragOffsetY.abs().clamp(0.0, 300.0) / 300.0);
              final double bgOpacity = (1.0 - pullProgress * 0.85).clamp(0.0, 1.0);
              final double imageScale = (1.0 - pullProgress * 0.18).clamp(0.75, 1.0);
              final double controlsAlpha = (1.0 - pullProgress * 2.5).clamp(0.0, 1.0);

              return Material(
                color: bgColor.withValues(alpha: bgOpacity),
                child: Stack(
                  children: [
                    // 1. Edge-to-edge PageView with pinch-to-zoom and swipe translation
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0.0, dragOffsetY),
                        child: Transform.scale(
                          scale: imageScale,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.0 * pullProgress),
                            child: child,
                          ),
                        ),
                      ),
                    ),

                    // 2. Overlays (Chevrons, Header, Action Bar) smoothly fading on swipe
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: controlsAlpha < 0.05,
                        child: Opacity(
                          opacity: controlsAlpha,
                          child: Stack(
                            children: [
                              LightboxNavArrows(
                                currentIndex: _currentIndex,
                                totalImages: widget.images.length,
                                onPrevious: () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                ),
                                onNext: () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              LightboxTopHeader(
                                topPadding: topPadding,
                                currentIndex: _currentIndex,
                                totalImages: widget.images.length,
                                onClose: () => Navigator.of(context).pop(),
                              ),
                              if (widget.post != null)
                                LightboxActionBar(
                                  post: widget.post!,
                                  bottomPadding: bottomPadding,
                                  isLiked: _isLiked,
                                  likesCount: _likesCount,
                                  isReposted: _isReposted,
                                  repostsCount: _repostsCount,
                                  likeScaleAnim: _likeScaleAnim,
                                  onLikeToggle: _handleLikeToggle,
                                  onCommentClick: () {
                                    Navigator.of(context).pop();
                                    widget.onPostClick?.call(widget.post!);
                                  },
                                  onRepostToggle: _handleRepostToggle,
                                  onShareClick: _handleShare,
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
            child: PageView.builder(
              controller: _pageController,
              physics: (_isCurrentZoomed || _isInteractingWithViewer || _isMultiTouch)
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemCount: widget.images.length,
              onPageChanged: (idx) => setState(() {
                _currentIndex = idx;
                _isCurrentZoomed = false;
                _isInteractingWithViewer = false;
              }),
              itemBuilder: (context, index) {
                return LightboxImageViewer(
                  imageUrl: widget.images[index],
                  screenWidth: mediaQuery.size.width,
                  isMultiTouch: _isMultiTouch,
                  onZoomChanged: (zoomed) {
                    if (zoomed != _isCurrentZoomed) {
                      setState(() {
                        _isCurrentZoomed = zoomed;
                      });
                    }
                  },
                  onInteractionChanged: (interacting) {
                    if (interacting != _isInteractingWithViewer) {
                      setState(() {
                        _isInteractingWithViewer = interacting;
                        if (interacting && _dragOffsetNotifier.value != 0.0) {
                          _springBackToZero();
                        }
                      });
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
}
}
