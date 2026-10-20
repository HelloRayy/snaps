# [SNAPS-87] fix(zoom-behaviour): fix zoom finger gesture

> **Ticket Metadata**:
> - **Sequence**: SNAPS-87
> - **Priority**: MEDIUM
> - **Domain**: `gestures / zoom / lightbox / pinch_scale / interactive_viewer`
> - **Status**: DONE (Implemented in commit 2d59d42)

---

## 1. Problem Statement & Root Cause Analysis

- **Gejala Masalah**:
  - Saat pengguna mencoba melakukan pinch-to-zoom menggunakan dua jari pada gambar di tampilan pratinjau penuh (*Media Lightbox* atau *Avatar Dialog*), gambar sering kali tersentak ke bawah atau layar langsung tertutup (*dismiss*), bukannya membesar.
  - Pengguna merasa gesture zoom tidak responsif dan terasa "kaku" atau "berebut" dengan gesture usap layar (*swipe*).
  - Tidak tersedianya gesture ketuk dua kali (*double-tap to zoom*) yang merupakan standar interaksi platform (Instagram/Twitter/iOS Photos).

- **Akar Masalah (Root Cause)**:
  1. **Konflik Antara `GestureDetector` Vertikal dan `InteractiveViewer`**:
     Di [`lib/features/feed/components/lightbox/media_lightbox_dialog.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/feed/components/lightbox/media_lightbox_dialog.dart), seluruh area dibungkus oleh `GestureDetector(onVerticalDragUpdate: _handleVerticalDragUpdate, onVerticalDragEnd: ...)`.
     Ketika dua jari diletakkan di layar untuk memulai zoom, pergerakan jari pertama langsung memicu event drag vertikal sebelum `InteractiveViewer` sempat menaikkan skala di atas threshold `1.05` (`_isCurrentZoomed`). Akibatnya, `_dragOffsetY` bertambah dan memicu animasi spring-back atau menutup layar secara tidak sengaja.
  2. **Pengabaian Deteksi Multi-Touch / Pointer Count**:
     `_handleVerticalDragUpdate` tidak memeriksa jumlah sentuhan aktif di layar (`PointerDownEvent`). Sentuhan dua jari seharusnya secara instan menonaktifkan gesture drag-to-dismiss vertikal.
  3. **Ketiadaan Double-Tap Zoom Controller**:
     Di `LightboxImageViewer` dan `AvatarViewerDialog`, `TransformationController` hanya diubah secara pasif melalui cubitan jari, tanpa animasi transisi zoom terarah berbasis posisi ketukan (*tap position*).

---

## 2. Target File Scope

| File Path | Peran & Perubahan |
| :--- | :--- |
| [`lib/features/feed/components/lightbox/media_lightbox_dialog.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/feed/components/lightbox/media_lightbox_dialog.dart) | Pasang deteksi pointer count (`Listener` dengan tracking jumlah sentuhan aktif) untuk menonaktifkan drag-to-dismiss saat $\ge 2$ jari berada di layar |
| [`lib/features/feed/components/lightbox/lightbox_image_viewer.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/feed/components/lightbox/lightbox_image_viewer.dart) | Implementasikan double-tap to zoom in (2.5x terpusat pada titik sentuh) dan double-tap reset (1.0x) dengan kurva animasi mulus |
| [`lib/core/components/avatar/avatar_viewer_dialog.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/core/components/avatar/avatar_viewer_dialog.dart) | Samakan mekanisme isolasi pointer multi-touch agar pembesaran foto profil terbebas dari tarikan vertikal |

---

## 3. Step-by-Step Technical Approach

### Langkah 1: Isolasi Pointer Multi-Touch di `MediaLightboxDialog`
1. Tambahkan variabel pelacak sentuhan:
   ```dart
   int _activePointerCount = 0;
   ```
2. Bungkus area sentuh dengan widget `Listener`:
   ```dart
   Listener(
     onPointerDown: (_) => setState(() => _activePointerCount++),
     onPointerUp: (_) => setState(() => _activePointerCount = (_activePointerCount - 1).clamp(0, 10)),
     onPointerCancel: (_) => setState(() => _activePointerCount = (_activePointerCount - 1).clamp(0, 10)),
     child: GestureDetector(
       onVerticalDragUpdate: (details) {
         if (_isCurrentZoomed || _activePointerCount > 1) return;
         // drag update logic
       },
       ...
     ),
   )
   ```
3. Hal ini menjamin bahwa setiap kali ada 2 jari atau lebih di layar, gesture drag vertikal diblokir total, memberikan hak kontrol 100% kepada `InteractiveViewer`.

### Langkah 2: Double-Tap Zoom dengan Animasi Mulus
1. Di `LightboxImageViewer`, tambahkan `AnimationController` untuk transisi matriks `TransformationController`.
2. Bungkus `InteractiveViewer` dengan `GestureDetector(onDoubleTapDown: (details) => ..., onDoubleTap: () => ...)`.
3. Jika skala saat ini $\approx 1.0$:
   - Animasikan matriks transformasi ke skala `2.5x` dengan titik fokus (*focal point*) pada koordinat sentuhan pengguna.
4. Jika skala saat ini $> 1.0$:
   - Animasikan kembali ke `Matrix4.identity()` (skala `1.0x`).

### Langkah 3: Penyelarasan di Avatar Viewer Dialog
1. Terapkan logika pointer counter dan double-tap yang serupa pada `AvatarViewerDialog`.
2. Pastikan saat skala kembali ke 1.0, notifikasi state `onZoomChanged` memulihkan kemampuan swipe-to-dismiss secara instan tanpa lag.

---

## 4. Definition of Done (DoD)

- [x] Pinch-to-zoom dengan dua jari pada gambar lightbox berjalan mulus tanpa memicu pergeseran vertikal atau penutupan dialog yang tidak diinginkan.
- [x] Ketuk dua kali (*double tap*) pada gambar memperbesar gambar ke 2.5x tepat di titik sentuh.
- [x] Ketuk dua kali lagi saat kondisi membesar mengembalikan gambar ke ukuran semula (1.0x).
- [x] Swipe-to-dismiss vertikal satu jari tetap berfungsi sempurna saat gambar berada pada posisi normal (skala 1.0x).
- [x] Lolos static analysis `flutter analyze` dengan 0 errors.
