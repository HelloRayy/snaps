# Pendekatan Teknis SNAPS-101: Perbaikan CTA Beli Sekarang Tidak Memunculkan Card Produk di DM yang Sudah Ada

> **Spesifikasi Teknis & Panduan Implementasi AI Agent**
> - **ID Tiket**: SNAPS-101
> - **Status**: Todo (High)
> - **Domain**: `feed / messages / social_commerce / bug_fix / state_management`
> - **Target Tanggal**: 2026-11-08

---

## 1. Analisis Masalah & Root Cause (Root Cause Analysis)

### Masalah yang Terjadi
Saat pengguna mengklik tombol "Beli Sekarang" dari postingan produk jualan di Feed:
- Jika pengguna **belum pernah** chatting dengan penjual: Obrolan baru dibuat, dan `ProductContext` (kartu info produk & tombol checkout) berhasil tampil di atas room chat.
- Jika pengguna **sudah pernah** chatting dengan penjual sebelumnya: Obrolan yang sudah ada ditemukan dan dibuka kembali, tetapi **kartu produk tidak muncul / hilang** di room chat.

### Akar Masalah pada Kode
Pada `lib/features/feed/utils/social_commerce_navigator.dart`:
```dart
final existing = DirectMessagesService.instance.findConversationByUserId(post.author.id);
if (existing != null) {
  conv = existing; // <-- Masalah: productContext dari post baru tidak di-inject ke conversation lama!
}
```
Dan pada `DirectMessagesService.dart`:
```dart
void addOrUpdateConversation(Conversation conversation) {
  final existingRealIdx = _conversations.indexWhere((c) => c.id == conversation.id);
  if (existingRealIdx != -1) {
    final oldConv = _conversations[existingRealIdx];
    // Masalah: Menggunakan oldConv.productContext lebih dulu sebelum memeriksa context baru
    productContext: oldConv.productContext ?? _conversations[existingRealIdx].productContext,
  }
}
```
Akibatnya:
1. Obrolan lama yang sudah memiliki `productContext = null` (atau context produk lama yang berbeda) tidak diperbarui dengan produk baru yang baru saja di-klik "Beli Sekarang".
2. Di layar `ChatConversationScreen`, banner produk (`OrderConfirmationCard` atau `productContext`) hanya membaca apa yang ada di state awal obrolan lama, sehingga gagal menampilkan kartu produk yang hendak dibeli.

---

## 2. File Terkait (Target Files)

- `lib/features/feed/utils/social_commerce_navigator.dart` (Titik pemicu navigasi feed ke DM)
- `lib/features/messages/services/direct_messages_service.dart` (Penyimpanan dan mutasi state percakapan)
- `lib/features/messages/screens/chat_conversation_screen.dart` (Layar ruang percakapan & render kartu produk)

---

## 3. Rencana Solusi & Implementasi AI Agent

1. **Update `SocialCommerceNavigator`**:
   - Jika `existing != null`, perbarui instans percakapan lama dengan menyuntikkan `productContext` baru dari produk yang sedang di-klik:
     ```dart
     if (existing != null) {
       conv = existing.copyWith(
         productContext: productCtx,
       );
     }
     ```
2. **Koreksi Logika Penggabungan di `DirectMessagesService`**:
   - Di method `addOrUpdateConversation`, prioritaskan `conversation.productContext` yang baru masuk di atas data lama:
     ```dart
     productContext: conversation.productContext ?? oldConv.productContext,
     ```
3. **Penyelarasan UI di `ChatConversationScreen`**:
   - Pastikan ketika pengguna masuk dari CTA "Beli Sekarang", state `productContext` segera di-render di atas timeline pesan, lengkap dengan rincian harga, foto thumbnail, dan tombol lanjut COD/Checkout.
