import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/services/snaps_disk_image_cache.dart';
import 'package:snapan_market/features/feed/models/market_post_model.dart';

class ProfileMediaItem {
  final String imageUrl;
  final MarketPostModel post;

  const ProfileMediaItem({
    required this.imageUrl,
    required this.post,
  });
}

/// 3-Column Vertical 3:4 Aspect Ratio Grid for "Media" Tab matching ProfilePage.tsx
class ProfileMediaGrid extends StatelessWidget {
  final List<ProfileMediaItem> mediaItems;
  final ValueChanged<MarketPostModel>? onMediaTap;

  const ProfileMediaGrid({
    super.key,
    required this.mediaItems,
    this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 36.0,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 10.0),
            Text(
              'Belum ada media',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              'Foto dan media yang diunggah akan muncul di sini.',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF94A3B8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mediaItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 3.0,
          mainAxisSpacing: 3.0,
          childAspectRatio: 1.0,
        ),

        itemBuilder: (context, index) {
          final item = mediaItems[index];
          return GestureDetector(
            onTap: () {
              onMediaTap?.call(item.post);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.0),
              child: Container(
                color: const Color(0xFFF1F5F9),
                child: _CachedGridThumb(imageUrl: item.imageUrl),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CachedGridThumb extends StatefulWidget {
  final String imageUrl;
  const _CachedGridThumb({required this.imageUrl});

  @override
  State<_CachedGridThumb> createState() => _CachedGridThumbState();
}

class _CachedGridThumbState extends State<_CachedGridThumb> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sync = SnapsDiskImageCache.instance.getCachedFileSync(widget.imageUrl);
    if (sync != null) {
      _file = sync;
      return;
    }
    final fetched = await SnapsDiskImageCache.instance.getOrFetch(widget.imageUrl);
    if (mounted && fetched != null) setState(() => _file = fetched);
  }

  @override
  Widget build(BuildContext context) {
    if (_file == null) return const SizedBox.shrink();
    return Image.file(
      _file!,
      cacheWidth: 300,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.image_not_supported_rounded, size: 24.0, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
