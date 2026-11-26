# Tiket: Fitur Reset Password Dalam Ekosistem Snaps (Tanpa Redirect Eksternal)

**Tanggal**: 2026-11-26
**Domain**: Auth (`lib/features/auth/`) & Admin / Supabase (`lib/core/services/supabase/`)
**Status**: Siap Dikerjakan (Menunggu Eksekusi)

---

## Ringkasan Masalah

Siswa yang lupa kata sandi belum memiliki jalur pemulihan akun di dalam aplikasi. Karena sistem akun sekolah berbasis NIS, pemulihan tidak bisa mengandalkan email pribadi dan harus tetap berada di dalam ekosistem Snaps (tanpa melempar pengguna ke WhatsApp/aplikasi luar).

---

## Ruang Lingkup Fitur (Approach)

1. **Tombol & Halaman Bantuan Reset Password (di Layar Login)**:
   - Tambahkan tombol **"Lupa Password?"** pada form login (`lib/features/auth/`).
   - Saat diklik, buka halaman/sheet khusus **Lupa Password** di dalam aplikasi.
   - Siswa mengisi data verifikasi: **NIS**, **Nama Lengkap**, dan **Kelas/Jurusan** (ditambah kolom pesan/kendala opsional).

2. **Penyimpanan Tiket Permintaan ke Supabase + FCM Token Perangkat**:
   - Buat tabel/endpoint permintaan reset (misal `password_reset_requests`) dengan status `pending`, `approved`, `rejected`, serta menyimpan `device_fcm_token` dari HP yang dipakai mengajukan.
   - Siswa bisa mengecek status permintaannya langsung di halaman yang sama berdasarkan NIS (misal: *"Menunggu verifikasi admin"* atau menampilkan instruksi password sementara jika sudah disetujui).
   - Saat admin memproses permintaan (Setujui/Tolak), backend mengirim push notification ke `device_fcm_token` tersebut dengan pesan aman tanpa menyertakan isi password (misal: *"Permintaan reset password sudah diproses admin. Ketuk untuk cek status."*).

3. **Integrasi dengan Admin Dashboard (Terkait Tiket Nomor 5)**:
   - Admin melihat daftar permintaan reset lengkap dengan **NIS dan Nama Lengkap Asli** siswa.
   - Admin memverifikasi kecocokan data, lalu menekan tombol **Reset Password** untuk mengatur ulang sandi akun siswa menjadi sandi sementara melalui fungsi admin Supabase (`auth.admin.updateUserById` via Edge Function / RPC aman).

4. **Fitur Ubah Kata Sandi di Edit Profil / Pengaturan (Flow Terpisah)**:
   - Tambahkan bagian **"Ubah Kata Sandi"** di halaman Edit Profil (`lib/features/profile/`) agar siswa yang sudah login (termasuk setelah memakai sandi sementara) dapat mengganti ke sandi baru pilihannya sendiri (`auth.updateUser`).
   - Alur: Buka Profil -> Edit Profil -> Ubah Kata Sandi -> Isi Sandi Baru & Konfirmasi Sandi -> Validasi (cocok & minimal 6 karakter) -> Update ke Supabase Auth -> Notif sukses.

5. **Keamanan & Edge Case**:
   - Batasi pengiriman permintaan berulang dari NIS yang sama saat masih ada tiket `pending` (anti-spam).
   - Pastikan fungsi reset password hanya bisa dieksekusi oleh role **Admin** yang terautentikasi.

---

## Target Area & File

- `lib/features/auth/` (tombol *"Lupa Password?"* di login screen + halaman/sheet form pengajuan & cek status).
- `lib/core/services/supabase/` (service untuk kirim & cek status `password_reset_requests`).
- Supabase Edge Function / Admin Dashboard (eksekusi reset password oleh admin).

---

## Kriteria Selesai (Definition of Done)

- [ ] User yang lupa password bisa mengajukan permintaan reset langsung dari halaman Login tanpa keluar dari aplikasi Snaps.
- [ ] Permintaan tersimpan di database dan muncul di antrean Admin Dashboard.
- [ ] Admin dapat memverifikasi dan mereset password siswa dengan aman.
