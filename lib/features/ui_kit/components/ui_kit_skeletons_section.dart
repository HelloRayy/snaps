import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/skeleton/activity_skeleton.dart';
import 'package:snapan_market/core/components/skeleton/comment_skeleton.dart';
import 'package:snapan_market/core/components/skeleton/post_card_skeleton.dart';
import 'package:snapan_market/core/components/skeleton/snaps_shimmer.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/ui_kit/components/m3_component_spec_card.dart';

/// Interactive showcase of Shimmer and Skeleton loading states
class UiKitSkeletonsSection extends StatelessWidget {
  const UiKitSkeletonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // PostCardSkeleton Spec Card
        M3ComponentSpecCard(
          title: 'Post Card Skeleton & Ambient Shimmer',
          description:
              'Placeholder loading animasi sweep gradien alami saat mengambil data feed thread atau produk.',
          sourcePath: 'lib/core/components/skeleton/post_card_skeleton.dart',
          preview: const SizedBox(
            height: 160.0,
            child: SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: PostCardSkeleton(),
            ),
          ),
          specDetails: Text(
            'Menggunakan SnapsShimmer provider berdurasi 1400ms dengan interpolasi warna #F1F3F5 (Base) -> #FFFFFF (Sweep) di light mode, dan #242626 -> #383A3A di dark mode.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),

        // Comment & Activity Skeleton
        M3ComponentSpecCard(
          title: 'Comment & Activity Skeletons',
          description:
              'Skeleton untuk daftar notifikasi/aktivitas siswa dan thread balasan komentar.',
          sourcePath: 'lib/core/components/skeleton/comment_skeleton.dart',
          preview: Column(
            children: const [
              SizedBox(
                height: 70.0,
                child: CommentSkeleton(),
              ),
              Divider(height: 16.0),
              SizedBox(
                height: 70.0,
                child: ActivitySkeleton(),
              ),
            ],
          ),
          specDetails: Text(
            'Radius sudut elemen placeholder adalah 4dp (baris teks), 8dp (thumbnail), dan lingkaran sempurna untuk avatar 36/40dp.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),
      ],
    );
  }
}
