# Sanitasi Input Auth: Display Name & Username (Karakter, Simbol, & 5 Solusi Best Practices)

> **Dokumen Spesifikasi Teknis & Pendekatan Arsitektur**
> - **Tanggal**: 2026-10-29
> - **Domain**: `auth / input_formatters / sanitization / security / validation`
> - **Status**: Planned (Approaching)

---

## 1. Analisis Kebutuhan: Tanpa Simbol & Tanpa Spasi

- **Display Name**:
  - Batasan: Murni alfanumerik `[a-zA-Z0-9]`, tanpa simbol dan tanpa spasi.
  - Panjang: Opsional. Boleh kosong, jika diisi wajib **3–20 karakter**.
- **Username**:
  - Batasan: Murni alfanumerik `[a-zA-Z0-9]`, tanpa simbol (`.` dan `_` ditutup) dan tanpa spasi.
  - Panjang: Wajib diisi, **3–20 karakter**, otomatis dipaksa huruf kecil (*lowercase*).

---

## 2. Rincian Teknis 5 Solusi Best Practices Kompetitor

Kelima solusi standar industri diterapkan secara terintegrasi pada arsitektur validasi registrasi Snapan:

### Solusi 1: Pemblokiran Kata Terlarang (Reserved Words Engine)
- **Mekanisme**: Memvalidasi input terhadap daftar hitam nama sistem resmi (`AuthConstants.reservedUsernames`).
- **Daftar Kata Terlarang**:
  `admin`, `administrator`, `root`, `snaps`, `snapan`, `official`, `support`, `system`, `moderator`, `help`, `superuser`, `operator`.
- **Feedback**: Jika cocok, langsung tampilkan error: `"Username ini dilindungi dan tidak dapat digunakan"`.

### Solusi 2: Pencegahan Karakter Tak Terlihat (Zero-Width & Invisible Characters)
- **Mekanisme**: Menggunakan `FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))` dan `FilteringTextInputFormatter.deny(RegExp(r'\s'))`.
- **Dampak**: Karakter unicode transparan (seperti Zero-Width Space `\u200B`, Non-Breaking Space `\u00A0`, Right-to-Left Override `\u202E`) ditolak 100% pada level penekanan tombol keyboard.

### Solusi 3: Auto-Lowercase & Normalisasi Konsisten
- **Mekanisme**: Menggunakan `TextInputFormatter` khusus pada kolom username:
  ```dart
  TextInputFormatter.withFunction((oldValue, newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  })
  ```
- **Dampak**: Tidak ada disparitas antara huruf besar dan kecil, menjamin pencarian mention `@` dan index database unik tanpa tabrakan.

### Solusi 4: Pemeriksaan Ketersediaan Real-Time dengan Debounce (350ms)
- **Mekanisme**:
  1. Pasang listener pada `usernameController` dengan `Timer? _usernameDebounceTimer`.
  2. Saat pengguna berhenti mengetik selama $350\text{ ms}$ dan panjang username $\ge 3$:
     - Tampilkan mini spinner di `customSuffixIcon`.
     - Panggil `SupabaseService.instance.isUsernameTaken(cleanUsername)`.
     - Jika sudah terpakai, set `_regUsernameError = 'Username @$cleanUsername sudah terpakai'`.
     - Jika tersedia, tampilkan ikon centang hijau kecil dan set error ke `null`.

### Solusi 5: Filter Kata Kasar / Profanity Filter Lokal
- **Mekanisme**: Mencegah nama pengguna yang mengandung kata kasar, pornografi, atau ujaran kebencian dalam bahasa Indonesia dan bahasa daerah (Jawa).
- **Daftar Filter**: Didefinisikan dalam `ProfanityFilterHelper` (misal kata-kata tabu/vulgar).
- **Feedback**: Jika terdeteksi, tampilkan pesan: `"Nama mengandung kata yang tidak diperbolehkan"`.

---

## 3. Spesifikasi Teknis Input Formatters & Controller

### A. Display Name Input Formatter (`auth_register_tab.dart`)
```dart
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
)
```

### B. Username Input Formatter (`auth_register_tab.dart`)
```dart
AuthInputField(
  label: isGeneratingUsername ? 'Memilih username...' : 'Username',
  hint: '@username (3-20 karakter)',
  prefixIcon: LucideIcons.atSign,
  controller: usernameController,
  errorText: usernameError,
  customSuffixIcon: isCheckingUsername
      ? const SizedBox(
          width: 16.0,
          height: 16.0,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        )
      : isUsernameAvailable
          ? const Icon(Icons.check_circle_rounded, size: 18.0, color: Color(0xFF10B981))
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
)
```

---

## 4. Cakupan File Target (Target File Scope)

| File Path | Tanggung Jawab & Rencana Perubahan |
| :--- | :--- |
| `lib/features/auth/components/auth_register_tab.dart` | Terapkan filter strictly `[a-zA-Z0-9]`, deny `\s`, indikator suffix check availability, dan inline error |
| `lib/features/auth/screens/auth_screen.dart` | Pasang debounce timer $350\text{ ms}$ untuk check username, validasi reserved words, dan profanity check |
| `lib/core/constants/auth_constants.dart` | Tambahkan `reservedUsernames` set dan helper validasi |
| `lib/features/profile/screens/edit_profile_screen.dart` | Sinkronkan sanitasi formatters yang sama pada halaman Edit Profil |

---

## 5. Kriteria Selesai (Definition of Done)

- [ ] **Tanpa Simbol & Spasi**: Kolom display name dan username menolak semua jenis spasi, simbol, tanda baca, dan emoji secara real-time.
- [ ] **Batas Minimum & Maksimum**: Display name (3–20 karakter jika diisi, boleh kosong) dan Username (3–20 karakter, wajib).
- [ ] **Solusi 1 (Reserved Words)**: Mendaftar dengan username sistem (`admin`, `snaps`, `snapan`, `official`, `support`) langsung ditolak dengan pesan yang jelas.
- [ ] **Solusi 2 (Zero-Width Chars)**: Karakter tersembunyi/unicode transparan tidak dapat disisipkan ke form.
- [ ] **Solusi 3 (Auto-Lowercase)**: Username otomatis diubah menjadi huruf kecil saat diketik.
- [ ] **Solusi 4 (Real-time Debounce)**: Terdapat indikator loading dan validasi ketersediaan username ($350\text{ ms}$) sebelum tombol submit ditekan.
- [ ] **Solusi 5 (Profanity Filter)**: Kata-kata tidak pantas/kasar langsung diblokir dengan pesan peringatan.
- [ ] **Edit Profil Konsisten**: Aturan sanitasi berlaku identik pada perubahan profil setelah login.
