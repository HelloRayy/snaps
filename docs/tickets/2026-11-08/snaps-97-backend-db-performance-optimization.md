# Pendekatan Teknis SNAPS-97: Optimasi Performa Backend, Supabase DB & Flutter Client

> **Spesifikasi Teknis & Panduan Implementasi AI Agent**
> - **ID Tiket**: SNAPS-97
> - **Status**: Todo (Urgent)
> - **Domain**: `core / backend / supabase / performance / fps_optimization`
> - **Target Tanggal**: 2026-11-08

---

## 1. Analisis Masalah & Kebutuhan (Problem Audit)

### Kondisi Saat Ini
1. Siswa SMKN 8 Semarang mayoritas menggunakan ponsel kelas menengah ke bawah (RAM 3–4GB, chipset budget).
2. Beberapa screen sering mengalami frame drop / jank ketika:
   - Query feed memuat payload JSON yang terlalu besar (terlalu banyak kolom yang di-`SELECT *`).
   - Kurangnya pagination / cursor-based indexing saat scrolling list panjang di Feed dan DM.
   - Re-rendering berlebihan pada widget root ketika data realtime masuk.
   - Indeks database Postgres di Supabase belum optimal untuk join antar tabel `posts`, `profiles`, dan `likes`.

### Kebutuhan Tiket
- Pendekatan komprehensif 3 lapis (Database -> Network Payload -> Flutter Rendering) untuk menjamin 60/120 FPS tanpa frame drop di perangkat pengguna.

---

## 2. File & Modul Terkait (Target Files)

- `lib/core/services/supabase/` (Supabase client & services)
- `lib/features/feed/controllers/feed_controller.dart` & `lib/features/feed/services/`
- Database Postgres Supabase: Indexes, foreign keys, and RLS evaluation cost

---

## 3. Rencana Solusi & Implementasi AI Agent

1. **Optimasi Lapisan Database (Supabase / Postgres)**:
   - Pastikan foreign key indexing aktif pada:
     - `posts(user_id)`
     - `post_likes(post_id, user_id)`
     - `comments(post_id)`
     - `messages(conversation_id, created_at DESC)`
   - Ganti `SELECT *` dengan proyeksi kolom spesifik (misal: hanya ambil `id, content, images, created_at, user_id, type` pada query feed utama).
2. **Optimasi Payload & Pagination**:
   - Terapkan keyset pagination / cursor pagination menggunakan timestamp `created_at` atau `id` berurutan, bukan `OFFSET / LIMIT` yang lambat pada data ribuan baris.
   - Kurangi limit batch fetch pertama dari 20–30 item menjadi 10–12 item agar Time-to-First-Frame (TTFF) sangat cepat.
3. **Optimasi Flutter Client (Frame Stability)**:
   - Tambahkan `cacheExtent` yang wajar pada `ListView.builder` (misal 500dp) agar tidak merender terlalu banyak view di memori.
   - Pastikan gambar menggunakan ukuran thumbnail yang sesuai atau cached network image dengan ukuran disk cache terbatas.
   - Gunakan `RepaintBoundary` pada item feed individual yang memiliki micro-animation agar repainting tidak memicu re-render seluruh halaman.
