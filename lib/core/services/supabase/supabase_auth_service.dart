import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snapan_market/core/constants/supabase_constants.dart';
import 'package:snapan_market/core/services/follow_service.dart';
import 'package:snapan_market/core/services/poll_sync_service.dart';
import 'package:snapan_market/features/messages/services/direct_messages_service.dart';

class SupabaseAuthService {
  SupabaseAuthService(this._client);
  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  bool? _isAdminCache;
  String? _isAdminCachedUserId;

  /// Trigger Google OAuth flow via deep link
  Future<bool> signInWithGoogle() async {
    try {
      final success = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${SupabaseConstants.authCallbackUrlScheme}://login-callback',
      );
      return success;
    } catch (e) {
      debugPrint('Error signInWithGoogle: $e');
      rethrow;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _isAdminCache = null;
      _isAdminCachedUserId = null;
      PollSyncService.instance.clear();
      DirectMessagesService.instance.clear();
      FollowService.instance.clear();
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error signOut: $e');
      rethrow;
    }
  }

  /// Check if the currently logged-in user has an admin role
  Future<bool> isCurrentUserAdmin() async {
    final user = currentUser;
    if (user == null) return false;
    if (_isAdminCachedUserId == user.id && _isAdminCache != null) {
      return _isAdminCache!;
    }

    try {
      final res = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      final role = res?['role'] as String?;
      _isAdminCache = role == 'admin';
      _isAdminCachedUserId = user.id;
      return _isAdminCache!;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if the currently logged-in user is suspended (SNAPS-16)
  Future<Map<String, dynamic>?> getCurrentUserSuspensionStatus() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res = await _client
          .from('profiles')
          .select('id, full_name, username, avatar_url, class_group, role, is_suspended, suspended_at, suspended_until, suspend_reason')
          .eq('id', user.id)
          .maybeSingle();

      if (res == null) return null;
      final isSuspended = res['is_suspended'] == true;
      if (!isSuspended) return null;

      final suspendedUntilStr = res['suspended_until'] as String?;
      if (suspendedUntilStr != null) {
        final until = DateTime.tryParse(suspendedUntilStr);
        if (until != null && DateTime.now().toUtc().isAfter(until.toUtc())) {
          return null; // Durasi suspen telah usai
        }
      }

      return res;
    } catch (e) {
      debugPrint('Error checking suspension status: $e');
      return null;
    }
  }

  /// Memeriksa status kesehatan akun aktif saat app startup atau resume:
  /// - 'unauthenticated': Tidak ada sesi aktif
  /// - 'deleted': Token sesi ada di perangkat, tetapi profil di database sudah dihapus oleh admin
  /// - 'suspended': Akun sedang ditangguhkan
  /// - 'active': Akun valid dan aktif normal
  Future<Map<String, dynamic>?> checkCurrentUserAccountHealth() async {
    final user = currentUser;
    if (user == null) return {'status': 'unauthenticated'};

    try {
      final res = await _client
          .from('profiles')
          .select('id, full_name, username, avatar_url, class_group, role, is_suspended, suspended_at, suspended_until, suspend_reason')
          .eq('id', user.id)
          .maybeSingle();

      if (res == null) {
        // Baris profil tidak ditemukan di database -> Akun telah dihapus oleh admin
        return {'status': 'deleted'};
      }

      final isSuspended = res['is_suspended'] == true;
      if (isSuspended) {
        final suspendedUntilStr = res['suspended_until'] as String?;
        if (suspendedUntilStr != null) {
          final until = DateTime.tryParse(suspendedUntilStr);
          if (until != null && DateTime.now().toUtc().isAfter(until.toUtc())) {
            return {'status': 'active', 'profile': res}; // Durasi suspen telah usai
          }
        }
        return {'status': 'suspended', 'data': res};
      }

      return {'status': 'active', 'profile': res};
    } catch (e) {
      debugPrint('Error checkCurrentUserAccountHealth: $e');
      return null;
    }
  }

  /// Ajukan permintaan reset password ke admin tanpa keluar dari aplikasi.
  Future<void> submitPasswordResetRequest({
    required String nis,
    required String fullName,
    required String classGroup,
    String? notes,
    String? deviceFcmToken,
  }) async {
    final cleanNis = nis.trim();
    final existing = await _client
        .from('password_reset_requests')
        .select('id')
        .eq('nis', cleanNis)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      throw Exception('Permintaan reset untuk NIS ini masih menunggu verifikasi admin.');
    }

    await _client.from('password_reset_requests').insert({
      'nis': cleanNis,
      'full_name': fullName.trim(),
      'class_group': classGroup.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      if (deviceFcmToken != null && deviceFcmToken.isNotEmpty) 'device_fcm_token': deviceFcmToken,
      'status': 'pending',
    });
  }

  /// Cek status permintaan reset password terbaru berdasarkan NIS.
  Future<Map<String, dynamic>?> getPasswordResetStatus(String nis) async {
    final cleanNis = nis.trim();
    if (cleanNis.isEmpty) return null;
    return await _client
        .from('password_reset_requests')
        .select('id, nis, full_name, class_group, status, temp_password, admin_note, created_at, updated_at')
        .eq('nis', cleanNis)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// Ubah kata sandi pengguna yang sedang login.
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
