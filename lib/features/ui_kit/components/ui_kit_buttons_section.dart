import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/kumo_button.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/ui_kit/components/m3_component_spec_card.dart';

/// Interactive showcase of buttons and action controls in Snaps Mobile
class UiKitButtonsSection extends StatefulWidget {
  const UiKitButtonsSection({super.key});

  @override
  State<UiKitButtonsSection> createState() => _UiKitButtonsSectionState();
}

class _UiKitButtonsSectionState extends State<UiKitButtonsSection> {
  bool _isLoading = false;

  void _triggerSimulateLoading() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      children: [
        // KumoButton Variants Spec Card
        M3ComponentSpecCard(
          title: 'KumoButton (Bot Start Button Spec)',
          description:
              'Tombol utama Snaps dengan bentuk Full Pill Capsule (cornerRadius 100), specular sheen highlight, dan diffuse elevation.',
          sourcePath: 'lib/core/components/kumo_button.dart',
          preview: Column(
            children: [
              KumoButton.primary(
                text: 'KumoButton Primary',
                onPressed: () {
                  SnapsToast.show(context, 'Primary Button Ditekan!');
                },
              ),
              const SizedBox(height: 12.0),
              KumoButton.secondary(
                text: 'KumoButton Secondary',
                onPressed: () {
                  SnapsToast.show(context, 'Secondary Button Ditekan!');
                },
              ),
              const SizedBox(height: 12.0),
              KumoButton.black(
                text: 'KumoButton Black / Obsidian',
                onPressed: () {
                  SnapsToast.show(context, 'Black Button Ditekan!');
                },
              ),
              const SizedBox(height: 12.0),
              KumoButton.outline(
                text: 'KumoButton Outline',
                onPressed: () {
                  SnapsToast.show(context, 'Outline Button Ditekan!');
                },
              ),
              const SizedBox(height: 12.0),
              KumoButton.primary(
                text: 'Loading State Simulation',
                isLoading: _isLoading,
                onPressed: _triggerSimulateLoading,
              ),
            ],
          ),
          specDetails: Text(
            'Tinggi default 52.0dp, hit target minimum 44dp, dilengkapi mikro-interaksi scale down (0.97) saat ditekan dan haptic feedback ringan.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),

        // Compact Icon Buttons & Chips Spec Card
        M3ComponentSpecCard(
          title: 'Pill Chips & Filter Action Buttons',
          description:
              'Chip pill untuk seleksi filter kategori, toggle tab timeline, dan tombol aksi ringkas.',
          preview: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: [
              _SampleChip(label: 'Semua', isSelected: true),
              _SampleChip(label: 'PPLG', isSelected: false),
              _SampleChip(label: 'DKV', isSelected: false),
              _SampleChip(label: 'Kuliner', isSelected: false),
              _SampleChip(label: 'Preloved', isSelected: false),
            ],
          ),
          specDetails: Text(
            'Padding 12px horizontal, 6px vertical. Border radius 100dp. Aktif menggunakan background AppColors.primary / AppColors.primaryPastel.',
            style: TextStyle(fontSize: 11.5, height: 1.45, color: textMuted),
          ),
        ),
      ],
    );
  }
}

class _SampleChip extends StatefulWidget {
  final String label;
  final bool isSelected;

  const _SampleChip({required this.label, required this.isSelected});

  @override
  State<_SampleChip> createState() => _SampleChipState();
}

class _SampleChipState extends State<_SampleChip> {
  late bool _selected = widget.isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionChip(
      label: Text(
        widget.label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: _selected ? FontWeight.w600 : FontWeight.w500,
          color: _selected
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF334155)),
        ),
      ),
      backgroundColor: _selected
          ? AppColors.primary
          : (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(100.0),
        side: BorderSide(
          color: _selected ? AppColors.primary : Colors.transparent,
          width: 1.0,
        ),
      ),
      onPressed: () {
        setState(() => _selected = !_selected);
      },
    );
  }
}
