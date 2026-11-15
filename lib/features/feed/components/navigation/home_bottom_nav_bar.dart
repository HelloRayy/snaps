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

/// Liquid Glass Bottom Nav Bar
/// Inspired by burakozyurt/liquid-glass-bottom-nav-bar
/// 
/// Refined with sNaps Electric Indigo brand signature:
/// - Active Tab: sNaps Electric Indigo (#3D38F5) with soft brand wash
/// - Squash & Stretch fluid physics: sliding capsule organically stretches during tab changes
/// - Frosted glass body with specular refraction perimeter edge
/// - High contrast readability in both Light and Dark modes
class HomeBottomNavBar extends StatefulWidget {
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
  State<HomeBottomNavBar> createState() => _HomeBottomNavBarState();
}

class _HomeBottomNavBarState extends State<HomeBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _morphController;
  late Animation<double> _stretchAnim;
  int _prevIndex = 0;

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.currentTab.index;
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    // Squash & Stretch curve: indicator expands slightly then snaps into place
    _stretchAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 0.96), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(covariant HomeBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTab != widget.currentTab) {
      _prevIndex = oldWidget.currentTab.index;
      _morphController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    if (bottomInset > 0) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Brand Signature: Electric Indigo (#3D38F5) when active
    const activeBrandColor = AppColors.primary;
    final inactiveColor = isDark
        ? const Color(0x99FFFFFF)
        : const Color(0xFF64748B); // Slate-500

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
                    : Colors.white.withValues(alpha: 0.90),
                width: 1.2,
              ),
              boxShadow: [
                // Deep liquid drop shadow for distinct contrast against feed
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.60)
                      : const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: isDark ? 30.0 : 24.0,
                  spreadRadius: isDark ? -2.0 : -4.0,
                  offset: const Offset(0, 8),
                ),
                // Specular top highlight
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.70),
                  blurRadius: 4.0,
                  spreadRadius: 0.0,
                  offset: const Offset(0, 1),
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
                    // Adaptive translucent liquid glass tint
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E2024).withValues(alpha: 0.90),
                              const Color(0xFF141518).withValues(alpha: 0.84),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.90),
                              const Color(0xFFF8FAFC).withValues(alpha: 0.82),
                            ],
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double tabWidth = constraints.maxWidth / 4.0;
                      return Stack(
                        children: [
                          // Sliding Liquid Bubble Pill Indicator with Squash & Stretch
                          AnimatedBuilder(
                            animation: _stretchAnim,
                            builder: (context, child) {
                              final stretchFactor = _stretchAnim.value;
                              final width = (tabWidth - 6.0) * stretchFactor;
                              final leftOffset = widget.currentTab.index * tabWidth + 3.0 - (width - (tabWidth - 6.0)) / 2;

                              return AnimatedPositioned(
                                duration: const Duration(milliseconds: 280),
                                curve: const Cubic(0.2, 0.9, 0.3, 1.0),
                                left: leftOffset,
                                top: 2.0,
                                width: width,
                                height: 52.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    // Brand Indigo Wash in light mode / Crisp glow in dark mode
                                    color: isDark
                                        ? AppColors.primary.withValues(alpha: 0.22)
                                        : AppColors.primaryPastel,
                                    borderRadius: BorderRadius.circular(26.0),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.primary.withValues(alpha: 0.45)
                                          : AppColors.primaryBorder,
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.08),
                                        blurRadius: 8.0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Tab 1: Home
                              _DockTabItem(
                                isActive: widget.currentTab == HomeNavTab.home,
                                label: 'Home',
                                glyph: HomeNavGlyph(
                                  isActive: widget.currentTab == HomeNavTab.home,
                                  activeColor: activeBrandColor,
                                  inactiveColor: inactiveColor,
                                ),
                                onTap: () => widget.onTabSelected(HomeNavTab.home),
                              ),

                              // Tab 2: Pesan (Chats)
                              _DockTabItem(
                                isActive: widget.currentTab == HomeNavTab.messages,
                                label: 'Pesan',
                                glyph: PaperPlaneNavGlyph(
                                  isActive: widget.currentTab == HomeNavTab.messages,
                                  hasBadge: widget.hasUnreadMessages,
                                  badgeCount: widget.unreadMessagesCount,
                                  activeColor: activeBrandColor,
                                  inactiveColor: inactiveColor,
                                ),
                                onTap: () => widget.onTabSelected(HomeNavTab.messages),
                              ),

                              // Tab 3: Aktivitas
                              _DockTabItem(
                                isActive: widget.currentTab == HomeNavTab.activity,
                                label: 'Aktivitas',
                                glyph: HeartNavGlyph(
                                  isActive: widget.currentTab == HomeNavTab.activity,
                                  hasBadge: widget.hasUnreadActivity,
                                  activeColor: activeBrandColor,
                                  inactiveColor: inactiveColor,
                                ),
                                onTap: () => widget.onTabSelected(HomeNavTab.activity),
                              ),

                              // Tab 4: Profil
                              _DockTabItem(
                                isActive: widget.currentTab == HomeNavTab.profile,
                                label: 'Profil',
                                glyph: UserNavGlyph(
                                  isActive: widget.currentTab == HomeNavTab.profile,
                                  userAvatar: widget.userAvatar,
                                  activeColor: activeBrandColor,
                                  inactiveColor: inactiveColor,
                                ),
                                onTap: () => widget.onTabSelected(HomeNavTab.profile),
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

/// Dock Tab Item with Liquid Spring Micro-Motion
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
    const activeColor = AppColors.primary;
    final inactiveColor = isDark
        ? const Color(0x99FFFFFF)
        : const Color(0xFF64748B);

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
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: Center(child: widget.glyph),
                  ),
                ),

                const SizedBox(height: 2.0),

                // Label Text with Brand Indigo color when active
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
