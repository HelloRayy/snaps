import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/avatar/default_profile_avatar.dart';
import 'package:snapan_market/core/components/mascot_indicator_badge.dart';
import 'package:snapan_market/core/components/snaps_logo.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/ui_kit/components/m3_component_spec_card.dart';

/// Interactive showcase of Brand Logo, Student Avatars, and Mascot Badges
class UiKitAvatarsSection extends StatelessWidget {
  const UiKitAvatarsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // Snaps Vector Logo Spec Card
        M3ComponentSpecCard(
          title: 'Snaps Vector Logo (Official Brandmark)',
          description:
              'Asset SVG resmi Snaps dengan adaptasi otomatis warna kontras terhadap Dark / Light Mode.',
          sourcePath: 'lib/core/components/snaps_logo.dart',
          preview: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              SnapsLogo(height: 24.0),
              SnapsLogo(height: 32.0),
              SnapsLogo(height: 40.0),
            ],
          ),
          specDetails: Text(
            'Assets path: assets/logo/snaps-logo-clean.svg. Menggunakan ColorFilter dinamis agar tetap putih tajam di dark mode dan hitam/asli di light canvas.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),

        // Universal AppAvatar & Default Fallbacks
        M3ComponentSpecCard(
          title: 'AppAvatar & Fallbacks',
          description:
              'Avatar profil siswa multi-resolusi dengan inisial fallback dan siluet standar Threads saat tidak ada foto.',
          sourcePath: 'lib/core/components/avatar/default_profile_avatar.dart',
          preview: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              DefaultProfileAvatar(size: 36.0),
              DefaultProfileAvatar(size: 48.0),
              DefaultProfileAvatar(size: 64.0),
              AppAvatar(
                size: 48.0,
                name: 'Raditya Rayhan',
                username: 'radityaray',
              ),
            ],
          ),
          specDetails: Text(
            'Ukuran standar: 36dp (Komentar/List), 48dp (Feed Post Card), 72dp (Halaman Profil Siswa). Background: #E2E8F0 (Light) / #1D1F1F (Dark).',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),

        // Mascot Badges & Micro-Flair
        M3ComponentSpecCard(
          title: 'Mascot Flair & Verification Badges',
          description:
              'Badge micro-indicator maskot Koala SMKN 8 Semarang dan icon verified akun resmi.',
          sourcePath: 'lib/core/components/mascot_indicator_badge.dart',
          preview: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const MascotIndicatorBadge(size: 24.0),
              const MascotIndicatorBadge(size: 32.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryPastel,
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.verified, size: 16.0, color: AppColors.primary),
                    SizedBox(width: 4.0),
                    Text(
                      'Siswa SMKN 8 Terverifikasi',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          specDetails: Text(
            'Menandakan keaslian status siswa SMKN 8 berdasarkan NIS terdaftar dan kepemilikan flair maskot.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),
      ],
    );
  }
}
