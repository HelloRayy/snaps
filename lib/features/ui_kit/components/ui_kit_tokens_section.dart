import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/ui_kit/components/m3_component_spec_card.dart';

/// Interactive showcase of Snaps color tokens and typography scale
class UiKitTokensSection extends StatelessWidget {
  const UiKitTokensSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // Color Tokens Spec Card
        M3ComponentSpecCard(
          title: 'Color System & Design Tokens',
          description:
              'Token warna resmi Snaps Mobile dengan Electric Indigo sebagai identitas utama dan Meta Threads Dark/Light theme.',
          sourcePath: 'lib/core/theme/app_colors.dart',
          preview: Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.center,
            children: const [
              _ColorSwatch(
                name: 'Primary (Brand)',
                color: AppColors.primary,
                hex: '#3D38F5',
              ),
              _ColorSwatch(
                name: 'Primary Dark',
                color: AppColors.primaryDark,
                hex: '#312BD9',
              ),
              _ColorSwatch(
                name: 'Pastel Indigo',
                color: AppColors.primaryPastel,
                hex: '#EEF0FF',
                isDarkText: true,
              ),
              _ColorSwatch(
                name: 'Success Emerald',
                color: AppColors.success,
                hex: '#10B981',
              ),
              _ColorSwatch(
                name: 'Warning Amber',
                color: AppColors.warning,
                hex: '#F59E0B',
              ),
              _ColorSwatch(
                name: 'Error Rose',
                color: AppColors.error,
                hex: '#EF4444',
              ),
              _ColorSwatch(
                name: 'Ink (Light Text)',
                color: AppColors.ink,
                hex: '#1A1A1A',
              ),
              _ColorSwatch(
                name: 'Dark Canvas',
                color: AppColors.darkCanvas,
                hex: '#000000',
              ),
              _ColorSwatch(
                name: 'Dark Surface',
                color: AppColors.darkSurface,
                hex: '#161717',
              ),
              _ColorSwatch(
                name: 'Dark Elevated',
                color: AppColors.darkSurfaceElevated,
                hex: '#1D1F1F',
              ),
            ],
          ),
          specDetails: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Accessibility & Standards:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '- Electric Indigo (#3D38F5) telah diaudit memenuhi WCAG AA rasio kontras 6.86:1.\n'
                '- Dark Mode mematuhi Barcelona WDS: Pure OLED Black #000000 dengan elevated charcoal surface #161717.\n'
                '- Tap swatch untuk menyalin kode hex secara instan.',
                style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
              ),
            ],
          ),
        ),

        // Typography Scale Spec Card
        M3ComponentSpecCard(
          title: 'Typography Scale',
          description:
              'Hirarki tipografi SFPro & Inter yang digunakan untuk judul, teks isi feed, harga tabular, dan label mikro.',
          sourcePath: 'lib/core/theme/snaps_theme.dart',
          preview: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TypeScaleRow(
                role: 'Display / Large Title',
                spec: '24px • Bold (w700)',
                sample: 'Snaps Market SMKN 8',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const Divider(height: 24.0),
              _TypeScaleRow(
                role: 'Title Medium (AppBar / Card)',
                spec: '17px • Bold (w700)',
                sample: 'Timeline Diskusi Siswa',
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const Divider(height: 24.0),
              _TypeScaleRow(
                role: 'Body Regular (Feed Post Content)',
                spec: '14.5px • Regular (w400)',
                sample:
                    'Ada yang punya modul DKV semester 2 nggak? Mau beli preloved nih buat referensi tugas.',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: textPrimary,
                ),
              ),
              const Divider(height: 24.0),
              _TypeScaleRow(
                role: 'Tabular Price (Marketplace)',
                spec: '16px • SemiBold (w600) • Tabular figures',
                sample: 'Rp 45.000',
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Divider(height: 24.0),
              _TypeScaleRow(
                role: 'Label / Timestamp / Tag',
                spec: '12px • Medium (w500)',
                sample: '2j lalu • Lab Komputer PPLG 1',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ],
          ),
          specDetails: Text(
            'Gunakan fontFeatures: [FontFeature.tabularFigures()] pada seluruh angka nominal harga agar lebar karakter konstan saat animasi counter atau scrolling.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;
  final String hex;
  final bool isDarkText;

  const _ColorSwatch({
    required this.name,
    required this.color,
    required this.hex,
    this.isDarkText = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Clipboard.setData(ClipboardData(text: hex));
        SnapsToast.show(context, 'Hex $hex berhasil disalin!');
      },
      child: Column(
        children: [
          Container(
            width: 72.0,
            height: 52.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 8.0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            hex,
            style: const TextStyle(
              fontSize: 9.5,
              fontFamily: 'monospace',
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeScaleRow extends StatelessWidget {
  final String role;
  final String spec;
  final String sample;
  final TextStyle style;

  const _TypeScaleRow({
    required this.role,
    required this.spec,
    required this.sample,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              role,
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              spec,
              style: const TextStyle(
                fontSize: 10.5,
                fontFamily: 'monospace',
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(sample, style: style),
      ],
    );
  }
}
