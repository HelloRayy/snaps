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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1 Circle: Author Avatar Placeholder (40x40)
          SnapsSkeletonBox.circle(size: 40.0),
          SizedBox(width: 12.0),

          // 3 Rectangles: Graded Text Placeholders
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rectangle 1: Name & Badge line (~35% width, 12dp height)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SnapsSkeletonBox(width: 110.0, height: 12.0, borderRadius: 4.0),
                    SnapsSkeletonBox(width: 32.0, height: 11.0, borderRadius: 4.0),
                  ],
                ),
                SizedBox(height: 10.0),

                // Rectangle 2: Primary Content Line (~85% width, 14dp height)
                SnapsSkeletonBox(width: double.infinity, height: 14.0, borderRadius: 4.0),
                SizedBox(height: 8.0),

                // Rectangle 3: Secondary Subtext Line (~60% width, 12dp height)
                FractionallySizedBox(
                  widthFactor: 0.65,
                  child: SnapsSkeletonBox(width: double.infinity, height: 12.0, borderRadius: 4.0),
                ),
                SizedBox(height: 14.0),

                // Compact Micro-Action Bar
                Row(
                  children: [
                    SnapsSkeletonBox(width: 36.0, height: 14.0, borderRadius: 4.0),
                    SizedBox(width: 20.0),
                    SnapsSkeletonBox(width: 36.0, height: 14.0, borderRadius: 4.0),
                    SizedBox(width: 20.0),
                    SnapsSkeletonBox(width: 30.0, height: 14.0, borderRadius: 4.0),
                  ],
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
