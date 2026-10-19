import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snapan_market/core/services/supabase_service.dart';

/// Singleton service managing state and persistence for the dismissible
/// mascot feature announcement badge indicator.
class MascotFeatureNoticeService {
  static final MascotFeatureNoticeService instance = MascotFeatureNoticeService._internal();
  MascotFeatureNoticeService._internal();

  static const String _kMascotNoticeSeenPrefix = 'has_seen_mascot_feature_';
  static const String _kMascotNoticeSeenFallbackKey = 'has_seen_mascot_feature_v1';

  /// Reactive notifier indicating whether the mascot badge should be displayed
  final ValueNotifier<bool> shouldShowMascotBadge = ValueNotifier<bool>(false);

  bool _isInitialized = false;
  SharedPreferences? _prefs;
  StreamSubscription<AuthState>? _authSubscription;

  /// Initialize listeners and evaluate current visibility state
  Future<void> init() async {
    if (!_isInitialized) {
      _isInitialized = true;
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (e) {
        debugPrint('MascotFeatureNoticeService SharedPreferences init notice: $e');
      }

      try {
        SupabaseService.instance.currentUserProfileNotifier.addListener(_onProfileChanged);
      } catch (e) {
        debugPrint('MascotFeatureNoticeService currentUserProfileNotifier listen notice: $e');
      }

      try {
        _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
          evaluate();
        });
      } catch (e) {
        debugPrint('MascotFeatureNoticeService onAuthStateChange listen notice: $e');
      }
    }
    await evaluate();
  }

  void _onProfileChanged() {
    evaluate();
  }

  /// Re-evaluates whether the mascot badge should be displayed for the active user
  Future<void> evaluate() async {
    try {
      if (!_checkIsAuthenticated()) {
        shouldShowMascotBadge.value = false;
        return;
      }

      final userId = _getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        shouldShowMascotBadge.value = false;
        return;
      }

      final profile = _getCurrentUserProfile();
      if (profile != null && profile['mascot_flair'] != null) {
        shouldShowMascotBadge.value = false;
        return;
      }

      _prefs ??= await SharedPreferences.getInstance();
      final hasSeenUser = _prefs?.getBool('$_kMascotNoticeSeenPrefix$userId') ?? false;

      if (hasSeenUser) {
        shouldShowMascotBadge.value = false;
      } else {
        shouldShowMascotBadge.value = true;
      }
    } catch (e) {
      debugPrint('MascotFeatureNoticeService evaluate notice: $e');
      shouldShowMascotBadge.value = false;
    }
  }

  /// Dismisses the badge permanently for the current user and persists to storage
  Future<void> markSeen() async {
    shouldShowMascotBadge.value = false;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final userId = _getCurrentUserId();
      if (userId != null && userId.isNotEmpty) {
        await _prefs?.setBool('$_kMascotNoticeSeenPrefix$userId', true);
      }
      await _prefs?.setBool(_kMascotNoticeSeenFallbackKey, true);
    } catch (e) {
      debugPrint('MascotFeatureNoticeService markSeen error: $e');
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _authSubscription?.cancel();
    _authSubscription = null;
    try {
      SupabaseService.instance.currentUserProfileNotifier.removeListener(_onProfileChanged);
    } catch (_) {}
    _prefs = null;
    _isInitialized = false;
    shouldShowMascotBadge.value = false;
  }

  bool _checkIsAuthenticated() {
    try {
      return SupabaseService.instance.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  String? _getCurrentUserId() {
    try {
      return SupabaseService.instance.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _getCurrentUserProfile() {
    try {
      return SupabaseService.instance.currentUserProfileNotifier.value;
    } catch (_) {
      return null;
    }
  }
}
