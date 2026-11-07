# Pendekatan Teknis SNAPS-100: Evaluasi Input Stok Barang vs. Penghapusan Informasi Kuantitas

> **Spesifikasi Teknis & Panduan Implementasi AI Agent**
> - **ID Tiket**: SNAPS-100
> - **Status**: Todo (Medium)
> - **Domain**: `create_post / selling_system / commerce / ux_decision`
> - **Target Tanggal**: 2026-11-08

---

## 1. Analisis Masalah & Kebutuhan (Problem Audit)

### Konteks Ekosistem SMKN 8 Semarang
1. Snaps Market berfokus pada dua tipe barang sekolah:
   - Barang bekas pakai / preloved (buku pelajaran bekas, seragam bekas, alat gambar DKV bekas): Kuantitas hampir selalu 1 unit (*one-off item*).
   - Karya/jasa kejuruan (snack Kuliner, jasa cetak merchandise DKV, jasa coding PPLG): Sistem pemesanan dibuat berdasarkan pesanan langsung via Direct Message (DM) COD, bukan sistem pergudangan e-commerce skala besar.
2. Memaksa siswa mengisi field "Jumlah Stok / Total Barang" menambah friksi (*cognitive load*) saat membuat postingan jualan. Siswa sering bingung harus mengisi angka berapa jika barangnya hanya 1 atau sistemnya pre-order.

### Evaluasi Opsi Solusi
- **Opsi A (Rekomendasi Utama)**: Hapus field total stok wajib dari formulir pembuatan postingan jualan. Secara default sistem menganggap item tersedia (status: `Tersedia`), dan penjual dapat menandai `Terjual` secara manual via tombol aksi sekali sentuh.
- **Opsi B (Opsional Toggle Kuantitas)**: Sediakan field kuantitas yang sifatnya *opsional* (hanya jika penjual menyalakan switch "Barang lebih dari 1").

---

## 2. File & Modul Terkait (Target Files)

- `lib/features/create_post/screens/create_post_screen.dart` atau `lib/features/create_post/components/` (Form input produk)
- `lib/features/feed/models/post_model.dart` (Model postingan produk)
- `lib/features/checkout/` & `lib/features/messages/` (Alur validasi ketersediaan barang)

---

## 3. Rencana Solusi & Implementasi AI Agent

1. **Formulir Buat Postingan**:
   - Hilangkan kewajiban input numerik stok barang.
   - Sederhanakan formulir postingan jualan menjadi 3 elemen esensial: **Judul Produk**, **Harga (Rp)**, dan **Kondisi/Deskripsi Singkat**.
2. **Status Produk**:
   - Gunakan status biner sederhana yang ramah siswa: `available` (Tersedia) dan `sold_out` (Sudah Terjual).
   - Di tampilan postingan jualan, tampilkan badge hijau "Tersedia" atau abu-abu "Terjual" tanpa membingungkan siswa dengan angka sisa stok (misal: "Stok: 1").
3. **Penyelarasan Alur Checkout / DM**:
   - Saat pembeli menekan tombol "Beli Sekarang", sistem langsung mengasumsikan kuantitas 1 paket/unit pesanan tanpa meminta input kuantitas bertingkat.
