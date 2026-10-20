# Sprint Active Tickets (2026-10-19)

Direktori ini memuat tiket spesifikasi teknis dan panduan pengerjaan untuk tiket aktif di Plane.so pada state **"Ticket"** (Unstarted).

---

## Daftar Tiket Aktif Sprint 2026-10-19

| Sequence | Judul Tiket | Domain | Prioritas | Status Plane | File Panduan |
| :---: | :--- | :--- | :---: | :---: | :--- |
| **SNAPS-84** | `feat(mention): add tag mention @username in many pages` | `mention / autocomplete / profile / chat / feed` | HIGH | `DONE` | [`SNAPS-84.md`](./SNAPS-84.md) |
| **SNAPS-85** | `feat(mascot-icon): add mascot icon access for public` | `mascot / flair / profile / create_post / permission` | MEDIUM | `TICKET` | [`SNAPS-85.md`](./SNAPS-85.md) |
| **SNAPS-86** | `fix(dm-notif): fix direct message notif not realtime` | `chat / direct_messages / realtime / supabase / notification` | HIGH | `TICKET` | [`SNAPS-86.md`](./SNAPS-86.md) |
| **SNAPS-87** | `fix(zoom-behaviour): fix zoom finger gesture` | `gestures / zoom / lightbox / pinch_scale / interactive_viewer` | MEDIUM | `DONE` | [`SNAPS-87.md`](./SNAPS-87.md) |
| **SNAPS-88** | `fix(OTA-script): issue OTA not worked at all` | `release / ota / scripts / supabase_storage / in_app_update` | HIGH | `DONE` | [`SNAPS-88.md`](./SNAPS-88.md) |

---

## Standar Pengerjaan

1. **Satu Tiket per Sesi**: AI Agent wajib fokus menyelesaikan satu tiket tuntas sebelum beralih ke tiket lainnya.
2. **Kepatuhan Batas File**: Setiap modul atau komponen yang diubah/dibuat tetap mematuhi batas arsitektur $\le 250$–$300$ baris.
3. **Verifikasi Statis & Run**: Pastikan `flutter analyze` bersih dengan 0 errors sebelum commit.
