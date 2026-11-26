# Tiket: Perbaikan & Dukungan Notifikasi Foreground (Saat User Di Dalam Aplikasi)

**Tanggal**: 2026-11-26
**Domain**: Global Notification (`lib/core/services/global_notification_service.dart`)
**Status**: Siap Dikerjakan (Menunggu Persetujuan Approach)

---

## Ringkasan Masalah

Saat pengguna sedang aktif membuka aplikasi (*foreground*), notifikasi masuk (terutama Direct Message dan aktivitas baru) sering tidak muncul di **status bar OS** (heads-up notification).

## Akar Masalah (Hasil Audit Kode)

1. **Jebakan Deduplikasi DM (Realtime vs FCM)**:
   - Saat pesan DM masuk lewat Supabase Realtime WebSocket, `showDmBanner` mencatat pesan ke cache deduplikasi (`registerHandledDm`) **tanpa** memanggil `_showOsNotification` (notifikasi OS).
   - Beberapa milidetik kemudian, ketika FCM foreground tiba di `FirebaseMessaging.onMessage`, pesan diblokir oleh `isDmRecentlyHandled(...)`. Akibatnya notifikasi status bar OS tidak pernah muncul sama sekali.

2. **Race Condition Avatar di Realtime Notification**:
   - Pada `_subscribeRealtime()`, pengambilan profil pengirim (`getProfile(actorId)`) memakai `.then(...)` tanpa `await`, sehingga `actorAvatar` selalu `null` saat notifikasi OS dirender.

3. **Belum Ada Deduplikasi Non-DM (Realtime vs FCM)**:
   - Notifikasi aktivitas/sistem yang masuk bersamaan dari Supabase Realtime dan FCM foreground berisiko muncul ganda di status bar OS.

---

## Ruang Lingkup Perbaikan (Approach — 100% OS Status Bar)

1. **Hapus Ketergantungan Banner Melayang (`OverlayEntry`)**:
   - Fokuskan seluruh notifikasi foreground langsung ke **Status Bar OS (Heads-up Notification)** menggunakan `flutter_local_notifications` dengan channel `Importance.max` dan `Priority.high`.

2. **Sinkronisasi Penuh Notifikasi DM di Foreground**:
   - Pastikan saat DM masuk di foreground (dan user tidak sedang berada di ruang chat yang sama), `showDmBanner` (atau handler Realtime) langsung memicu `_showOsNotification` dengan avatar pengirim, suara, dan aksi tap menuju ruang chat.
   - Pertahankan *in-room suppression*: jika user sedang membuka ruang chat dengan pengirim tersebut, notifikasi OS tetap disembunyikan agar tidak mengganggu.

3. **Perbaiki Pengambilan Avatar & Deduplikasi Aktivitas**:
   - Ubah callback `_subscribeRealtime()` menjadi `async` dan `await` pengambilan `actorAvatar` (dengan batas timeout singkat agar notifikasi tidak tertunda lama).
   - Tambahkan deduplikasi sederhana berbasis `notification_id` / `title+message` selama beberapa detik agar event dari Realtime dan FCM tidak tampil dua kali di status bar OS.

---

## Target Area & File

- `lib/core/services/global_notification_service.dart` (fokus perbaikan utama: `showDmBanner`, `_subscribeRealtime`, dan `FirebaseMessaging.onMessage`).

---

## Kriteria Selesai (Definition of Done)

- [ ] Saat user berada di halaman Feed/Explore/Profile dan menerima DM baru, notifikasi heads-up muncul di status bar OS lengkap dengan avatar pengirim dan bisa diklik langsung menuju ruang chat.
- [ ] Saat user sedang berada di dalam ruang chat yang sama dengan pengirim, notifikasi tidak muncul mengganggu.
- [ ] Saat user menerima notifikasi aktivitas/pengumuman di foreground, notifikasi status bar OS muncul tepat satu kali (tidak ganda) dan bisa diklik untuk menjalankan aksinya.
