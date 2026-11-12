# 05. DATA FLOW DIAGRAM (DFD LEVEL 0 & LEVEL 1)

**Dokumen**: Bab III - Bagian 3.4  
**Proyek**: Snapan Market Mobile (sNaps) - SMKN 8 Semarang  
**Fokus**: Dekomposisi Fungsional Aliran Data Logis dan Interaksi Datastore  

---

## 1. Definisi Data Flow Diagram
Data Flow Diagram (DFD) memodelkan sistem dari sudut pandang pemrosesan data: bagaimana data masuk, ditransformasikan oleh proses komputasi, disimpan ke dalam *datastore*, dan dikeluarkan kembali ke entitas tujuan.

---

## 2. DFD Level 0 (Overview Sistem sNaps)

DFD Level 0 memecah *Proses 0.0* menjadi 5 sub-proses inti:

```mermaid
flowchart TD
    %% Entitas
    Siswa["👤 SISWA"]
    Admin["🛡️ ADMIN SEKOLAH"]

    %% Sub-Proses
    P1(("1.0<br/>Autentikasi &<br/>Device Binding"))
    P2(("2.0<br/>Feed Komunitas &<br/>Diskusi Vokasi"))
    P3(("3.0<br/>Manajemen Produk &<br/>Katalog Karya"))
    P4(("4.0<br/>Transaksi COD &<br/>Titik Temu"))
    P5(("5.0<br/>Moderasi Konten &<br/>Registry Siswa"))

    %% Datastores
    D1[("D1: student_registry")]
    D2[("D2: profiles")]
    D3[("D3: market_posts")]
    D4[("D4: school_meeting_points")]
    D5[("D5: conversations & direct_messages")]
    D6[("D6: content_reports")]

    %% Aliran Proses 1.0 (Autentikasi)
    Siswa -->|NIS & Password| P1
    D1 -->|Data Validasi Siswa Aktif| P1
    P1 -->|Insert/Update Data Akun| D2
    P1 -->|Token Sesi & Info Profil| Siswa

    %% Aliran Proses 2.0 (Feed & Diskusi)
    Siswa -->|Input Thread, Polling, Komentar| P2
    P2 -->|Simpan Konten Interaksi| D3
    D3 -->|Ambil Data Timeline Terkini| P2
    P2 -->|Feed Interaktif Warga Sekolah| Siswa

    %% Aliran Proses 3.0 (Katalog Karya)
    Siswa -->|Unggah Karya Vokasi/Preloved| P3
    P3 -->|Simpan Info Produk & Stok| D3
    D3 -->|Ambil Data Katalog Jurusan| P3
    P3 -->|Tampilkan Etalase Produk| Siswa

    %% Aliran Proses 4.0 (Transaksi COD via Direct Message)
    Siswa -->|Pilih Produk & Titik Temu COD| P4
    D4 -->|"Data Master Titik Temu (Gazebo/Kantin/Lab)"| P4
    P4 -->|Validasi Ketersediaan Produk| D3
    P4 -->|"Simpan Riwayat Janjian COD"| D5
    D5 -->|Ambil Pesan Obrolan & Konteks Produk| P4
    P4 -->|Notifikasi Chat & Ringkasan Janjian COD| Siswa

    %% Aliran Proses 5.0 (Moderasi & Registry)
    Siswa -->|Aduan Pelanggaran Konten| P5
    P5 -->|Simpan Laporan| D6
    Admin -->|Import CSV Master Siswa| P5
    P5 -->|Perbarui Data Buku Induk| D1
    Admin -->|Kelola Titik Kumpul COD| P5
    P5 -->|Update Data Spot Sekolah| D4
    D6 -->|Daftar Aduan Konten Siswa| P5
    P5 -->|Eksekusi Banned / Take Down| Admin
```

---

## 3. DFD Level 1 (Fokus: Proses 4.0 Transaksi COD & Titik Temu)

Untuk memodelkan proses koordinasi transaksi langsung di lingkungan SMKN 8 Semarang secara akurat, proses 4.0 didekomposisi lebih lanjut:

```mermaid
flowchart TD
    Pembeli["👤 Siswa Pembeli"]
    Penjual["👤 Siswa Penjual"]

    P41(("4.1<br/>Pengecekan Ketersediaan<br/>Produk"))
    P42(("4.2<br/>Pemilihan Titik Temu<br/>(Dropdown Spot)"))
    P43(("4.3<br/>Inisialisasi Chat &<br/>Notifikasi Realtime"))
    P44(("4.4<br/>Verifikasi Fisik &<br/>Serah Terima Tunai"))

    D3[("D3: market_posts")]
    D4[("D4: school_meeting_points")]
    D5[("D5: conversations & direct_messages")]

    %% 4.1
    Pembeli -->|Pilih Item & Kuantitas| P41
    D3 -->|Cek Sisa Stok Produk| P41
    P41 -->|Produk Tersedia Valid| P42
    P41 -.->|Stok Habis: Batalkan| Pembeli

    %% 4.2
    D4 -->|Daftar Master Spot COD Sekolah| P42
    Pembeli -->|Pilih Titik Temu & Catatan Jam| P42
    P42 -->|Payload Checkout & Konteks COD| P43

    %% 4.3
    P43 -->|"Simpan Pesan Janjian COD Otomatis"| D5
    P43 -->|Push Notification Chat Masuk| Penjual
    P43 -->|Buka Ruang Obrolan Terpadu| Pembeli

    %% 4.4
    Pembeli -->|Periksa Fisik Barang di Spot COD & Bayar Tunai| P44
    Penjual -->|Serahkan Barang & Terima Uang Tunai| P44
```

---

## 4. Matriks Hubungan Sub-Proses dengan Datastore

| Sub-Proses | Datastore Terlibat | Mode Akses | Keterangan Fungsional |
|---|---|---|---|
| **1.0 Autentikasi** | `student_registry`, `profiles` | Read, Write | Memvalidasi NIS terdaftar dan mencatat profil resmi siswa. |
| **2.0 Feed Komunitas** | `market_posts`, `profiles` | Read, Write | Menyimpan thread diskusi dan interaksi sosial. |
| **3.0 Manajemen Produk** | `market_posts` | Read, Write | Menangani CRUD etalase karya siswa dan kuantitas produk. |
| **4.0 Transaksi COD** | `conversations`, `direct_messages`, `market_posts`, `school_meeting_points` | Read, Write | Menghubungkan pembeli-penjual via chat otomatis dan titik temu sekolah. |
| **5.0 Moderasi & Admin** | `content_reports`, `student_registry`, `school_meeting_points` | Read, Write | Menjaga kepatuhan aturan sekolah dan data induk siswa. |
