# Pendekatan Teknis SNAPS-98: Layar Aktivitas Sosial (Likes, Follows, Mentions)

> **Spesifikasi Teknis & Panduan Implementasi AI Agent**
> - **ID Tiket**: SNAPS-98
> - **Status**: Todo (High)
> - **Domain**: `activity / notifications / social_interactions / feed`
> - **Target Tanggal**: 2026-11-08

---

## 1. Analisis Masalah & Kebutuhan (Problem Audit)

### Kondisi Saat Ini
1. Layar aktivitas (`ActivityScreen` di `lib/features/activity/`) saat ini belum lengkap mendukung ragam jenis interaksi sosial modern seperti di Threads atau Instagram.
2. Interaksi siswa SMKN 8 seperti menyukai postingan, mem-follow profil jurusan, atau me-mention akun belum terorganisir dengan badge/ikon kategori yang jelas dan informatif.

### Benchmark Kompetitor (Threads by Instagram)
- **Kategori Filter (Tabs / Pills)**:
  - `Semua` (All activity)
  - `Balasan` (Replies & comments)
  - `Mention` (@username tags)
  - `Suka` (Likes & claps)
  - `Follow` (Pengikut baru)
- **Komponen Kartu Aktivitas**:
  - Avatar pengguna pemicu aksi di sisi kiri, dengan badge sub-icon kecil di pojok kanan bawah avatar (ikon hati merah untuk like, ikon user untuk follow, ikon chat untuk balasan).
  - Teks deskripsi: **@username** menyukai postingan Anda "Teks singkat postingan...".
  - Timestamp ringkas di sisi kanan (`2m`, `1j`, `2h`).
  - Action CTA sekunder (misal tombol "Ikuti Balik" untuk follow notification).

---

## 2. File & Modul Terkait (Target Files)

- `lib/features/activity/screens/activity_screen.dart` (Orchestrator)
- `lib/features/activity/components/activity_item_card.dart` atau leaf widgets baru di `lib/features/activity/components/`
- `lib/features/activity/models/activity_model.dart`
- `lib/core/services/supabase/` (Tabel `notifications` / `activities`)

---

## 3. Rencana Solusi & Implementasi AI Agent

1. **Model Data Standarisasi (`ActivityModel`)**:
   - Definisikan enum tipe aktivitas: `like`, `follow`, `reply`, `mention`, `system`.
   - Pastikan field memuat: `actorUser` (id, username, avatar, classGroup), `targetPost` (id, snippet/thumbnail), `createdAt`, dan `isRead`.
2. **Desain Komponen Kartu (Threads Standard)**:
   - Buat widget leaf modular yang bersih dan ramah layar HP (tinggi wajar, padding horizontal 16dp).
   - Gunakan badge mikro berwarna sesuai aksi (misal Merah Rose untuk Like, Electric Indigo untuk Follow, Emerald untuk Mention).
3. **Navigasi Cepat (Deep Navigation)**:
   - Tap pada kartu Like / Reply / Mention langsung membuka postingan terkait via `PostDetailScreen`.
   - Tap pada kartu Follow langsung membuka `ProfileScreen` aktor tersebut.
