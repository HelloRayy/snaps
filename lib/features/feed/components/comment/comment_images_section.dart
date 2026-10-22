import 'package:flutter/material.dart';
import 'package:snapan_market/features/feed/components/post_card/adaptive_carousel_card.dart';
import 'package:snapan_market/features/feed/components/post_card/dynamic_feed_image.dart';

/// Preview section for attached images in a comment with dynamic aspect ratio parity to the home feed.
class CommentImagesSection extends StatefulWidget {
  final List<String> images;
  final void Function(List<String> images, int index)? onImageClick;

  const CommentImagesSection({
    super.key,
    required this.images,
    this.onImageClick,
  });

  @override
  State<CommentImagesSection> createState() => _CommentImagesSectionState();
}

class _CommentImagesSectionState extends State<CommentImagesSection> {
  static const double _commentCarouselHeight = 170.0;
  static const double _carouselGap = 6.0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    // 1. Single Image Display (Dynamic Aspect Ratio up to 4:5, max height 360)
    if (widget.images.length == 1) {
      return DynamicFeedImage(
        imageUrl: widget.images.first,
        maxHeight: 360.0,
        borderRadius: 14.0,
        onTap: () => widget.onImageClick?.call(widget.images, 0),
      );
    }

    // 2. Multi-Image Display (2+ photos) - Threads Dual Strategy: 50-50 Split or Peeking Carousel
    return LayoutBuilder(
      builder: (context, constraints) {
        final isFiniteWidth = constraints.maxWidth.isFinite;
        final availableWidth = isFiniteWidth ? constraints.maxWidth : 0.0;
        final maxCardWidth = (isFiniteWidth && availableWidth > 0)
            ? (availableWidth * 0.82)
            : 260.0;

        // POLA A: Exactly 2 photos, both portrait or square (naturalRatio <= 1.15)
        if (widget.images.length == 2 && availableWidth > 0) {
          final ratio0 = AdaptiveCarouselCard.getCachedRatio(widget.images[0]);
          final ratio1 = AdaptiveCarouselCard.getCachedRatio(widget.images[1]);
          final bool isBothPortraitOrSquare = (ratio0 != null && ratio0 <= 1.15) &&
              (ratio1 != null && ratio1 <= 1.15);

          if (isBothPortraitOrSquare) {
            final halfWidth = (availableWidth - _carouselGap) / 2;

            return SizedBox(
              height: _commentCarouselHeight,
              child: Row(
                children: [
                  Expanded(
                    child: AdaptiveCarouselCard(
                      imageUrl: widget.images[0],
                      height: _commentCarouselHeight,
                      customWidth: halfWidth,
                      borderRadius: 14.0,
                      onTap: () => widget.onImageClick?.call(widget.images, 0),
                      onRatioResolved: (_) {
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: _carouselGap),
                  Expanded(
                    child: AdaptiveCarouselCard(
                      imageUrl: widget.images[1],
                      height: _commentCarouselHeight,
                      customWidth: halfWidth,
                      borderRadius: 14.0,
                      onTap: () => widget.onImageClick?.call(widget.images, 1),
                      onRatioResolved: (_) {
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        }

        // POLA B: 3+ photos, mixed ratios, or while ratios are resolving
        return SizedBox(
          height: _commentCarouselHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(widget.images.length, (idx) {
                final imgUrl = widget.images[idx];
                final isLast = idx == widget.images.length - 1;

                return Padding(
                  padding: EdgeInsets.only(right: isLast ? 0.0 : _carouselGap),
                  child: AdaptiveCarouselCard(
                    imageUrl: imgUrl,
                    height: _commentCarouselHeight,
                    borderRadius: 14.0,
                    minCardWidth: 100.0,
                    maxCardWidth: maxCardWidth,
                    onTap: () => widget.onImageClick?.call(widget.images, idx),
                    onRatioResolved: (_) {
                      if (mounted) setState(() {});
                    },
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
