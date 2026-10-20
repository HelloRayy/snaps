# Spesifikasi Arsitektur Sistem Notifikasi Terpadu (sNaps)

Dokumen ini merupakan acuan teknis (*RFC / Technical Proposal*) untuk implementasi sistem notifikasi terintegrasi pada **Snapan Market Mobile (sNaps)** SMKN 8 Semarang.

---

## 1. Latar Belakang & Masalah
Saat ini, tabel `public.notifications` dan antarmuka *Activity & Notifications* (`ActivityScreen`) telah siap menerima data, namun pembuatan notifikasi belum berjalan otomatis pada aksi sosial pengguna seperti:
1. Mention username (`@nama_siswa`) di caption postingan atau komentar.
2. Balasan komentar (*comment reply*).
3. Komentar baru di postingan milik penjual/penulis.
4. Like postingan feed/produk.
5. Aksi mengikuti pengguna (*user follow*).
6. Update status transaksi COD (*orders*).

---

## 2. Prinsip Arsitektur: PostgreSQL Triggers vs Client-Side

Kami memilih pendekatan **Server-Side PostgreSQL Database Triggers** (`SECURITY DEFINER`) dengan alasan:
- **Transaksional & Resilien**: Jika koneksi jaringan siswa terputus setelah me-like atau mengomentari, notifikasi tetap terjamin tersimpan di server.
- **Anti Self-Notification**: Secara ketat menyaring kondisi `NEW.actor_id != target_user_id` agar pengguna tidak menotifikasi diri sendiri.
- **Parsing Mention Berkecepatan Tinggi**: Menggunakan fungsi bawaan regex PostgreSQL `regexp_matches()` yang efisien.
- **Deduplikasi Cerdas**: Mencegah spam ketika pengguna melakukan toggle like secara cepat.

---

## 3. Matriks Domain Notifikasi & Skema Data

### 3.1 Skema Tabel `public.notifications`
| Kolom | Tipe | Keterangan |
| :--- | :--- | :--- |
| `id` | `uuid` | Primary Key (Default: `gen_random_uuid()`) |
| `user_id` | `uuid` | ID Pengguna Penerima (*Recipient*) |
| `actor_id` | `uuid` | ID Pengguna Pemicu Aksi (*Actor*) |
| `type` | `text` | Enum: `'like'`, `'comment'`, `'reply'`, `'mention'`, `'follow'`, `'order'`, `'system'` |
| `title` | `text` | Judul notifikasi (nama actor / instansi) |
| `message` | `text` | Pesan cuplikan interaksi |
| `post_id` | `uuid` | ID postingan terkait (opsional jika bukan interaksi postingan) |
| `action_type` | `text` | Deep-link action (`'post_link'`, `'user_profile'`, `'order_detail'`, dll.) |
| `action_url` | `text` | Payload link atau identifier sasaran aksi |
| `is_read` | `boolean` | Status baca (Default: `false`) |
| `created_at` | `timestamptz`| Waktu pembuatan |

---

## 4. Rancangan PostgreSQL Triggers

### 4.1 Trigger Komentar & Balas Komentar (`post_comments`)
- **Pemicu**: `AFTER INSERT ON public.post_comments`
- **Alur Logika**:
  1. Jika `parent_comment_id IS NOT NULL`:
     - Ambil pembuat komentar induk (`parent_comment_author_id`).
     - Jika pembuat komentar induk $\neq$ pengirim balasan:
       - Buat notifikasi bertipe `comment` (*"membalas komentarmu: ..."*).
  2. Ambil pemilik postingan (`seller_id` dari `market_posts`).
  3. Jika pemilik postingan $\neq$ pengirim komentar dan $\neq$ pembuat komentar induk:
     - Buat notifikasi bertipe `comment` (*"mengomentari postinganmu: ..."*).

### 4.2 Trigger Mention `@username` (`post_comments` & `market_posts`)
- **Pemicu**: `AFTER INSERT ON public.market_posts` dan `AFTER INSERT ON public.post_comments`
- **Alur Logika**:
  1. Jalankan regex: `regexp_matches(content, '@([a-zA-Z0-9_.]+)', 'g')`.
  2. Cari `id` di `public.profiles` berdasarkan `username ILIKE match`.
  3. Hindari notifikasi ke diri sendiri dan hindari duplikasi jika username yang sama di-mention dua kali dalam satu teks.
  4. Buat notifikasi bertipe `mention` (*"menyebut kamu dalam postingan/komentar"*).

### 4.3 Trigger Like Postingan (`post_likes`)
- **Pemicu**: `AFTER INSERT ON public.post_likes`
- **Alur Logika**:
  1. Ambil pemilik postingan (`seller_id`).
  2. Jika pemilik postingan $\neq$ pelaku like:
     - Cek apakah sudah pernah ada notifikasi like serupa yang belum terbaca dalam 1 jam terakhir untuk mencegah spam.
     - Buat notifikasi bertipe `like` (*"menyukai postinganmu"*).

### 4.4 Trigger Follow Akun (`user_follows`)
- **Pemicu**: `AFTER INSERT ON public.user_follows`
- **Alur Logika**:
  1. Target penerima: `NEW.following_id`.
  2. Pelaku: `NEW.follower_id`.
  3. Buat notifikasi bertipe `follow` (*"mulai mengikuti kamu"*).

---

## 5. Rencana Penyesuaian Antarmuka Mobile (Flutter `lib/`)

1. **`ActivityScreen` (`lib/features/activity/screens/activity_screen.dart`)**:
   - Memperluas handler `onTap` pada `ActivityItemTile`:
     - Tipe `like`, `comment`, `mention`: Navigasi ke `PostDetailScreen(post)`.
     - Tipe `follow`: Navigasi ke `ProfileScreen(username: actorUsername)`.
     - Tipe `order`: Navigasi ke daftar/detail pesanan COD.
2. **`GlobalNotificationService` (`lib/core/services/global_notification_service.dart`)**:
   - Sinkronisasi payload notifikasi Realtime ke status bar dan in-app banner sesuai tipe interaksi yang baru.
