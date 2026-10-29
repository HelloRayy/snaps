# Perbaikan Gestur Zoom Native & Dismiss (Zoom Behaviour Fix)

> **Dokumen Spesifikasi Teknis & Pendekatan Arsitektur**
> - **Tanggal**: 2026-10-29
> - **Domain**: `gestures / zoom / lightbox / interactive_viewer / gesture_arena`
> - **Status**: In Discussion (Approaching)

---

## 1. Analisis Teknis (Root Cause Analysis di Codebase)

Setelah penelusuran mendalam pada `lib/features/feed/components/lightbox/media_lightbox_dialog.dart` dan `lightbox_image_viewer.dart`, ditemukan 3 akar masalah teknis utama:

1. **Perebutan Gesture Arena Antara Outer GestureDetector dan InteractiveViewer (Penyebab Utama Scrolling Tidak Ter-trigger & Kaku)**:
   - Struktur hirarki saat ini:
     `Listener -> GestureDetector (vertical drag) -> PageView -> LightboxImageViewer -> GestureDetector (double tap) -> InteractiveViewer (scale/pan)`.
   - Di Flutter, `InteractiveViewer` menggunakan `ScaleGestureRecognizer` internal untuk menangani *pinch zoom* (2 jari) sekaligus *panning* (1 jari geser gambar saat diperbesar).
   - Namun, outer `GestureDetector` memiliki `VerticalDragGestureRecognizer`. Ketika pengguna menggeser gambar dengan 1 jari saat zoom, kedua recognizer masuk ke Gesture Arena.
   - Outer `GestureDetector` memenangkan arena untuk gerakan vertikal, lalu masuk ke `_handleVerticalDragUpdate`. Di dalam method tersebut terdapat guard clause:
     `if (_isCurrentZoomed || _activePointerCount > 1 || _isInteractingWithViewer) return;`.
   - **Akibat Fatal**: Outer gesture menangkap sentuhan jari tapi mengabaikannya (return kosong), sementara `InteractiveViewer` sudah terlanjur dibatalkan oleh Flutter. Sentuhan 1 jari pengguna "ditelan mentah-mentah", gambar macet total dan tidak bisa digeser.

2. **Keterlambatan Pendaratan 2 Jari (Pinch Initial Latency)**:
   - Saat manusia mencubit layar, jari pertama dan jari kedua mendarat dengan jeda waktu $10$–$50\text{ ms}$.
   - Selama rentang milidetik tersebut, jari pertama dianggap sentuhan tunggal oleh outer `GestureDetector`. Saat jari kedua mendarat, gesture recognizer sudah dalam kondisi konflik sehingga respon zoom terasa "kaku / tertahan".
   - Selain itu, `setState` dipanggil setiap kali pointer bertambah/berkurang, memicu *rebuild* seluruh tree widget tepat saat interaksi dimulai.

3. **Penguncian Geser ke Atas (Swipe Up Dismiss Diblokir Kaku)**:
   - Pada `media_lightbox_dialog.dart` baris 174–176:
     `if (_dragOffsetY < 0) { _dragOffsetY = _dragOffsetY.clamp(-30.0, 0.0); }`
   - Dan pada `_handleVerticalDragEnd` baris 188:
     `if (_dragOffsetY > 110.0 || velocity > 650.0) { Navigator.of(context).pop(); }`
   - Logika ini hanya mengizinkan tarikan ke bawah (nilai offset positif). Jika pengguna mengusap ke atas (*swipe up*), gambar membentur tembok limit `-30dp` lalu kembali ke tengah (`_springBackToZero()`), sehingga gestur swipe up tidak pernah menutup dialog.

---

## 2. Penjelasan Non-Teknis (Bahasa Manusia / Analogi Sederhana)

Bayangkan ada dua orang satpam yang menjaga pintu yang sama:
- **Satpam Luar (Outer Drag)**: Bertugas mengecek apakah pengguna mau menutup foto dengan geser ke bawah.
- **Satpam Dalam (InteractiveViewer)**: Bertugas mengizinkan pengguna memperbesar foto dan menggeser foto yang sudah diperbesar.

Ketika foto sedang diperbesar dan kamu ingin menggeser foto memakai 1 jari:
1. **Satpam Luar** langsung menyambar tangan kamu duluan: *"Eh, ada gerakan tangan nih, biar saya yang urus!"*
2. **Satpam Dalam** akhirnya mengalah dan melepas kendali.
3. Tapi setelah menyambar tanganmu, **Satpam Luar** sadar: *"Loh, fotonya lagi dizoom, bukan urusan saya ah."* Lalu dia diam saja dan tidak melakukan apa-apa.
4. **Hasilnya**: Tanganmu bergerak di layar, tapi fotonya sama sekali tidak bergerak karena kedua satpam saling lempar tanggung jawab.

Begitu juga saat mencubit dengan 2 jari: kedua jarimu hampir mustahil menyentuh layar di seperseribu detik yang sama persis. Jari pertama sempat ditahan oleh Satpam Luar sebentar sebelum Satpam Dalam sadar bahwa kamu sedang mencubit dengan dua jari. Itu yang membuat zoom terasa kaku dan tersendat.

Untuk swipe-up: aplikasi sengaja diberi ganjalan kaku di bagian atas. Kamu hanya boleh menarik foto ke bawah untuk keluar, sedangkan kalau didorong ke atas layarnya menabrak tembok mentok.

---

## 3. Rencana Solusi Pendekatan Baru (Native-Feel Architecture)

### Solusi 1: Nonaktifkan Total Outer Vertical Drag Saat Gambar Zoomed
- Ubah pengkondisian pada outer `GestureDetector`:
  Ketika gambar berada dalam status `_isCurrentZoomed` ($> 1.02x$), properti `onVerticalDragStart`, `onVerticalDragUpdate`, dan `onVerticalDragEnd` diisi `null` (atau tidak aktif).
- Dengan menonaktifkan recognizer vertikal luar saat zoom aktif, `InteractiveViewer` memiliki kendali 100% tanpa lawan di Gesture Arena. Pengguna bisa menggeser foto bebas ke segala arah (atas, bawah, kiri, kanan) dengan 1 jari secara super mulus.

### Solusi 2: Dukungan Penuh Dual-Direction Dismiss (Swipe Down & Swipe Up)
- Buka limitasi `clamp(-30.0, 0.0)` pada tarikan negatif.
- Izinkan `_dragOffsetY` bergerak bebas ke atas (negatif) maupun ke bawah (positif) saat skala gambar `1.0x`.
- Opacity latar belakang dan skala gambar mengecil proporsional terhadap jarak mutlak (`_dragOffsetY.abs()`).
- Pada `_handleVerticalDragEnd`:
  Jika `_dragOffsetY.abs() > 110.0` atau kecepatan `velocity.abs() > 650.0`, tutup dialog (`Navigator.pop`).

### Solusi 3: Eliminasi setState pada Tracking Pointer (Zero Latency)
- Ganti variabel state `_activePointerCount` dan `_dragOffsetY` dengan `ValueNotifier`.
- Pembacaan pointer tidak lagi memicu rebuild widget menyeluruh, sehingga inisiasi 2 jari seketika diproses tanpa jeda frame.

---

## 4. Target File Scope

| File Path | Perubahan Kunci |
| :--- | :--- |
| `lib/features/feed/components/lightbox/media_lightbox_dialog.dart` | Nonaktifkan drag vertikal luar saat zoom; buka batasan swipe up dismiss |
| `lib/features/feed/components/lightbox/lightbox_image_viewer.dart` | Optimasi `panEnabled` dan hilangkan rebuild berlebih di dalam `InteractiveViewer` |
| `lib/core/components/avatar/avatar_viewer_dialog.dart` | Terapkan perbaikan yang sama pada viewer foto profil pengguna |

---

## 5. Kriteria Selesai (Definition of Done)

- [ ] Saat gambar diperbesar (zoom in), pengguna dapat menggeser (pan) gambar ke segala arah menggunakan 1 jari dengan mulus tanpa macet.
- [ ] Gestur cubit zoom in dan zoom out dengan dua jari merespons seketika tanpa terasa kaku atau tersendat.
- [ ] Saat skala normal (1.0x), mengusap gambar ke bawah (swipe down) maupun ke atas (swipe up) dapat menutup layar lightbox secara mulus.
- [ ] Latar belakang merespons tarikan ke atas dan ke bawah dengan memudar secara proporsional sebelum dialog tertutup.
