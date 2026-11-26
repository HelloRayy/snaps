import 'package:flutter/material.dart';
import 'package:snapan_market/features/feed/components/navigation/home_bottom_nav_bar.dart';

/// Animated Directional Slide Tab Switcher for Bottom Nav.
/// Lazy-mounts non-home tabs on first visit to keep cold startup fast & stutter-free,
/// then preserves their state once visited.
class HomeNavTabSwitcher extends StatefulWidget {
  final HomeNavTab currentNavTab;
  final Widget feedTab;
  final Widget messagesTab;
  final Widget activityTab;
  final Widget profileTab;

  const HomeNavTabSwitcher({
    super.key,
    required this.currentNavTab,
    required this.feedTab,
    required this.messagesTab,
    required this.activityTab,
    required this.profileTab,
  });

  @override
  State<HomeNavTabSwitcher> createState() => _HomeNavTabSwitcherState();
}

class _HomeNavTabSwitcherState extends State<HomeNavTabSwitcher> {
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    _visitedTabs.add(widget.currentNavTab.index);
  }

  @override
  void didUpdateWidget(covariant HomeNavTabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visitedTabs.add(widget.currentNavTab.index);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          _buildNavTabScreen(index: 0, child: widget.feedTab),
          if (_visitedTabs.contains(1))
            _buildNavTabScreen(index: 1, child: widget.messagesTab),
          if (_visitedTabs.contains(2))
            _buildNavTabScreen(index: 2, child: widget.activityTab),
          if (_visitedTabs.contains(3))
            _buildNavTabScreen(index: 3, child: widget.profileTab),
        ],
      ),
    );
  }

  Widget _buildNavTabScreen({required int index, required Widget child}) {
    final int currentIndex = widget.currentNavTab.index;
    final bool isCurrent = currentIndex == index;

    final Offset targetOffset = isCurrent
        ? Offset.zero
        : (index > currentIndex ? const Offset(1.0, 0.0) : const Offset(-0.25, 0.0));

    final double targetOpacity = isCurrent ? 1.0 : (index > currentIndex ? 1.0 : 0.0);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isCurrent,
        child: AnimatedSlide(
          offset: targetOffset,
          duration: const Duration(milliseconds: 280),
          curve: const Cubic(0.22, 1.0, 0.36, 1.0),
          child: AnimatedOpacity(
            opacity: targetOpacity,
            duration: const Duration(milliseconds: 240),
            curve: const Cubic(0.22, 1.0, 0.36, 1.0),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
