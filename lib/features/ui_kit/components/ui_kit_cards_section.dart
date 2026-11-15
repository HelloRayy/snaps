import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/components/avatar/default_profile_avatar.dart';
import 'package:snapan_market/core/components/mascot_indicator_badge.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/ui_kit/components/m3_component_spec_card.dart';

/// Interactive showcase of Post Cards, Meeting Point Spot Cards, and Modals
class UiKitCardsSection extends StatelessWidget {
  const UiKitCardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // Thread Post Card Preview
        M3ComponentSpecCard(
          title: 'Feed Post Card (Threads Inspired Layout)',
          description:
              'Struktur kartu utama linimasa Snaps: Avatar kiri dengan connecting thread visual, info siswa, badge NIS/Maskot, isi teks, dan bar aksi.',
          preview: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DefaultProfileAvatar(size: 40.0),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Alya Putri DKV',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.0,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              const MascotIndicatorBadge(size: 16.0),
                              const Spacer(),
                              Text(
                                '15m',
                                style: TextStyle(fontSize: 12.0, color: textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            '@alyaputri • XII DKV 2',
                            style: TextStyle(fontSize: 11.5, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                Text(
                  'Siap terima pesanan totebag canvas sablon custom hasil praktik unit produksi DKV! Minat COD bisa di Gazebo Depan ya ✨',
                  style: TextStyle(fontSize: 13.5, height: 1.45, color: textPrimary),
                ),
                const SizedBox(height: 14.0),
                Row(
                  children: [
                    _IconMetric(icon: Icons.favorite_border, count: '32'),
                    const SizedBox(width: 20.0),
                    _IconMetric(icon: Icons.chat_bubble_outline, count: '8'),
                    const SizedBox(width: 20.0),
                    _IconMetric(icon: Icons.repeat, count: '4'),
                    const Spacer(),
                    _IconMetric(icon: Icons.share_outlined, count: ''),
                  ],
                ),
              ],
            ),
          ),
          specDetails: Text(
            'Desain thread card mengadopsi spacing vertikal compact 12dp antar elemen, font size judul 14.0dp (w700), dan avatar 40dp.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),

        // COD Spot Card Preview
        M3ComponentSpecCard(
          title: 'COD Campus Spot Meeting Card',
          description:
              'Kartu lokasi titik temu serah terima barang di lingkungan SMKN 8 Semarang dengan label zona denah.',
          preview: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPastel,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gazebo Depan Bengkel PPLG',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3.0),
                      Text(
                        'Zona Aman COD • Terbuka & Ramai saat Jam Istirahat',
                        style: TextStyle(fontSize: 11.5, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IconMetric extends StatelessWidget {
  final IconData icon;
  final String count;

  const _IconMetric({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white70 : const Color(0xFF64748B);

    return InkWell(
      onTap: () => HapticFeedback.lightImpact(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18.0, color: color),
          if (count.isNotEmpty) ...[
            const SizedBox(width: 5.0),
            Text(
              count,
              style: TextStyle(fontSize: 12.0, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}
