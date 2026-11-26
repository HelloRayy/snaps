import 'dart:io';
import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/skeleton/snaps_shimmer.dart';
import 'package:snapan_market/core/services/snaps_disk_image_cache.dart';

/// Renders a carousel card with dynamic width based on its natural aspect ratio
/// and a fixed height, backed by [SnapsDiskImageCache] for zero repeat egress.
class AdaptiveCarouselCard extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double maxCardWidth;
  final double minCardWidth;
  final double? customWidth;
  final double borderRadius;
  final Widget? child;
  final VoidCallback? onTap;
  final ValueChanged<double>? onRatioResolved;

  static final Map<String, double> ratioCache = {};

  static double? getCachedRatio(String url) => ratioCache[url];

  const AdaptiveCarouselCard({
    super.key,
    required this.imageUrl,
    this.height = 230.0,
    this.maxCardWidth = 340.0,
    this.minCardWidth = 120.0,
    this.borderRadius = 16.0,
    this.customWidth,
    this.child,
    this.onTap,
    this.onRatioResolved,
  });

  @override
  State<AdaptiveCarouselCard> createState() => _AdaptiveCarouselCardState();
}

class _AdaptiveCarouselCardState extends State<AdaptiveCarouselCard> {
  ImageStream? _imageStream;
  ImageStreamListener? _listener;
  double? _resolvedRatio;
  File? _localFile;
  bool _hasError = false;
  int _retryCount = 0;

  bool get _isNetwork =>
      widget.imageUrl.startsWith('http://') || widget.imageUrl.startsWith('https://');

  @override
  void initState() {
    super.initState();
    _initImage();
  }

  @override
  void didUpdateWidget(covariant AdaptiveCarouselCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolvedRatio = AdaptiveCarouselCard.ratioCache[widget.imageUrl];
      _localFile = null;
      _hasError = false;
      _initImage();
    }
  }

  Future<void> _initImage() async {
    _resolvedRatio = AdaptiveCarouselCard.ratioCache[widget.imageUrl];

    if (!_isNetwork) {
      final f = File(widget.imageUrl);
      _localFile = f;
      _resolveRatioFromFile(f);
      return;
    }

    final syncFile = SnapsDiskImageCache.instance.getCachedFileSync(widget.imageUrl);
    if (syncFile != null) {
      _localFile = syncFile;
      _resolveRatioFromFile(syncFile);
      return;
    }

    final fetched = await SnapsDiskImageCache.instance.getOrFetch(widget.imageUrl);
    if (!mounted) return;
    if (fetched != null) {
      setState(() {
        _localFile = fetched;
        _hasError = false;
      });
      _resolveRatioFromFile(fetched);
    } else {
      setState(() => _hasError = true);
    }
  }

  void _resolveRatioFromFile(File file) {
    if (AdaptiveCarouselCard.ratioCache.containsKey(widget.imageUrl)) return;
    if (_imageStream != null && _listener != null) {
      _imageStream!.removeListener(_listener!);
    }
    _imageStream = FileImage(file).resolve(const ImageConfiguration());
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        final w = info.image.width;
        final h = info.image.height;
        if (w > 0 && h > 0) {
          final naturalRatio = w / h;
          AdaptiveCarouselCard.ratioCache[widget.imageUrl] = naturalRatio;
          setState(() => _resolvedRatio = naturalRatio);
          widget.onRatioResolved?.call(naturalRatio);
        }
      },
      onError: (_, _) {},
    );
    _imageStream!.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_imageStream != null && _listener != null) {
      _imageStream!.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _resolvedRatio ?? (4 / 3);
    final calculatedWidth = widget.customWidth ??
        (widget.height * ratio).clamp(widget.minCardWidth, widget.maxCardWidth);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget imageBody;
    if (widget.child != null) {
      imageBody = widget.child!;
    } else if (_hasError) {
      imageBody = _errorPlaceholder(calculatedWidth, isDark);
    } else if (_localFile != null) {
      imageBody = Image.file(
        _localFile!,
        key: ValueKey('${widget.imageUrl}#$_retryCount'),
        cacheWidth: 600,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _errorPlaceholder(calculatedWidth, isDark),
      );
    } else {
      imageBody = SnapsShimmer(
        child: Container(
          color: isDark ? const Color(0xFF242626) : const Color(0xFFF1F3F5),
        ),
      );
    }

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: calculatedWidth,
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1D1E) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0),
            width: 0.8,
          ),
        ),
        child: imageBody,
      ),
    );

    if (widget.onTap != null && !_hasError) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: content,
      );
    }
    return content;
  }

  Widget _errorPlaceholder(double width, bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isNetwork
          ? () async {
              await SnapsDiskImageCache.instance.evict(widget.imageUrl);
              if (!mounted) return;
              setState(() {
                _localFile = null;
                _hasError = false;
                _retryCount++;
              });
              _initImage();
            }
          : null,
      child: Container(
        width: width,
        height: widget.height,
        color: isDark ? const Color(0xFF1E2021) : const Color(0xFFF1F5F9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isNetwork ? Icons.refresh_rounded : Icons.image_outlined,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                size: 32.0,
              ),
              if (_isNetwork) ...[
                const SizedBox(height: 6.0),
                Text(
                  'Ketuk untuk muat ulang',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
