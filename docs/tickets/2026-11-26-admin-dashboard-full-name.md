# Tiket: Tampilkan Nama Lengkap Asli di Admin Dashboard

**Tanggal**: 2026-11-26
**Domain**: Admin Dashboard & Supabase (`profiles` / `student_registry`)
**Status**: Siap Dikerjakan (Menunggu Eksekusi)

---

## Ringkasan Masalah

Di Admin Dashboard (baik daftar akun siswa maupun antrean tiket), selama ini yang menonjol cuma angka **NIS**, padahal admin tidak mungkin hafal ratusan NIS siswa. Jadi **Nama Lengkap Asli** siswa wajib tampil jelas di samping/atas NIS-nya, dan kolom pencarian juga harus bisa mencari berdasarkan nama asli maupun NIS.

---

## Ruang Lingkup Perbaikan (Approach)

1. **Tampilkan Nama Lengkap Asli Bersamaan dengan NIS**:
   - Pada tabel daftar pengguna dan antrean tiket (termasuk antrean Reset Password), tampilkan **Nama Lengkap Asli** sebagai label utama dan **NIS + Kelas/Jurusan** sebagai sub-label.
   - Ambil data nama asli dari relasi tabel `profiles` (kolom `full_name` / `name`) atau `student_registry`.

2. **Pencarian Berdasarkan Nama atau NIS**:
   - Pastikan kolom pencarian di Admin Dashboard mendukung filter berdasarkan **Nama Lengkap Asli** maupun **NIS**, sehingga admin cepat menemukan siswa tertentu.

3. **Edge Case**:
   - Jika ada akun lama yang belum mengisi nama lengkap di `profiles`, tampilkan fallback aman (misal `username` atau `NIS` dengan penanda *"(Nama belum diisi)"*) agar tidak tampil kosong/null.

---

## Kriteria Selesai (Definition of Done)

- [ ] Admin Dashboard menampilkan **Nama Lengkap Asli** berdampingan dengan **NIS** pada daftar siswa dan antrean tiket.
- [ ] Admin dapat mencari siswa menggunakan **Nama** maupun **NIS**.
- [ ] Tidak ada tampilan kosong/error jika ditemukan data profil dengan nama yang belum lengkap.
