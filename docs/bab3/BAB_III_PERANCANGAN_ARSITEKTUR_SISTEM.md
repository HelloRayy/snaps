# BAB III: PERANCANGAN ARSITEKTUR SISTEM

**Judul Proyek**: Pengembangan Aplikasi Snapan Market Mobile (sNaps) Berbasis Android Sebagai Platform Komunitas dan Marketplace Vokasi di Lingkungan SMKN 8 Semarang  
**Program Keahlian**: Pengembangan Perangkat Lunak dan Gim (PPLG) - SMKN 8 Semarang  

---

## 3.1 Pelaksanaan dan Hasil Riset

### 3.1.1 Pelaksanaan Riset Lapangan
Riset perancangan sistem dilaksanakan di lingkungan kampus SMKN 8 Semarang dengan melibatkan siswa dari berbagai program keahlian (PPLG, DKV, Kuliner, dan Otomotif) melalui metode wawancara mendalam (*in-depth interview*) serta observasi langsung terhadap dinamika komunikasi siswa di grup chat WhatsApp sekolah.

### 3.1.2 Hasil dan Analisis Kebutuhan
Dari pelaksanaan riset tersebut, diperoleh kesimpulan dan analisis kebutuhan sebagai berikut:
1. **Kejenuhan dan Banjir Informasi pada Grup WhatsApp**: Siswa merasa promosi karya dan penawaran barang preloved di grup kelas atau grup angkatan sangat cepat tenggelam oleh tumpukan chat lainnya sehingga tidak efisien.
2. **Kebutuhan Wadah Unjuk Karya Jurusan**: Siswa PPLG membutuhkan media untuk mendistribusikan aplikasi/game, siswa DKV membutuhkan tempat memasarkan merchandise dan portofolio, dan siswa Kuliner memerlukan media pemesanan makanan ringan siap antar saat jam istirahat sekolah.
3. **Pentingnya Keamanan Ekosistem Berbasis NIS**: Siswa menginginkan aplikasi yang tertutup khusus warga sekolah, di mana login diwajibkan menggunakan Nomor Induk Siswa (NIS) untuk mencegah akun palsu atau penipuan dari luar sekolah.
4. **Preferensi Metode Pembayaran COD di Spot Sekolah**: Siswa menghendaki transaksi tanpa biaya admin transfer bank dengan metode pembayaran tunai saat bertemu langsung (*Cash on Delivery*) di titik-titik kumpul resmi sekolah.

---

## 3.2 Diagram Flowchart Sistem

### 3.2.1 Diagram Flowchart Alur Manual (Konvensional)
Diagram berikut menggambarkan alur jual-beli antar siswa sebelum adanya sistem aplikasi sNaps:

```mermaid
flowchart TD
    Start([Mulai: Siswa Ingin Menjual Barang/Karya]) --> PostWA[Unggah Foto & Deskripsi ke Status WhatsApp/Instagram]
    PostWA --> WaitChat[Menunggu Chat Masuk dari Siswa Lain]
    WaitChat --> ChatCheck{Apakah Ada Siswa yang Membalas?}
    ChatCheck -- Tidak (Chat Tenggelam) --> Expired[Postingan Hilang 24 Jam Tanpa Penjualan] --> EndCancel([Selesai / Gagal])
    ChatCheck -- Ya --> ChatTawar[Tanya Jawab Manual via DM: Stok & Harga]
    ChatTawar --> DealCheck{Sepakat Membeli?}
    DealCheck -- Batal --> EndCancel
    DealCheck -- Sepakat --> JanjiManual[Menentukan Tempat & Waktu Janji Temu]
    JanjiManual --> RiskMiscommunication[Rawan Miskomunikasi Lokasi & Waktu / Ghosting]
    RiskMiscommunication --> MeetManual[Bertemu Fisik di Area Sekolah]
    MeetManual --> CashHandover[Pemberian Uang Tunai & Serah Terima Barang]
    CashHandover --> ManualCalc[Pencatatan Keuangan Manual di Buku Pribadi]
    ManualCalc --> EndSuccess([Selesai: Transaksi Berhasil])
```

### 3.2.2 Diagram Flowchart Alur Sistem Digital (sNaps)
Diagram berikut menggambarkan alur terotomatisasi transaksi C2C dan interaksi komunitas pada aplikasi sNaps:

```mermaid
flowchart TD
    Start([Mulai: Siswa Buka Snaps]) --> CheckAuth{Sudah Login?}
    
    %% Alur Login Sederhana
    CheckAuth -- Belum --> FormLogin[Input NIS & Password]
    FormLogin --> ValidasiLogin[(Validasi ke student_registry)]
    ValidasiLogin --> Beranda[Masuk ke Halaman Beranda]
    CheckAuth -- Sudah --> Beranda

    %% Pilihan Menu Utama
    Beranda --> PilihAksi{Pilih Aktivitas}

    %% JALUR 1: JUAL KARYA (KIRI)
    PilihAksi -- Jual Produk / Karya --> FormJual[Buka Form Buat Postingan]
    FormJual --> InputJual[Input Foto, Judul, Kategori Jurusan & Harga]
    InputJual --> SimpanPost[(Simpan ke Database PostgreSQL)]
    SimpanPost --> TayangPost[Produk Tayang di Beranda]
    TayangPost --> SelesaiJual([Selesai])

    %% JALUR 2: BELI PRODUK (KANAN)
    PilihAksi -- Beli Produk --> BukaDetail[Buka Halaman Detail Produk]
    BukaDetail --> KlikBeli[Tekan Tombol 'Beli Sekarang']
    KlikBeli --> MasukChat[Langsung Masuk ke Ruang Chat DM Penjual]
    MasukChat --> TempelProduk[Sistem Otomatis Melampirkan Kartu Produk di Chat]
    TempelProduk --> NotifPenjual[Kirim Push Notifikasi Chat ke HP Penjual]
    NotifPenjual --> JanjianCOD[Kedua Siswa Diskusi & Janjian Titik Temu COD]
    JanjianCOD --> KetemuCOD[Bertemu Fisik di Area Sekolah Pas Jam Istirahat]
    KetemuCOD --> BayarTunai[Pembeli Cek Kondisi Barang & Bayar Tunai]
    BayarTunai --> SelesaiBeli([Selesai: Transaksi Berhasil])
```

---

## 3.3 Diagram Konteks (Context Diagram)

Diagram Konteks memposisikan sistem sNaps pada Level 0 Global dengan batasan entitas luar **Siswa** dan **Admin Sekolah**:

```mermaid
flowchart LR
    subgraph SiswaEntity["Entitas Luar: Siswa"]
        Siswa["👤 SISWA (Warga SMKN 8)"]
    end

    subgraph CoreSystem["Sistem Utama"]
        App(("0.0<br/>SISTEM APLIKASI<br/>SNAPAN MARKET MOBILE<br/>(sNAPS)"))
    end

    subgraph AdminEntity["Entitas Luar: Admin"]
        Admin["🛡️ ADMIN SEKOLAH"]
    end

    %% Siswa -> Sistem
    Siswa -->|1. Kredensial Login NIS & Registrasi Perangkat| App
    Siswa -->|2. Data Postingan Thread & Produk Vokasi| App
    Siswa -->|3. Data Pesanan COD & Pilihan Titik Temu| App
    Siswa -->|4. Pesan Chat Realtime| App
    Siswa -->|5. Laporan Pelanggaran Konten| App

    %% Sistem -> Siswa
    App -->|a. Akses Beranda & Profil Siswa| Siswa
    App -->|b. Tampilan Feed & Katalog Produk Vokasi| Siswa
    App -->|c. Notifikasi Status Pesanan & Lokasi COD| Siswa
    App -->|d. Pesan Chat Masuk Realtime| Siswa

    %% Admin -> Sistem
    Admin -->|"1. Master Data Registry Siswa (NIS & Kelas)"| App
    Admin -->|2. Master Titik Temu COD Sekolah| App
    Admin -->|"3. Tindakan Moderasi (Banned Akun/Take Down Post)"| App

    %% Sistem -> Admin
    App -->|a. Notifikasi Laporan Konten Siswa| Admin
    App -->|b. Log Keamanan & Registrasi Hardware| Admin
    App -->|c. Rekapitulasi Data Siswa & Transaksi Sekolah| Admin
```

---

## 3.4 Data Flow Diagram (DFD)

### 3.4.1 DFD Level 0
Menguraikan sistem utama menjadi lima sub-proses fungsional terintegrasi dengan tabel penyimpanan:

```mermaid
flowchart TD
    Siswa["👤 Siswa"]
    Admin["🛡️ Admin Sekolah"]

    P1(("1.0<br/>Autentikasi &<br/>Profil Siswa"))
    P2(("2.0<br/>Feed Komunitas &<br/>Diskusi Vokasi"))
    P3(("3.0<br/>Manajemen Produk &<br/>Katalog Karya"))
    P4(("4.0<br/>Transaksi COD &<br/>Titik Temu"))
    P5(("5.0<br/>Moderasi Konten &<br/>Master Registry"))

    D1[("D1: student_registry")]
    D2[("D2: profiles")]
    D3[("D3: market_posts")]
    D4[("D4: school_meeting_points")]
    D5[("D5: conversations & direct_messages")]
    D6[("D6: content_reports")]

    Siswa -->|NIS & Password| P1
    D1 -->|Verifikasi Validitas NIS| P1
    P1 -->|Simpan Profil| D2
    P1 -->|Session Aktif| Siswa

    Siswa -->|Unggah Thread / Like / Komen| P2
    P2 -->|Simpan Interaksi| D3
    D3 -->|Ambil Data Feed| P2
    P2 -->|Timeline Beranda| Siswa

    Siswa -->|Unggah Produk Vokasi| P3
    P3 -->|Simpan Produk & Stok| D3
    D3 -->|Katalog Produk| P3
    P3 -->|Tampilkan Produk Jurusan| Siswa

    Siswa -->|Pilih Barang & Titik Temu| P4
    D4 -->|Data Master Titik Temu| P4
    P4 -->|Validasi Ketersediaan Produk| D3
    P4 -->|Simpan Riwayat Janjian COD| D5
    D5 -->|Pesan Obrolan & Konteks COD| P4
    P4 -->|Notifikasi Chat & Ringkasan COD| Siswa

    Siswa -->|Laporkan Konten| P5
    P5 -->|Simpan Laporan| D6
    Admin -->|"Master Siswa (NIS/Kelas)"| P5
    P5 -->|Update Registry| D1
    Admin -->|Kelola Spot COD| P5
    P5 -->|Update Titik Temu| D4
    D6 -->|Daftar Laporan| P5
    P5 -->|Hasil Moderasi| Admin
```

### 3.4.2 DFD Level 1 (Fokus: Proses 4.0 Transaksi COD)
Menguraikan rincian sub-proses koordinasi transaksi pemesanan barang hingga serah terima di sekolah:

```mermaid
flowchart TD
    Pembeli["👤 Siswa Pembeli"]
    Penjual["👤 Siswa Penjual"]

    P41(("4.1<br/>Validasi Produk &<br/>Ketersediaan"))
    P42(("4.2<br/>Pemilihan Titik Temu<br/>(Dropdown Spot)"))
    P43(("4.3<br/>Inisialisasi Chat &<br/>Notifikasi Realtime"))
    P44(("4.4<br/>Verifikasi Fisik COD &<br/>Serah Terima Tunai"))

    D3[("D3: market_posts")]
    D4[("D4: school_meeting_points")]
    D5[("D5: conversations & direct_messages")]

    Pembeli -->|Pilih Item & Kuantitas| P41
    D3 -->|Cek Sisa Stok| P41
    P41 -->|Stok Valid| P42

    D4 -->|Daftar Titik Temu Aktif| P42
    Pembeli -->|Pilih Titik Kumpul & Catatan Jam| P42
    P42 -->|Data Lengkap Checkout| P43

    P43 -->|"Simpan Pesan Janjian COD Otomatis"| D5
    P43 -->|Push Notifikasi Chat Masuk| Penjual
    P43 -->|Buka Ruang Obrolan Terpadu| Pembeli

    Pembeli -->|Periksa Fisik Barang & Bayar Tunai di Spot COD| P44
    Penjual -->|Serahkan Barang & Terima Uang Tunai| P44
```

---

## 3.5 Use Case Diagram

```mermaid
flowchart LR
    Siswa["👤 Siswa (Warga SMKN 8)"]
    Admin["🛡️ Admin Sekolah"]

    subgraph sNapsBoundary["Boundary Sistem sNaps"]
        UC1(["Registrasi & Login NIS"])
        UC1_INC(["Validasi Master Registry Sekolah"])
        UC2(["Kelola Profil Siswa"])
        UC3(["Publikasi Thread Komunitas"])
        UC3_EXT(["Tambahkan Polling Interaktif"])
        UC4(["Interaksi Feed (Like & Komentar)"])
        UC5(["Publikasi Produk Vokasi & Karya"])
        UC6(["Jelajah Katalog & Filter Jurusan"])
        UC7(["Checkout Pesanan COD"])
        UC7_INC1(["Validasi Kuantitas Stok"])
        UC7_INC2(["Pilih Titik Temu Resmi Sekolah"])
        UC8(["Direct Chat Realtime (DM)"])
        UC9(["Laporkan Konten Melanggar"])

        UC10(["Kelola Master Registry Siswa"])
        UC11(["Kelola Master Titik Temu COD"])
        UC12(["Tinjau & Moderasi Konten"])
        UC13(["Monitor Log Keamanan & Perangkat"])
    end

    Siswa --> UC1
    Siswa --> UC2
    Siswa --> UC3
    Siswa --> UC4
    Siswa --> UC5
    Siswa --> UC6
    Siswa --> UC7
    Siswa --> UC8
    Siswa --> UC9

    UC1 -.->|"<<include>>"| UC1_INC
    UC3_EXT -.->|"<<extend>>"| UC3
    UC7 -.->|"<<include>>"| UC7_INC1
    UC7 -.->|"<<include>>"| UC7_INC2

    Admin --> UC10
    Admin --> UC11
    Admin --> UC12
    Admin --> UC13
```

#### Skenario Use Case Utama (UC-07: Pemesanan Langsung via Chat DM & COD Titik Temu)
- **Aktor Utama**: Siswa Pembeli
- **Aktor Sekunder**: Siswa Penjual, Database Server
- **Kondisi Awal (Pre-condition)**: Pembeli terautentikasi NIS dan melihat karya produk di aplikasi.
- **Kondisi Akhir (Post-condition)**: Ruang percakapan `conversations` terhubung membawa konteks produk dan notifikasi terkirim ke penjual.
- **Alur Normal**: Pembeli memilih produk -> Menekan tombol 'Beli Sekarang' -> Sistem langsung menghubungkan ke ruang chat DM penjual dengan kartu ringkasan produk menempel -> Kedua siswa berdiskusi dan menyepakati titik temu COD -> Bertemu fisik saat jam istirahat untuk serah terima barang dan pembayaran tunai.
- **Alur Alternatif**: Jika penjual belum merespons, pembeli dapat meninggalkan pesan teks dan menunggu notifikasi balasan.

---

## 3.6 Activity Diagram (Pemesanan COD via Chat DM)

```mermaid
flowchart TD
    subgraph Pembeli["Siswa Pembeli"]
        A1([Mulai: Buka Detail Produk]) --> A2[Tekan 'Beli Sekarang']
        A3[Langsung Masuk ke Ruang Chat DM Penjual]
        A4[Kirim Pesan & Sepakati Titik Temu COD]
        A5[Temui Penjual di Spot COD Sesuai Janjian]
        A6[Periksa Fisik Barang & Serahkan Uang Tunai]
    end

    subgraph Sistem["Sistem sNaps"]
        A2 --> S1[Hubungkan ke Percakapan: conversations & direct_messages]
        S1 --> S2[Otomatis Lampirkan Kartu Ringkasan Produk di Chat]
        S2 --> S3[Kirim Push Notifikasi Realtime ke HP Penjual]
        S3 --> A3
        A4 --> S4[Simpan Pesan Janjian COD ke Database]
        S4 --> P2
        A6 --> S_Final([Selesai: Transaksi Berhasil])
    end

    subgraph Penjual["Siswa Penjual"]
        S3 -.-> P1[Terima Notifikasi Chat Masuk]
        P1 --> P2[Buka Chat & Sepakati Janjian di Titik Temu]
        P2 --> P3[Bawa Produk ke Spot COD Saat Jam Istirahat]
        P3 --> A5
        A6 --> P4[Terima Uang Tunai & Serahkan Barang]
        P4 --> S_Final
    end
```

---

## 3.7 Perancangan Basis Data (ERD, CDM, PDM)

### 3.7.1 Conceptual Data Model (CDM)
Struktur konseptual data logis mendefinisikan hubungan bisnis antara entitas utama:
- `student_registry`: Master buku induk sekolah (NIS, Nama, Kelas, Jurusan).
- `profiles`: Akun aktif pengguna aplikasi sNaps.
- `market_posts`: Listing produk karya vokasi dan thread forum diskusi.
- `school_meeting_points`: Daftar lokasi titik temu fisik resmi di sekolah.
- `conversations` & `direct_messages`: Data obrolan privat antar pengguna terintegrasi konteks produk.
- `content_reports`: Data pelaporan konten melanggar etika sekolah.

### 3.7.2 Physical Data Model (PDM)
Struktur fisik tabel diimplementasikan pada database PostgreSQL (Supabase):

```mermaid
erDiagram
    student_registry {
        TEXT nis PK
        TEXT full_name
        TEXT class_group
        TEXT major
        BOOLEAN is_active
    }

    profiles {
        UUID id PK
        TEXT nis FK
        TEXT username
        TEXT full_name
        TEXT avatar_url
        TEXT role
        TEXT class_group
        TEXT bio
        TIMESTAMPTZ created_at
    }

    market_posts {
        UUID id PK
        UUID seller_id FK
        TEXT title
        TEXT description
        INT price
        TEXT type
        TEXT category
        JSONB image_urls
        INT view_count
        TIMESTAMPTZ created_at
    }

    school_meeting_points {
        UUID id PK
        TEXT name
        TEXT code
        TEXT area_zone
        TEXT description
        TEXT photo_url
        BOOLEAN is_active
    }

    conversations {
        UUID id PK
        UUID participant_one FK
        UUID participant_two FK
        UUID product_id FK
        TEXT last_message
        TIMESTAMPTZ last_message_at
        TIMESTAMPTZ created_at
    }

    direct_messages {
        UUID id PK
        UUID conversation_id FK
        UUID sender_id FK
        TEXT content
        BOOLEAN is_read
        TIMESTAMPTZ created_at
    }

    content_reports {
        UUID id PK
        UUID reporter_id FK
        UUID target_post_id FK
        TEXT reason
        TEXT status
        TIMESTAMPTZ created_at
    }

    student_registry ||--o| profiles : "nis"
    profiles ||--o{ market_posts : "seller_id"
    profiles ||--o{ conversations : "participant_one"
    profiles ||--o{ conversations : "participant_two"
    market_posts ||--o{ conversations : "product_id"
    conversations ||--o{ direct_messages : "conversation_id"
    profiles ||--o{ direct_messages : "sender_id"
    profiles ||--o{ content_reports : "reporter_id"
    market_posts ||--o{ content_reports : "target_post_id"
```    profiles ||--o{ content_reports : "reporter_id"
    market_posts ||--o{ content_reports : "target_post_id"
```

---

## 3.8 Class Diagram

```mermaid
classDiagram
    %% Presentation & Navigation
    class HomeFeedScreen {
        +HomeFeedController controller
        +_handleBuyNow(MarketPostModel post) void
    }

    class SocialCommerceNavigator {
        +openDirectMessage(BuildContext context, MarketPostModel post) void
    }

    class ChatConversationScreen {
        +ConversationModel conversation
        +createState() State~ChatConversationScreen~
    }

    %% Models
    class UserProfile {
        +String id
        +String nis
        +String username
        +String fullName
        +String? avatarUrl
        +String role
        +String classGroup
        +String? bio
        +fromJson(Map data) UserProfile
        +toJson() Map
    }

    class MarketPostModel {
        +String id
        +UserProfile seller
        +String? title
        +String caption
        +int? price
        +String category
        +List~String~ images
        +DateTime createdAt
    }

    class ProductContext {
        +String title
        +String price
        +String? image
        +String location
    }

    class ConversationModel {
        +String id
        +UserProfile user
        +String? productId
        +String lastMessage
        +DateTime lastMessageAt
        +int unreadCount
        +ProductContext? productContext
    }

    class ChatMessageModel {
        +String id
        +String conversationId
        +String senderId
        +String messageText
        +bool isRead
        +DateTime createdAt
    }

    %% Services
    class DirectMessagesService {
        -List~ConversationModel~ _conversations
        -Map~String, List~ChatMessageModel~~ _conversationMessages
        +static DirectMessagesService instance
        +loadConversations() Future~void~
        +loadMessages(String conversationId) Future~List~ChatMessageModel~~
        +sendMessage(String conversationId, String text) Future~ChatMessageModel~
        +markAsRead(String conversationId) Future~void~
    }

    class SupabaseService {
        -SupabaseClient client
        +static SupabaseService instance
        +fetchConversations() Future~List~Map~~~~
        +fetchMessages(String convId) Future~List~Map~~~~
        +sendChatMessage(String convId, String text) Future~Map~
        +subscribeToGlobalInbox(Function onNewMessage) RealtimeChannel
    }

    %% Relationships
    HomeFeedScreen --> SocialCommerceNavigator : "delegates buy action"
    SocialCommerceNavigator --> DirectMessagesService : "retrieves/creates conversation"
    SocialCommerceNavigator --> ChatConversationScreen : "navigates to"
    SocialCommerceNavigator ..> ProductContext : "creates context"
    
    ChatConversationScreen --> DirectMessagesService : "observes messages"
    ChatConversationScreen o-- ConversationModel : "holds active"
    ConversationModel o-- ProductContext : "contains"
    ConversationModel o-- UserProfile : "peer user"
    
    DirectMessagesService --> SupabaseService : "calls realtime gateway"
    DirectMessagesService o-- ConversationModel : "manages list"
    DirectMessagesService o-- ChatMessageModel : "caches messages"
    MarketPostModel --> UserProfile : "seller"
```

---

## 3.9 Sequence Diagram

### 3.9.1 Sequence Diagram: Autentikasi NIS & Device Binding

```mermaid
sequenceDiagram
    autonumber
    actor Siswa as 👤 Siswa
    participant UI as 📱 LoginScreen
    participant Ctrl as 🎮 AuthController
    participant Svc as 🌐 SupabaseAuthService
    participant DB_Reg as 🗄️ student_registry
    participant DB_Prof as 🗄️ profiles

    Siswa->>UI: Input NIS & Password
    UI->>Ctrl: login(nis, password)
    Ctrl->>Svc: loginWithNis(nis, password)
    
    activate Svc
    Svc->>DB_Reg: SELECT * FROM student_registry WHERE nis = :nis AND is_active = true
    alt NIS Tidak Terdaftar di Sekolah
        DB_Reg-->>Svc: Data Kosong (Not Found)
        Svc-->>Ctrl: Error: NIS tidak terdaftar
        Ctrl-->>UI: Tampilkan SnackBar Peringatan NIS Ilegal
        UI-->>Siswa: Pesan Gagal Login
    else NIS Terdaftar Valid
        DB_Reg-->>Svc: Record Siswa (Nama, Kelas, Jurusan)
        Svc->>DB_Prof: SELECT * FROM profiles WHERE nis = :nis
        DB_Prof-->>Svc: User Profile & Role
        Svc->>Svc: Validasi Bind Hardware Device
        Svc-->>Ctrl: AuthResponse Sukses + Token JWT
        deactivate Svc
        
        Ctrl-->>UI: Update State Login Berhasil
        UI-->>Siswa: Navigasi ke Beranda (Feed & Market)
    end
```

### 3.9.2 Sequence Diagram: Pemesanan Langsung via Chat DM (Feed-to-DM)

```mermaid
sequenceDiagram
    autonumber
    actor Pembeli as 👤 Siswa Pembeli
    participant UI_Feed as 📱 HomeFeedScreen
    participant Nav as 🧭 SocialCommerceNavigator
    participant Svc_DM as 💬 DirectMessagesService
    participant UI_Chat as 📱 ChatConversationScreen
    participant DB as 🗄️ Supabase (PostgreSQL & Realtime)
    actor Penjual as 👤 Siswa Penjual

    Pembeli->>UI_Feed: Tekan Tombol 'Beli Sekarang' pada Postingan Produk
    UI_Feed->>Nav: openDirectMessage(context, post)
    activate Nav
    
    Nav->>Nav: Bentuk ProductContext(title, price, image, location)
    Nav->>Svc_DM: Cek Riwayat Percakapan dengan Penjual
    activate Svc_DM
    
    alt Percakapan Belum Ada
        Svc_DM->>DB: Buat Record di conversations (participant_one, participant_two, product_id)
        DB-->>Svc_DM: Return ConversationModel Baru
    else Percakapan Sudah Ada
        Svc_DM-->>Nav: Gunakan ConversationModel yang Tersedia
    end
    deactivate Svc_DM
    
    Nav->>UI_Chat: Navigasi Membuka Layar Chat (Bawa ConversationModel & ProductContext)
    deactivate Nav
    activate UI_Chat
    UI_Chat-->>Pembeli: Tampilkan Layar Chat dengan Kartu Produk Menempel di Atas Input
    
    Pembeli->>UI_Chat: Ketik Pesan & Tekan Kirim (cth: "Halo kak, COD di Gazebo PPLG istirahat pertama?")
    UI_Chat->>Svc_DM: sendMessage(conversationId, text)
    activate Svc_DM
    Svc_DM->>DB: INSERT INTO direct_messages (conversation_id, sender_id, content)
    activate DB
    DB-->>Svc_DM: Record Pesan Tersimpan
    
    DB-->>Penjual: Realtime Broadcast / Push Notification Chat Masuk
    deactivate DB
    deactivate Svc_DM
    
    Penjual->>UI_Chat: Buka DM & Sepakati Janjian di Titik Temu
    Pembeli->>Penjual: Bertemu di Lokasi Sekolah, Periksa Barang & Bayar Tunai
    deactivate UI_Chat
```
