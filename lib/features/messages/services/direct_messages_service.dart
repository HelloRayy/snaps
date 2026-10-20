import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snapan-market/core/services/global_notification_service.dart';
import 'package:snapan-market/core/services/supabase_service.dart';
import 'package:snapan-market/features/messages/models/conversation_model.dart';
import 'package:snapan-market/features/messages/models/chat_message_model.dart';

/// Singleton service to manage live Direct Message conversations & history with Supabase Realtime
class DirectMessagesService extends ChangeNotifier {
  static final DirectMessagesService instance = DirectMessagesService._internal();
  DirectMessagesService._internal();

  final List<ConversationModel> _conversations = [];
  final Map<String, List<ChatMessageModel>> _conversationMessages = {};
  final Map<String, String> _migratedConversationIds = {};
  bool _isFetchingConversations = false;
  String? _activeUserId;
  StreamSubscription<AuthState>? _authSub;
  RealtimeChannel? _globalInboxSub;
  String? activeConversationId;

  List<ConversationModel> get conversations => List.unmodifiable(_conversations);
  bool get isFetchingConversations => _isFetchingConversations;
  int get totalUnreadCount => _conversations.fold<int>(0, (acc, c) => acc + c.unreadCount);

  String resolveConversationId(String id) => _migratedConversationIds[id] ?? id;

  void init() {
    _authSub?.cancel();
    final currentUser = SupabaseService.instance.currentUser;
    _activeUserId = currentUser?.id;
    if (_activeUserId != null) {
      loadConversations();
      _setupGlobalInboxSubscription(_activeUserId!);
    }
    _authSub = SupabaseService.instance.auth.onAuthStateChange.listen((data) {
      final newUserId = data.session?.user.id;
      if (data.event == AuthChangeEvent.signedOut || newUserId == null) {
        clear();
      } else if (newUserId != _activeUserId) {
        clear();
        _activeUserId = newUserId;
        loadConversations();
        _setupGlobalInboxSubscription(newUserId);
      }
    });
  }

  void _setupGlobalInboxSubscription(String userId) {
    _globalInboxSub?.unsubscribe();
    _globalInboxSub = SupabaseService.instance.subscribeToGlobalInbox(
      onNewMessage: _handleIncomingRealtimeMessage,
      onConversationUpdated: _handleConversationUpdated,
    );
  }

  void _handleIncomingRealtimeMessage(Map<String, dynamic> record) async {
    final senderId = record['sender_id']?.toString() ?? '';
    if (senderId == _activeUserId) return;

    final convId = record['conversation_id']?.toString() ?? '';
    final messageText = record['message_text']?.toString() ?? '';
    final messageId = record['id']?.toString() ?? '';
    if (convId.isEmpty) return;

    final currentActive = activeConversationId;
    final isCurrentRoom = currentActive != null &&
        (currentActive == convId || resolveConversationId(currentActive) == convId);
    if (isCurrentRoom) return;

    int convIdx = _conversations.indexWhere((c) => c.id == convId);
    ConversationModel? targetConv;
    if (convIdx != -1) {
      targetConv = _conversations[convIdx].copyWith(
        lastMessage: messageText,
        timestamp: 'Baru saja',
        unreadCount: _conversations[convIdx].unreadCount + 1,
        isSender: false,
      );
      _conversations.removeAt(convIdx);
      _conversations.insert(0, targetConv);
      notifyListeners();
    } else {
      targetConv = await getOrFetchConversation(convId);
      if (targetConv != null) {
        convIdx = _conversations.indexWhere((c) => c.id == convId);
        if (convIdx != -1) {
          _conversations[convIdx] = _conversations[convIdx].copyWith(
            unreadCount: _conversations[convIdx].unreadCount > 0 ? _conversations[convIdx].unreadCount : 1,
            lastMessage: messageText,
            timestamp: 'Baru saja',
            isSender: false,
          );
          notifyListeners();
        }
      }
    }

    final senderName = targetConv?.user.name.isNotEmpty == true
        ? targetConv!.user.name
        : (targetConv?.user.username.isNotEmpty == true ? '@${targetConv!.user.username}' : 'Pesan Masuk');

    GlobalNotificationService.instance.showDmBanner(
      messageId: messageId,
      conversationId: convId,
      senderName: senderName,
      messageText: messageText,
    );
  }

  void _handleConversationUpdated(Map<String, dynamic> record) {
    final convId = record['id']?.toString() ?? '';
    if (convId.isEmpty) return;
    final idx = _conversations.indexWhere((c) => c.id == convId);
    if (idx != -1) {
      final lastMsg = record['last_message']?.toString();
      if (lastMsg != null && lastMsg.isNotEmpty) {
        _conversations[idx] = _conversations[idx].copyWith(lastMessage: lastMsg, timestamp: 'Baru saja');
        notifyListeners();
      }
    }
  }

  Future<ConversationModel?> getOrFetchConversation(String conversationId) async {
    for (final conv in _conversations) {
      if (conv.id == conversationId) return conv;
    }
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) return null;
    try {
      final raw = await SupabaseService.instance.fetchConversationById(conversationId);
      if (raw != null) {
        final conv = ConversationModel.fromJson(raw, currentUser.id);
        _conversations.insert(0, conv);
        notifyListeners();
        return conv;
      }
    } catch (e) {
      debugPrint('Error getOrFetchConversation: $e');
    }
    return null;
  }

  void clear() {
    _globalInboxSub?.unsubscribe();
    _globalInboxSub = null;
    _migratedConversationIds.clear();
    _conversations.clear();
    _conversationMessages.clear();
    _activeUserId = null;
    _isFetchingConversations = false;
    notifyListeners();
  }

  List<ChatMessageModel> getMessages(String conversationId) => _conversationMessages[conversationId] ?? [];

  Future<void> loadConversations() async {
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) {
      if (_conversations.isNotEmpty || _conversationMessages.isNotEmpty) clear();
      return;
    }
    if (_isFetchingConversations) return;
    if (_activeUserId != null && _activeUserId != currentUser.id) clear();
    _activeUserId = currentUser.id;

    _isFetchingConversations = true;
    notifyListeners();
    try {
      final records = await SupabaseService.instance.fetchConversations();
      final liveList = records.map((r) => ConversationModel.fromJson(r, currentUser.id)).toList();
      _conversations..clear()..addAll(liveList);
    } catch (e) {
      debugPrint('Error loadConversations: $e');
    } finally {
      _isFetchingConversations = false;
      notifyListeners();
    }
  }

  Future<List<ChatMessageModel>> loadMessages(String conversationId) async {
    final currentUser = SupabaseService.instance.currentUser;
    final currentUserId = currentUser?.id ?? '';
    try {
      final records = await SupabaseService.instance.fetchMessages(conversationId);
      if (records.isNotEmpty) {
        final liveMessages = records.map((r) => ChatMessageModel.fromJson(r, currentUserId)).toList();
        _conversationMessages[conversationId] = liveMessages;
        notifyListeners();
        markAsRead(conversationId);
        return liveMessages;
      }
    } catch (e) {
      debugPrint('Error loadMessages from Supabase: $e');
    }
    return _conversationMessages[conversationId] ?? [];
  }

  Future<void> markAsRead(String conversationId) async {
    await SupabaseService.instance.markMessagesAsRead(conversationId);
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1 && _conversations[idx].unreadCount > 0) {
      _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
      notifyListeners();
    }
  }

  void updateConversationId({required String oldId, required String newId}) {
    if (oldId == newId) return;
    _migratedConversationIds[oldId] = newId;
    if (activeConversationId == oldId) activeConversationId = newId;

    final msgs = _conversationMessages.remove(oldId);
    if (msgs != null) {
      final existingNewMsgs = _conversationMessages[newId] ?? [];
      for (final m in msgs) {
        if (!existingNewMsgs.any((x) => x.id == m.id)) existingNewMsgs.add(m);
      }
      _conversationMessages[newId] = existingNewMsgs;
    }
    final idx = _conversations.indexWhere((c) => c.id == oldId);
    if (idx != -1) _conversations[idx] = _conversations[idx].copyWith(id: newId);
    notifyListeners();
  }

  void addOrUpdateConversation(ConversationModel conv) {
    final idx = _conversations.indexWhere((c) => c.id == conv.id || c.user.username == conv.user.username);
    if (idx != -1) {
      _conversations[idx] = conv;
    } else {
      _conversations.insert(0, conv);
    }
    notifyListeners();
  }

  void addMessage(String conversationId, ChatMessageModel msg, {ConversationModel? conversation}) {
    final msgs = _conversationMessages.putIfAbsent(conversationId, () => []);
    if (msg.isMe && !msg.id.startsWith('temp-')) {
      final tempIdx = msgs.lastIndexWhere((m) => m.id.startsWith('temp-') && m.text == msg.text);
      if (tempIdx != -1) {
        msgs[tempIdx] = msg;
      } else if (!msgs.any((m) => m.id == msg.id)) {
        msgs.add(msg);
      }
    } else if (!msgs.any((m) => m.id == msg.id)) {
      msgs.add(msg);
    }

    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(
        lastMessage: msg.text,
        timestamp: msg.timestamp,
        isSender: msg.isMe,
      );
    } else if (conversation != null) {
      _conversations.insert(0, conversation.copyWith(
        lastMessage: msg.text,
        timestamp: msg.timestamp,
        isSender: msg.isMe,
      ));
    }
    notifyListeners();
  }

  void updateMessage(String conversationId, ChatMessageModel updatedMsg) {
    final msgs = _conversationMessages[conversationId];
    if (msgs != null) {
      final idx = msgs.indexWhere((m) => m.id == updatedMsg.id);
      if (idx != -1) {
        msgs[idx] = updatedMsg;
        notifyListeners();
      }
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
    ConversationModel? conversation,
  }) async {
    final currentUser = SupabaseService.instance.currentUser;
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final tempMsg = ChatMessageModel(
      id: "temp-${now.millisecondsSinceEpoch}",
      senderId: currentUser?.id ?? "saya",
      text: text,
      timestamp: timeStr,
      isMe: true,
      status: MessageStatus.sending,
    );
    addMessage(conversationId, tempMsg, conversation: conversation);

    if (currentUser != null) {
      String targetConvId = conversationId;
      final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);

      if (!isUuid.hasMatch(targetConvId)) {
        String? targetUserId = conversation?.user.id;
        if (targetUserId == null && conversation != null) {
          final profile = await SupabaseService.instance.getProfileByUsername(conversation.user.username);
          targetUserId = profile?['id'] as String?;
        }
        if (targetUserId != null) {
          final realId = await SupabaseService.instance.getOrCreateConversation(
            otherUserId: targetUserId,
            productId: conversation?.productId,
          );
          if (realId != null) {
            updateConversationId(oldId: conversationId, newId: realId);
            targetConvId = realId;
          }
        }
      }

      try {
        final inserted = await SupabaseService.instance.sendDirectMessage(
          conversationId: targetConvId,
          text: text,
        );
        if (inserted != null) {
          final serverMsg = ChatMessageModel.fromJson(inserted, currentUser.id);
          addMessage(targetConvId, serverMsg, conversation: conversation);
        }
      } catch (e) {
        debugPrint('Error sending direct message to Supabase: $e');
      }
    }
  }
}
