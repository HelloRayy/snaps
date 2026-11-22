import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snapan_market/core/components/glass_toolbar_top.dart';
import 'package:snapan_market/core/components/avatar/default_profile_avatar.dart';
import 'package:snapan_market/core/components/mascot_flair_badge.dart';
import 'package:snapan_market/core/components/skeleton/chat_conversation_skeleton.dart';
import 'package:snapan_market/core/navigation/app_slide_page_route.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
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

class _ChatConversationScreenState extends State<ChatConversationScreen>
    with WidgetsBindingObserver {
  late String _activeConvId;
  late ConversationModel _currentConversation;
  late List<ChatMessageModel> _messages;
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _messagesSubscription;
  bool _isLoadingProduct = false;
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _currentConversation = widget.conversation;
    _activeConvId = widget.conversation.id;
    DirectMessagesService.instance.activeConversationId = _activeConvId;
    DirectMessagesService.instance.addListener(_onServiceChanged);
    WidgetsBinding.instance.addObserver(this);

    final savedMessages = DirectMessagesService.instance.getMessages(_activeConvId);
    if (savedMessages.isNotEmpty) {
      _messages = List.from(savedMessages);
      _isLoadingMessages = false;
      _scrollToBottom(60, true);
    } else {
      _messages = [];
      _isLoadingMessages = true;
    }

    _initRealtimeChat();
  }

  void _onServiceChanged() {
    if (!mounted) return;
    final resolvedId = DirectMessagesService.instance.resolveConversationId(_activeConvId);
    if (resolvedId != _activeConvId) {
      _resubscribeToNewConversationId(resolvedId);
    }
    final latestConv = DirectMessagesService.instance.findConversationById(resolvedId);
    final updated = DirectMessagesService.instance.getMessages(_activeConvId);
    setState(() {
      if (latestConv != null && latestConv.productContext != null) {
        _currentConversation = latestConv;
      }
      if (updated.isNotEmpty) {
        _messages = List.from(updated);
        _isLoadingMessages = false;
      }
    });
    if (updated.isNotEmpty) {
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

    try {
      final live = await DirectMessagesService.instance.loadMessages(_activeConvId);
      if (live.isNotEmpty && mounted) {
        setState(() {
          _messages = List.from(live);
        });
        _scrollToBottom(50, true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _scrollToBottom(150);
  }

  void _scrollToBottom([int delayMs = 0, bool immediate = false]) {
    void performScroll() {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        final target = _scrollController.position.maxScrollExtent;
        if (immediate) {
          _scrollController.jumpTo(target);
        } else {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
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
    final productId = _currentConversation.productId;
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

  Widget _buildChatHeader(bool isDark) {
    final user = widget.conversation.user;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppAvatar(
            avatarUrl: user.avatar,
            size: 64.0,
            name: user.name,
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (user.isVerified) ...[
                const SizedBox(width: 4.0),
                const Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 15.0,
                  color: Color(0xFF008BFF),
                ),
              ],
              if (user.mascotFlair != null) ...[
                const SizedBox(width: 4.0),
                MascotFlairBadge(
                  flair: user.mascotFlair!,
                  size: 26.0,
                ),
              ],
            ],
          ),
          const SizedBox(height: 2.0),
          Text(
            "@${user.username.replaceAll('@', '')}",
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.adaptiveMuted(context),
              letterSpacing: -0.2,
            ),
          ),
          if (user.classGroup != null && user.classGroup!.isNotEmpty) ...[
            const SizedBox(height: 6.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                user.classGroup!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10.0),
          Text(
            "Ini adalah awal percakapan Anda dengan ${user.name}.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.0,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCardFromMe = _currentConversation.isSender || !_currentConversation.isSeller;
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
              child: _isLoadingMessages && _messages.isEmpty
                  ? ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                      children: [
                        _buildChatHeader(isDark),
                        if (_currentConversation.productContext != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Align(
                              alignment: isCardFromMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: ChatProductCard(
                                product: _currentConversation.productContext!,
                                location: _currentConversation.productContext?.location ?? "Kantin Belakang SMKN 8 Semarang",
                                shape: isCardFromMe ? ChatProductCardShape.sent : ChatProductCardShape.firstReceived,
                                isMe: isCardFromMe,
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
                          ),
                        const SizedBox(
                          height: 220.0,
                          child: ChatConversationSkeleton(),
                        ),
                      ],
                    )
                  : ListView(
                      controller: _scrollController,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                      children: [
                        _buildChatHeader(isDark),
                        if (_currentConversation.productContext != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Align(
                              alignment: isCardFromMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: ChatProductCard(
                                product: _currentConversation.productContext!,
                                location: _currentConversation.productContext?.location ?? "Kantin Belakang SMKN 8 Semarang",
                                shape: isCardFromMe ? ChatProductCardShape.sent : ChatProductCardShape.firstReceived,
                                isMe: isCardFromMe,
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
                          ),
                        ..._messages.map(
                          (msg) => ChatMessageBubble(
                            message: msg,
                            onLongPress: () {
                              HapticFeedback.mediumImpact();
                              showModalBottomSheet<void>(
                                context: context,
                                builder: (ctx) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (msg.text.isNotEmpty)
                                        ListTile(
                                          leading: const Icon(Icons.copy_rounded),
                                          title: const Text('Salin Pesan'),
                                          onTap: () {
                                            Clipboard.setData(ClipboardData(text: msg.text));
                                            Navigator.pop(ctx);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Pesan disalin'),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                        ),
                                      if (msg.text.isNotEmpty)
                                        ListTile(
                                          leading: const Icon(Icons.reply_rounded),
                                          title: const Text('Balas Pesan'),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _handleSendMessage('Membalas "${msg.text}": ');
                                          },
                                        ),
                                      if (msg.isMe && msg.text.isNotEmpty)
                                        ListTile(
                                          leading: const Icon(Icons.edit_rounded),
                                          title: const Text('Edit Pesan'),
                                          onTap: () async {
                                            Navigator.pop(ctx);
                                            final ctrl = TextEditingController(text: msg.text);
                                            final updated = await showDialog<String>(
                                              context: context,
                                              builder: (dCtx) => AlertDialog(
                                                title: const Text('Edit Pesan'),
                                                content: TextField(controller: ctrl, autofocus: true),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dCtx),
                                                    child: const Text('Batal'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(dCtx, ctrl.text.trim()),
                                                    child: const Text('Simpan'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (updated != null && updated.isNotEmpty && mounted) {
                                              setState(() {
                                                final idx = _messages.indexWhere((m) => m.id == msg.id);
                                                if (idx != -1) {
                                                  _messages[idx] = msg.copyWith(text: updated);
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      if (msg.isMe)
                                        ListTile(
                                          leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                          title: const Text('Hapus Pesan', style: TextStyle(color: Colors.red)),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            setState(() {
                                              _messages.removeWhere((m) => m.id == msg.id);
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            ChatComposerBar(
              initialText: _messages.isEmpty ? widget.initialDraft : null,
              onSendMessage: _handleSendMessage,
              onSendMessageWithMedia: _handleSendMessageWithMedia,
              onTap: () {
                _scrollToBottom(50);
                _scrollToBottom(250);
              },
            ),
        ],
      ),
    ),
  );
}
}
