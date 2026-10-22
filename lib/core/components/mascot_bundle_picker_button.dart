import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/components/mascot_flair_badge.dart';
import 'package:snapan_market/core/components/mascot_gallery_bottom_sheet.dart';
import 'package:snapan_market/core/models/mascot_flair_model.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Interactive button displaying active mascot and opening the 21-mascot bottom sheet.
/// Eliminates horizontal scroll gestures for immediate and accessible navigation.
class MascotBundlePickerButton extends StatelessWidget {
  final MascotBundle selectedBundle;
  final ValueChanged<MascotBundle> onBundleSelected;
  final bool compact;
  final VoidCallback? onOpenGallery;

  const MascotBundlePickerButton({
    super.key,
    required this.selectedBundle,
    required this.onBundleSelected,
    this.compact = false,
    this.onOpenGallery,
  });

  void _handleTap(BuildContext context) {
    HapticFeedback.lightImpact();
    if (onOpenGallery != null) {
      onOpenGallery!();
    } else {
      MascotGalleryBottomSheet.show(
        context,
        selectedBundle: selectedBundle,
        onSelected: onBundleSelected,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(10.0),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: Container(
            height: 38.0,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Row(
              children: [
                MascotFlairBadge(
                  flair: MascotFlairModel(
                    bundle: selectedBundle,
                    emotion: MascotEmotion.delighted,
                  ),
                  size: 24.0,
                  enableGradientFade: false,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    selectedBundle.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimaryPastel : const Color(0xFFEEF0FF),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.layoutGrid,
                        size: 13.0,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        'Ganti',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Full-width non-compact tile for Edit Profile
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(14.0),
        splashColor: AppColors.primary.withValues(alpha: 0.12),
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              MascotFlairBadge(
                flair: MascotFlairModel(
                  bundle: selectedBundle,
                  emotion: MascotEmotion.delighted,
                ),
                size: 32.0,
                enableGradientFade: false,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedBundle.label,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Pilih dari ${MascotBundle.values.length} karakter maskot',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimaryPastel : const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.layoutGrid,
                      size: 14.0,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      'Katalog',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
