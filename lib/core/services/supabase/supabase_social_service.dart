import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSocialService {
  SupabaseSocialService(this._client);
  final SupabaseClient _client;

  User? get _currentUser => _client.auth.currentUser;

  /// Fetch notifications for current user
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final user = _currentUser;
    if (user == null) return [];

    try {
      // Coba fetch dengan left outer join actor profile
      try {
        final response = await _client
            .from('notifications')
            .select('*, actor:profiles!actor_id(*)')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(40);
        return (response as List<dynamic>).whereType<Map<String, dynamic>>().toList();
      } catch (_) {
        // Fallback jika foreign key join ketat gagal karena actor_id bernilai null (pengumuman sistem)
        final response = await _client
            .from('notifications')
            .select('*')
            .eq('user_id', user.id)
            .order('created_at', ascending: false)
            .limit(40);
        return (response as List<dynamic>).whereType<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      debugPrint('Error fetchNotifications: $e');
      return [];
    }
  }

  /// Count unread notifications for current user
  Future<int> getUnreadNotificationsCount() async {
    final user = _currentUser;
    if (user == null) return 0;

    try {
      final res = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false);
      return (res as List).length;
    } catch (e) {
      debugPrint('Error getUnreadNotificationsCount: $e');
      return 0;
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markNotificationsAsRead() async {
    final user = _currentUser;
    if (user == null) return;

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('Error markNotificationsAsRead: $e');
    }
  }

  /// Mark a single notification as read
  Future<void> markSingleNotificationAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error markSingleNotificationAsRead: $e');
    }
  }

  /// Realtime channel subscription for user's notifications
  RealtimeChannel subscribeToNotifications(void Function(Map<String, dynamic> record) onNewNotification) {
    final user = _currentUser;
    final userId = user?.id ?? '';
    final channelName = 'public:notifications:$userId';

    return _client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            if (newRecord.isNotEmpty) {
              onNewNotification(newRecord);
            }
          },
        )
        .subscribe();
  }

  /// Fetch all followings for the authenticated user
  Future<List<Map<String, dynamic>>> fetchFollowings() async {
    final user = _currentUser;
    if (user == null) return [];
    try {
      final res = await _client
          .from('user_follows')
          .select('following_id, following:profiles!user_follows_following_id_fkey(id, username)')
          .eq('follower_id', user.id);
      return (res as List<dynamic>).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error fetchFollowings with join: $e');
      try {
        final resSimple = await _client
            .from('user_follows')
            .select('following_id')
            .eq('follower_id', user.id);
        return (resSimple as List<dynamic>).whereType<Map<String, dynamic>>().toList();
      } catch (e2) {
        debugPrint('Error fetchFollowings fallback: $e2');
        return [];
      }
    }
  }

  /// Follow a target user
  Future<bool> followUser(String targetUserId) async {
    final user = _currentUser;
    if (user == null || user.id == targetUserId) return false;
    try {
      await _client.from('user_follows').insert({
        'follower_id': user.id,
        'following_id': targetUserId,
      });

      // Send in-app notification to target user
      try {
        await _client.from('notifications').insert({
          'user_id': targetUserId,
          'actor_id': user.id,
          'type': 'follow',
          'message': 'mulai mengikuti profil Anda.',
        });
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Error followUser: $e');
      return false;
    }
  }

  /// Unfollow a target user
  Future<bool> unfollowUser(String targetUserId) async {
    final user = _currentUser;
    if (user == null) return false;
    try {
      await _client
          .from('user_follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId);
      return true;
    } catch (e) {
      debugPrint('Error unfollowUser: $e');
      return false;
    }
  }

  /// Get exact follower count for a user from public.user_follows
  Future<int> getFollowersCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final int count = await _client
          .from('user_follows')
          .count(CountOption.exact)
          .eq('following_id', userId);
      return count;
    } catch (e) {
      debugPrint('Error getFollowersCount: $e');
      try {
        final res = await _client
            .from('user_follows')
            .select('follower_id')
            .eq('following_id', userId);
        return (res as List).length;
      } catch (e2) {
        debugPrint('Error getFollowersCount fallback: $e2');
        return 0;
      }
    }
  }

  /// Get exact following count for a user from public.user_follows
  Future<int> getFollowingCount(String userId) async {
    if (userId.isEmpty) return 0;
    try {
      final int count = await _client
          .from('user_follows')
          .count(CountOption.exact)
          .eq('follower_id', userId);
      return count;
    } catch (e) {
      debugPrint('Error getFollowingCount: $e');
      try {
        final res = await _client
            .from('user_follows')
            .select('following_id')
            .eq('follower_id', userId);
        return (res as List).length;
      } catch (e2) {
        debugPrint('Error getFollowingCount fallback: $e2');
        return 0;
      }
    }
  }

  /// Fetch up to [limit] follower profiles for facepile avatar stack.
  /// If [currentUserId] is provided and distinct from [targetUserId],
  /// mutual connections (followers also followed by current user) are prioritized first.
  Future<List<Map<String, dynamic>>> fetchProfileFollowerAvatars({
    required String targetUserId,
    String? currentUserId,
    int limit = 3,
  }) async {
    if (targetUserId.isEmpty || limit <= 0) return [];

    try {
      final isOwnOrGuest = currentUserId == null ||
          currentUserId.isEmpty ||
          currentUserId == targetUserId;

      if (isOwnOrGuest) {
        return await _fetchRecentFollowerProfiles(targetUserId, limit: limit);
      }

      // Skenario 2: Melihat profil pengguna lain saat login
      // 1. Ambil ID pengguna yang diikuti oleh currentUserId
      final myFollowingRes = await _client
          .from('user_follows')
          .select('following_id')
          .eq('follower_id', currentUserId);

      final myFollowingIds = (myFollowingRes as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['following_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet();

      final List<Map<String, dynamic>> results = [];

      // 2. Query pengikut targetUserId yang juga ada di myFollowingIds (mutual follows)
      if (myFollowingIds.isNotEmpty) {
        try {
          final mutualRes = await _client
              .from('user_follows')
              .select('follower_id, created_at, follower:profiles!user_follows_follower_id_fkey(id, username, display_name, full_name, avatar_url)')
              .eq('following_id', targetUserId)
              .inFilter('follower_id', myFollowingIds.toList())
              .order('created_at', ascending: false)
              .limit(limit);

          for (final row in (mutualRes as List<dynamic>)) {
            if (row is Map<String, dynamic>) {
              final profile = _extractProfile(row);
              if (profile != null) {
                profile['is_mutual'] = true;
                results.add(profile);
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching mutual followers join: $e');
          try {
            final mutualSimple = await _client
                .from('user_follows')
                .select('follower_id')
                .eq('following_id', targetUserId)
                .inFilter('follower_id', myFollowingIds.toList())
                .order('created_at', ascending: false)
                .limit(limit);

            final mutualIds = (mutualSimple as List<dynamic>)
                .map((r) => (r as Map<String, dynamic>)['follower_id']?.toString())
                .whereType<String>()
                .toList();

            if (mutualIds.isNotEmpty) {
              final pRes = await _client
                  .from('profiles')
                  .select('id, username, display_name, full_name, avatar_url')
                  .inFilter('id', mutualIds);

              for (final p in (pRes as List<dynamic>)) {
                if (p is Map<String, dynamic>) {
                  results.add({
                    'id': p['id']?.toString() ?? '',
                    'username': p['username']?.toString() ?? '',
                    'display_name': p['display_name'] ?? p['full_name'],
                    'avatar_url': p['avatar_url'] as String?,
                    'is_mutual': true,
                  });
                }
              }
            }
          } catch (e2) {
            debugPrint('Error fetching mutual followers fallback: $e2');
          }
        }
      }

      // 3. Jika mutual < limit, lengkapi sisa slot dengan pengikut terbaru non-mutual
      if (results.length < limit) {
        final existingIds = results.map((r) => r['id']?.toString()).whereType<String>().toSet();
        final needed = limit - results.length;

        try {
          final recentRes = await _client
              .from('user_follows')
              .select('follower_id, created_at, follower:profiles!user_follows_follower_id_fkey(id, username, display_name, full_name, avatar_url)')
              .eq('following_id', targetUserId)
              .order('created_at', ascending: false)
              .limit(limit + existingIds.length);

          for (final row in (recentRes as List<dynamic>)) {
            if (row is Map<String, dynamic>) {
              final profile = _extractProfile(row);
              if (profile != null) {
                final id = profile['id']?.toString();
                if (id != null && !existingIds.contains(id)) {
                  existingIds.add(id);
                  profile['is_mutual'] = false;
                  results.add(profile);
                  if (results.length >= limit) break;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching non-mutual followers join: $e');
          try {
            final recentSimple = await _client
                .from('user_follows')
                .select('follower_id')
                .eq('following_id', targetUserId)
                .order('created_at', ascending: false)
                .limit(limit + existingIds.length);

            final nonMutualIds = (recentSimple as List<dynamic>)
                .map((r) => (r as Map<String, dynamic>)['follower_id']?.toString())
                .whereType<String>()
                .where((id) => !existingIds.contains(id))
                .take(needed)
                .toList();

            if (nonMutualIds.isNotEmpty) {
              final pRes = await _client
                  .from('profiles')
                  .select('id, username, display_name, full_name, avatar_url')
                  .inFilter('id', nonMutualIds);

              for (final p in (pRes as List<dynamic>)) {
                if (p is Map<String, dynamic>) {
                  results.add({
                    'id': p['id']?.toString() ?? '',
                    'username': p['username']?.toString() ?? '',
                    'display_name': p['display_name'] ?? p['full_name'],
                    'avatar_url': p['avatar_url'] as String?,
                    'is_mutual': false,
                  });
                }
              }
            }
          } catch (e2) {
            debugPrint('Error fetching non-mutual followers fallback: $e2');
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error fetchProfileFollowerAvatars: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRecentFollowerProfiles(
    String targetUserId, {
    required int limit,
  }) async {
    try {
      final res = await _client
          .from('user_follows')
          .select('follower_id, created_at, follower:profiles!user_follows_follower_id_fkey(id, username, display_name, full_name, avatar_url)')
          .eq('following_id', targetUserId)
          .order('created_at', ascending: false)
          .limit(limit);

      final List<Map<String, dynamic>> list = [];
      for (final row in (res as List<dynamic>)) {
        if (row is Map<String, dynamic>) {
          final profile = _extractProfile(row);
          if (profile != null) {
            profile['is_mutual'] = false;
            list.add(profile);
          }
        }
      }
      return list;
    } catch (e) {
      debugPrint('Error _fetchRecentFollowerProfiles join: $e');
      try {
        final resSimple = await _client
            .from('user_follows')
            .select('follower_id')
            .eq('following_id', targetUserId)
            .order('created_at', ascending: false)
            .limit(limit);

        final followerIds = (resSimple as List<dynamic>)
            .map((r) => (r as Map<String, dynamic>)['follower_id']?.toString())
            .whereType<String>()
            .toList();

        if (followerIds.isEmpty) return [];

        final profilesRes = await _client
            .from('profiles')
            .select('id, username, display_name, full_name, avatar_url')
            .inFilter('id', followerIds);

        final Map<String, Map<String, dynamic>> profileMap = {};
        for (final p in (profilesRes as List<dynamic>)) {
          if (p is Map<String, dynamic> && p['id'] != null) {
            profileMap[p['id'].toString()] = Map<String, dynamic>.from(p);
          }
        }

        final List<Map<String, dynamic>> list = [];
        for (final id in followerIds) {
          if (profileMap.containsKey(id)) {
            final p = profileMap[id]!;
            list.add({
              'id': p['id'],
              'username': p['username'] ?? '',
              'display_name': p['display_name'] ?? p['full_name'],
              'avatar_url': p['avatar_url'],
              'is_mutual': false,
            });
          }
        }
        return list;
      } catch (e2) {
        debugPrint('Error _fetchRecentFollowerProfiles fallback: $e2');
        return [];
      }
    }
  }

  Map<String, dynamic>? _extractProfile(Map<String, dynamic> row) {
    if (row['follower'] is Map<String, dynamic>) {
      final f = Map<String, dynamic>.from(row['follower'] as Map<String, dynamic>);
      return {
        'id': f['id']?.toString() ?? row['follower_id']?.toString() ?? '',
        'username': f['username']?.toString() ?? '',
        'display_name': f['display_name'] ?? f['full_name'],
        'avatar_url': f['avatar_url'] as String?,
      };
    }
    return null;
  }

  /// Subscribe to realtime changes on user_follows for a specific user
  RealtimeChannel subscribeToFollowers(String userId, void Function() onFollowChange) {
    return _client
        .channel('public:user_follows:following:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_follows',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'following_id',
            value: userId,
          ),
          callback: (payload) {
            onFollowChange();
          },
        )
        .subscribe();
  }

  /// Save FCM Device Token for Push Notifications
  Future<void> saveFcmToken(String token) async {
    final user = _currentUser;
    if (user == null) {
      debugPrint('[FCM] saveFcmToken ditunda: Pengguna belum login (currentUser null)');
      throw StateError('Pengguna belum login ke akun');
    }
    if (token.isEmpty) {
      throw ArgumentError('Token FCM tidak boleh kosong');
    }

    try {
      await _client.from('user_fcm_tokens').upsert(
        {
          'user_id': user.id,
          'fcm_token': token,
          'device_info': 'Android',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
      debugPrint('[FCM] ✅ Berhasil mendaftarkan FCM Token untuk user ${user.id} ke tabel user_fcm_tokens');
    } catch (e) {
      debugPrint('[FCM] ❌ Gagal menyimpan FCM Token ke tabel user_fcm_tokens: $e');
      rethrow;
    }
  }
}
