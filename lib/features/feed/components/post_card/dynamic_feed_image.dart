import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/skeleton/snaps_shimmer.dart';
/// Renders a feed image with dynamic aspect ratio bounded between
/// [minAspectRatio] (default 0.8 for 4:5 vertical limit) and
/// [maxAspectRatio] (default 1.91 for 16:9 landscape limit).
///
/// Prevents cropping for 16:9, 4:3, 1:1, and other common formats.
class DynamicFeedImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback? onTap;
  final double minAspectRatio;
  final double maxAspectRatio;
  final double? maxHeight;
  final double borderRadius;

  const DynamicFeedImage({
    super.key,
    required this.imageUrl,
    this.onTap,
    this.minAspectRatio = 0.8,
    this.maxAspectRatio = 1.91,
    this.maxHeight = 460.0,
    this.borderRadius = 16.0,
  });

  @override
  State<DynamicFeedImage> createState() => _DynamicFeedImageState();
}

class _DynamicFeedImageState extends State<DynamicFeedImage> {
  static final Map<String, double> _ratioCache = {};
  ImageStream? _imageStream;
  ImageStreamListener? _listener;
  double? _resolvedRatio;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _resolveRatio();
  }

  @override
  void didUpdateWidget(covariant DynamicFeedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolvedRatio = _ratioCache[widget.imageUrl];
      _resolveRatio();
    }
  }

  void _resolveRatio() {
    final cached = _ratioCache[widget.imageUrl];
    if (cached != null) {
      _resolvedRatio = cached;
      return;
    }

    final provider = CachedNetworkImageProvider(widget.imageUrl);
    _imageStream?.removeListener(_listener!);
    _imageStream = provider.resolve(const ImageConfiguration());
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        final w = info.image.width;
        final h = info.image.height;
        if (w > 0 && h > 0) {
          final naturalRatio = w / h;
          final clampedRatio = naturalRatio.clamp(
            widget.minAspectRatio,
            widget.maxAspectRatio,
          );
          _ratioCache[widget.imageUrl] = clampedRatio;
          setState(() {
            _resolvedRatio = clampedRatio;
          });
        }
      },
      onError: (exception, stackTrace) {
        // Fallback gracefully without breaking layout
      },
    );
    _imageStream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_listener != null && _imageStream != null) {
      _imageStream?.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _resolvedRatio ?? (4 / 3);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor = isDark ? const Color(0xFF1E2021) : const Color(0xFFF1F5F9);

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Container(
          constraints: BoxConstraints(maxHeight: widget.maxHeight ?? 460.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1D1E) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0),
              width: 0.6,
            ),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AspectRatio(
              aspectRatio: ratio,
              child: CachedNetworkImage(
                key: ValueKey('${widget.imageUrl}#$_retryCount'),
                imageUrl: widget.imageUrl,
                memCacheWidth: 800,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 180),
                fadeOutDuration: const Duration(milliseconds: 120),
                placeholder: (_, __) => SnapsShimmer(
                  child: Container(
                    color: isDark
                        ? const Color(0xFF242626)
                        : const Color(0xFFF1F3F5),
                  ),
                ),
                errorWidget: (_, __, ___) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    CachedNetworkImage.evictFromCache(widget.imageUrl);
                    setState(() => _retryCount++);
                    _resolveRatio();
                  },
                  child: Container(
                    color: placeholderColor,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            size: 34.0,
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            'Ketuk untuk muat ulang',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
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
}
