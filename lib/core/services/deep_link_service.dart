import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:snapan_market/core/navigation/app_slide_page_route.dart';
import 'package:snapan_market/core/navigation/navigation_service.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/feed/screens/post_detail_screen.dart';

/// Central singleton service to intercept, parse, and route deep links
/// into Snaps Mobile App, providing seamless guest and authenticated detail viewing.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  String? _lastHandledPostId;
  DateTime? _lastHandledTime;

  /// Initialize deep link listeners on app startup (cold start & stream)
  Future<void> init() async {
    try {
      // 1. Check initial cold-start deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Initial link error: $e');
    }

    // 2. Listen to subsequent runtime incoming links (warm state)
    _linkSub?.cancel();
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (err) => debugPrint('[DeepLinkService] Stream link error: $err'),
    );
  }

  /// Extracts the post ID from various supported URI formats
  static String? extractPostId(Uri uri) {
    // Case 1: Custom Scheme (snaps://post/<id>)
    if (uri.scheme == 'snaps' && uri.host == 'post') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.first;
      }
    }

    // Case 2: Web Domain (https://snaps.web.id/post/<id>)
    final path = uri.path;
    if (path.contains('/post/')) {
      final parts = path.split('/post/').where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        // Handle /post/<id> or /@username/post/<id>
        final rawId = parts.last.split('/')[0].trim();
        if (rawId.isNotEmpty) {
          return Uri.decodeComponent(rawId);
        }
      }
    }

    // Case 3: URL Hash (#post-<id>)
    if (uri.fragment.startsWith('post-')) {
      return Uri.decodeComponent(uri.fragment.replaceFirst('post-', ''));
    }

    return null;
  }

  Future<void> _handleUri(Uri uri) async {
    final postId = extractPostId(uri);
    if (postId == null || postId.isEmpty) return;

    // Deduplication check: prevent navigating multiple times within 2 seconds
    final now = DateTime.now();
    if (_lastHandledPostId == postId &&
        _lastHandledTime != null &&
        now.difference(_lastHandledTime!).inSeconds < 2) {
      return;
    }
    _lastHandledPostId = postId;
    _lastHandledTime = now;

    await _navigateToPostDetail(postId);
  }

  Future<void> _navigateToPostDetail(String postId) async {
    // Wait briefly if app navigation root is still mounting
    int retries = 0;
    while (NavigationService.navigatorKey.currentState == null && retries < 10) {
      await Future.delayed(const Duration(milliseconds: 150));
      retries++;
    }

    final navState = NavigationService.navigatorKey.currentState;
    final context = NavigationService.currentContext;
    if (navState == null || context == null) return;

    try {
      final post = await SupabaseService.instance.fetchPostById(postId);
      if (!context.mounted) return;

      if (post != null) {
        navState.push(
          AppSlidePageRoute(
            builder: (_) => PostDetailScreen(post: post),
          ),
        );
      } else {
        SnapsToast.show(
          context,
          'Postingan tidak ditemukan atau telah dihapus',
          hasBottomNav: false,
        );
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Failed to load post $postId: $e');
    }
  }

  void dispose() {
    _linkSub?.cancel();
    _linkSub = null;
  }
}
