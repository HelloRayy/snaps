# Indeks Pendekatan Teknis Tiket - 2026-11-08

Dokumen ini merangkum analisis dan pendekatan teknis detail untuk seluruh tiket aktif (status `Todo`) di proyek Snaps Mobile (Plane.so) yang disiapkan bagi AI Agent untuk eksekusi implementasi berikutnya.

---

## Daftar Dokumen Pendekatan per Tiket

1. **[SNAPS-96: Skeleton UI Refinement](file:///home/rayhan/Windows-D/project/snapan-market-mobile/docs/tickets/2026-11-08/snaps-96-skeleton-ui-refinement.md)**
   - **Prioritas**: Urgent
   - **Ringkasan**: Menghilangkan image skeleton box yang berat di feed, menggantinya dengan struktur 1 lingkaran avatar dan 3 baris rectangle abu-abu bertingkat agar lebih ringan di ponsel siswa.

2. **[SNAPS-97: Optimasi Performa Backend & Database](file:///home/rayhan/Windows-D/project/snapan-market-mobile/docs/tickets/2026-11-08/snaps-97-backend-db-performance-optimization.md)**
   - **Prioritas**: Urgent
   - **Ringkasan**: Strategi 3 lapis (Postgres Indexing di Supabase, Keyset Pagination, dan RepaintBoundary Flutter) untuk mengeliminasi framedrop/lag pada HP low-end.

3. **[SNAPS-98: Desain Layar Aktivitas Sosial](file:///home/rayhan/Windows-D/project/snapan-market-mobile/docs/tickets/2026-11-08/snaps-98-activity-screen-social-interactions.md)**
   - **Prioritas**: High
   - **Ringkasan**: Mengadopsi pola Threads untuk notifikasi sosial (suka, komentar, follow, mention) dengan filter pills dan badge aksi mikro.

4. **[SNAPS-99: Redesign Tombol CTA Transparan & Sinkronisasi Feed](file:///home/rayhan/Windows-D/project/snapan-market-mobile/docs/tickets/2026-11-08/snaps-99-cta-button-translucent-styling.md)**
   - **Prioritas**: High
   - **Ringkasan**: Mengganti background solid tombol "Beli Sekarang" dengan frosted translucent pill yang elegan di atas gambar feed.

5. **[SNAPS-100: Evaluasi Kuantitas Stok Sistem Jualan](file:///home/rayhan/Windows-D/project/snapan-market-mobile/docs/tickets/2026-11-08/snaps-100-selling-system-stock-evaluation.md)**
   - **Prioritas**: Medium
   - **Ringkasan**: Menghapus beban input angka stok pada pembuatan postingan preloved siswa dan menggantinya dengan status biner sederhana (Tersedia / Terjual).

6. **[SNAPS-101: Perbaikan Bug Kartu Produk Hilang di DM yang Sudah Ada](file:///home/rayhan/Windows-D/project/snapan-market-mobile/docs/tickets/2026-11-08/snaps-101-sell-dm-card-product-persistence-fix.md)**
   - **Prioritas**: High
   - **Ringkasan**: Memperbaiki logika penimpaan `productContext` saat pengguna mengklik "Beli Sekarang" ke penjual yang riwayat obrolannya sudah ada di DM.
