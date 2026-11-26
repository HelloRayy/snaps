# Tiket: Auto-Update Feed Realtime (Tanpa Reload Manual)

**Tanggal**: 2026-11-26
**Domain**: Feed (`lib/features/feed/`) & Supabase Service (`lib/core/services/supabase/`)
**Status**: Siap Dikerjakan (Menunggu Eksekusi)

---

## Ringkasan Masalah

Saat ada pengguna lain mengunggah utas atau produk baru, timeline di halaman beranda (`HomeFeedScreen`) tidak otomatis mengetahui adanya postingan baru. Pengguna harus melakukan *pull-to-refresh* secara manual untuk melihat konten terbaru.

## Akar Masalah (Hasil Audit Kode)

1. **Belum Ada Listener Realtime untuk Tabel `posts`**:
   - Di `lib/features/feed/controllers/home_feed_controller.dart`, controller baru berlangganan perubahan profil (`subscribeToProfile`), tetapi belum memiliki channel Supabase Realtime untuk event `INSERT` pada tabel `posts`.
2. **Belum Ada Mekanisme Penampung Post Baru (Pending Posts Pill)**:
   - Jika feed langsung menyisipkan postingan orang lain ke posisi teratas saat user sedang membaca di tengah layar, posisi scroll akan melonjak tiba-tiba dan mengganggu pengalaman membaca.

---

## Ruang Lingkup Perbaikan (Approach)

1. **Postingan Sendiri Langsung Muncul**:
   - Saat user selesai mengunggah utas/produk sendiri, panggil `fetchPosts(isSilent: true)` (atau sisipkan langsung ke posisi teratas list) sehingga langsung tampil tanpa perlu refresh manual.

2. **Listener Realtime untuk Postingan Orang Lain**:
   - Tambahkan subscription Supabase Realtime pada `HomeFeedController` untuk memantau `INSERT` baru di tabel `posts` (abaikan jika `author_id == currentUser.id` agar tidak bentrok dengan poin 1).
   - Simpan penanda `hasNewPosts = true` (atau jumlah post baru) tanpa langsung menggeser posisi scroll user.

3. **Tombol Melayang *"Utas Baru"* (Gaya Threads / X)**:
   - Saat `hasNewPosts == true`, tampilkan pill melayang kecil di bagian atas `HomeFeedScreen` (misal: *"Utas baru • Ketuk untuk lihat"*).
   - Ketika user mengetuk pill tersebut: muat ulang `fetchPosts(isRefresh: true)`, scroll halus ke paling atas (`scrollToTop()`), dan sembunyikan pill.
   - Jika user melakukan *pull-to-refresh* manual, reset juga `hasNewPosts = false`.

4. **Keamanan & Kebersihan Resource**:
   - Pastikan channel realtime `posts` di-`unsubscribe()` dengan benar di `dispose()` pada `HomeFeedController` agar tidak terjadi kebocoran koneksi.

---

## Target Area & File

- `lib/core/services/supabase/` & `lib/core/services/supabase_service.dart` (tambah helper `subscribeToNewPosts`).
- `lib/features/feed/controllers/home_feed_controller.dart` (kelola state `hasNewPosts` dan subscription realtime).
- `lib/features/feed/screens/home_feed_screen.dart` & komponen pill baru di `lib/features/feed/components/` (render pill *"Utas baru"* dan animasi scroll ke atas).

---

## Catatan Desain

- **Pengingat Fase Eksekusi**: Sebelum membuat UI pill *"Utas baru"*, konfirmasi dulu desain/tampilan pill ke user (user sudah menyiapkan referensi UI khusus).

---

## Kriteria Selesai (Definition of Done)

- [ ] Setelah user sendiri membuat postingan baru, postingan langsung muncul di posisi paling atas feed tanpa refresh manual.
- [ ] Saat pengguna lain mengunggah postingan baru, muncul pill melayang *"Utas baru"* di atas feed tanpa menggeser posisi scroll user saat ini.
- [ ] Mengetuk pill *"Utas baru"* langsung memuat postingan terbaru dan menggulir layar ke atas dengan mulus.
