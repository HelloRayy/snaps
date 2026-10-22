import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/components/mascot_flair_badge.dart';
import 'package:snapan_market/core/models/mascot_flair_model.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Modal bottom sheet showcasing all 21 mascot bundles in a responsive 4-column grid.
/// Supports real-time search filtering by animal name.
class MascotGalleryBottomSheet extends StatefulWidget {
  final MascotBundle selectedBundle;
  final ValueChanged<MascotBundle> onSelected;

  const MascotGalleryBottomSheet({
    super.key,
    required this.selectedBundle,
    required this.onSelected,
  });

  /// Displays the mascot catalog modal bottom sheet.
  static Future<MascotBundle?> show(
    BuildContext context, {
    required MascotBundle selectedBundle,
    required ValueChanged<MascotBundle> onSelected,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<MascotBundle>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MascotGalleryBottomSheet(
        selectedBundle: selectedBundle,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<MascotGalleryBottomSheet> createState() => _MascotGalleryBottomSheetState();
}

class _MascotGalleryBottomSheetState extends State<MascotGalleryBottomSheet> {
  late MascotBundle _currentSelected;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.selectedBundle;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
    }
  }

  List<MascotBundle> get _filteredBundles {
    if (_searchQuery.isEmpty) return MascotBundle.values;
    return MascotBundle.values.where((b) {
      return b.label.toLowerCase().contains(_searchQuery) ||
          b.name.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final sheetHeight = (mediaQuery.size.height * 0.75).clamp(380.0, 580.0);

    return Container(
      height: sheetHeight + bottomInset,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 24.0,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 38.0,
                height: 4.5,
                margin: const EdgeInsets.only(top: 10.0, bottom: 8.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: Row(
                children: [
                  Text(
                    'Katalog Maskot Snaps',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimaryPastel : const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkPrimary.withValues(alpha: 0.35)
                            : AppColors.primary.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '${MascotBundle.values.length} Mascot',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.x,
                      size: 20.0,
                      color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32.0, minHeight: 32.0),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
            ),

            // Real-time Search Filter Bar
            Container(
              height: 40.0,
              margin: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 12.0),
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(11.0),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.search,
                    size: 16.0,
                    color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari nama maskot (cth: cat, dino, koala)...',
                        hintStyle: TextStyle(
                          fontSize: 13.0,
                          color: isDark ? AppColors.darkTextDisabled : const Color(0xFF94A3B8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _searchController.clear();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Icon(
                          LucideIcons.circleX,
                          size: 16.0,
                          color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 4-Column Virtualized Grid or Empty State
            Expanded(
              child: _filteredBundles.isEmpty
                  ? _buildEmptyState(isDark)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16.0, 2.0, 16.0, 20.0),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio: 0.86,
                      ),
                      itemCount: _filteredBundles.length,
                      itemBuilder: (context, index) {
                        final bundle = _filteredBundles[index];
                        final isSelected = _currentSelected == bundle;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _currentSelected = bundle);
                              widget.onSelected(bundle);
                              Navigator.of(context).pop(bundle);
                            },
                            borderRadius: BorderRadius.circular(12.0),
                            splashColor: AppColors.primary.withValues(alpha: 0.12),
                            highlightColor: AppColors.primary.withValues(alpha: 0.06),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark ? AppColors.darkPrimaryPastel : const Color(0xFFEEF0FF))
                                    : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.16),
                                          blurRadius: 6.0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      MascotFlairBadge(
                                        flair: MascotFlairModel(
                                          bundle: bundle,
                                          emotion: MascotEmotion.delighted,
                                        ),
                                        size: 38.0,
                                        enableGradientFade: false,
                                      ),
                                      const SizedBox(height: 5.0),
                                      Text(
                                        bundle.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark
                                                  ? AppColors.darkTextPrimary
                                                  : const Color(0xFF1E293B)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 0.0,
                                      right: 0.0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2.0),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.check,
                                          size: 10.0,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.search,
            size: 36.0,
            color: isDark ? AppColors.darkTextDisabled : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10.0),
          Text(
            'Maskot tidak ditemukan',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            'Coba cari dengan kata kunci maskot lain',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
