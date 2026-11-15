import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/theme/tactile_shadows.dart';
import 'package:snapan_market/features/feed/components/navigation/nav_glyphs/home_nav_glyph.dart';
import 'package:snapan_market/features/feed/components/navigation/nav_glyphs/paper_plane_nav_glyph.dart';
import 'package:snapan_market/features/feed/components/navigation/nav_glyphs/heart_nav_glyph.dart';
import 'package:snapan_market/features/feed/components/navigation/nav_glyphs/user_nav_glyph.dart';

/// Enum representing the 4 main navigation tabs in the Center Bot Bar
enum HomeNavTab {
  home,
  messages,
  activity,
  profile;

  // Backward-compatible aliases
  static const HomeNavTab create = HomeNavTab.home;
  static const HomeNavTab post = HomeNavTab.home;

  String get label {
    switch (this) {
      case HomeNavTab.home:
        return 'Home';
      case HomeNavTab.messages:
        return 'Pesan';
      case HomeNavTab.activity:
        return 'Aktivitas';
      case HomeNavTab.profile:
        return 'Profil';
    }
  }
}

/// Center Bot Bar sliced from user layout sketch & pen.dev spec (`snaps-design.pen` node `HaFs1`)
///
/// Features:
/// - Single centered floating pill dock (`height: 62px, cornerRadius: 296`)
/// - Liquid frosted glass container (`Colors.white.withValues(alpha: 0.85)` + 20px blur)
/// - Diffuse 35px drop shadow from pen.dev (`#0000001f`, y=8)
/// - 4 symmetrical tabs (Home, Pesan, Aktivitas, Profil)
/// - Active selection capsule (`#EDEDED` fill, cornerRadius 100) with `#008BFF` azure icon & label
/// - Inactive tabs in `#1A1A1A` ink typography
class HomeBottomNavBar extends StatelessWidget {
  final HomeNavTab currentTab;
  final ValueChanged<HomeNavTab> onTabSelected;
  final VoidCallback? onSearchTap;
  final VoidCallback? onPostTap;
  final VoidCallback? onCreateTap;
  final bool hasUnreadMessages;
  final int unreadMessagesCount;
  final bool hasUnreadActivity;
  final String? userAvatar;

  const HomeBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    this.onSearchTap,
    this.onPostTap,
    this.onCreateTap,
    this.hasUnreadMessages = false,
    this.unreadMessagesCount = 0,
    this.hasUnreadActivity = false,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-detect virtual keyboard to prevent bottom nav from floating over inputs
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    if (bottomInset > 0) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // High contrast liquid glass typography & icons (matching screenshot reference)
    const activeColor = Colors.white;
    final inactiveColor = isDark
        ? const Color(0x99FFFFFF)
        : const Color(0xB3FFFFFF); // 70% white on dark translucent glass

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        bottom: bottomPadding > 0 ? bottomPadding + 8.0 : 18.0,
      ),
      child: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360.0),
          child: Container(
            height: 64.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.0),
              // Specular light edge refraction (Liquid Glass perimeter)
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
              boxShadow: [
                // Deep liquid drop shadow for distinct separation against white or dark feed
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.60)
                      : const Color(0xFF0F172A).withValues(alpha: 0.16),
                  blurRadius: 30.0,
                  spreadRadius: -2.0,
                  offset: const Offset(0, 10),
                ),
                // Specular ambient ring
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8.0,
                  spreadRadius: 0.0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28.0, sigmaY: 28.0),
                child: Container(
                  height: 64.0,
                  padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32.0),
                    // Translucent smoky liquid glass tint matching screenshot reference
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E2024).withValues(alpha: 0.88),
                              const Color(0xFF141518).withValues(alpha: 0.82),
                            ]
                          : [
                              const Color(0xFF23262B).withValues(alpha: 0.86), // Smoky dark glass on light feed
                              const Color(0xFF191B1F).withValues(alpha: 0.92),
                            ],
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double tabWidth = constraints.maxWidth / 4.0;
                      return Stack(
                        children: [
                          // Sliding Liquid Bubble Pill Indicator (from burakozyurt / Apple liquid glass)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 280),
                            curve: const Cubic(0.2, 0.9, 0.3, 1.0),
                            left: currentTab.index * tabWidth + 2.0,
                            top: 2.0,
                            width: tabWidth - 4.0,
                            height: 52.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(26.0),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8.0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Tab 1: Home
                              _DockTabItem(
                                isActive: currentTab == HomeNavTab.home,
                                label: 'Home',
                                glyph: HomeNavGlyph(
                                  isActive: currentTab == HomeNavTab.home,
                                  activeColor: activeColor,
                                  inactiveColor: inactiveColor,
                                ),
                                onTap: () => onTabSelected(HomeNavTab.home),
                              ),

                              // Tab 2: Pesan (Chats)
                              _DockTabItem(
                                isActive: currentTab == HomeNavTab.messages,
                                label: 'Pesan',
                                glyph: PaperPlaneNavGlyph(
                                  isActive: currentTab == HomeNavTab.messages,
                                  hasBadge: hasUnreadMessages,
                                  badgeCount: unreadMessagesCount,
                                  activeColor: activeColor,
                                  inactiveColor: inactiveColor,
                                ),
                                onTap: () => onTabSelected(HomeNavTab.messages),
                              ),

                              // Tab 3: Aktivitas
                              _DockTabItem(
                                isActive: currentTab == HomeNavTab.activity,
                                label: 'Aktivitas',
                                glyph: HeartNavGlyph(
                                  isActive: currentTab == HomeNavTab.activity,
                                  hasBadge: hasUnreadActivity,
                                  activeColor: activeColor,
                                  inactiveColor: inactiveColor,
                                ),
                                onTap: () => onTabSelected(HomeNavTab.activity),
                              ),

                              // Tab 4: Profil
                              _DockTabItem(
                                isActive: currentTab == HomeNavTab.profile,
                                label: 'Profil',
                                glyph: UserNavGlyph(
                                  isActive: currentTab == HomeNavTab.profile,
                                  userAvatar: userAvatar,
                                  activeColor: activeColor,
                                  inactiveColor: inactiveColor,
                                ),
                                onTap: () => onTabSelected(HomeNavTab.profile),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dock Tab Item with Selection Capsule (#EDEDED fill, cornerRadius 100)
class _DockTabItem extends StatefulWidget {
  final bool isActive;
  final String label;
  final Widget glyph;
  final VoidCallback onTap;

  const _DockTabItem({
    required this.isActive,
    required this.label,
    required this.glyph,
    required this.onTap,
  });

  @override
  State<_DockTabItem> createState() => _DockTabItemState();
}

class _DockTabItemState extends State<_DockTabItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Colors.white;
    final inactiveColor = isDark
        ? const Color(0x99FFFFFF)
        : const Color(0xB3FFFFFF);

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            height: 56.0,
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon / Glyph with spring pop micro-motion
                AnimatedScale(
                  scale: widget.isActive ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: Center(child: widget.glyph),
                  ),
                ),

                const SizedBox(height: 2.0),

                // Label Text with smooth color transition
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    color: widget.isActive ? activeColor : inactiveColor,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
