# Pendekatan Teknis SNAPS-99: Redesign Tombol CTA Beli Sekarang & Sinkronisasi Visual Feed

> **Spesifikasi Teknis & Panduan Implementasi AI Agent**
> - **ID Tiket**: SNAPS-99
> - **Status**: Todo (High)
> - **Domain**: `feed / components / post_card / ui_polish / cta_button`
> - **Target Tanggal**: 2026-11-08

---

## 1. Analisis Masalah & Kebutuhan (Problem Audit)

### Kondisi Saat Ini
1. Tombol floating CTA "Beli Sekarang" pada kartu postingan jualan (`lib/features/feed/components/post_card/post_buy_now_button.dart`) menggunakan latar belakang solid hitam / putih pekat (`Color(0xFF0F172A)` atau `Colors.white`) dengan shadow pekat.
2. Saat menempel di atas foto produk dalam kartu feed, background solid ini terlihat memotong estetika foto produk secara kasar dan tidak modern.
3. Kebutuhan tiket meminta tombol CTA disesuaikan agar:
   - Memiliki background yang agak transparan / semi-transparan (subtle translucent glass / frosted pill).
   - Tampilan tombol CTA di feed postingan seragam dengan style yang ditampilkan di atas banner gambar produk.

---

## 2. File & Modul Terkait (Target Files)

- `lib/features/feed/components/post_card/post_buy_now_button.dart` (Leaf widget tombol floating)
- `lib/features/feed/components/sheets/sticky_buy_bar.dart` (Bottom sticky CTA)
- `lib/core/theme/app_colors.dart` (Palette semitransparan resmi)

---

## 3. Rencana Solusi & Implementasi AI Agent

1. **Styling Semi-Transparan Bersih (Frosted Dark / Light Pill)**:
   - Ganti solid container dengan semi-translucent surface:
     - Dark overlay: `Colors.black.withValues(alpha: 0.65)` atau `Color(0xFF0F172A).withValues(alpha: 0.75)`.
     - Light overlay: `Colors.white.withValues(alpha: 0.85)`.
   - Tambahkan border halus `0.8dp` dengan warna `Colors.white.withValues(alpha: 0.2)` (pada dark overlay) untuk memberikan ketegasan kontur tanpa bayangan berat.
   - Pangkas `BoxShadow` tebal menjadi ambient shadow lembut (`blurRadius: 6.0, offset: Offset(0, 1.5)`).
2. **Kesesuaian Teks & Kontras (A11y)**:
   - Teks "Beli Sekarang" dan ikon `LucideIcons.arrowRight` tetap mempertahankan kontras tajam (putih murni `#FFFFFF` di atas dark translucent pill) sehingga tetap terbaca jelas di atas warna gambar apa pun.
3. **Penyelarasan Desain (Visual Parity)**:
   - Samakan styling pill ini dengan badge/label kategori yang melayang di atas foto produk feed.
