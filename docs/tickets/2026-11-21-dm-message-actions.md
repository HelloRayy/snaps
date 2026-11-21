# Tiket: Aksi Pesan Direct Message (Reply, Delete, Copy, Edit)

**Tanggal**: 2026-11-21
**Domain**: Direct Messages (`lib/features/messages/`)
**Status**: Terkunci (Siap Dikerjakan)

---

## Ringkasan Masalah

Fitur Direct Message (DM) saat ini belum memiliki aksi interaktif pada bubble pesan seperti yang umum tersedia di aplikasi kompetitor (WhatsApp/Instagram/Threads), khususnya untuk membalas pesan tertentu, menghapus pesan, menyalin teks, dan mengedit pesan yang sudah terkirim.

---

## Ruang Lingkup Fitur (Scope)

1. **Reply Pesan**
   - Swipe kanan pada bubble pesan untuk memicu Reply cepat (disertai haptic feedback).
   - Menampilkan quote preview pesan yang dibalas di atas `chat_composer_bar.dart` lengkap dengan tombol batal.
   - Bubble pesan balasan menampilkan cuplikan pesan asli yang di-reply (tap untuk scroll/highlight ke pesan asal jika masih ada di viewport).

2. **Hapus Pesan (Delete)**
   - **Delete for Everyone (Unsend)**: Khusus pesan milik sendiri, bebas kapan saja tanpa batas waktu. Pesan berubah menjadi placeholder `"Pesan telah dihapus"`.
   - **Delete for Me**: Menghapus pesan hanya dari tampilan akun sendiri.

3. **Salin Teks (Copy Text)**
   - Menyalin isi teks pesan ke clipboard dengan feedback toast/snackbar singkat.

4. **Edit Pesan**
   - Khusus pesan teks milik sendiri, bebas kapan saja tanpa batas waktu.
   - Mengisi ulang teks ke composer dalam mode edit (atau inline edit) dan menampilkan label `"Diedit"` pada bubble setelah disimpan.

---

## Pola Interaksi (UX Trigger)

- **Swipe Kanan**: Memicu Reply cepat pada bubble pesan.
- **Long-Press Bubble**: Memunculkan context menu / bottom sheet berisi opsi:
  - Reply
  - Copy (jika pesan memiliki teks)
  - Edit (khusus pesan teks milik sendiri yang belum dihapus)
  - Delete (opsi *Delete for Me* dan *Delete for Everyone* untuk pesan milik sendiri)

---

## Catatan Teknis & Target Area

- **UI Components**:
  - `lib/features/messages/components/chat_message_bubble.dart` (swipe gesture, long-press menu, quote block, placeholder `"Pesan telah dihapus"`, label `"Diedit"`).
  - `lib/features/messages/components/chat_composer_bar.dart` (banner preview reply & mode edit).
- **Model & Service**:
  - `lib/features/messages/models/` & `lib/features/messages/services/` untuk mendukung `reply_to_id`, `edited_at`, `is_deleted_for_everyone`, serta array/tabel `deleted_for_users`.
- **Database (Supabase)**:
  - Pastikan RLS mengizinkan pengirim melakukan `UPDATE` untuk edit/unsend pesan miliknya sendiri.
