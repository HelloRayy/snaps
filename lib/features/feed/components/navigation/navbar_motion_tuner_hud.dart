import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

class NavbarMotionConfig {
  final int durationMs;
  final String curveName;
  final double collapsedWidth;

  const NavbarMotionConfig({
    this.durationMs = 425,
    this.curveName = 'fastOutSlowIn',
    this.collapsedWidth = 62.0,
  });

  Curve get curve => switch (curveName) {
        'easeOutQuart' => Curves.easeOutQuart,
        'easeOutBack' => Curves.easeOutBack,
        'fastOutSlowIn' => Curves.fastOutSlowIn,
        _ => Curves.easeOutCubic,
      };

  NavbarMotionConfig copyWith({
    int? durationMs,
    String? curveName,
    double? collapsedWidth,
  }) {
    return NavbarMotionConfig(
      durationMs: durationMs ?? this.durationMs,
      curveName: curveName ?? this.curveName,
      collapsedWidth: collapsedWidth ?? this.collapsedWidth,
    );
  }
}

class NavbarMotionTunerHud extends StatelessWidget {
  final NavbarMotionConfig config;
  final ValueChanged<NavbarMotionConfig> onChanged;
  final VoidCallback onToggleCollapse;
  final VoidCallback onClose;

  const NavbarMotionTunerHud({
    super.key,
    required this.config,
    required this.onChanged,
    required this.onToggleCollapse,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 56,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xEE18181B) : const Color(0xF5FFFFFF),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Motion Tuner HUD',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onToggleCollapse,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(44, 32),
                    ),
                    child: const Text('Test Buka/Tutup', style: TextStyle(fontSize: 12)),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(LucideIcons.x, size: 16),
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Durasi: ${config.durationMs} ms',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Slider(
                value: config.durationMs.toDouble(),
                min: 150,
                max: 800,
                divisions: 26,
                activeColor: AppColors.primary,
                onChanged: (v) => onChanged(config.copyWith(durationMs: v.round())),
              ),
              Wrap(
                spacing: 6,
                children: ['easeOutCubic', 'easeOutQuart', 'easeOutBack', 'fastOutSlowIn']
                    .map((name) {
                  final selected = config.curveName == name;
                  return ChoiceChip(
                    label: Text(name, style: const TextStyle(fontSize: 11)),
                    selected: selected,
                    onSelected: (_) => onChanged(config.copyWith(curveName: name)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
