import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/feed/models/market_post_model.dart';

/// Centralized utility for building canonical share URLs and executing share actions.
class ShareHelper {
  ShareHelper._();

  /// Canonical domain for public web preview and guest mode access
  static const String canonicalDomain = 'https://snaps.web.id';

  /// Builds canonical public web link for a post
  static String getPostShareUrl(String postId) {
    final cleanId = postId.trim();
    return '$canonicalDomain/post/$cleanId';
  }

  /// Builds custom deep link URI for opening in installed Snaps mobile app
  static String getPostDeepLinkScheme(String postId) {
    final cleanId = postId.trim();
    return 'snaps://post/$cleanId';
  }

  /// Copies canonical link to clipboard and notifies user with a feedback toast
  static Future<void> sharePost(BuildContext context, MarketPostModel post) async {
    HapticFeedback.lightImpact();
    final url = getPostShareUrl(post.id);

    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        SnapsToast.success(
          context,
          'Tautan postingan berhasil disalin',
          hasBottomNav: false,
        );
      }
    } catch (e) {
      debugPrint('Error copying share link: $e');
    }
  }
}
