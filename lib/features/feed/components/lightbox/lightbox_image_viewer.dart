import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-width edge-to-edge interactive image item with pinch-to-zoom
/// and zoom-state awareness to disambiguate swipe-to-dismiss gestures.
class LightboxImageViewer extends StatefulWidget {
  final String imageUrl;
  final double screenWidth;
  final ValueChanged<bool>? onZoomChanged;

  const LightboxImageViewer({
    super.key,
    required this.imageUrl,
    required this.screenWidth,
    this.onZoomChanged,
  });

  @override
  State<LightboxImageViewer> createState() => _LightboxImageViewerState();
}

class _LightboxImageViewerState extends State<LightboxImageViewer>
    with SingleTickerProviderStateMixin {
  late final TransformationController _controller;
  late final AnimationController _animController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;

  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller = TransformationController();
    _controller.addListener(_handleTransform);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _controller.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.removeListener(_handleTransform);
    _controller.dispose();
    super.dispose();
  }

  void _handleTransform() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
      widget.onZoomChanged?.call(zoomed);
    }
  }

  void _handleDoubleTap() {
    HapticFeedback.lightImpact();
    final currentMatrix = _controller.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();

    Matrix4 targetMatrix;
    if (currentScale > 1.05) {
      targetMatrix = Matrix4.identity();
    } else {
      final tapPos = _doubleTapDetails?.localPosition ??
          Offset(widget.screenWidth / 2, widget.screenWidth / 2);
      const targetScale = 2.5;
      final dx = -tapPos.dx * (targetScale - 1);
      final dy = -tapPos.dy * (targetScale - 1);
      targetMatrix = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(targetScale);
    }

    _zoomAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onDoubleTapDown: (details) => _doubleTapDetails = details,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1.0,
          maxScale: 4.0,
          panEnabled: true,
          boundaryMargin: const EdgeInsets.symmetric(
            horizontal: 48.0,
            vertical: 64.0,
          ),
          clipBehavior: Clip.none,
          onInteractionEnd: (_) {
            final scale = _controller.value.getMaxScaleOnAxis();
            if (scale <= 1.02 && !_animController.isAnimating) {
              if (_controller.value != Matrix4.identity()) {
                _controller.value = Matrix4.identity();
              }
            }
          },
          child: SizedBox(
            width: widget.screenWidth,
            child: Image.network(
              widget.imageUrl,
              width: widget.screenWidth,
              fit: BoxFit.fitWidth,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2.0,
                    color: const Color(0xFF008BFF),
                  ),
                );
              },
              errorBuilder: (_, _, _) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 48.0,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
