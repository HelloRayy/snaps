import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snapan_market/core/components/glass_toolbar_top.dart';
import 'package:snapan_market/core/navigation/app_slide_page_route.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/features/map/screens/campus_map_screen.dart';
import 'package:snapan_market/features/messages/components/chat_app_bar_title.dart';
import 'package:snapan_market/features/messages/components/chat_composer_bar.dart';
import 'package:snapan_market/features/messages/components/chat_message_bubble.dart';
import 'package:snapan_market/features/messages/components/chat_options_sheet.dart';
import 'package:snapan_market/features/messages/components/chat_product_card.dart';
import 'package:snapan_market/features/messages/models/chat_message_model.dart';
import 'package:snapan_market/features/messages/models/conversation_model.dart';
import 'package:snapan_market/features/messages/services/direct_messages_service.dart';
import 'package:snapan_market/features/profile/screens/profile_screen.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/feed/screens/post_detail_screen.dart';

/// Layar ruang obrolan 1-on-1 Direct Messaging (1:1 ActiveChatOverlay.tsx)
class ChatConversationScreen extends StatefulWidget {
  final ConversationModel conversation;
  final String? initialDraft;

  const ChatConversationScreen({
    super.key,
    required this.conversation,
    this.initialDraft,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  late String _activeConvId;
  late List<ChatMessageModel> _messages;
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _messagesSubscription;
  bool _isLoadingProduct = false;

  @override
  void initState() {
    super.initState();
    _activeConvId = widget.conversation.id;
    DirectMessagesService.instance.activeConversationId = _activeConvId;
    DirectMessagesService.instance.addListener(_onServiceChanged);

    final savedMessages = DirectMessagesService.instance.getMessages(_activeConvId);
    if (savedMessages.isNotEmpty) {
      _messages = List.from(savedMessages);
    } else if (widget.conversation.lastMessage.trim().isNotEmpty) {
      final initialMsg = ChatMessageModel(
        id: "msg-${DateTime.now().millisecondsSinceEpoch}",
        senderId: widget.conversation.isSender ? "saya" : widget.conversation.user.username,
        text: widget.conversation.lastMessage.trim(),
        timestamp: widget.conversation.timestamp,
        isMe: widget.conversation.isSender,
      );
      _messages = [initialMsg];
      DirectMessagesService.instance.addMessage(
        _activeConvId,
        initialMsg,
        conversation: widget.conversation,
      );
    } else {
      _messages = [];
    }

    _initRealtimeChat();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    final resolvedId = DirectMessagesService.instance.resolveConversationId(_activeConvId);
    if (resolvedId != _activeConvId) {
      _resubscribeToNewConversationId(resolvedId);
    }
    final updated = DirectMessagesService.instance.getMessages(_activeConvId);
    if (updated.isNotEmpty) {
      setState(() {
        _messages = List.from(updated);
      });
      _scrollToBottom();
    }
  }

  void _resubscribeToNewConversationId(String newId) {
    _activeConvId = newId;
    DirectMessagesService.instance.activeConversationId = newId;
    final currentUserId = SupabaseService.instance.currentUser?.id ?? '';
    _messagesSubscription?.unsubscribe();
    _messagesSubscription = SupabaseService.instance.subscribeToMessages(
      newId,
      (newRecord) {
        if (!mounted) return;
        final msg = ChatMessageModel.fromJson(newRecord, currentUserId);
        DirectMessagesService.instance.addMessage(
          newId,
          msg,
          conversation: widget.conversation,
        );
        if (!msg.isMe) {
          DirectMessagesService.instance.markAsRead(newId);
        }
        _scrollToBottom();
      },
      onMessageUpdated: (updatedRecord) {
        if (!mounted) return;
        final updatedMsg = ChatMessageModel.fromJson(updatedRecord, currentUserId);
        DirectMessagesService.instance.updateMessage(newId, updatedMsg);
      },
    );
  }

  Future<void> _initRealtimeChat() async {
    final currentUserId = SupabaseService.instance.currentUser?.id ?? '';
    final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

    // Auto-resolve real UUID if opened with temporary conversation ID
    if (!isUuid.hasMatch(_activeConvId)) {
      String? targetUserId = widget.conversation.user.id;
      if (targetUserId == null) {
        final profile = await SupabaseService.instance.getProfileByUsername(widget.conversation.user.username);
        targetUserId = profile?['id'] as String?;
      }

      if (targetUserId != null) {
        final realId = await SupabaseService.instance.getOrCreateConversation(
          otherUserId: targetUserId,
          productId: widget.conversation.productId,
        );
        if (realId != null && realId != _activeConvId) {
          final oldId = _activeConvId;
          _activeConvId = realId;
          DirectMessagesService.instance.activeConversationId = realId;
          DirectMessagesService.instance.updateConversationId(
            oldId: oldId,
            newId: realId,
          );
        }
      }
    }

    // Load message history from Supabase
    final live = await DirectMessagesService.instance.loadMessages(_activeConvId);
    if (live.isNotEmpty && mounted) {
      setState(() {
        _messages = List.from(live);
      });
      _scrollToBottom();
    }

    // Subscribe to live realtime messages and read-status updates
    _messagesSubscription?.unsubscribe();
    _messagesSubscription = SupabaseService.instance.subscribeToMessages(
      _activeConvId,
      (newRecord) {
        if (!mounted) return;
        final msg = ChatMessageModel.fromJson(newRecord, currentUserId);
        DirectMessagesService.instance.addMessage(
          _activeConvId,
          msg,
          conversation: widget.conversation,
        );
        // If message is from other user, automatically mark as read
        if (!msg.isMe) {
          DirectMessagesService.instance.markAsRead(_activeConvId);
        }
        _scrollToBottom();
      },
      onMessageUpdated: (updatedRecord) {
        if (!mounted) return;
        final updatedMsg = ChatMessageModel.fromJson(updatedRecord, currentUserId);
        DirectMessagesService.instance.updateMessage(_activeConvId, updatedMsg);
      },
    );
  }

  @override
  void dispose() {
    final currentActive = DirectMessagesService.instance.activeConversationId;
    if (currentActive == _activeConvId ||
        DirectMessagesService.instance.resolveConversationId(currentActive ?? '') == _activeConvId) {
      DirectMessagesService.instance.activeConversationId = null;
    }
    DirectMessagesService.instance.removeListener(_onServiceChanged);
    _messagesSubscription?.unsubscribe();
    _scrollController.dispose();
    super.dispose();
  }


  void _scrollToBottom([int delayMs = 0]) {
    void performScroll() {
      if (!mounted) return;
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        );
      }
    }

    if (delayMs > 0) {
      Future.delayed(Duration(milliseconds: delayMs), performScroll);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => performScroll());
    }
  }

  void _handleSendMessage(String text) {
    DirectMessagesService.instance.sendMessage(
      conversationId: _activeConvId,
      text: text,
      conversation: widget.conversation,
    );
    _scrollToBottom();
  }

  void _handleSendMessageWithMedia(String text, List<String> images) async {
    if (images.isEmpty) {
      _handleSendMessage(text);
      return;
    }

    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final tempMsg = ChatMessageModel(
      id: "temp-${now.millisecondsSinceEpoch}",
      senderId: SupabaseService.instance.currentUser?.id ?? "saya",
      text: text,
      images: images,
      timestamp: timeStr,
      isMe: true,
      status: MessageStatus.sending,
    );
    DirectMessagesService.instance
        .addMessage(_activeConvId, tempMsg, conversation: widget.conversation);
    _scrollToBottom();

    try {
      List<String> uploadedUrls = [];
      for (final imgPath in images) {
        final file = File(imgPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final url = await SupabaseService.instance.uploadImage(
            bytes: bytes,
            fileName:
                'chat_${DateTime.now().millisecondsSinceEpoch}_${images.indexOf(imgPath)}.jpg',
            bucket: 'market-media',
          );
          if (url != null) {
            uploadedUrls.add(url);
          }
        }
      }

      final payloadText = text.isNotEmpty
          ? text
          : (uploadedUrls.isNotEmpty ? uploadedUrls.first : '');

      DirectMessagesService.instance.sendMessage(
        conversationId: _activeConvId,
        text: payloadText,
        conversation: widget.conversation,
      );
    } catch (e) {
      debugPrint('Error uploading chat media: $e');
    }
  }

  void _handleViewProfile() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      AppSlidePageRoute(
        builder: (_) => ProfileScreen(
          username: widget.conversation.user.username,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _handleReportUser() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Laporan terhadap @${widget.conversation.user.username} telah dikirim ke admin sekolah."),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleClearChat() {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Obrolan telah dibersihkan."),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleViewProduct() async {
    final productId = widget.conversation.productId;
    if (productId == null || productId.trim().isEmpty) {
      SnapsToast.show(
        context,
        'Produk tidak ditemukan atau telah dihapus',
        hasBottomNav: false,
      );
      return;
    }

    if (_isLoadingProduct) return;
    setState(() => _isLoadingProduct = true);

    try {
      final post = await SupabaseService.instance.fetchPostById(productId);
      if (!mounted) return;

      if (post != null) {
        Navigator.of(context).push(
          AppSlidePageRoute(
            builder: (_) => PostDetailScreen(post: post),
          ),
        );
      } else {
        SnapsToast.show(
          context,
          'Produk tidak ditemukan atau telah dihapus',
          hasBottomNav: false,
        );
      }
    } catch (e) {
      if (mounted) {
        SnapsToast.show(
          context,
          'Produk tidak ditemukan atau telah dihapus',
          hasBottomNav: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProduct = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F17) : const Color(0xFFF6F7F9),
      appBar: GlassToolbarTop(
        leadingIcon: CupertinoIcons.chevron_back,
        leadingTooltip: "Kembali",
        onLeadingTap: () => Navigator.of(context).pop(),
        showVerifiedBadge: false,
        centerTitle: false,
        titleWidget: ChatAppBarTitle(
          user: widget.conversation.user,
          onTapProfile: _handleViewProfile,
        ),
        trailingActions: [
          GlassToolbarAction(
            icon: CupertinoIcons.person_crop_circle,
            tooltip: 'Profil',
            onTap: _handleViewProfile,
          ),
          GlassToolbarAction(
            icon: CupertinoIcons.ellipsis,
            tooltip: 'Menu lainnya',
            onTap: () {
              HapticFeedback.lightImpact();
              ChatOptionsSheet.show(
                context: context,
                onViewProfile: _handleViewProfile,
                onReportUser: _handleReportUser,
                onClearChat: _handleClearChat,
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                itemCount: _messages.length + (widget.conversation.productContext != null ? 1 : 0),
                itemBuilder: (context, index) {
                  final hasProduct = widget.conversation.productContext != null;
                  if (hasProduct && index == _messages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ChatProductCard(
                          product: widget.conversation.productContext!,
                          location: widget.conversation.productContext?.location ?? "Kantin Belakang SMKN 8 Semarang",
                          onViewProduct: _isLoadingProduct ? null : _handleViewProduct,
                          onCheckLocation: () {
                            Navigator.of(context).push(
                              AppSlidePageRoute(
                                builder: (_) => CampusMapScreen(
                                  onBack: () => Navigator.pop(context),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                  final msgIndex = _messages.length - 1 - index;
                  final msg = _messages[msgIndex];
                  return ChatMessageBubble(message: msg);
                },
              ),
          ),
          ChatComposerBar(
            initialText: _messages.isEmpty ? widget.initialDraft : null,
            onSendMessage: _handleSendMessage,
            onSendMessageWithMedia: _handleSendMessageWithMedia,
          ),
        ],
      ),
    ),
  );
}
}
