# Sanitasi Input Auth: Display Name & Username (Karakter, Simbol, & Best Practices Kompetitor)

> **Dokumen Spesifikasi Teknis & Pendekatan Arsitektur**
> - **Tanggal**: 2026-10-29
> - **Domain**: `auth / input_formatters / sanitization / security / validation`
> - **Status**: Planned (Approaching)

---

## 1. Analisis Kebutuhan Baru: Tanpa Simbol & Tanpa Spasi

- **Display Name**:
  - Saat ini: Belum memiliki filter sama sekali (`LengthLimitingTextInputFormatter(20)` saja). Masih bisa disusupi simbol, emoji, spasi berulang, dan zero-width character.
  - Kebutuhan: Dibatasi murni alfanumerik tanpa simbol dan tanpa spasi, panjang **3–20 karakter**.
- **Username**:
  - Saat ini: Memblokir spasi dan mengizinkan huruf, angka, titik, dan garis bawah (`[a-zA-Z0-9._]`).
  - Kebutuhan: Dibatasi murni alfanumerik tanpa simbol (`.` dan `_` dihilangkan) dan tanpa spasi (`[a-zA-Z0-9]`), panjang **3–20 karakter**.

---

## 2. Benchmark Best Practices Aplikasi Kompetitor (Twitter, Instagram, Telegram, TikTok)

Selain pemblokiran simbol dan spasi, berikut 5 praktik standar industri yang diterapkan kompetitor untuk mencegah penipuan, bug visual, dan celah keamanan:

1. **Daftar Kata Terlarang (Reserved & System Words Whitelist/Blacklist)**:
   - *Penerapan di Kompetitor*: Melarang pembuatan username/display name yang meniru identitas sistem resmi, seperti `admin`, `administrator`, `root`, `snaps`, `snapan`, `official`, `support`, `system`, `moderator`, `help`.
   - *Tujuan di Snapan*: Mencegah siswa iseng membuat akun berpura-pura menjadi admin sekolah atau akun resmi OSIS/Snaps saat bertransaksi.

2. **Pencegahan Karakter Tak Terlihat (Zero-Width & Invisible Characters)**:
   - *Penerapan di Kompetitor*: Menolak karakter unicode transparan (seperti Zero-Width Space `\u200B`, Non-Breaking Space `\u00A0`, Right-to-Left Override `\u202E`).
   - *Tujuan di Snapan*: Karakter tak terlihat sering digunakan untuk membuat username tiruan yang tampak sama persis di mata korban. Dengan membatasi strictly ke regex `[a-zA-Z0-9]`, seluruh karakter tak terlihat otomatis ditolak di level keyboard formatter.

3. **Auto-Lowercase & Case-Insensitive Collision**:
   - *Penerapan di Kompetitor*: Username selalu dipaksa huruf kecil (`a-z0-9`), baik saat diketik di form maupun saat disimpan di database.
   - *Tujuan di Snapan*: Menghilangkan kerancuan antara `Rayhan`, `RAYHAN`, dan `rayhan`. Di Snaps, input formatter otomatis mengubah huruf kapital menjadi huruf kecil secara real-time.

4. **Pemeriksaan Ketersediaan Real-Time dengan Debounce (300–400ms)**:
   - *Penerapan di Kompetitor*: Saat mengetik username, ada indikator kecil (centang hijau jika tersedia, silang merah jika sudah dipakai) tanpa perlu menekan tombol daftar terlebih dahulu.
   - *Tujuan di Snapan*: Mencegah frustrasi pengguna baru yang baru tahu username-nya bentrok setelah selesai mengisi seluruh form.

5. **Penyaringan Kata Kasar / Profanity Filter Lokal**:
   - *Penerapan di Kompetitor*: Memblokir kata-kata kotor, umpatan, atau konten SARA di nama pengguna.
   - *Tujuan di Snapan*: Menjaga kesopanan linimasa di lingkungan edukasi sekolah menengah kejuruan.

---

## 3. Spesifikasi Teknis Input Formatters & Validasi

### A. Display Name Input Formatter
```dart
inputFormatters: [
  LengthLimitingTextInputFormatter(20),
  FilteringTextInputFormatter.deny(RegExp(r'\s')), // Tolak semua jenis spasi
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), // Hanya huruf dan angka
]
```
- Validasi Panjang: Boleh kosong (opsional). Jika diisi, panjang wajib $3 \le \text{length} \le 20$.
- Error Real-time: Jika panjang 1–2 karakter, tampilkan: `"Nama tampilan minimal 3 karakter (atau kosongkan)"`.

### B. Username Input Formatter
```dart
inputFormatters: [
  LengthLimitingTextInputFormatter(20),
  FilteringTextInputFormatter.deny(RegExp(r'\s')), // Tolak spasi
  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')), // Tanpa simbol (. dan _ ditutup)
  TextInputFormatter.withFunction((oldValue, newValue) {
    return newValue.copyWith(text: newValue.text.toLowerCase()); // Paksa lowercase
  }),
]
```
- Validasi Panjang: Wajib diisi, panjang $3 \le \text{length} \le 20$.
- Cek Kata Terlarang: Tolak jika cocok dengan daftar reserved words (`admin`, `snaps`, `snapan`, `support`).

---

## 4. Cakupan File Target (Target File Scope)

| File Path | Tanggung Jawab Perubahan |
| :--- | :--- |
| `lib/features/auth/components/auth_register_tab.dart` | Terapkan filter alfanumerik strictly `[a-zA-Z0-9]` pada display name dan username, serta perbarui hint teks |
| `lib/features/auth/screens/auth_screen.dart` | Sinkronkan regex validation dan pengecekan reserved words saat submit form |
| `lib/features/profile/screens/edit_profile_screen.dart` | Sinkronkan aturan alfanumerik yang sama pada halaman Edit Profil pengguna yang sudah login |

---

## 5. Kriteria Selesai (Definition of Done)

- [ ] Kolom display name menolak semua jenis spasi, simbol, tanda baca, dan emoji secara real-time saat diketik.
- [ ] Kolom username menolak semua jenis spasi dan simbol (termasuk titik `.` dan garis bawah `_`), serta otomatis mengubah huruf kapital menjadi kecil.
- [ ] Batas panjang untuk display name (jika diisi) dan username adalah minimal 3 karakter dan maksimal 20 karakter.
- [ ] Terdapat teks error inline real-time jika display name diisi kurang dari 3 karakter.
- [ ] Sistem menolak username yang termasuk dalam daftar kata terlarang (`admin`, `snaps`, `snapan`, `support`, `official`).
- [ ] Aturan sanitasi yang sama diterapkan secara konsisten pada halaman edit profil.
