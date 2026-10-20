# [SNAPS-88] fix(OTA-script): issue OTA not worked at all

> **Ticket Metadata**:
> - **Sequence**: SNAPS-88
> - **Priority**: HIGH
> - **Domain**: `release / ota / scripts / supabase_storage / in_app_update`
> - **Status**: Done

---

## 1. Problem Statement & Root Cause Analysis

- **Gejala Masalah**:
  - Alur rilis OTA menggunakan skrip bawaan `./scripts/auto_release.sh` tidak berfungsi di HP murid saat versi baru dirilis.
  - Unduhan APK sering mengalami kegagalan / 404 karena masih mengarahkan download URL ke GitHub Releases (`https://github.com/HelloRayy/snaps/releases/download/...`) yang terproteksi hak akses atau mengalami masalah redirect AWS S3 pada `ota_update` Android.
  - Skrip lama tidak mengunggah biner APK ke Supabase Storage Public CDN (`app_releases`), tidak menonaktifkan versi sebelumnya (`is_active: false`), dan mencetak version code mentah (< 2000) pada fallback SQL.
  - Terjadi fragmentasi skrip rilis (`auto_release.sh`, `publish_ota.sh`, `update_release.sh`, `release.sh`, `release_v1_0_27.sh`).
  - Pada sisi aplikasi Flutter (`UpdateInfoBottomSheet`), saat download `ota_update` gagal atau diblokir izin Android 13/14, tidak tersedia tombol fallback manual browser, sehingga pengguna terjebak pada pesan error.

- **Akar Masalah (Root Cause)**:
  1. **Fragmentasi Skrip & Skrip Usang**: `auto_release.sh` yang menjadi rujukan `AGENTS.md` belum dimigrasi ke arsitektur Supabase Storage CDN yang dibangun di `publish_ota.sh`.
  2. **Ketiadaan Fallback Browser**: `UpdateInfoBottomSheet` hanya menyediakan tombol "Keluar dari Aplikasi" saat terjadi kegagalan jaringan atau instalasi native.

---

## 2. Target File Scope

| File Path | Peran & Perubahan |
| :--- | :--- |
| [`scripts/auto_release.sh`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/scripts/auto_release.sh) | Menjadi Single Source of Truth skrip rilis OTA dengan engine Supabase Storage CDN, mirror GitHub, deaktifasi versi lama, dan auto-bumping |
| [`scripts/publish_ota.sh`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/scripts/publish_ota.sh) | Dijadikan wrapper bersih yang meneruskan pemanggilan ke `auto_release.sh` |
| [`update_release.sh`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/update_release.sh) | Dijadikan wrapper bersih di root yang meneruskan pemanggilan ke `scripts/auto_release.sh` |
| [`lib/core/components/update_info_bottom_sheet.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/core/components/update_info_bottom_sheet.dart) | Ditambahkan fail-safe action "Unduh Manual via Browser" (`url_launcher`) saat error dan tautan alternatif |
| [`docs/RELEASE_OTA_GUIDE.md`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/docs/RELEASE_OTA_GUIDE.md) | Diperbarui agar mereferensikan `./scripts/auto_release.sh` sebagai standar rilis utama |

---

## 3. Step-by-Step Technical Approach

### Langkah 1: Konsolidasi Skrip Rilis ke `scripts/auto_release.sh`
1. Terapkan engine rilis lengkap dengan flag `--dry-run`, `--skip-build`, `-y/--yes`, `--arm64`, dan `auto`.
2. Pastikan biner APK otomatis di-upload ke bucket publik Supabase Storage: `${SUPABASE_URL}/storage/v1/object/public/app_releases/v${VERSION_NAME}/app-release.apk`.
3. Nonaktifkan versi lama di database via `PATCH /rest/v1/app_versions?version_code=lt.${REAL_VERSION_CODE}`.
4. Pastikan `REAL_VERSION_CODE` konsisten bernilai $\ge 2000$.

### Langkah 2: Pembersihan Skrip Legacy
1. Ubah `publish_ota.sh` dan `update_release.sh` menjadi wrapper shell script yang memanggil `scripts/auto_release.sh`.
2. Hapus skrip usang `scripts/release.sh` dan `scripts/release_v1_0_27.sh`.

### Langkah 3: Penambahan Fail-Safe Browser di UI Flutter
1. Import `package:url_launcher/url_launcher.dart` di `UpdateInfoBottomSheet`.
2. Implementasikan `_openInBrowser()` untuk membuka `widget.update.downloadUrl` secara eksternal.
3. Tambahkan tombol "Unduh Manual via Browser" pada kotak error dialog update.
4. Tambahkan teks tautan "Kendala pembaruan? Unduh via browser" di bawah tombol update utama.

---

## 4. Definition of Done (DoD)

- [x] `./scripts/auto_release.sh --dry-run auto "test"` berjalan sukses tanpa error.
- [x] APK rilis di-host pada Supabase Storage Public CDN langsung tanpa bergantung pada GitHub asset private.
- [x] Rilis lama otomatis dinonaktifkan di tabel Supabase `app_versions`.
- [x] Tersedia tombol fail-safe browser di `UpdateInfoBottomSheet` saat terjadi kendala instalasi native.
- [x] Skrip rilis usang telah dibersihkan dari repositori.
