# Tiket: Daftar Utas yang Disukai (Liked / Loved Posts)

**Tanggal**: 2026-11-26
**Domain**: Profile (`lib/features/profile/`) & Supabase Service (`lib/core/services/supabase/`)
**Status**: Siap Dikerjakan (Menunggu Eksekusi)

---

## Ringkasan Masalah

Fitur Love / Like pada utas dan produk sudah berjalan, tetapi pengguna belum memiliki halaman atau tab khusus untuk melihat kembali daftar utas/barang apa saja yang pernah mereka sukai (berfungsi juga sebagai penanda barang yang ingin dibeli nanti).

---

## Ruang Lingkup Fitur (Approach)

1. **Query Utas yang Disukai di Supabase Service**:
   - Tambahkan method `fetchUserLikedPosts(String userId)` di service post Supabase (`lib/core/services/supabase/` + ekspos di `SupabaseService`).
   - Ambil daftar postingan berdasarkan relasi tabel like milik `userId` (diurutkan dari yang paling baru disukai).

2. **Tampilan di Profil (`ProfileScreen`)**:
   - Tambahkan tab atau menu **"Disukai"** pada halaman profil (khusus profil sendiri, atau bisa dilihat sesuai kebijakan privasi).
   - Gunakan kembali komponen kartu feed yang sudah ada agar konsisten dan ringan.

3. **Sinkronisasi State**:
   - Jika pengguna membatalkan Love (*unlike*) dari daftar tersebut, item langsung hilang atau ter-update secara reaktif.

---

## Kriteria Selesai (Definition of Done)

- [ ] Pengguna dapat membuka daftar seluruh utas/produk yang pernah di-Love dari halaman Profil.
- [ ] Mengetuk item di daftar tersebut langsung membuka detail utas (`PostDetailScreen`).
- [ ] Jika pengguna belum pernah menyukai utas apa pun, tampil state kosong yang rapi.
