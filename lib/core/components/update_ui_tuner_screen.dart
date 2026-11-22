import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Standalone preview & HUD tuner for iterating the In-App Update UI locally
/// without triggering an actual OTA release.
class UpdateUiTunerScreen extends StatefulWidget {
  const UpdateUiTunerScreen({super.key});

  @override
  State<UpdateUiTunerScreen> createState() => _UpdateUiTunerScreenState();
}

class _UpdateUiTunerScreenState extends State<UpdateUiTunerScreen> {
  double _horizontalPadding = 24.0;
  double _verticalPadding = 24.0;
  double _borderRadius = 24.0;
  double _sectionSpacing = 16.0;
  double _titleFontSize = 22.0;
  bool _isMandatory = false;
  bool _showHud = true;

  void _copyConfigForAi() {
    final configText = '''
Update UI Config (hasil tuning HUD):
- horizontalPadding: ${_horizontalPadding.toStringAsFixed(1)}
- verticalPadding: ${_verticalPadding.toStringAsFixed(1)}
- borderRadius: ${_borderRadius.toStringAsFixed(1)}
- sectionSpacing: ${_sectionSpacing.toStringAsFixed(1)}
- titleFontSize: ${_titleFontSize.toStringAsFixed(1)}
- isMandatory: $_isMandatory
Terapkan nilai ini ke UI In-App Update.
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
    final cardBg = isDark ? AppColors.darkSurfaceElevated : Colors.white;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.ink;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.muted;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('In-App Update UI Preview'),
        actions: [
          IconButton(
            tooltip: _showHud ? 'Sembunyikan HUD' : 'Tampilkan HUD',
            icon: Icon(_showHud ? LucideIcons.eyeOff : LucideIcons.slidersHorizontal),
            onPressed: () => setState(() => _showHud = !_showHud),
          ),
          IconButton(
            tooltip: 'Copy Config untuk AI Agent',
            icon: const Icon(LucideIcons.copy),
            onPressed: _copyConfigForAi,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: _horizontalPadding,
                  vertical: _verticalPadding,
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: _horizontalPadding,
                    vertical: _verticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(_borderRadius),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'v1.0.18 • Pembaruan Tersedia',
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
                        style: TextStyle(
                          fontSize: _titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: _sectionSpacing * 0.5),
                      Text(
                        '• Perbaikan ganti & hapus foto profil\n'
                        '• Auto-sync avatar di feed tanpa refresh\n'
                        '• Loading gambar lebih cepat & hemat kuota\n'
                        '• Aksi balas, edit, dan hapus pesan DM',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: mutedColor,
                        ),
                      ),
                      SizedBox(height: _sectionSpacing * 1.25),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(_borderRadius * 0.55),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                          },
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
              ),
            ),
          ),
          if (_showHud)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSlider('H-Pad', _horizontalPadding, 12, 36, (v) => setState(() => _horizontalPadding = v)),
                    _buildSlider('V-Pad', _verticalPadding, 12, 36, (v) => setState(() => _verticalPadding = v)),
                    _buildSlider('Radius', _borderRadius, 8, 32, (v) => setState(() => _borderRadius = v)),
                    _buildSlider('Spacing', _sectionSpacing, 8, 28, (v) => setState(() => _sectionSpacing = v)),
                    _buildSlider('Title', _titleFontSize, 18, 28, (v) => setState(() => _titleFontSize = v)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mandatory Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Switch.adaptive(
                          value: _isMandatory,
                          onChanged: (v) => setState(() => _isMandatory = v),
                        ),
                      ],
                    ),
                  ],
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
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            '$label ${value.toInt()}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
    );
  }
}
