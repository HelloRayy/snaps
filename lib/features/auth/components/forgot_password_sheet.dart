import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/auth/components/auth_text_field.dart';

/// Bottom sheet Lupa Password dalam ekosistem Snaps (Ajukan Reset & Cek Status).
class ForgotPasswordSheet extends StatefulWidget {
  const ForgotPasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (_) => const ForgotPasswordSheet(),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  int _tabIndex = 0; // 0 = Ajukan Reset, 1 = Cek Status
  final _nisController = TextEditingController();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _notesController = TextEditingController();
  final _checkNisController = TextEditingController();

  bool _isSubmitting = false;
  bool _isChecking = false;
  Map<String, dynamic>? _statusResult;
  bool _hasChecked = false;

  @override
  void dispose() {
    _nisController.dispose();
    _nameController.dispose();
    _classController.dispose();
    _notesController.dispose();
    _checkNisController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final nis = _nisController.text.trim();
    final name = _nameController.text.trim();
    final classGroup = _classController.text.trim();

    if (nis.isEmpty || name.isEmpty || classGroup.isEmpty) {
      SnapsToast.error(context, 'NIS, Nama Lengkap, dan Kelas wajib diisi.');
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

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      SnapsToast.success(context, 'Permintaan reset terkirim. Cek status secara berkala.');
      _checkNisController.text = nis;
      setState(() {
        _tabIndex = 1;
        _isSubmitting = false;
      });
      _checkStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      SnapsToast.error(context, msg);
    }
  }

  Future<void> _checkStatus() async {
    final nis = _checkNisController.text.trim();
    if (nis.isEmpty) {
      SnapsToast.error(context, 'Masukkan NIS untuk cek status.');
      return;
    }
    setState(() {
      _isChecking = true;
      _hasChecked = false;
    });
    try {
      final res = await SupabaseService.instance.auth.getPasswordResetStatus(nis);
      if (!mounted) return;
      setState(() {
        _statusResult = res;
        _hasChecked = true;
        _isChecking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isChecking = false);
      SnapsToast.error(context, 'Gagal memuat status permintaan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Bantuan Reset Kata Sandi',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 4.0),
            const Text(
              'Verifikasi data siswa untuk reset sandi oleh admin sekolah.',
              style: TextStyle(fontSize: 13.0, color: AppColors.muted),
            ),
            const SizedBox(height: 16.0),
            _buildTabSwitcher(),
            const SizedBox(height: 16.0),
            if (_tabIndex == 0) _buildRequestForm() else _buildStatusChecker(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'Ajukan Reset'),
          _buildTabButton(1, 'Cek Status'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _tabIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.ink : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Column(
      children: [
        AuthInputField(
          label: 'NIS',
          hint: 'Contoh: 23001',
          prefixIcon: LucideIcons.idCard,
          controller: _nisController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12.0),
        AuthInputField(
          label: 'Nama Lengkap',
          hint: 'Nama sesuai absen sekolah',
          prefixIcon: LucideIcons.user,
          controller: _nameController,
        ),
        const SizedBox(height: 12.0),
        AuthInputField(
          label: 'Kelas / Jurusan',
          hint: 'Contoh: XI PPLG 1',
          prefixIcon: LucideIcons.graduationCap,
          controller: _classController,
        ),
        const SizedBox(height: 12.0),
        AuthInputField(
          label: 'Catatan (Opsional)',
          hint: 'Kendala tambahan jika ada',
          prefixIcon: LucideIcons.messageSquare,
          controller: _notesController,
        ),
        const SizedBox(height: 18.0),
        SizedBox(
          width: double.infinity,
          height: 48.0,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20.0, height: 20.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white))
                : const Text('Kirim Permintaan', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChecker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthInputField(
          label: 'NIS',
          hint: 'Masukkan NIS kamu',
          prefixIcon: LucideIcons.search,
          controller: _checkNisController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _checkStatus(),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          width: double.infinity,
          height: 46.0,
          child: OutlinedButton(
            onPressed: _isChecking ? null : _checkStatus,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
            ),
            child: _isChecking
                ? const SizedBox(width: 18.0, height: 18.0, child: CircularProgressIndicator(strokeWidth: 2.0))
                : const Text('Cek Status Permintaan', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ),
        if (_hasChecked) ...[
          const SizedBox(height: 16.0),
          _buildStatusCard(),
        ],
      ],
    );
  }

  Widget _buildStatusCard() {
    if (_statusResult == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Belum ada permintaan reset untuk NIS ini.',
          style: TextStyle(fontSize: 13.0, color: AppColors.muted),
        ),
      );
    }

    final status = _statusResult!['status'] as String? ?? 'pending';
    final tempPassword = _statusResult!['temp_password'] as String?;
    final adminNote = _statusResult!['admin_note'] as String?;

    final (Color bg, Color fg, String title) = switch (status) {
      'approved' => (const Color(0xFFECFDF5), const Color(0xFF065F46), 'Disetujui Admin'),
      'rejected' => (const Color(0xFFFEF2F2), const Color(0xFF991B1B), 'Ditolak Admin'),
      _ => (const Color(0xFFFFFBEB), const Color(0xFF92400E), 'Menunggu Verifikasi Admin'),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w800, color: fg)),
          if (status == 'approved' && tempPassword != null && tempPassword.isNotEmpty) ...[
            const SizedBox(height: 6.0),
            Text('Sandi sementara: $tempPassword', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: fg)),
            const SizedBox(height: 2.0),
            Text('Segera login lalu ubah sandi di Edit Profil.', style: TextStyle(fontSize: 12.0, color: fg)),
          ],
          if (adminNote != null && adminNote.isNotEmpty) ...[
            const SizedBox(height: 6.0),
            Text('Catatan: $adminNote', style: TextStyle(fontSize: 12.5, color: fg)),
          ],
        ],
      ),
    );
  }
}
