# Perbaikan Gestur Zoom Native (Zoom Behaviour Fix)

> **Dokumen Spesifikasi Teknis & Pendekatan Arsitektur**
> - **Tanggal**: 2026-10-29
> - **Domain**: `gestures / zoom / lightbox / interactive_viewer / physics`
> - **Status**: In Discussion (Approaching)

---

## 1. Analisis Masalah: Mengapa Gestur Zoom Terasa Kurang Native?

Dibandingkan aplikasi kompetitor kelas dunia (Instagram, Twitter/X, Telegram, iOS Photos), implementasi zoom di Snaps saat ini (`LightboxImageViewer` dan `MediaLightboxDialog`) memiliki 4 batasan mendasar yang menyebabkan feel interaksi terasa kaku atau tidak alami:

1. **Penguncian Total PageView saat Zoom (Edge-Pan Block)**:
   - *Masalah*: Saat gambar diperbesar (`_isCurrentZoomed = true`), `PageView` diubah menjadi `NeverScrollableScrollPhysics()`.
   - *Dampak*: Pengguna tidak bisa menggeser ke foto berikutnya/sebelumnya meskipun sudah menggeser gambar sampai ke batas ujung tepi kiri/kanan. Pada aplikasi native (Twitter/Telegram), saat viewport gambar mencapai ujung tepi horizontal, sisa tarikan jari secara mulus mengalirkan halaman ke foto selanjutnya.
2. **Ketiadaan Fluid Pinch-Dismiss (Cubitan Mengecil untuk Menutup)**:
   - *Masalah*: Swipe-to-dismiss hanya aktif saat skala persis `1.0x` dengan satu jari.
   - *Dampak*: Pada Instagram dan Telegram, pengguna bisa mencubit gambar menjadi lebih kecil ($< 1.0x$) sekaligus menariknya ke bawah dalam satu gerakan kontinu untuk menutup dialog. Di Snaps, cubitan $< 1.0x$ tertahan oleh batas kaku dan langsung memicu animasi spring-back yang membatalkan gesture tutup.
3. **Rebuild Berat Akibat setState pada Pointer Listener**:
   - *Masalah*: Setiap kali jari menyentuh atau terangkat dari layar (`onPointerDown`, `onPointerUp`), `MediaLightboxDialog` memanggil `setState()` untuk mengubah `_activePointerCount`.
   - *Dampak*: Terjadi micro-stutter atau drop frame tepat di awal inisiasi zoom dua jari, membuat respon pinch terasa ada jeda (*latency*).
4. **Presisi Titik Fokus Double-Tap (Focal Point Alignment)**:
   - *Masalah*: Perhitungan translasi matriks saat double-tap masih mengasumsikan koordinat lokal sederhana tanpa memperhitungkan pergeseran rasio aspek asli gambar (FitWidth vs FitHeight).
   - *Dampak*: Gambar terkadang melompat ke titik yang sedikit bergeser dari titik ketukan jari pengguna.

---

## 2. Benchmark Pendekatan Aplikasi Kompetitor

- **Telegram / Twitter/X (Unified Matrix & Boundary Hand-off)**:
  - Menggunakan satu controller transformasi terpadu.
  - Saat skala $> 1.0x$, jika pengguna melakukan pan horizontal dan posisi konten mencapai tepi kiri/kanan matriks, threshold gesekan dilepaskan ke transisi halaman berikutnya.
  - Memungkinkan dismiss fluida dengan gerakan mencubit mengecil ($< 1.0x$) dan tarikan vertikal simultan.
- **Instagram (Feed Inline Pinch vs Lightbox)**:
  - Di feed: Cubit dua jari langsung mengangkat gambar ke overlay sementara tanpa membuka lightbox baru, lalu kembali ke posisi semula dengan pegas (*spring physics*) saat jari diangkat.
  - Di lightbox/viewer: Double-tap memiliki akselerasi animasi kubik cepat (180–200ms) dengan titik bidik presisi.

---

## 3. Rencana Solusi Teknis & Arsitektur

### Langkah 1: Transisi Elastis Edge Pan ke PageView
- Hilangkan `NeverScrollableScrollPhysics()` statis.
- Pasang deteksi batas translasi matriks horizontal (`matrix.getTranslation().x`).
- Jika offset horizontal mencapai batas ujung gambar ($dx = 0$ atau $dx = \text{maxScroll}$), izinkan `DragUpdate` diteruskan ke `PageController` dengan resistensi gesekan elastis.

### Langkah 2: Fluid Pinch-Down Dismiss
- Izinkan skala menyusut hingga `0.65x` dengan resistensi pegas elastis (*rubber-band effect*).
- Jika skala $< 0.85x$ dan terdapat pergeseran vertikal $> 60dp$, saat jari diangkat (`onInteractionEnd`), anggap sebagai perintah dismiss dan tutup dialog dengan transisi memudar halus.

### Langkah 3: Optimasi State Menggunakan ValueNotifier (Zero Rebuild Overhead)
- Gantikan `setState` pada `onPointerDown`/`onPointerUp` dan `_dragOffsetY` dengan `ValueNotifier<int>` dan `ValueNotifier<double>`.
- Gunakan `ValueListenableBuilder` atau `AnimatedBuilder` hanya pada bagian transformasi gambar, menjaga tree dialog tetap statis tanpa rebuild menyeluruh.

---

## 4. Cakupan File Target

| File Path | Peran & Perubahan |
| :--- | :--- |
| `lib/features/feed/components/lightbox/lightbox_image_viewer.dart` | Refaktor transformasi matriks, rubber-band boundary, dan integrasi fluid pinch dismiss |
| `lib/features/feed/components/lightbox/media_lightbox_dialog.dart` | Eliminasi `setState` berlebih, pasang transisi edge-pan horizontal ke `PageView` |
| `lib/core/components/avatar/avatar_viewer_dialog.dart` | Sinkronisasi perilaku zoom native pada peninjau foto profil |

---

## 5. Kriteria Selesai (Definition of Done)

- [ ] Pinch-to-zoom terasa instan tanpa jeda frame awal berkat eliminasi rebuild menyeluruh.
- [ ] Gambar dapat dicubit mengecil ($< 1.0x$) dan ditarik ke bawah secara bersamaan untuk menutup layar (*fluid pinch-dismiss*).
- [ ] Saat gambar diperbesar ($> 1.0x$), menggeser sampai ujung tepi gambar memungkinkan perpindahan halaman foto berikutnya secara alami.
- [ ] Ketuk dua kali (*double-tap*) memperbesar gambar tepat di titik ketukan dengan animasi pegas yang responsif.
