# Tiket: Titik Temu COD & Lokasi Dinamis (Hapus Default Kaku)

**Tanggal**: 2026-11-26
**Domain**: Locations & Checkout (`lib/features/locations/`, `lib/core/services/meeting_point_service.dart`, Supabase)
**Status**: Backlog (UI dibahas terpisah sebelum eksekusi)

---

## Ringkasan Masalah

Daftar titik temu COD / lokasi saat ini masih bersifat kaku dan menggunakan data default statis (seperti Lab PPLG 2, dll). Hal ini membatasi fleksibilitas siswa maupun admin jika ada lokasi baru, perubahan nama ruangan, atau titik temu kustom di lingkungan sekolah.

---

## Ruang Lingkup Fitur (Approach)

1. **Sumber Data Lokasi Dinamis**:
   - Lepaskan ketergantungan pada daftar lokasi hardcoded/default statis.
   - Ambil daftar titik temu secara dinamis dari database (Supabase) dan/atau izinkan input lokasi kustom sesuai kebutuhan pengguna/admin.

2. **Pengelolaan Lokasi**:
   - Siapkan mekanisme agar daftar titik temu bisa ditambah, diubah, atau dinonaktifkan tanpa perlu merilis ulang aplikasi.

3. **Desain UI & Alur Pilih Lokasi**:
   - **TBD**: Tampilan dan pengalaman memilih/menambah lokasi dinamis akan dibahas dan disepakati bersama sebelum masuk tahap implementasi.

---

## Kriteria Selesai (Definition of Done)

- [ ] Daftar titik temu COD tidak lagi bergantung pada data hardcoded statis (Lab PPLG 2, dll).
- [ ] Perubahan atau penambahan lokasi baru langsung tercermin secara dinamis di aplikasi.
- [ ] Desain UI pemilihan lokasi disetujui dan terintegrasi mulus dengan alur Checkout & Create Post.
