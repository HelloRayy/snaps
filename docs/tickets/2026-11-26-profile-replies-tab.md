# Tiket: Perbaikan Tab Balasan di Halaman Profil (`ProfileScreen`)

**Tanggal**: 2026-11-26
**Domain**: Profile (`lib/features/profile/`) & Supabase Service (`lib/core/services/supabase/`)
**Status**: Siap Dikerjakan (Menunggu Eksekusi)

---

## Ringkasan Masalah

Tab **Balasan** pada halaman profil siswa (`ProfileScreen`) selalu menampilkan status kosong (*"Belum ada balasan"*), meskipun pengguna tersebut sudah pernah membalas atau mengomentari utas orang lain.

## Akar Masalah (Hasil Audit Kode)

1. **Data `allUserReplies` Tidak Pernah Di-Fetch**:
   - Di `lib/features/profile/controllers/profile_controller.dart`, variabel `List<ProfileReplyThreadModel> allUserReplies = [];` sudah dideklarasikan dan diteruskan ke `ProfileContentTabs`.
   - Namun, di dalam `_loadProfileInternal()` (baik untuk profil sendiri maupun profil orang lain), `ProfileController` hanya memanggil `fetchUserPosts(...)` dan belum memanggil query apa pun untuk mengambil daftar balasan/komentar milik user dari Supabase.
2. **Belum Ada Method Service untuk Mengambil Balasan User**:
   - Di `lib/core/services/supabase/` belum tersedia method khusus yang mengambil komentar/balasan berdasarkan `user_id` beserta data utas induknya (`parent post`) untuk dipetakan ke `ProfileReplyThreadModel`.

---

## Ruang Lingkup Perbaikan (Approach)

1. **Tambah Query Balasan User di Supabase Service**:
   - Buat method `fetchUserReplies(String userId)` di service post/komentar Supabase (`lib/core/services/supabase/` + ekspos di `SupabaseService`).
   - Query mengambil seluruh komentar **dan balasan komentar (*reply-to-comment*)** milik `userId` (diurutkan dari yang terbaru) dengan relasi ke postingan induk (`posts`) dan profil pembuat postingan induk.
   - Petakan hasilnya ke `List<ProfileReplyThreadModel>` agar siap ditampilkan dan memiliki referensi `parentPost` untuk navigasi.

2. **Integrasikan ke `ProfileController`**:
   - Panggil `fetchUserReplies(targetUserId)` secara paralel di dalam `Future.wait(...)` pada `_loadProfileInternal()` (baik `isOwnProfile == true` maupun `false`), lalu simpan ke `allUserReplies`.

3. **Sederhanakan UI Kartu Balasan (`ProfileReplyThreadCard`)**:
   - Ubah tampilan dari model 2-tingkat (parent + reply dengan garis vertikal) menjadi **kartu teks feed ringkas** (avatar user, nama, waktu, keterangan singkat *"Membalas @username"*, dan teks balasannya).
   - Saat kartu diklik, langsung navigasi masuk ke detail utas induknya (`PostDetailScreen`).

4. **Keamanan & Edge Case**:
   - Pastikan komentar pada postingan yang sudah dihapus atau tidak valid tidak menyebabkan crash (gunakan null-safe mapping / filter data yang tidak lengkap).

---

## Target Area & File

- `lib/core/services/supabase/` (penambahan `fetchUserReplies(String userId)`).
- `lib/core/services/supabase_service.dart` (ekspos wrapper `fetchUserReplies`).
- `lib/features/profile/controllers/profile_controller.dart` (isi `allUserReplies` saat `loadProfile`).
- `lib/features/profile/components/profile_content_tabs.dart` & `profile_reply_thread_card.dart` (verifikasi rendering dan tap ke detail post).

---

## Kriteria Selesai (Definition of Done)

- [ ] Membuka tab **Balasan** di profil sendiri maupun profil siswa lain menampilkan daftar komentar/balasan yang pernah dibuat beserta cuplikan utas induknya.
- [ ] Jika user memang belum pernah membalas utas mana pun, tetap tampil state kosong *"Belum ada balasan"* dengan rapi.
- [ ] Mengetuk kartu balasan langsung membuka halaman detail utas (`PostDetailScreen`).
