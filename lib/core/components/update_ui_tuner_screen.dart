import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/components/snaps_logo.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Full-screen standalone In-App Update UI with a floating HUD tuner overlay
/// so you can iterate padding/spacing/radius live and copy values for AI.
class UpdateUiTunerScreen extends StatefulWidget {
  const UpdateUiTunerScreen({super.key});

  @override
  State<UpdateUiTunerScreen> createState() => _UpdateUiTunerScreenState();
}

class _UpdateUiTunerScreenState extends State<UpdateUiTunerScreen> {
  double _horizontalPadding = 24.8;
  double _verticalPadding = 32.9;
  double _borderRadius = 8.0;
  double _sectionSpacing = 16.4;
  double _titleFontSize = 24.4;
  bool _isMandatory = true;
  bool _hudExpanded = false;

  void _copyConfigForAi() {
    final configText = '''
Update UI Config (hasil tuning HUD):
- horizontalPadding: ${_horizontalPadding.toStringAsFixed(1)}
- verticalPadding: ${_verticalPadding.toStringAsFixed(1)}
- borderRadius: ${_borderRadius.toStringAsFixed(1)}
- sectionSpacing: ${_sectionSpacing.toStringAsFixed(1)}
- titleFontSize: ${_titleFontSize.toStringAsFixed(1)}
- isMandatory: $_isMandatory
Terapkan nilai ini ke UI In-App Update standalone screen.
''';
    Clipboard.setData(ClipboardData(text: configText.trim()));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Config HUD disalin! Tinggal paste ke AI Agent.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final hudBg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFF0F172A);
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Full-screen Standalone In-App Update UI
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: _horizontalPadding,
                      vertical: _verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        const SnapsLogo(height: 56.0),
                        SizedBox(height: _sectionSpacing * 1.25),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'v1.0.18 • Pembaruan Resmi',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: _sectionSpacing),
                        Text(
                          'Pembaruan Snaps v1.0.18',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: _titleFontSize,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.4,
                          ),
                        ),
                        SizedBox(height: _sectionSpacing * 0.6),
                        Text(
                          'Kami telah menyiapkan pembaruan penting untuk meningkatkan stabilitas, kecepatan, dan keamanan aplikasi Snaps:\n\n'
                          '• Perbaikan ganti & hapus foto profil\n'
                          '• Auto-sync avatar di feed tanpa refresh\n'
                          '• Loading gambar lebih cepat & hemat kuota\n'
                          '• Aksi balas, edit, dan hapus pesan DM',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    _horizontalPadding,
                    12,
                    _horizontalPadding,
                    _verticalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_borderRadius),
                            ),
                          ),
                          onPressed: () => HapticFeedback.lightImpact(),
                          child: const Text(
                            'Perbarui Sekarang',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ),
                      if (!_isMandatory) ...[
                        SizedBox(height: _sectionSpacing * 0.5),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Nanti Saja',
                              style: TextStyle(color: mutedColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Floating HUD Tuner Overlay
          Positioned(
            right: 12,
            bottom: 16,
            left: _hudExpanded ? 12 : null,
            child: SafeArea(
              child: Material(
                color: hudBg.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(16),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: _hudExpanded
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'HUD Tuner',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(LucideIcons.copy, size: 16, color: Colors.white),
                                      tooltip: 'Copy AI Config',
                                      onPressed: _copyConfigForAi,
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(LucideIcons.chevronDown, size: 18, color: Colors.white),
                                      onPressed: () => setState(() => _hudExpanded = false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            _buildSlider('H-Pad', _horizontalPadding, 12, 36, (v) => setState(() => _horizontalPadding = v)),
                            _buildSlider('V-Pad', _verticalPadding, 12, 36, (v) => setState(() => _verticalPadding = v)),
                            _buildSlider('Radius', _borderRadius, 8, 28, (v) => setState(() => _borderRadius = v)),
                            _buildSlider('Space', _sectionSpacing, 8, 28, (v) => setState(() => _sectionSpacing = v)),
                            _buildSlider('Title', _titleFontSize, 18, 30, (v) => setState(() => _titleFontSize = v)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Mandatory', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                Switch.adaptive(
                                  value: _isMandatory,
                                  onChanged: (v) => setState(() => _isMandatory = v),
                                ),
                              ],
                            ),
                          ],
                        )
                      : InkWell(
                          onTap: () => setState(() => _hudExpanded = true),
                          borderRadius: BorderRadius.circular(16),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.slidersHorizontal, size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'HUD',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '$label ${value.toInt()}',
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
