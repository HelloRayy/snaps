# Tiket: Penyederhanaan Header Feed (Hapus Kelas & Wrap Topic Tag)

**Tanggal**: 2026-11-26
**Domain**: Feed (`lib/features/feed/components/post_card/`)
**Status**: Selesai

---

## Ringkasan Masalah

Header kartu utas di Home Feed (`PostCardHeader`) saat ini masih menampilkan nama kelas (`XI PS 2`, dll.) di sebelah kanan nama pengguna, serta memotong (`ellipsis`) `topicTag` jika nama pengguna atau topik terlalu panjang. Hal ini membuat baris header terasa penuh dan teks topik terpotong.

---

## Ruang Lingkup Perubahan

1. **Hapus Kelas dari Home Feed (`PostCardHeader`)**:
   - Hilangkan tampilan `classGroup` di header kartu utas pada Home Feed.
   - Tampilkan hanya **Nama (`displayAuthor`)** + Verified badge (jika ada) + Mascot Flair (jika ada).
   - **Kelas tetap dipertahankan** di halaman Profil Siswa, Checkout / Buy Sheet, dan Admin Dashboard.

2. **Wrap `topicTag` ke Baris Berikutnya Jika Melebihi Lebar**:
   - Jika utas memiliki `topicTag` dan gabungan `Nama > Topic Tag` terlalu panjang, biarkan `topicTag` turun rapi ke baris bawah (`Wrap` atau layout 2 baris yang bersih) tanpa memotong teks dan tanpa merusak alignment timestamp/menu titik 3 di sisi kanan.

---

## Target File

- `lib/features/feed/components/post_card/post_card_header.dart`

---

## Kriteria Selesai (Definition of Done)

- [ ] Kelas siswa tidak lagi muncul di header kartu utas Home Feed.
- [ ] `topicTag` yang panjang turun rapi ke baris bawah tanpa terpotong dan tanpa menggeser timestamp/menu titik 3.
- [ ] Kelas tetap tampil normal di Profil, Checkout, dan Admin Dashboard.
