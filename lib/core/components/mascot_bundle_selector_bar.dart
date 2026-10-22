import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/components/mascot_flair_badge.dart';
import 'package:snapan_market/core/components/mascot_gallery_bottom_sheet.dart';
import 'package:snapan_market/core/models/mascot_flair_model.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Horizontal lazy-scrollable mascot bundle selector bar.
/// Prevents layout overflows by virtualizing the bundle list across screens
/// and provides an affordance trigger to open the 21-mascot grid gallery.
class MascotBundleSelectorBar extends StatefulWidget {
  final MascotBundle selectedBundle;
  final ValueChanged<MascotBundle> onBundleSelected;
  final bool compact;
  final VoidCallback? onOpenGallery;

  const MascotBundleSelectorBar({
    super.key,
    required this.selectedBundle,
    required this.onBundleSelected,
    this.compact = false,
    this.onOpenGallery,
  });

  @override
  State<MascotBundleSelectorBar> createState() => _MascotBundleSelectorBarState();
}

class _MascotBundleSelectorBarState extends State<MascotBundleSelectorBar> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToSelected(animate: false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MascotBundleSelectorBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBundle != widget.selectedBundle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToSelected(animate: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected({required bool animate}) {
    if (!_scrollController.hasClients) return;
    final index = MascotBundle.values.indexOf(widget.selectedBundle);
    if (index < 0) return;

    final itemWidth = widget.compact ? 42.0 : 100.0;
    final viewportWidth = _scrollController.position.viewportDimension;
    final targetOffset = (index * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  void _handleOpenGallery() {
    HapticFeedback.lightImpact();
    if (widget.onOpenGallery != null) {
      widget.onOpenGallery!();
    } else {
      MascotGalleryBottomSheet.show(
        context,
        selectedBundle: widget.selectedBundle,
        onSelected: widget.onBundleSelected,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = widget.compact ? 34.0 : 40.0;
    final iconSize = widget.compact ? 19.0 : 22.0;

    return Container(
      height: height,
      padding: EdgeInsets.all(widget.compact ? 2.5 : 3.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(widget.compact ? 9.0 : 10.0),
      ),
      child: Row(
        children: [
          // Scrollable Virtualized Bundle List with Fade Edge Indicators
          Expanded(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.03, 0.97, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: MascotBundle.values.length,
                itemBuilder: (context, index) {
                  final bundle = MascotBundle.values[index];
                  final isSelected = widget.selectedBundle == bundle;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onBundleSelected(bundle);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.compact ? 10.0 : 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? AppColors.darkSurface : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(widget.compact ? 7.0 : 8.0),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0x0E000000),
                                  blurRadius: widget.compact ? 3.0 : 4.0,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: widget.compact
                          ? MascotFlairBadge(
                              flair: MascotFlairModel(
                                bundle: bundle,
                                emotion: MascotEmotion.delighted,
                              ),
                              size: iconSize,
                              enableGradientFade: false,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MascotFlairBadge(
                                  flair: MascotFlairModel(
                                    bundle: bundle,
                                    emotion: MascotEmotion.delighted,
                                  ),
                                  size: iconSize,
                                  enableGradientFade: false,
                                ),
                                const SizedBox(width: 6.0),
                                Text(
                                  bundle.label,
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? (isDark ? AppColors.darkTextPrimary : AppColors.primary)
                                        : (isDark
                                            ? AppColors.darkTextSecondary
                                            : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Divider
          Container(
            width: 1.0,
            height: widget.compact ? 16.0 : 20.0,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
          ),

          // Quick Catalog Grid Trigger
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleOpenGallery,
              borderRadius: BorderRadius.circular(widget.compact ? 6.0 : 8.0),
              splashColor: AppColors.primary.withValues(alpha: 0.12),
              highlightColor: AppColors.primary.withValues(alpha: 0.06),
              child: Tooltip(
                message: 'Semua Maskot (${MascotBundle.values.length})',
                child: Container(
                  width: widget.compact ? 28.0 : 32.0,
                  height: widget.compact ? 28.0 : 32.0,
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.layoutGrid,
                    size: widget.compact ? 15.0 : 17.0,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
