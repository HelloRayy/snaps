import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/splash/components/eraser_logo.dart';

/// Splash screen that coordinates:
/// 1. 750ms Static Hold (logo static in center)
/// 2. 450ms Right-to-Left Reverse Diagonal Eraser Wipe (easeInOutCubic)
/// 3. Calls [onCompleted] when logo is completely erased to trigger cross-fade to feed
class SplashScreen extends StatefulWidget {
  final VoidCallback onCompleted;

  const SplashScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _eraserAnim;

  // Snappy timeline durations (eliminates blank white screen gap)
  static const int _entranceMs = 260;
  static const int _holdMs = 360;
  static const int _wipeMs = 340;
  static const int _totalMs = _entranceMs + _holdMs + _wipeMs; // 960ms
  bool _hasNotifiedCompletion = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    // 1. Entrance Motion (Subtle Pop-In without blank white delay)
    final entranceEnd = _entranceMs / _totalMs;
    _fadeAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, entranceEnd, curve: Curves.easeOutCubic),
      ),
    );
    _scaleAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, entranceEnd, curve: Curves.easeOutCubic),
      ),
    );
    _slideAnim = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, entranceEnd, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Eraser wipe begins after entrance + hold
    final wipeStart = (_entranceMs + _holdMs) / _totalMs;
    _eraserAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(wipeStart, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // Overlap cross-fade with the end of the wipe so there is ZERO blank white screen
    _controller.addListener(() {
      if (!_hasNotifiedCompletion && _controller.value >= 0.78) {
        _hasNotifiedCompletion = true;
        widget.onCompleted();
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasNotifiedCompletion) {
        _hasNotifiedCompletion = true;
        widget.onCompleted();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveCanvas(context),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _fadeAnim.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnim.value),
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: EraserLogo(
                    progress: _eraserAnim.value,
                    height: 64.0,
                    feather: 0.22,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
