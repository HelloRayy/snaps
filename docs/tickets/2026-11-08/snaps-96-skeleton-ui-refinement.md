# Pendekatan Teknis SNAPS-96: Skeleton UI Refinement (Gray Rectangles & Circle Avatar)

> **Spesifikasi Teknis & Panduan Implementasi AI Agent**
> - **ID Tiket**: SNAPS-96
> - **Status**: Todo (Urgent)
> - **Domain**: `core / skeleton / shimmer / performance / ui_polish`
> - **Target Tanggal**: 2026-11-08

---

## 1. Analisis Masalah & Kebutuhan (Problem Audit)

### Kondisi Saat Ini
1. Komponen skeleton saat ini (`lib/core/components/skeleton/post_card_skeleton.dart`) memuat placeholder skeleton untuk media gambar postingan (`AspectRatio(aspectRatio: 16 / 9, ...)`).
2. Ketika loading feed atau pindah tab, skeleton media gambar memakan area viewport yang terlalu besar dan membuat efek flickering yang kurang nyaman saat postingan teks tanpa gambar masuk menggantikan placeholder.
3. Struktur skeleton belum seragam dan terlalu berat bagi ponsel Android entry-level siswa SMKN 8.

### Kebutuhan Tiket
- Format visual skeleton baru untuk feed:
  - **1 Circle**: Placeholder foto profil / avatar pengguna (ukuran 40x40 atau 44x44 dp).
  - **3 Rectangle Columns**: Placeholder teks abu-abu bertingkat:
    1. Rectangle 1: Nama pengguna & badge kelas/jurusan (lebar ~35%, tinggi 12dp).
    2. Rectangle 2: Baris utama konten postingan (lebar ~85%, tinggi 14dp).
    3. Rectangle 3: Baris penjelas / subteks (lebar ~60%, tinggi 12dp).
  - **Dilarang memuat skeleton image/gambar**: Sesuai instruksi tiket ("tidak load image skeleton"), hilangkan block skeleton box gambar 16:9 agar layout tetap ringkas dan fluid.

---

## 2. File Terkait (Target Files)

- `lib/core/components/skeleton/post_card_skeleton.dart` (Komponen leaf utama)
- `lib/core/components/skeleton/snaps_shimmer.dart` (Base shimmer effect container)
- `lib/core/theme/app_colors.dart` (Token warna abu-abu netral untuk placeholder)

---

## 3. Rencana Solusi & Implementasi AI Agent

1. **Refactor `PostCardSkeleton`**:
   - Buka `lib/core/components/skeleton/post_card_skeleton.dart`.
   - Modifikasi struktur `Row`:
     - Sisi kiri: Lingkaran shimmer `Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: grayShimmer))`.
     - Sisi kanan (`Expanded`): `Column(crossAxisAlignment: CrossAxisAlignment.start)` berisi 3 rectangle abu-abu dengan `BorderRadius.circular(4)`.
   - Hapus blok container/aspect ratio yang merender skeleton gambar.
2. **Penggunaan Token Warna**:
   - Gunakan `AppColors.border` atau palette `Color(0xFFE2E8F0)` / `Color(0xFFCBD5E1)` untuk light mode, dan `Color(0xFF334155)` untuk dark mode.
3. **Optimasi Frame Rate**:
   - Jadikan sub-widgets `const` jika tidak dinamis, pastikan shimmer animation loop tidak membebani GPU saat list di-scroll.
