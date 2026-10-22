import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/core/services/deep_link_service.dart';
import 'package:snapan_market/core/utils/share_helper.dart';

void main() {
  group('DeepLinkService URI Parsing Tests', () {
    test('extracts postId from custom scheme snaps://post/<id>', () {
      final uri = Uri.parse('snaps://post/123e4567-e89b-12d3-a456-426614174000');
      final postId = DeepLinkService.extractPostId(uri);
      expect(postId, '123e4567-e89b-12d3-a456-426614174000');
    });

    test('extracts postId from web link https://snaps.web.id/post/<id>', () {
      final uri = Uri.parse('https://snaps.web.id/post/test-post-uuid');
      final postId = DeepLinkService.extractPostId(uri);
      expect(postId, 'test-post-uuid');
    });

    test('extracts postId from handle route https://snaps.web.id/@radityaray/post/<id>', () {
      final uri = Uri.parse('https://snaps.web.id/@radityaray/post/my-special-thread');
      final postId = DeepLinkService.extractPostId(uri);
      expect(postId, 'my-special-thread');
    });

    test('extracts postId from vercel domain fallback', () {
      final uri = Uri.parse('https://snapan-market.vercel.app/post/abc-123');
      final postId = DeepLinkService.extractPostId(uri);
      expect(postId, 'abc-123');
    });

    test('extracts postId from hash fragment #post-<id>', () {
      final uri = Uri.parse('https://snaps.web.id/#post-frag-456');
      final postId = DeepLinkService.extractPostId(uri);
      expect(postId, 'frag-456');
    });

    test('returns null for unrelated URLs', () {
      final uri = Uri.parse('https://snaps.web.id/search');
      final postId = DeepLinkService.extractPostId(uri);
      expect(postId, isNull);
    });
  });

  group('ShareHelper Canonical Format Tests', () {
    test('generates canonical snaps.web.id share URL', () {
      final shareUrl = ShareHelper.getPostShareUrl('post-100');
      expect(shareUrl, 'https://snaps.web.id/post/post-100');
    });

    test('generates canonical app scheme URI', () {
      final schemeUri = ShareHelper.getPostDeepLinkScheme('post-100');
      expect(schemeUri, 'snaps://post/post-100');
    });
  });
}
