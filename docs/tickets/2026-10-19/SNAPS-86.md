# [SNAPS-86] fix(dm-notif): fix direct message notif not realtime

> **Ticket Metadata**:
> - **Sequence**: SNAPS-86
> - **Priority**: HIGH
> - **Domain**: `chat / direct_messages / realtime / supabase / notification`
> - **Status**: Ticket (Unstarted)

---

## 1. Problem Statement & Root Cause Analysis

- **Gejala Masalah**:
  - Pengguna tidak menerima notifikasi pesan masuk (DM) secara realtime saat sedang menggunakan aplikasi.
  - Badge unread pada ikon pesan di navbar tidak terbarui secara instan kecuali pengguna me-refresh atau membuka halaman pesan secara manual.
  - Pada ruang chat yang baru pertama kali dibuat dari halaman profil, pesan balasan lawan bicara sering kali tidak muncul secara otomatis kecuali halaman ditutup lalu dibuka kembali.

- **Akar Masalah (Root Cause)**:
  1. **Subscription Realtime Terlokalisasi di Layar DM**:
     Method `subscribeToInbox()` saat ini hanya dipanggil di dalam `initState` milik `DirectMessagesScreen`. Begitu pengguna berpindah ke layar linimasa (Home Feed) atau layar profil, subscription tersebut terputus (atau tidak aktif sejak awal jika pengguna belum pernah membuka tab pesan).
  2. **Putusnya Koneksi pada ID Percakapan Sementara (Temporary ID)**:
     Saat percakapan baru diinisiasi dari profil, ID percakapan dimulai sebagai ID sementara (bukan UUID). `ChatConversationScreen` melakukan `subscribeToMessages` ke nama channel sementara. Ketika pesan pertama dikirim dan Supabase mengembalikan UUID percakapan yang valid, `_messagesSubscription` tidak di-resubscribe ke channel UUID resmi, sehingga pesan balasan realtime dari lawan bicara terlewat.
  3. **Ketergantungan Total pada Push Notification FCM**:
     Notifikasi in-app saat ini hanya bergantung pada stream FCM (`FirebaseMessaging.onMessage`). Jika terjadi latensi pada `net.http_post` edge function Supabase atau perangkat mengalami delay koneksi Google Play Services, pesan tidak dapat memicu UI update secara instan.

---

## 2. Target File Scope

| File Path | Peran & Perubahan |
| :--- | :--- |
| [`lib/features/messages/services/direct_messages_service.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/messages/services/direct_messages_service.dart) | Pasang persistent Realtime Channel global pada `init()` untuk memantau pesan masuk milik `currentUserId` |
| [`lib/features/messages/screens/chat_conversation_screen.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/messages/screens/chat_conversation_screen.dart) | Tangani resubscription otomatis saat `updateConversationId` beralih dari temporary ID ke real UUID |
| [`lib/core/services/global_notification_service.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/core/services/global_notification_service.dart) | Sinergikan notifikasi foreground FCM dengan Realtime WebSocket lokal agar banner tidak tampil dobel (deduplication) |
| [`lib/core/services/supabase/supabase_chat_service.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/core/services/supabase/supabase_chat_service.dart) | Optimalkan query filter Realtime Channel `direct_messages` per partisipan pengguna |

---

## 3. Step-by-Step Technical Approach

### Langkah 1: Global Realtime Inbox Listener di `DirectMessagesService`
1. Di dalam `DirectMessagesService.init()`:
   - Buat channel realtime permanen (misal: `dm_inbox_user_<userId>`) yang mendengarkan event `INSERT` pada tabel `direct_messages`.
   - Filter atau periksa apakah pengirim pesan bukan `currentUser.id`.
2. Saat ada pesan baru masuk:
   - Jika pengguna **tidak sedang membuka ruang chat terkait** (`activeConversationId != incoming.conversationId`):
     - Tambahkan pesan ke cache percakapan lokal.
     - Tambah `unreadCount` pada percakapan tersebut.
     - Panggil `GlobalNotificationService.instance.showTopBanner` untuk menampilkan banner in-app notifikasi jika pesan belum ditangani oleh FCM.
   - Panggil `notifyListeners()` agar badge di navbar/app bar terbarui seketika.

### Langkah 2: Resubscription Dinamis pada Ruang Obrolan
1. Di `ChatConversationScreen`, pasang listener pada perubahan ID percakapan.
2. Ketika `conversationId` berhasil dimigrasikan dari temporary string menjadi UUID Supabase:
   - Putuskan channel lama (`_messagesSubscription?.unsubscribe()`).
   - Sambungkan ulang ke `SupabaseService.instance.subscribeToMessages(newUuid, ...)`.

### Langkah 3: In-Room Message Suppression & Anti-Duplikasi
1. Pastikan flag `activeConversationId` di `DirectMessagesService` disetel saat `ChatConversationScreen` terbuka dan di-reset ke `null` saat ditutup (`dispose`).
2. Saring notifikasi banner agar suara dan banner pesan tidak mengganggu saat pengguna sedang aktif mengetik di dalam ruang chat tersebut.

---

## 4. Definition of Done (DoD)

- [ ] Ketika pengguna lain mengirim DM dan kita sedang berada di Home Feed, badge pesan di navbar langsung bertambah tanpa perlu refresh manual.
- [ ] Banner notifikasi in-app muncul seketika saat ada pesan masuk dan kita tidak sedang membuka room chat tersebut.
- [ ] Percakapan baru yang diinisiasi dari halaman profil menerima pesan balasan secara realtime tanpa perlu reload layar.
- [ ] Tidak terjadi duplikasi pesan atau duplikasi banner notifikasi saat FCM dan Realtime WebSocket aktif bersamaan.
- [ ] Lolos static analysis `flutter analyze` dengan 0 errors.
