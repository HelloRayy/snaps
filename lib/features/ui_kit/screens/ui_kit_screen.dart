import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/snaps_logo.dart';
import 'package:snapan_market/core/services/theme_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/ui_kit/components/ui_kit_avatars_section.dart';
import 'package:snapan_market/features/ui_kit/components/ui_kit_buttons_section.dart';
import 'package:snapan_market/features/ui_kit/components/ui_kit_cards_section.dart';
import 'package:snapan_market/features/ui_kit/components/ui_kit_inputs_section.dart';
import 'package:snapan_market/features/ui_kit/components/ui_kit_skeletons_section.dart';
import 'package:snapan_market/features/ui_kit/components/ui_kit_tokens_section.dart';

/// Snaps Mobile Design System & UI Kit Screen (URL Route: /ui-kit)
/// Formatted like Material 3 Components Catalog with tabs, spec cards,
/// and live component playgrounds for SMKN 8 Semarang student app.
class UiKitScreen extends StatefulWidget {
  const UiKitScreen({super.key});

  @override
  State<UiKitScreen> createState() => _UiKitScreenState();
}

class _UiKitScreenState extends State<UiKitScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<String> _categories = const [
    'Tokens',
    'Buttons',
    'Inputs',
    'Cards',
    'Avatars',
    'Skeletons',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final appBarBg = isDark ? AppColors.darkCanvas : AppColors.canvas;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16.0,
        title: Row(
          children: [
            const SnapsLogo(height: 22.0),
            const SizedBox(width: 10.0),
            Text(
              'UI Kit',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 6.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
              decoration: BoxDecoration(
                color: AppColors.primaryPastel,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: const Text(
                'v1.0',
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Theme Switcher Quick Toggle
          IconButton(
            tooltip: 'Ganti Tema',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: textPrimary,
              size: 20.0,
            ),
            onPressed: () {
              final newMode = isDark ? AppThemeMode.light : AppThemeMode.dark;
              ThemeService.instance.setThemeMode(newMode);
            },
          ),
          const SizedBox(width: 8.0),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelColor: AppColors.primary,
              unselectedLabelColor: textMuted,
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: _categories.map((c) => Tab(text: c)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UiKitTokensSection(),
          UiKitButtonsSection(),
          UiKitInputsSection(),
          UiKitCardsSection(),
          UiKitAvatarsSection(),
          UiKitSkeletonsSection(),
        ],
      ),
    );
  }
}
