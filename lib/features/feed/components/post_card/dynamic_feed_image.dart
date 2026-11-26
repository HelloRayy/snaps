import 'dart:io';
import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/skeleton/snaps_shimmer.dart';
import 'package:snapan_market/core/services/snaps_disk_image_cache.dart';

/// Renders a feed image with dynamic aspect ratio bounded between
/// [minAspectRatio] and [maxAspectRatio], backed by [SnapsDiskImageCache].
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
  File? _localFile;
  bool _hasError = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _initImage();
  }

  @override
  void didUpdateWidget(covariant DynamicFeedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolvedRatio = _ratioCache[widget.imageUrl];
      _localFile = null;
      _hasError = false;
      _initImage();
    }
  }

  Future<void> _initImage() async {
    _resolvedRatio = _ratioCache[widget.imageUrl];

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
    if (_ratioCache.containsKey(widget.imageUrl)) return;
    if (_listener != null && _imageStream != null) {
      _imageStream?.removeListener(_listener!);
    }
    _imageStream = FileImage(file).resolve(const ImageConfiguration());
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        final w = info.image.width;
        final h = info.image.height;
        if (w > 0 && h > 0) {
          final clampedRatio = (w / h).clamp(
            widget.minAspectRatio,
            widget.maxAspectRatio,
          );
          _ratioCache[widget.imageUrl] = clampedRatio;
          setState(() => _resolvedRatio = clampedRatio);
        }
      },
      onError: (_, _) {},
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

    Widget child;
    if (_hasError) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          await SnapsDiskImageCache.instance.evict(widget.imageUrl);
          if (!mounted) return;
          setState(() {
            _localFile = null;
            _hasError = false;
            _retryCount++;
          });
          _initImage();
        },
        child: Container(
          color: placeholderColor,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  size: 34.0,
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Ketuk untuk muat ulang',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (_localFile != null) {
      child = Image.file(
        _localFile!,
        key: ValueKey('${widget.imageUrl}#$_retryCount'),
        cacheWidth: 800,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: placeholderColor,
          child: Center(
            child: Icon(
              Icons.image_outlined,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 40.0,
            ),
          ),
        ),
      );
    } else {
      child = SnapsShimmer(
        child: Container(
          color: isDark ? const Color(0xFF242626) : const Color(0xFFF1F3F5),
        ),
      );
    }

    return GestureDetector(
      onTap: _hasError ? null : widget.onTap,
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
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
