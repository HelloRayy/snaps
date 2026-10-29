# Perbaikan Validasi & Feedback Copy Display Name Registrasi

> **Dokumen Spesifikasi Teknis & Pendekatan Arsitektur**
> - **Tanggal**: 2026-10-29
> - **Domain**: `auth / register / validation / ui_feedback / copy`
> - **Status**: Planned (Approaching)

---

## 1. Analisis Akar Masalah (Root Cause Analysis)

Berdasarkan pengujian alur registrasi akun siswa di `lib/features/auth/components/auth_register_tab.dart` dan `auth_screen.dart`, ditemukan 3 faktor penyebab pengguna terjebak:

1. **Paradoks Silent Disabled Button (Tombol Mati Tanpa Penjelasan)**:
   - Pada `auth_register_tab.dart` baris 141–155, status `isDisplayNameValid` ditentukan oleh:
     `final bool isDisplayNameValid = rawDisplayName.isEmpty || (rawDisplayName.length >= 6 && rawDisplayName.length <= 20);`
   - Jika pengguna mengisi display name sebanyak 1 sampai 5 karakter (misal: "Ray", "Ali", "Eko"), variabel `isDisplayNameValid` bernilai `false`, menyebabkan tombol `PrimaryAuthButton` dinonaktifkan (`isEnabled: false`).
   - Sementara itu, teks pesan error (`_regDisplayNameError = 'Nama tampilan minimal 6 karakter'`) baru dipicu di dalam fungsi `onSubmit` pada `auth_screen.dart`.
   - **Dampaknya**: Pengguna tidak dapat menekan tombol karena tombol dalam status mati, dan pesan error tidak pernah ditampilkan karena fungsi klik tombol tidak pernah terpanggil. Pengguna bingung mengapa tombol tidak bisa diklik.

2. **Ketiadaan Helper Text / Copy pada Field**:
   - Kolom password memiliki teks petunjuk yang jelas: `hint: 'Minimal 6 karakter'`.
   - Kolom display name hanya bertuliskan: `hint: 'Masukkan nama tampilan kamu'` tanpa keterangan batas minimum maupun maksimum.

3. **Batas Minimum 6 Karakter Terlalu Kaku untuk Nama Panggilan**:
   - Display name merupakan nama panggilan/tampilan siswa di aplikasi, bukan username sistem (yang sudah dipisahkan ke kolom `@username`).
   - Banyak siswa di SMKN 8 memiliki nama panggilan pendek (3–5 karakter, misal: "Ali", "Aji", "Dina", "Budi", "Fahmi", "Rian"). Mengharuskan minimal 6 karakter menimbulkan friksi yang tidak perlu.
   - Pada basis data Supabase (`public.profiles`), kolom `display_name` bertipe `text` bebas tanpa batasan minimum karakter.

---

## 2. Rencana Solusi & Spesifikasi Perubahan

### A. Rasionalisasi Batas Karakter (3–20 Karakter)
- Ubah batas minimum panjang display name dari **6 karakter menjadi 3 karakter**.
- Aturan validasi:
  - Boleh kosong (`rawDisplayName.isEmpty` $\rightarrow$ valid karena opsional).
  - Jika diisi, panjangnya harus antara **3 sampai 20 karakter** ($3 \le \text{length} \le 20$).

### B. Perbaikan Copy & Hint Teks
- Pada `AuthInputField` display name di `auth_register_tab.dart`:
  - `label`: `Display Name (Opsional)`
  - `hint`: `Nama panggilan (3–20 karakter)`
- Memberikan kepastian visual sejak awal sebelum pengguna mulai mengetik.

### C. Inline Real-Time Validation Feedback
- Jangan sembunyikan alasan error di dalam fungsi `onSubmit`.
- Saat pengguna mengetik di `displayNameController`:
  - Jika panjang teks $> 0$ dan $< 3$ karakter, langsung tampilkan `errorText`:
    `"Nama tampilan minimal 3 karakter (atau kosongkan)"`
  - Jika panjang teks $\ge 3$ dan $\le 20$, bersihkan error text (`null`).
  - Jika kosong, error text tetap `null`.
- Pengguna langsung paham mengapa tombol belum aktif tanpa harus menebak-nebak.

---

## 3. Cakupan File Target (Target File Scope)

| File Path | Tanggung Jawab & Rencana Perubahan |
| :--- | :--- |
| `lib/features/auth/components/auth_register_tab.dart` | Ubah validasi `isDisplayNameValid` ke $\ge 3$, perbarui hint text, dan pasang error listener inline real-time |
| `lib/features/auth/screens/auth_screen.dart` | Sinkronkan validasi `rawDisplayName.length < 3` di method submit form registrasi |

---

## 4. Kriteria Selesai (Definition of Done)

- [ ] Kolom display name memiliki teks petunjuk yang jelas mengenai batas karakter (`3–20 karakter`).
- [ ] Siswa dapat mendaftarkan display name dengan panjang 3 sampai 5 karakter (misal: "Ali", "Eko", "Dina") tanpa terblokir.
- [ ] Jika siswa mengetik 1 atau 2 karakter pada display name, muncul teks error real-time di bawah kolom yang menginformasikan bahwa minimal 3 karakter atau boleh dikosongkan.
- [ ] Tombol `Aktifkan Akun & Masuk` aktif secara visual saat seluruh persyaratan terpenuhi (NIS, Username valid, Password $\ge 6$, Ketentuan dicentang, dan Display Name valid/kosong).
