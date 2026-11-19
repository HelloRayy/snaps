# Perbaikan Performa Scroll Feed Homepage (Anti-Jank & 60/120 FPS)

**Tanggal:** 19 November 2026  
**Status:** Siap Eksekusi  
**Prioritas:** Tinggi (Critical UX)  
**Domain:** `lib/features/feed/`

---

## 1. Ringkasan Eksekutif

Masalah scroll patah-patah (jank / frame drop) saat user langsung melakukan scroll ke bawah di Homepage **bukan disebabkan oleh backend, database Supabase, ataupun jaringan server**. Masalah ini 100% terjadi di sisi **Frontend Flutter** pada saat me-render kartu postingan dan memproses gambar di dalam viewport list.

Secara sederhana, saat user melakukan scroll cepat, CPU dan RAM perangkat dipaksa bekerja berkali-kali lipat karena:
1. Gambar di-decode **dua kali** dalam ukuran penuh (resolusi asli kamera HP) hanya untuk mengecek rasio aspek.
2. Setiap kartu postingan melakukan **double layout pass** karena penggunaan widget `IntrinsicHeight` yang tidak perlu.
3. Tinggi kartu berubah-ubah secara dinamis saat gambar selesai dimuat (`AnimatedSize`), memicu **layout shift** beruntun.
4. Tidak adanya **disk caching** untuk gambar feed sehingga gambar terus di-decode ulang dari nol saat scroll naik-turun.

---

## 2. Analisis Root Cause (Akar Masalah)

### A. Double Image Decoding Tanpa Batas Resolusi (Biang Kerok Utama)
- **Lokasi:**
  - `lib/features/feed/components/post_card/dynamic_feed_image.dart` (baris 59–61)
  - `lib/features/feed/components/post_card/adaptive_carousel_card.dart` (baris 68–75)
- **Mekanisme Masalah:**
  - Kedua widget memanggil `NetworkImage(widget.imageUrl).resolve(...)` secara manual di `initState()` untuk mendapatkan `width` dan `height` asli gambar.
  - Karena tidak dibungkus `ResizeImage`, Flutter ImageCache membongkar (decode) gambar dalam **resolusi penuh** (misal 4000x3000px = ~48 MB uncompressed bitmap di RAM per gambar).
  - Di saat yang sama, widget `Image.network(..., cacheWidth: 800)` di dalam `build()` juga melakukan decode ulang.
  - **Dampak:** 3–4 postingan bergambar yang masuk ke layar secara bersamaan langsung memakan ratusan MB RAM dan memblokir UI/Raster thread.

### B. `IntrinsicHeight` pada Setiap Kartu Postingan
- **Lokasi:** `lib/features/feed/components/post_card/market_post_card.dart` (baris 247)
- **Mekanisme Masalah:**
  - Method `_buildRowWithAvatar` membungkus seluruh isi kartu dengan `IntrinsicHeight` agar garis konektor vertikal (`showConnector`) bisa memanjang mengikuti tinggi konten.
  - Padahal, mayoritas postingan di feed adalah postingan tunggal (`hasChain == false`, `showConnector == false`) yang tidak membutuhkan garis konektor sama sekali.
  - **Dampak:** `IntrinsicHeight` memaksa Flutter melakukan **2x layout pass** untuk setiap kartu yang muncul saat scroll. Ini adalah salah satu anti-pattern performa paling berat di dalam `SliverList`.

### C. Layout Shift Beruntun Akibat `AnimatedSize`
- **Lokasi:** `lib/features/feed/components/post_card/dynamic_feed_image.dart` (baris 114–118)
- **Mekanisme Masalah:**
  - Sebelum rasio gambar diketahui, widget menggunakan fallback rasio `4 / 3`.
  - Begitu `ImageStreamListener` selesai membaca dimensi asli, `setState()` dipanggil dan `AnimatedSize` mengubah tinggi kartu secara animasi selama 220ms.
  - **Dampak:** Saat beberapa gambar selesai dimuat hampir bersamaan, posisi scroll di bawahnya bergeser dan Flutter harus menghitung ulang posisi seluruh sliver di bawahnya setiap frame animasi.

### D. Ketiadaan Disk Cache & `cacheExtent` Terlalu Kecil
- **Lokasi:**
  - `lib/features/feed/components/home_feed_scrollable_list.dart` (baris 151, `cacheExtent: 450.0`)
  - Penggunaan `Image.network` polos di `dynamic_feed_image.dart` dan `adaptive_carousel_card.dart`.
- **Dampak:** Saat memori RAM penuh, bitmap gambar dibuang. Ketika user scroll kembali ke atas, gambar harus di-download/decode ulang dari awal.

---

## 3. Rencana Eksekusi & Pendekatan Solusi (Step-by-Step)

### Langkah 1: Hapus Double-Decode Gambar (Prioritas 1 — Dampak Terbesar)
**Target File:**
- `lib/features/feed/components/post_card/dynamic_feed_image.dart`
- `lib/features/feed/components/post_card/adaptive_carousel_card.dart`

**Pendekatan Teknis:**
1. **Gunakan `ResizeImage` atau `cached_network_image` dengan `memCacheWidth`:**
   - Jangan memanggil `NetworkImage(url).resolve(...)` secara terpisah.
   - Ambil dimensi gambar langsung dari `ImageStreamListener` milik widget gambar utama yang sudah dibatasi `cacheWidth: 800` (atau `ResizeImage(NetworkImage(url), width: 800)`).
   - Dengan begitu, gambar hanya di-download **1 kali** dan di-decode **1 kali** pada lebar maksimal 800px (~1–2 MB di RAM, turun >90% dari 48 MB).
2. **Simpan Rasio ke Cache Statis:**
   - Pertahankan `_ratioCache` / `ratioCache` agar saat widget di-recycle oleh `SliverList`, rasio langsung tersedia secara sinkron tanpa menunggu listener.

---

### Langkah 2: Eliminasi `IntrinsicHeight` pada Postingan Tunggal (Prioritas 1)
**Target File:** `lib/features/feed/components/post_card/market_post_card.dart`

**Pendekatan Teknis:**
1. Di `_buildRowWithAvatar(context, showConnector: ...)`:
   - Hanya bungkus dengan `IntrinsicHeight` **jika dan hanya jika `showConnector == true`** (yaitu postingan yang memiliki `threadChain`).
   - Untuk postingan biasa (`showConnector == false`), langsung kembalikan `Row(crossAxisAlignment: CrossAxisAlignment.start, children: [...])` tanpa `IntrinsicHeight`.
2. **Alternatif Lebih Bersih (Opsional):**
   - Jika ingin menghilangkan `IntrinsicHeight` sepenuhnya bahkan pada `threadChain`, gunakan `CustomPaint` atau `Positioned.fill` di dalam `Stack` untuk menggambar garis konektor vertikal di belakang avatar.

---

### Langkah 3: Stabilkan Layout Gambar & Hilangkan `AnimatedSize` di Feed (Prioritas 2)
**Target File:** `lib/features/feed/components/post_card/dynamic_feed_image.dart`

**Pendekatan Teknis:**
1. Hapus `AnimatedSize` di dalam item list scroll (`SliverList`). Perubahan tinggi kartu secara animasi di dalam feed yang sedang di-scroll adalah penyebab utama stutter.
2. Gunakan `AspectRatio` langsung dengan nilai `_resolvedRatio ?? (4 / 3)`.
3. *(Rekomendasi Jangka Menengah)*: Simpan `aspect_ratio` (atau `width` & `height`) media di metadata JSONB / kolom tabel Supabase saat proses upload di `create_post`. Dengan begitu, feed sudah tahu tinggi pasti gambar bahkan sebelum gambar mulai di-download (0% layout shift).

---

### Langkah 4: Optimasi `CustomScrollView` & `RepaintBoundary` (Prioritas 3)
**Target File:** `lib/features/feed/components/home_feed_scrollable_list.dart`

**Pendekatan Teknis:**
1. **Naikkan `cacheExtent`:**
   - Ubah `cacheExtent: 450.0` menjadi `cacheExtent: 800.0` atau `1000.0` agar kartu dan gambar di bawah viewport sudah mulai disiapkan sebelum masuk layar.
2. **Kurangi Rebuild Listener di `HomeFeedScreen`:**
   - Di `lib/features/feed/screens/home_feed_screen.dart` (baris 65–67), `_feedController.addListener(() { if (mounted) setState(() {}); });` me-rebuild seluruh `HomeFeedScreen` (termasuk header, drawer, bottom nav, dan FAB) setiap kali ada perubahan kecil di controller (seperti `isLoadingMore = true` atau like toggle).
   - **Solusi:** Bungkus hanya bagian `HomeFeedScrollableList` dengan `ListenableBuilder(listenable: _feedController, ...)` agar header dan bottom navigation bar tidak ikut ter-rebuild saat feed melakukan pagination atau update state.

---

### Langkah 5: Implementasi Disk Caching Gambar (`cached_network_image`)
**Target:** Seluruh komponen gambar di `lib/features/feed/components/post_card/` (`dynamic_feed_image.dart`, `adaptive_carousel_card.dart`, `post_author_avatar.dart`).

**Pendekatan Teknis:**
1. Ganti `Image.network` dengan `CachedNetworkImage` (atau `CachedNetworkImageProvider` dengan `maxWidthDiskCache: 1080` dan `memCacheWidth: 800`).
2. Ini memastikan gambar tersimpan di disk lokal HP sehingga scroll balik ke atas atau buka-tutup aplikasi terasa instan tanpa decode ulang dari jaringan.

---

## 4. Checklist Verifikasi Setelah Implementasi

Setelah langkah-langkah di atas diterapkan, lakukan verifikasi berikut:
1. **Profile Mode Test:** Jalankan aplikasi menggunakan `flutter run --profile` (bukan debug mode, karena debug mode memang selalu lebih lambat).
2. **Flutter DevTools Performance Overlay:**
   - Pastikan grafik **UI thread** dan **Raster thread** tetap berada di bawah garis 16ms (untuk 60Hz) atau 8.3ms (untuk 120Hz) saat melakukan *fling scroll* cepat ke bawah.
3. **Memory Footprint:**
   - Cek tab Memory di DevTools saat scroll 30+ postingan bergambar; pastikan tidak ada lonjakan RAM tajam akibat decoding gambar resolusi penuh.
4. **Visual Check:**
   - Pastikan tidak ada gambar yang terpotong aneh, garis konektor `threadChain` tetap menyambung rapi, dan tidak ada kedipan shimmer yang mengganggu.
