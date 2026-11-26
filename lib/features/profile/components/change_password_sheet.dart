import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/utils/snaps_toast.dart';
import 'package:snapan_market/features/auth/components/auth_text_field.dart';

/// Bottom sheet untuk mengganti kata sandi siswa yang sedang login.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPass = _newPassController.text;
    final confirmPass = _confirmPassController.text;

    if (newPass.length < 6) {
      SnapsToast.error(context, 'Kata sandi minimal 6 karakter.', hasBottomNav: false);
      return;
    }
    if (newPass != confirmPass) {
      SnapsToast.error(context, 'Konfirmasi kata sandi tidak cocok.', hasBottomNav: false);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await SupabaseService.instance.auth.updatePassword(newPass);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      SnapsToast.success(context, 'Kata sandi berhasil diperbarui.', hasBottomNav: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnapsToast.error(context, 'Gagal memperbarui kata sandi.', hasBottomNav: false);
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
              'Ubah Kata Sandi',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 4.0),
            const Text(
              'Gunakan minimal 6 karakter agar akun tetap aman.',
              style: TextStyle(fontSize: 13.0, color: AppColors.muted),
            ),
            const SizedBox(height: 16.0),
            AuthInputField(
              label: 'Kata Sandi Baru',
              hint: 'Minimal 6 karakter',
              prefixIcon: LucideIcons.lock,
              controller: _newPassController,
              isPassword: true,
              showPassword: _showNew,
              onTogglePassword: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 12.0),
            AuthInputField(
              label: 'Konfirmasi Kata Sandi',
              hint: 'Ulangi kata sandi baru',
              prefixIcon: LucideIcons.shieldCheck,
              controller: _confirmPassController,
              isPassword: true,
              showPassword: _showConfirm,
              onTogglePassword: () => setState(() => _showConfirm = !_showConfirm),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 18.0),
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20.0, height: 20.0, child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white))
                    : const Text('Simpan Kata Sandi', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
