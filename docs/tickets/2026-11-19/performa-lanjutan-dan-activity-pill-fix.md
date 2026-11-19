# Optimasi Performa Lanjutan & Perbaikan UI/Filter Pill Button Aktivitas

**Tanggal:** 19 November 2026  
**Status:** Siap Eksekusi  
**Prioritas:** Tinggi  
**Domain:** `lib/features/feed/`, `lib/features/activity/`

---

## 1. Ringkasan Masalah

Selain masalah *double-decode* gambar dan `IntrinsicHeight` di feed (lihat tiket `feed-scroll-jank-performance-fix.md`), terdapat dua area lain yang perlu ditangani:
1. **Optimasi Performa Lanjutan:** Masih ada *excessive widget rebuild* di `HomeFeedScreen`, pemanggilan berulang di dalam `build()`, serta *getter* komputasi berat di `ActivityScreen` yang dieksekusi setiap frame rebuild.
2. **UI & Fitur Pill Button di Halaman Aktivitas:** Filter kategori (pill button) di `ActivityHeaderBar` tidak sinkron dengan tipe notifikasi yang ada (`follow`, `like`, `comment`, `mention`, `order`, `system`). Info seperti **orang yang mem-follow** (`ActivityType.follow`) dan **like** (`ActivityType.like`) tidak punya tab/pill khusus dan hanya tersembunyi di tab `Semua`.

---

## 2. Bagian A: Analisis & Solusi Optimasi Performa Lanjutan

### 1. Rebuild Seluruh `HomeFeedScreen` pada Setiap Perubahan Feed
- **Lokasi:** `lib/features/feed/screens/home_feed_screen.dart` (baris 65–67)
- **Masalah:**
  - `_feedController.addListener(() { if (mounted) setState(() {}); });` memicu rebuild seluruh `Scaffold` (termasuk `HomeFeedHeader`, `HomeNavDrawer`, `HomeDockOverlay`, dan `FAB`) setiap kali ada perubahan kecil di feed (seperti `isLoadingMore = true`, `toggleLike`, atau `votePoll`).
- **Solusi:**
  - Hapus `addListener` + `setState` di `initState()` `HomeFeedScreen`.
  - Bungkus hanya bagian `HomeFeedScrollableList` dengan `ListenableBuilder(listenable: _feedController, builder: ...)` agar hanya area timeline yang ter-rebuild.

### 2. Komputasi Grouping & Flattening Berulang di `ActivityScreen`
- **Lokasi:** `lib/features/activity/screens/activity_screen.dart` (baris 77–114)
- **Masalah:**
  - Getter `_filteredNotifications` dan `_flattenedItems` melakukan iterasi, filtering, dan grouping `Map<ActivityTimelineGroup, List<ActivityNotification>>` langsung di dalam `build()` setiap kali state berubah (misal saat tap "Tandai dibaca").
- **Solusi:**
  - Hitung `_cachedFlattenedItems` hanya saat data `_notifications` berubah atau saat `_activeTabIndex` berubah (di dalam method `_rebuildListCache()`), bukan di dalam `build()`.

### 3. `MarketPostCard` Memanggil `FollowService.instance.isFollowing` di `build()`
- **Lokasi:** `lib/features/feed/components/post_card/market_post_card.dart` (baris 169 & 240)
- **Masalah:**
  - Dipanggil 2 kali per kartu dalam satu kali `build()` (`build()` dan `_buildRowWithAvatar()`).
- **Solusi:**
  - Hitung `isFollowingAuthor` satu kali saja di `build()`, lalu oper sebagai parameter ke `_buildRowWithAvatar`.

---

## 3. Bagian B: Analisis & Solusi UI / Fitur Pill Button Aktivitas

### Kondisi Saat Ini (Ketidaksinkronan)
1. Di `lib/features/activity/models/activity_notification_model.dart` (baris 1), sistem sudah mendukung 6 tipe aktivitas:
   - `like`, `comment`, `mention`, `follow`, `order`, `system`
2. Di `lib/features/activity/components/activity_header_bar.dart` (baris 66–88), hanya ada **3 pill button**:
   - `Semua` (index 0)
   - `Balasan` (index 1) -> hanya memfilter `comment` & `mention`
   - `Pengumuman` (index 2) -> hanya memfilter `system` & `order`
3. Di `lib/features/activity/screens/activity_screen.dart` (baris 28), komentar kode masih tertulis:
   `// 0: Semua, 1: Pengumuman, 2: Interaksi, 3: Pesanan COD` — menunjukkan desain awalnya memang tidak selesai disinkronkan.
4. **Dampak ke User:**
   - User tidak bisa memfilter notifikasi **Pengikut Baru (`follow`)** atau **Suka (`like`)** secara terpisah.
   - Notifikasi **Pesanan COD (`order`)** tercampur dengan **Pengumuman Sekolah (`system`)**.

### Pendekatan Solusi (5 Pill Button Terstruktur)
Ubah daftar pill button di `ActivityHeaderBar` dan logika `_filteredNotifications` di `ActivityScreen` menjadi **5 kategori yang jelas**:

1. **Index 0 — `Semua`**: Menampilkan seluruh tipe notifikasi.
2. **Index 1 — `Balasan`**: Menampilkan `ActivityType.comment` dan `ActivityType.mention` (info balasan komentar & mention).
3. **Index 2 — `Pengikut`**: Menampilkan `ActivityType.follow` (info siswa yang baru mem-follow, lengkap dengan tombol *Ikuti Balik* di `ActivityFollowButton`).
4. **Index 3 — `Disukai`**: Menampilkan `ActivityType.like` (info postingan/jualan yang disukai).
5. **Index 4 — `Info & COD`**: Menampilkan `ActivityType.order` dan `ActivityType.system` (atau dipisah menjadi `Pesanan` dan `Pengumuman` jika diperlukan).

### Perbaikan UI Tambahan pada Pill Button (`_ActivityFilterChip`)
- **Lokasi:** `lib/features/activity/components/activity_header_bar.dart` (baris 95–152)
- **Perbaikan:**
  - Pastikan setiap pill memiliki padding horizontal yang nyaman disentuh (minimal tinggi 36–40 dp dengan area sentuh 44 dp), jarak antar pill konsisten (`8.0` dp), dan indikator **unread dot / count badge** opsional pada tab yang memiliki notifikasi belum dibaca.
  - Tambahkan `HapticFeedback.selectionClick()` saat berpindah pill tab agar terasa responsif.

---

## 4. Checklist Verifikasi

1. **Performa:** `HomeFeedScreen` tidak lagi me-rebuild header dan bottom nav saat pagination `isLoadingMore` berjalan.
2. **Filter Aktivitas:**
   - Tap pill `Pengikut` -> hanya menampilkan notifikasi `follow` beserta tombol *Ikuti* / *Mengikuti*.
   - Tap pill `Balasan` -> hanya menampilkan balasan komentar & mention.
   - Tap pill `Disukai` -> hanya menampilkan notifikasi like.
   - Tap pill `Info & COD` -> menampilkan update pesanan COD & pengumuman resmi Snaps.
3. **Empty State:** Pastikan `ActivityEmptyState` muncul dengan pesan yang sesuai jika salah satu kategori pill belum memiliki notifikasi.
