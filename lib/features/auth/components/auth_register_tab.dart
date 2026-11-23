import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/services/student_registry_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/auth/components/auth_footer_switcher.dart';
import 'package:snapan_market/features/auth/components/auth_text_field.dart';
import 'package:snapan_market/features/auth/components/student_nis_combobox.dart';
import 'package:snapan_market/features/auth/models/auth_constants.dart';

class AuthRegisterTab extends StatelessWidget {
  final TextEditingController nisController;
  final String? nisError;
  final RegisteredStudent? verifiedStudent;
  final ValueChanged<RegisteredStudent?> onStudentSelected;

  final TextEditingController displayNameController;
  final String? displayNameError;
  final TextEditingController usernameController;
  final String? usernameError;
  final TextEditingController passwordController;
  final String? passwordError;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final bool agreedTerms;
  final VoidCallback onToggleAgreedTerms;
  final bool isSubmitting;
  final bool isGeneratingUsername;
  final bool isCheckingUsername;
  final bool isUsernameAvailable;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchToLogin;

  const AuthRegisterTab({
    super.key,
    required this.nisController,
    this.nisError,
    this.verifiedStudent,
    required this.onStudentSelected,
    required this.displayNameController,
    this.displayNameError,
    required this.usernameController,
    this.usernameError,
    required this.passwordController,
    this.passwordError,
    required this.showPassword,
    required this.onTogglePassword,
    required this.agreedTerms,
    required this.onToggleAgreedTerms,
    required this.isSubmitting,
    this.isGeneratingUsername = false,
    this.isCheckingUsername = false,
    this.isUsernameAvailable = false,
    required this.onSubmit,
    required this.onSwitchToLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. COMBOBOX NIS SISWA DENGAN FLOATING OVERLAY & BORDER HIJAU DINAMIS
        StudentNisCombobox(
          controller: nisController,
          errorText: nisError,
          verifiedStudent: verifiedStudent,
          onStudentSelected: onStudentSelected,
        ),
        const SizedBox(height: 16.0),

        // 2. DISPLAY NAME (OPSIONAL, MAX 20 KARAKTER)
        AuthInputField(
          label: 'Display Name (Opsional)',
          hint: 'Nama panggilan (3-20 karakter)',
          prefixIcon: LucideIcons.user,
          controller: displayNameController,
          errorText: displayNameError,
          maxLength: 20,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            LengthLimitingTextInputFormatter(20),
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
        ),
        const SizedBox(height: 16.0),

        // 3. USERNAME @ (AUTO SUGGEST DARI NAMA DEPAN + TENGAH DENGAN LOADING SPINNER)
        AuthInputField(
          label: isGeneratingUsername ? 'Memilih username...' : 'Username',
          hint: isGeneratingUsername ? 'Menyiapkan rekomendasi...' : '@username (3-20 karakter)',
          prefixIcon: LucideIcons.atSign,
          controller: usernameController,
          errorText: usernameError,
          customSuffixIcon: (isGeneratingUsername || isCheckingUsername)
              ? const Padding(
                  padding: EdgeInsets.only(right: 14.0),
                  child: SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                )
              : (isUsernameAvailable &&
                      usernameError == null &&
                      usernameController.text.trim().length >= 3)
                  ? const Padding(
                      padding: EdgeInsets.only(right: 14.0),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18.0,
                        color: Color(0xFF10B981),
                      ),
                    )
                  : null,
          maxLength: 20,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            LengthLimitingTextInputFormatter(20),
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(text: newValue.text.toLowerCase());
            }),
          ],
        ),
        const SizedBox(height: 16.0),

        // 4. KATA SANDI
        AuthInputField(
          label: 'Kata Sandi',
          hint: 'Minimal 6 karakter',
          prefixIcon: LucideIcons.lock,
          controller: passwordController,
          isPassword: true,
          showPassword: showPassword,
          onTogglePassword: onTogglePassword,
          errorText: passwordError,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 16.0),

        // 5. PERSETUJUAN KETENTUAN
        _buildRegisterTermsRow(),
        const SizedBox(height: 22.0),

        // 6. TOMBOL AKSI DAFTAR (Fixed di bawah form, scrollable)
        ListenableBuilder(
          listenable: Listenable.merge([
            nisController,
            displayNameController,
            usernameController,
            passwordController,
          ]),
          builder: (context, _) {
            final rawDisplayName = displayNameController.text.trim();
            final bool isDisplayNameValid = rawDisplayName.isEmpty ||
                (rawDisplayName.length >= 3 &&
                    rawDisplayName.length <= 20 &&
                    !AuthConstants.isProfane(rawDisplayName));
            final cleanUsername = usernameController.text.trim().toLowerCase().replaceAll('@', '');
            final bool isUsernameValid = cleanUsername.length >= 3 &&
                cleanUsername.length <= 20 &&
                !AuthConstants.isReservedUsername(cleanUsername) &&
                !AuthConstants.isProfane(cleanUsername) &&
                usernameError == null;
            final bool isFormValid = verifiedStudent != null &&
                nisController.text.trim().isNotEmpty &&
                isUsernameValid &&
                passwordController.text.length >= 6 &&
                agreedTerms &&
                isDisplayNameValid &&
                displayNameError == null;
            return PrimaryAuthButton(
              text: 'Aktifkan Akun & Masuk',
              isLoading: isSubmitting,
              isEnabled: isFormValid,
              onPressed: onSubmit,
            );
          },
        ),
        const SizedBox(height: 16.0),

        // 7. FOOTER SWITCHER (Kembali ke Masuk Akun)
        AuthFooterSwitcher(
          isLogin: false,
          onSwitch: onSwitchToLogin,
        ),
      ],
    );
  }

  Widget _buildRegisterTermsRow() {
    return GestureDetector(
      onTap: () {
        onToggleAgreedTerms();
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 20.0,
            height: 20.0,
            decoration: BoxDecoration(
              color: agreedTerms ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(
                color: agreedTerms ? AppColors.primary : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
            ),
            child: agreedTerms
                ? const Icon(Icons.check_rounded, size: 14.0, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10.0),
          const Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Saya menyetujui ',
                style: TextStyle(
                  fontSize: 13.0,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  TextSpan(
                    text: 'Ketentuan Komunitas & Privasi SMKN 8',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
