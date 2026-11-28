# Catatan Ide: Peningkatan Algoritma Feed Snaps

**Status:** Ditunda (Nice to Have)  
**Tanggal:** 2026-11-28  
**Konteks:** Diskusi optimasi feed utama (`lib/core/services/supabase/supabase_feed_service.dart`) yang saat ini masih menggunakan urutan kronologis murni (`created_at DESC`).

## Latar Belakang Masalah
- Postingan lama yang punya nilai tinggi (diskusi ramai atau produk bagus yang masih tersedia) tenggelam jauh di bawah (~50+ post) untuk user baru atau user yang jarang membuka aplikasi.
- Namun, mengubah seluruh timeline menjadi ranking berbasis engagement berisiko membuat feed terasa "basi" jika volume posting harian masih di bawah ~100 post/hari.

## Opsi Solusi (Saat Dibutuhkan Nanti)
1. **Slot Injection di Timeline Utama (Rekomendasi):**
   - Tetap pakai urutan `Terbaru` sebagai default, lalu sisipkan 1 postingan lama bernilai tinggi (engagement tinggi & belum `sold_out`) di posisi ke-4 atau setiap 10 post.
   - User langsung melihat tanpa harus pindah tab.
2. **Tab / Filter `Populer` (Alternatif):**
   - Pisahkan feed menjadi `Terbaru` dan `Populer` (7–14 hari terakhir), dengan catatan ada risiko user jarang mengklik tab kedua.

## Syarat Eksekusi
- Hanya dikerjakan jika trafik posting harian sudah ramai atau ada keluhan nyata dari siswa bahwa konten penting/bagus sulit ditemukan.
