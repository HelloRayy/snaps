# [SNAPS-85] feat(mascot-icon): add mascot icon access for public

> **Ticket Metadata**:
> - **Sequence**: SNAPS-85
> - **Priority**: MEDIUM
> - **Domain**: `mascot / flair / profile / create_post / permission`
> - **Status**: Ticket (Unstarted)

---

## 1. Problem Statement & User Context

- **Kondisi Saat Ini**:
  - Fitur ikon maskot mikro (Mascot Flair) diperkenalkan pada SNAPS-13 (mendukung bundle maskot Koala & Fox dengan berbagai ekspresi emosi).
  - Namun, akses pemilihan maskot ini **dibatasi secara ketat** hanya untuk akun pengembang / pilot beta melalui getter `_isBetaPilotUser`:
    ```dart
    // create_post_modal.dart & edit_profile_screen.dart
    bool get _isBetaPilotUser {
      final username = ...;
      final email = ...;
      return username == 'snaps' || email.contains('snaps');
    }
    ```
  - Akibatnya, siswa dan pengguna umum tidak dapat memilih maskot saat mengedit profil di `EditProfileAvatarSection` (selalu diarahkan ke preset avatar statis), serta tombol trigger maskot di `CreatePostAuthorLine` disembunyikan.

- **Kebutuhan Fitur**:
  - Membuka akses penuh (*public availability*) fitur pemilihan ikon maskot untuk seluruh pengguna terdaftar di Snaps.
  - Seluruh pengguna dapat memilih maskot & ekspresi favorit di halaman Edit Profil dan memilih flair maskot per postingan saat membuat post di linimasa.

---

## 2. Target File Scope

| File Path | Peran & Perubahan |
| :--- | :--- |
| [`lib/features/profile/screens/edit_profile_screen.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/profile/screens/edit_profile_screen.dart) | Menghapus pengecekan eksklusif `isBetaPilotUser` agar berlaku untuk semua pengguna |
| [`lib/features/profile/components/edit_profile_avatar_section.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/profile/components/edit_profile_avatar_section.dart) | Membuka `_buildMascotSection()` bagi publik (atau menggabungkannya secara harmonis dengan preset avatar) |
| [`lib/features/create_post/screens/create_post_modal.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/create_post/screens/create_post_modal.dart) | Membuka flag pemilihan maskot default dan pemanggilan trigger untuk semua pembuat postingan |
| [`lib/features/create_post/components/create_post_author_line.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/create_post/components/create_post_author_line.dart) | Selalu menampilkan container interaktif Mascot Flair Trigger |
| [`lib/core/models/mascot_flair_model.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/core/models/mascot_flair_model.dart) | Validasi bundle maskot yang tersedia untuk publik |

---

## 3. Step-by-Step Technical Approach

### Langkah 1: Pelepasan Gating di Edit Profile
1. Di `edit_profile_screen.dart`, ubah parameter:
   ```dart
   isBetaPilotUser: true, // Dibuka untuk seluruh pengguna umum
   ```
   atau hapus parameter tersebut dan jadikan pemilihan maskot sebagai bagian standar dari kustomisasi profil.
2. Di `edit_profile_avatar_section.dart`, pastikan pemilih maskot (`_buildMascotSection()`) dapat diakses berdampingan dengan foto profil dan preset avatar, memungkinkan pengguna memilih apakah ingin menggunakan flair maskot atau tidak (opsi *Clear Flair*).

### Langkah 2: Pelepasan Gating di Create Post Modal
1. Di `create_post_modal.dart`, ubah `_isBetaPilotUser` menjadi `true` atau periksa ketersediaan `mascotFlair` yang tersimpan pada profil user saat ini.
2. Pastikan `_initMascotFlair()` meng-hydrate maskot dari profil pengguna aktif saat modal dibuka.
3. Di `create_post_author_line.dart`, tampilkan trigger maskot sehingga pengguna dapat mengganti ekspresi maskot untuk postingan spesifik.

### Langkah 3: Sinkronisasi dan Validasi Database
1. Pastikan payload `mascot_flair` tersimpan dengan benar di Supabase tabel `profiles` dan `market_posts`.
2. Validasi bahwa fallback query di `SupabaseFeedService` dan `SupabaseProfileService` tetap aman jika kolom belum diisi (graceful degradation ke `null`).

---

## 4. Definition of Done (DoD)

- [ ] Pengguna dengan akun non-'snaps' dapat melihat dan memilih ikon maskot di halaman Edit Profil.
- [ ] Pengguna umum dapat memilih ekspresi maskot di header pembuat postingan (`CreatePostModal`).
- [ ] Ikon maskot yang dipilih muncul di samping nama pengguna pada header postingan linimasa (`PostCardHeader`) dan di profil (`ProfileInfoHeader`).
- [ ] Tersedia opsi untuk menghapus atau mengganti maskot yang telah terpasang.
- [ ] Lolos static analysis `flutter analyze` dengan 0 errors.
