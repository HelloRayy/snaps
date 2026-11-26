import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snapan_market/core/components/snaps_logo.dart';
import 'package:snapan_market/core/services/device_security_service.dart';
import 'package:snapan_market/core/services/student_registry_service.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/auth/components/auth_text_field.dart';
import 'package:snapan_market/features/auth/components/student_nis_combobox.dart';

/// Halaman tunggal Reset Kata Sandi dengan dialog pengantar & waiting state.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const String _lastNisKey = 'last_password_reset_nis';

  /// Tampilkan overlay popup pengantar sebelum masuk ke halaman single page.
  static Future<void> showIntroDialog(BuildContext context) async {
    HapticFeedback.lightImpact();
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52.0,
                height: 52.0,
                decoration: BoxDecoration(
                  color: AppColors.primaryPastel,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: const Icon(LucideIcons.keyRound, color: AppColors.primary, size: 26.0),
              ),
              const SizedBox(height: 14.0),
              const Text(
                'Lupa Kata Sandi?',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Siapkan NIS, nama lengkap, dan kelas untuk verifikasi admin sekolah.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46.0),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                      ),
                      child: const Text(
                        'Batal',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.slateInk),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46.0),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                      ),
                      child: const Text(
                        'Lanjut',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (proceed == true && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
      );
    }
  }

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _nisController = TextEditingController();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingStatus = false;
  bool _isWaitingView = false;
  bool _agreedOwnership = false;
  String? _activeNis;
  String? _currentDeviceToken;
  RegisteredStudent? _verifiedStudent;
  Map<String, dynamic>? _statusData;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _restoreLastNis();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _nisController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _restoreLastNis() async {
    final prefs = await SharedPreferences.getInstance();
    final savedNis = prefs.getString(ForgotPasswordScreen._lastNisKey);
    if (savedNis != null && savedNis.isNotEmpty && mounted) {
      _activeNis = savedNis;
      _fetchStatus(savedNis);
    }
  }

  Future<void> _fetchStatus(String nis) async {
    setState(() {
      _isLoadingStatus = true;
      _isWaitingView = true;
    });
    try {
      try {
        _currentDeviceToken ??= await FirebaseMessaging.instance.getToken();
      } catch (_) {}
      final res = await SupabaseService.instance.auth.getPasswordResetStatus(nis);
      if (!mounted) return;
      setState(() {
        _statusData = res;
        _isLoadingStatus = false;
      });
      if ((res?['status'] as String?) == 'pending') {
        _subscribeRealtime(nis);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingStatus = false);
      SnapsToast.error(context, 'Gagal memuat status permintaan.', hasBottomNav: false);
    }
  }

  void _subscribeRealtime(String nis) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = Supabase.instance.client
        .channel('password_reset_$nis')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'password_reset_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'nis',
            value: nis,
          ),
          callback: (payload) {
            if (!mounted) return;
            HapticFeedback.mediumImpact();
            setState(() {
              _statusData = payload.newRecord;
            });
          },
        )
        .subscribe();
  }

  Future<void> _submit() async {
    final nis = _nisController.text.trim();
    final name = _nameController.text.trim();
    final classGroup = _classController.text.trim();

    if (nis.isEmpty || name.isEmpty || classGroup.isEmpty) {
      SnapsToast.error(context, 'NIS, Nama Lengkap, dan Kelas wajib diisi.', hasBottomNav: false);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {}
      final deviceName = await DeviceSecurityService.instance.getDeviceName();

      await SupabaseService.instance.auth.submitPasswordResetRequest(
        nis: nis,
        fullName: name,
        classGroup: classGroup,
        notes: _notesController.text.trim(),
        deviceFcmToken: fcmToken,
        deviceName: deviceName,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ForgotPasswordScreen._lastNisKey, nis);

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      _activeNis = nis;
      setState(() => _isSubmitting = false);
      _fetchStatus(nis);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      SnapsToast.error(context, e.toString().replaceFirst('Exception: ', ''), hasBottomNav: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            _isWaitingView ? _buildWaitingState() : _buildFormState(),
            Positioned(
              top: 12.0,
              left: 16.0,
              child: Material(
                color: const Color(0xFFF1F5F9),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 42.0,
                    height: 42.0,
                    child: Icon(CupertinoIcons.chevron_back, color: AppColors.ink, size: 20.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState() {
    final canSubmit = _verifiedStudent != null && _agreedOwnership && !_isSubmitting;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20.0, 68.0, 20.0, 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: SnapsLogo(height: 28.0)),
                const SizedBox(height: 16.0),
                const Text(
                  'Reset Kata Sandi',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 6.0),
                const Text(
                  'Masukkan NIS sekolahmu untuk mengajukan pemulihan kata sandi ke admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 24.0),
                StudentNisCombobox(
                  controller: _nisController,
                  verifiedStudent: _verifiedStudent,
                  allowClaimed: true,
                  onStudentSelected: (student) {
                    setState(() {
                      _verifiedStudent = student;
                      if (student != null) {
                        _nameController.text = student.name;
                        _classController.text = student.classGroup;
                      }
                    });
                  },
                ),
                if (_verifiedStudent != null) ...[
                  const SizedBox(height: 10.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPastel,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.userCheck, size: 16.0, color: AppColors.primary),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${_verifiedStudent!.name} • ${_verifiedStudent!.classGroup}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16.0),
                const Text(
                  'Alasan Lupa Kata Sandi (Opsional)',
                  style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600, color: AppColors.slateInk),
                ),
                const SizedBox(height: 6.0),
                TextField(
                  controller: _notesController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ceritakan singkat kenapa lupa sandi...',
                    hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.lightMuted),
                    filled: true,
                    fillColor: AppColors.inputBg,
                    contentPadding: const EdgeInsets.all(14.0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14.0),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _agreedOwnership = !_agreedOwnership);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 20.0,
                        height: 20.0,
                        margin: const EdgeInsets.only(top: 2.0),
                        decoration: BoxDecoration(
                          color: _agreedOwnership ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: _agreedOwnership ? AppColors.primary : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: _agreedOwnership
                            ? const Icon(LucideIcons.check, size: 14.0, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10.0),
                      const Expanded(
                        child: Text(
                          'Saya menyatakan bahwa NIS ini adalah akun milik saya sendiri.',
                          style: TextStyle(fontSize: 13.0, color: AppColors.slateInk, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50.0,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999.0)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20.0, height: 20.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white))
                  : const Text('Kirim Permintaan', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    if (_isLoadingStatus) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final status = _statusData?['status'] as String? ?? 'pending';
    final tempPassword = _statusData?['temp_password'] as String?;
    final requestToken = _statusData?['device_fcm_token'] as String?;
    final isSameDevice = requestToken == null || requestToken.isEmpty || requestToken == _currentDeviceToken;
    final adminNote = _statusData?['admin_note'] as String?;

    final (IconData icon, Color bg, Color fg, String title, String desc) = switch (status) {
      'approved' => (
          LucideIcons.circleCheck,
          const Color(0xFFECFDF5),
          const Color(0xFF065F46),
          'Permintaan Disetujui',
          'Admin sudah mereset kata sandi akun kamu. Gunakan sandi sementara di bawah lalu segera ubah di Edit Profil.'
        ),
      'rejected' => (
          LucideIcons.circleX,
          const Color(0xFFFEF2F2),
          const Color(0xFF991B1B),
          'Permintaan Ditolak',
          'Data tidak sesuai atau perlu verifikasi ulang.'
        ),
      _ => (
          LucideIcons.clock,
          const Color(0xFFFFFBEB),
          const Color(0xFF92400E),
          'Permintaan Sedang Ditinjau',
          'Admin sekolah sedang memeriksa data kamu. Layar ini akan otomatis terbarui begitu disetujui.'
        ),
    };

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72.0,
            height: 72.0,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24.0)),
            child: Icon(icon, size: 34.0, color: fg),
          ),
          const SizedBox(height: 18.0),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19.0, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8.0),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.5)),
          if (status == 'approved' && tempPassword != null && tempPassword.isNotEmpty) ...[
            const SizedBox(height: 18.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14.0)),
              child: Text(
                isSameDevice
                    ? 'Sandi sementara: $tempPassword'
                    : 'Terdeteksi perangkat berbeda. Gunakan HP yang sama saat mengajukan atau hubungi admin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: isSameDevice ? 15.0 : 13.0, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ],
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            Text('Catatan admin: $adminNote', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.0, color: fg)),
          ],
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            height: 48.0,
            child: ElevatedButton(
              onPressed: _activeNis == null ? null : () => _fetchStatus(_activeNis!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
              ),
              child: const Text('Refresh Status', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 10.0),
          TextButton(
            onPressed: () => setState(() => _isWaitingView = false),
            child: const Text('Ajukan dengan NIS lain', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
