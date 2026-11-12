# 03. DIAGRAM FLOWCHART SISTEM DIGITAL (sNAPS)

**Dokumen**: Bab III - Bagian 3.2.2  
**Proyek**: Snapan Market Mobile (sNaps) - SMKN 8 Semarang  
**Fokus**: Pemetaan Logika Terotomatisasi Platform Mobile sNaps  

---

## 1. Definisi & Konsep Alur Sistem Digital
Alur sistem digital memodelkan bagaimana instruksi komputasi berjalan di aplikasi mobile sNaps, mulai dari validasi akun berbasis NIS, pemilihan katalog karya, pemilihan titik temu sekolah (*School Meeting Points*), pengecekan stok atomik di database PostgreSQL Supabase, hingga penerbitan bukti pesanan digital.

---

## 2. Diagram Flowchart Sistem

```mermaid
flowchart TD
    Start([Mulai: Siswa Buka Snaps]) --> CheckAuth{Apakah Sudah Login?}
    CheckAuth -- Belum --> InputNIS[Input NIS & Password]
    InputNIS --> ValidateRegistry[(Validasi ke student_registry)]
    ValidateRegistry --> CheckNISValid{Apakah NIS Terdaftar & Aktif?}
    CheckNISValid -- Tidak --> ShowAlertAuth[Tampilkan Peringatan: 'NIS Tidak Terdaftar'] --> InputNIS
    CheckNISValid -- Ya --> LoginSuccess[Login Berhasil]
    
    CheckAuth -- Sudah --> LoadHome[Masuk ke Halaman Beranda]
    LoginSuccess --> LoadHome

    LoadHome --> UserNavChoice{Pilih Aktivitas}

    %% JALUR PENJUAL
    UserNavChoice -- Jual Produk / Unjuk Karya --> OpenCreatePost[Buka Formulir Buat Postingan]
    OpenCreatePost --> FillProductData[Input Foto, Judul, Deskripsi, Kategori Jurusan, & Harga]
    FillProductData --> ValidateInput{Validasi Lengkap?}
    ValidateInput -- Tidak --> ShowErrorForm[Tampilkan Pesan Error] --> FillProductData
    ValidateInput -- Ya --> InsertProductDB[(Simpan ke Database PostgreSQL)]
    InsertProductDB --> PostBroadcast[Produk Tayang di Beranda & Marketplace] --> EndSellerWait([Selesai])

    %% JALUR PEMBELI
    UserNavChoice -- Beli Produk Vokasi --> BrowseMarket[Jelajah Beranda & Pilih Produk]
    BrowseMarket --> OpenDetail[Buka Halaman Detail Produk]
    OpenDetail --> TapBuy[Tekan Tombol 'Beli Sekarang']
    
    TapBuy --> DirectToDM[Langsung Masuk ke Ruang Chat DM Penjual]
    DirectToDM --> AttachProductCard[Sistem Otomatis Melampirkan Kartu Ringkasan Produk di Chat]
    AttachProductCard --> TriggerPushNotif[Kirim Push Notifikasi Chat Masuk ke HP Penjual]
    TriggerPushNotif --> ChatAgreement[Kedua Siswa Diskusi & Menyepakati Titik Temu COD via Chat]
    
    ChatAgreement --> MeetPhysicalCOD[Bertemu Fisik di Titik Temu Sekolah Pas Jam Istirahat]
    MeetPhysicalCOD --> CompleteVerification[Pembeli Memeriksa Fisik Barang & Membayar Tunai]
    CompleteVerification --> EndFinish([Selesai: Transaksi Berhasil])
```

---

## 3. Penjelasan Tahapan Krusial Sistem

1. **Autentikasi Siswa Berbasis NIS**:
   Aplikasi memastikan setiap pengguna adalah siswa aktif SMKN 8 Semarang dengan memeriksa identitas ke database `student_registry`.
2. **Publikasi Karya Fleksibel (Tanpa Beban Stok)**:
   Siswa dapat mempublikasikan karya vokasi atau barang preloved dengan mengisi foto, deskripsi, kategori jurusan, dan harga secara instan.
3. **Pemesanan Instan Langsung ke Chat DM (*Direct-to-DM Flow*)**:
   Ketika pembeli menekan tombol 'Beli Sekarang', sistem langsung menghubungkan pembeli ke ruang obrolan pribadi (*Direct Message*) penjual dengan otomatis melampirkan kartu ringkasan produk.
4. **Kesepakatan Titik Temu COD & Transaksi Tunai**:
   Kedua siswa menyepakati titik kumpul sekolah (seperti Gazebo PPLG, Kantin, atau Lobby) secara langsung lewat percakapan chat, kemudian bertemu fisik saat jam istirahat untuk serah terima barang dan pembayaran tunai.
