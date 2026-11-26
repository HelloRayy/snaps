import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
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
  final bool isCollapsed;
  final VoidCallback? onExpandTap;
  final int motionDurationMs;
  final Curve motionCurve;
  final double collapsedWidth;
  final double navHeight;
  final double horizontalPadding;
  final double bottomMargin;
  final double iconScale;
  final double iconGap;

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
    this.isCollapsed = false,
    this.onExpandTap,
    this.motionDurationMs = 501,
    this.motionCurve = Curves.easeOutCubic,
    this.collapsedWidth = 64.0,
    this.navHeight = 64.0,
    this.horizontalPadding = 16.0,
    this.bottomMargin = 24.0,
    this.iconScale = 1.48,
    this.iconGap = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    // Auto-detect virtual keyboard to prevent bottom nav from floating over inputs
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    if (bottomInset > 0) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final double expandedWidth = (MediaQuery.sizeOf(context).width - horizontalPadding * 2).clamp(0.0, 360.0);
    final double innerWidth = (expandedWidth - 8.0).clamp(0.0, 352.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : AppColors.primary;
    final inactiveColor = isDark ? const Color(0x99FFFFFF) : const Color(0xFF64748B);

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: bottomPadding > 0 ? bottomPadding + 8.0 : bottomMargin,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        heightFactor: 1.0,
        child: AnimatedContainer(
          duration: Duration(milliseconds: motionDurationMs),
          curve: Curves.easeOutCubic,
          width: isCollapsed ? collapsedWidth : expandedWidth,
          height: navHeight,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(31.0),
              border: Border.all(
                color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? const Color(0x4D000000) : const Color(0x0F000000),
                  blurRadius: isDark ? 12.0 : 10.0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(31.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                child: Container(
                  height: 62.0,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(31.0),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              const Color(0xFF161717).withValues(alpha: 0.94),
                              const Color(0xFF161717).withValues(alpha: 0.88),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.90),
                              Colors.white.withValues(alpha: 0.80),
                            ],
                    ),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isCollapsed
                        ? () {
                            HapticFeedback.selectionClick();
                            onExpandTap?.call();
                          }
                        : null,
                    child: IgnorePointer(
                      ignoring: isCollapsed,
                      child: AnimatedPadding(
                        duration: Duration(milliseconds: motionDurationMs),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.only(
                          left: 0,
                        ),
                        child: Transform.translate(
                          offset: Offset(
                            isCollapsed ? -((innerWidth / 8.0) - (collapsedWidth / 2.0 - 4.0)) : 0.0,
                            0.0,
                          ),
                          child: OverflowBox(
                            maxWidth: innerWidth,
                          minWidth: innerWidth,
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: innerWidth,
                            child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double tabWidth = constraints.maxWidth / 4.0;
                      return Stack(
                        children: [
                          // Sliding Selection Capsule - Clean borderless soft pill wash
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 260),
                            curve: const Cubic(0.2, 0.9, 0.3, 1.0),
                            left: currentTab.index * tabWidth + 3.0 + (iconGap / 2),
                            top: 3.0,
                            width: (tabWidth - 6.0 - iconGap).clamp(24.0, 120.0),
                            height: (navHeight - 12.0).clamp(32.0, 60.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isCollapsed
                                    ? Colors.transparent
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : AppColors.primary.withValues(alpha: 0.08)),
                                borderRadius: BorderRadius.circular(25.0),
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
                                iconScale: iconScale,
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
  final bool showLabel;
  final double iconScale;

  const _DockTabItem({
    required this.isActive,
    required this.label,
    required this.glyph,
    required this.onTap,
    this.showLabel = false,
    this.iconScale = 1.48,
  });

  @override
  State<_DockTabItem> createState() => _DockTabItemState();
}

class _DockTabItemState extends State<_DockTabItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : AppColors.primary;
    final inactiveColor = isDark ? const Color(0x99FFFFFF) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
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
                Transform.scale(
                  scale: widget.iconScale,
                  child: AnimatedScale(
                  scale: widget.isActive ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: Center(child: widget.glyph),
                  ),
                ),
                ),

                if (widget.showLabel) ...[
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
