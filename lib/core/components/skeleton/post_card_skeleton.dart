import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/skeleton/snaps_shimmer.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Refined Post Card Skeleton (SNAPS-96):
/// 1 Circle avatar + 3 graded text rectangles without bulky image placeholders
/// to guarantee fast, fluid frame-rates on entry-level student devices.
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFF1F3F5),
            width: 0.8,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1 Circle: Author Avatar Placeholder (48x48)
          SnapsSkeletonBox.circle(size: 48.0),
          SizedBox(width: 14.0),

          // 2 Pill Rectangles: Text Placeholders matching user reference
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top line: long rounded pill (~80% width)
                FractionallySizedBox(
                  widthFactor: 0.82,
                  child: SnapsSkeletonBox(
                    width: double.infinity,
                    height: 12.0,
                    borderRadius: 100.0,
                  ),
                ),
                SizedBox(height: 10.0),

                // Bottom line: shorter rounded pill (~55% width)
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: SnapsSkeletonBox(
                    width: double.infinity,
                    height: 12.0,
                    borderRadius: 100.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Feed Timeline Skeleton containing multiple PostCardSkeletons on a solid canvas
class FeedTimelineSkeleton extends StatelessWidget {
  final int itemCount;

  const FeedTimelineSkeleton({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.adaptiveCanvas(context),
      child: SnapsShimmer(
        child: Column(
          children: List.generate(
            itemCount,
            (index) => const PostCardSkeleton(),
          ),
        ),
      ),
    );
  }
}
