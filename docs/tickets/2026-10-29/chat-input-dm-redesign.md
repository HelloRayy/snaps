# Redesign Styling Input Direct Message (Chat Composer Bar)

> **Dokumen Spesifikasi Teknis & Pendekatan Arsitektur**
> - **Tanggal**: 2026-10-29
> - **Domain**: `messages / chat_composer / ui_redesign / dark_mode / micro_interactions`
> - **Status**: In Progress (Terpilih: Opsi A - Modern Unified Pill)

---

## 1. Analisis Masalah Styling Saat Ini (Current Audit)

Berdasarkan audit teknis terhadap `lib/features/messages/components/chat_composer_bar.dart`, ditemukan beberapa masalah desain dan teknis:

1. **Inkonsistensi Brand Colors**:
   - Tombol kirim saat ini menggunakan warna biru Azure hardcoded `Color(0xFF008BFF)` peninggalan slicing pen.dev lama, bukan Brand Primary resmi Snaps (`#3D38F5` / `AppColors.primary`).

2. **Shadow Terlalu Tebal & Buram (Heavy AI Glassmorphism Slop)**:
   - Menggunakan bayangan `BoxShadow(color: Color(0x1F000000), blurRadius: 35.0, offset: Offset(0, 8))` ganda dengan `BackdropFilter` sigma 25.0 pada container statis.
   - Hasilnya di perangkat terlihat kusam, berat, dan memicu overhead rendering raster GPU berlebih pada low-end Android saat keyboard aktif/tutup.

3. **Ketiadaan Dukungan Tema Gelap (Dark Mode)**:
   - Latar belakang container (`#F6F7F9`), gradien putih kapsul, warna teks (`#000000`), dan border putih masih di-hardcode. Saat dark mode aktif di `ChatConversationScreen`, composer bar tetap berwarna terang menyilaukan.

4. **Struktur Layout Asimetris**:
   - Tombol attachment foto berbentuk lingkaran terpisah (42x42) di luar kapsul teks, membuat area ketik terasa sempit pada layar HP kecil (width < 380dp).
   - Pada input multiline (2-4 baris), tombol media tertahan di pojok kiri bawah (`crossAxisAlignment: CrossAxisAlignment.end`), tampak tidak seimbang dengan baris pertama teks.

---

## 2. Pilihan Pendekatan Desain (Design Direction)

### Opsi A: Modern Unified Pill (Instagram DM & Threads Style) - [Recommended]
- **Karakter**: Seluruh kontrol (ikon attachment, field teks, dan tombol kirim/emoji) berada di dalam **satu kapsul pil rounded utuh** (radius 22dp).
- **Keunggulan**: Bersih, modern, memaksimalkan area ketik di layar HP sempit, serta konsisten dengan bahasa desain modern iOS/Android.
- **Warna & Permukaan**:
  - Light Mode: Permukaan elevated putih/slate bersih (`#F8FAFC` atau `#FFFFFF`), border tipis halus `0.8dp` (`#E2E8F0`).
  - Dark Mode: Surface `#1E293B`, border `#334155`, teks `#F8FAFC`.
- **Tombol Kirim**: Tombol bulat 32x32 warna `AppColors.primary` (`#3D38F5`) dengan ikon panah putih dan micro haptic feedback.

### Opsi B: Floating Minimalist Glass (iMessage Modern Style)
- **Karakter**: Tombol attachment `(+)` bulat terpisah di sisi kiri dengan transisi rotasi halus saat foto terlampir. Kapsul teks mandiri di sisi kanan.
- **Warna & Permukaan**: Permukaan semi-transparan adaptif dengan blur ringan (sigma 10–12dp) dan shadow ambient minimalis (`blurRadius: 12, offset: (0, 2)`).

### Opsi C: Integrated Bottom Dock (WhatsApp / Telegram Modern Style)
- **Karakter**: Composer bar menyatu mulus ke dock bawah dengan pemisah border halus di atas. Input textfield berbentuk squircle (radius 18dp) di tengah, tombol media di kiri luar, dan tombol kirim di kanan luar.

---

## 3. Spesifikasi Teknis Komponen

```dart
// Struktur Unified Pill yang diusulkan
Container(
  padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
  decoration: BoxDecoration(
    color: adaptiveBackgroundColor,
    border: Border(top: BorderSide(color: adaptiveBorderColor, width: 0.8)),
  ),
  child: Container(
    constraints: const BoxConstraints(minHeight: 44.0),
    decoration: BoxDecoration(
      color: adaptivePillColor,
      borderRadius: BorderRadius.circular(22.0),
      border: Border.all(color: adaptivePillBorderColor, width: 1.0),
    ),
    child: Row(
      children: [
        // Attachment Icon Button (Integrated inside pill or sleek external)
        // Auto-expanding multiline TextField
        // Trailing: Animated Send Button or Emoji Action
      ],
    ),
  ),
)
```

---

## 4. Cakupan File Target (Target File Scope)

| Path File | Tanggung Jawab & Rencana Perubahan |
| :--- | :--- |
| `lib/features/messages/components/chat_composer_bar.dart` | Refactor arsitektur visual composer: hilangkan heavy blur/shadow, sinkronkan `AppColors.primary`, dukung dark mode penuh, perbaiki layout attachment dan multiline |
| `lib/features/messages/screens/chat_conversation_screen.dart` | Sinkronisasi background bar terhadap background room chat agar transisi keyboard terasa seamless |

---

## 5. Kriteria Selesai (Definition of Done)

- [ ] Styling composer bar tampil bersih, modern, dan selaras dengan Design System Snaps (warna brand `#3D38F5`).
- [ ] Tampilan 100% adaptif terhadap Light Mode dan Dark Mode (teks, border, dan permukaan latar).
- [ ] Tombol kirim responsif dengan micro-interaction haptic feedback saat ditekan.
- [ ] Input multiline (1–4 baris) mengembang secara mulus tanpa layout overflow atau ikon terpotong.
- [ ] Lampiran foto thumbnail di atas input bar tetap interaktif (tambah foto & hapus foto lancar).
