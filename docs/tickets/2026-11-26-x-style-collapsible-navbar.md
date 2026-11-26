# Tiket: Redesign Floating Navbar Ala X.com (Collapsible & Dynamic FAB)

**Tanggal**: 2026-11-26
**Domain**: Navigation / Shell (`lib/features/feed/components/navigation/` atau root navigation)
**Status**: Siap Dikerjakan (Menunggu Eksekusi)

---

## Ringkasan Desain & Interaksi

Mengubah bottom navigation bar menjadi **floating pill** ala X.com dengan efek kaca (*backdrop blur*) dan perilaku adaptif terhadap arah scroll:

1. **Saat Scroll ke Atas / Diam (Expanded State)**:
   - Navbar terbuka penuh berbentuk kapsul melayang (`rounded-full`) berisi seluruh ikon tab utama dengan efek `BackdropFilter` blur + border tipis.
   - Tombol **FAB (Buat Utas/Produk)** berada di posisi **naik** (di atas kanan navbar).

2. **Saat Scroll ke Bawah (Collapsed State)**:
   - Navbar melipat mulus ke kiri menjadi **satu tombol bulat** yang hanya menampilkan ikon tab yang sedang aktif.
   - Tombol **FAB** ikut **turun** sejajar ke kanan bawah layar sehingga area baca konten jauh lebih luas.

---

## Catatan Teknis & Edge Case

- **Scroll Threshold**: Gunakan ambang batas jarak scroll (misal `> 16 px`) sebelum memicu transisi buka/tutup agar navbar tidak berkedip saat jempol bergeser sedikit.
- **Sinkronisasi Motion**: Animasi lebar kapsul navbar dan posisi vertikal FAB disinkronkan menggunakan kurva `Curves.easeOutCubic` (~250ms).
- **Performa Blur**: Bungkus `BackdropFilter` dengan `ClipRRect` ketat seukuran kapsul saja agar frame rate tetap stabil di 60/120 FPS.
- **Bottom Padding Konten**: Pastikan daftar feed/explore memiliki ruang bawah yang cukup agar item terakhir tidak tertutup saat navbar dalam posisi terbuka.

---

## Kriteria Selesai (Definition of Done)

- [ ] Navbar tampil sebagai kapsul melayang dengan efek kaca blur dan bayangan halus.
- [ ] Scroll ke bawah melipat navbar ke kiri menjadi lingkaran dan menurunkan posisi FAB ke kanan bawah.
- [ ] Scroll ke atas membuka kembali navbar penuh dan menaikkan posisi FAB dengan animasi sinkron.
