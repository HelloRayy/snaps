# Tiket: Notifikasi Komentar & Balasan Utas

**Tanggal**: 2026-11-26
**Domain**: Notification & Feed (`lib/core/services/global_notification_service.dart`, Supabase Trigger / Edge Function)
**Status**: Siap Dikerjakan (Menunggu Eksekusi)

---

## Ringkasan Masalah

Saat ada pengguna lain mengomentari utas/produk atau membalas komentar, pemilik utas/komentar belum mendapatkan notifikasi. Akibatnya penjual atau pembuat utas sering telat merespons pertanyaan calon pembeli.

---

## Ruang Lingkup Perbaikan (Approach)

1. **Trigger Notifikasi di Backend (Supabase)**:
   - Saat ada `INSERT` baru pada tabel komentar/balasan:
     - Kirim notifikasi ke **pemilik utas** (`post_author_id`).
     - Jika merupakan balasan komentar (*reply-to-comment*), kirim juga ke **pemilik komentar induk** (`parent_comment_author_id`).
   - Masukkan ke tabel `notifications` dengan `action_type: 'post_link'` dan `action_url: <post_id>`, serta picu push notification FCM.

2. **Penanganan Tap Notifikasi di Aplikasi**:
   - Ketika notifikasi diklik (baik dari status bar OS maupun tab Aktivitas), langsung arahkan pengguna ke `PostDetailScreen` utas terkait.

3. **Keamanan & Edge Case**:
   - **Anti-Self-Notification**: Jangan kirim notifikasi jika pelaku komentar adalah pemilik utas/komentar itu sendiri.
   - **Anti-Duplikat**: Jika pemilik komentar induk sama dengan pemilik utas, kirim cukup 1 notifikasi saja.

---

## Kriteria Selesai (Definition of Done)

- [ ] Pembuat utas menerima notifikasi saat ada komentar baru dari pengguna lain.
- [ ] Pemilik komentar menerima notifikasi saat komentarnya dibalas oleh pengguna lain.
- [ ] Mengetuk notifikasi langsung membuka halaman detail utas (`PostDetailScreen`).
- [ ] Tidak ada notifikasi yang terkirim ke diri sendiri saat mengomentari utas sendiri.
