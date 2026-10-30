import 'package:flutter/material.dart';
import 'package:snapan_market/core/navigation/app_slide_page_route.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/core/utils/formatters.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/feed/models/market_post_model.dart';
import 'package:snapan_market/features/messages/models/conversation_model.dart';
import 'package:snapan_market/features/messages/screens/chat_conversation_screen.dart';
import 'package:snapan_market/features/messages/services/direct_messages_service.dart';

/// Helper to navigate from a product post directly into seller Direct Message
/// with attached ProductContext and auto-inbox categorization (Social Commerce Feed-to-DM).
class SocialCommerceNavigator {
  const SocialCommerceNavigator._();

  static void openDirectMessage(
    BuildContext context,
    MarketPostModel post, {
    bool hasBottomNav = true,
  }) {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    if (currentUserId != null && currentUserId == post.seller.id) {
      SnapsToast.show(
        context,
        'Ini adalah produk jualan Anda sendiri.',
        hasBottomNav: hasBottomNav,
      );
      return;
    }

    final targetUserId = post.seller.id;
    final title = post.title ??
        (post.caption.isNotEmpty ? post.caption.split('\n').first : 'Produk');
    final conv = ConversationModel(
      id: "product-${post.id}",
      productId: post.id,
      user: ConversationUser(
        id: targetUserId.isNotEmpty ? targetUserId : null,
        name: post.seller.displayName ?? post.seller.name,
        username: post.seller.username ?? 'penjual',
        avatar: post.seller.avatar,
        classGroup: post.seller.classGroup,
        isVerified: post.seller.isVerified,
        mascotFlair: post.seller.mascotFlair,
      ),
      lastMessage: "Halo, saya tertarik dengan $title",
      timestamp: "Baru saja",
      isSeller: false,
      isRequest: true,
      productContext: ProductContext(
        title: title,
        price: formatRupiah(post.price ?? 0),
        image: post.images.isNotEmpty ? post.images.first : null,
        location: post.locationTag ?? 'SMKN 8 Semarang',
      ),
    );

    DirectMessagesService.instance.addOrUpdateConversation(conv);
    Navigator.of(context).push(
      AppSlidePageRoute(
        builder: (_) => ChatConversationScreen(
          conversation: conv,
          initialDraft: "Halo kak, saya tertarik mau beli $title.",
        ),
      ),
    );
  }
}
