import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _activeNis;
  RegisteredStudent? _verifiedStudent;
  Map<String, dynamic>? _statusData;

  @override
  void initState() {
    super.initState();
    _restoreLastNis();
  }

  @override
  void dispose() {
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
      final res = await SupabaseService.instance.auth.getPasswordResetStatus(nis);
      if (!mounted) return;
      setState(() {
        _statusData = res;
        _isLoadingStatus = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingStatus = false);
      SnapsToast.error(context, 'Gagal memuat status permintaan.', hasBottomNav: false);
    }
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

      await SupabaseService.instance.auth.submitPasswordResetRequest(
        nis: nis,
        fullName: name,
        classGroup: classGroup,
        notes: _notesController.text.trim(),
        deviceFcmToken: fcmToken,
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
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reset Kata Sandi',
          style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
      ),
      body: SafeArea(
        child: _isWaitingView ? _buildWaitingState() : _buildFormState(),
      ),
    );
  }

  Widget _buildFormState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ajukan Reset Sandi',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 4.0),
                const Text(
                  'Isi data diri sesuai absen sekolah.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.muted),
                ),
                const SizedBox(height: 20.0),
                StudentNisCombobox(
                  controller: _nisController,
                  verifiedStudent: _verifiedStudent,
                  onStudentSelected: (student) {
                    setState(() {
                      _verifiedStudent = student;
                      if (student != null) {
                        _nameController.text = student.fullName;
                        _classController.text = student.classGroup;
                      }
                    });
                  },
                ),
                const SizedBox(height: 14.0),
                AuthInputField(
                  label: 'Nama Lengkap',
                  hint: 'Nama sesuai absen sekolah',
                  prefixIcon: LucideIcons.user,
                  controller: _nameController,
                ),
                const SizedBox(height: 14.0),
                AuthInputField(
                  label: 'Kelas / Jurusan',
                  hint: 'Contoh: XI PPLG 1',
                  prefixIcon: LucideIcons.graduationCap,
                  controller: _classController,
                ),
                const SizedBox(height: 14.0),
                AuthInputField(
                  label: 'Catatan (Opsional)',
                  hint: 'Kendala tambahan jika ada',
                  prefixIcon: LucideIcons.messageSquare,
                  controller: _notesController,
                ),
                const SizedBox(height: 24.0),
                SizedBox(
                  width: double.infinity,
                  height: 50.0,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20.0, height: 20.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white))
                        : const Text('Kirim Permintaan', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingState() {
    if (_isLoadingStatus) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final status = _statusData?['status'] as String? ?? 'pending';
    final tempPassword = _statusData?['temp_password'] as String?;
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
          'Menunggu Verifikasi Admin',
          'Permintaan reset untuk NIS ${_activeNis ?? ''} sedang diproses. Kami akan mengirim notifikasi setelah selesai.'
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
                'Sandi sementara: $tempPassword',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w800, color: fg),
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
