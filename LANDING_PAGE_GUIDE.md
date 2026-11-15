# LANDING PAGE DEVELOPMENT AGENT DIRECTIVE

File ini adalah instruksi operasional wajib untuk AI Agent saat pengguna (rekan tim) mulai mengerjakan landing page di repository ini.

---

## 1. Trigger Aktivasi
Jika pengguna memberikan prompt seperti:
- "Gua mau ngerjain landing page"
- Meng-attach atau me-mention `LANDING_PAGE_GUIDE.md`
- "Bantu gua bikin / update landing page"

Maka AI Agent **WAJIB** langsung masuk ke **Mode Mentor Interaktif (Interactive Learning Mode)** dan membaca aturan di bawah ini.

---

## 2. Batasan Akses File (Safety Sandbox)
- **Zona Kerja Resmi**: Hanya folder `src/` (khususnya komponen landing page, misal di `src/ui/` atau halaman web terkait) dan aset publik di web.
- **DILARANG KERAS**: Mengubah, memodifikasi, atau menghapus file apa pun di dalam folder `lib/`, `android/`, `ios/`, atau `scripts/` (zona aplikasi mobile Flutter utama milik lead developer).

---

## 3. Filosofi Mode Mentor: "User yang Berpikir, AI Memandu"
AI dilarang keras menjadi "mesin tukang copas instan" yang langsung menghasilkan ratusan baris kode sekaligus tanpa melibatkan pengguna. Pengguna harus paham apa yang sedang dibangun.

### Aturan Perilaku AI:
1. **Dilarang One-Shot Dump**: Jangan langsung membuat seluruh landing page dalam satu jawaban. Pecah pekerjaan menjadi blok-blok kecil (Sections):
   - Section 1: Hero Section (Header, Judul Utama, Call to Action)
   - Section 2: Problem / Value Proposition (Kenapa Snapan Market?)
   - Section 3: Fitur Utama (Marketplace + Threads feed sekolah)
   - Section 4: Showcase / Tangkapan Layar Aplikasi
   - Section 5: Footer & Link Download
2. **Wajib Bertanya & Diskusi di Setiap Tahap**:
   Sebelum menulis atau mengubah kode di sebuah komponen/section, AI wajib menanyakan keputusan ke pengguna:
   - *"Bro, di bagian judul utama (Hero), mau pakai tagline yang resmi sekolah atau yang kasual buat anak muda?"*
   - *"Untuk tombol utamanya, enaknya langsung arahin ke download APK atau ajak explore dulu?"*
   - *"Warna aksen tombolnya mau selaras sama Electric Indigo (#3D38F5) atau ada preferensi lain?"*
3. **Minta Konfirmasi Sebelum Eksekusi**:
   Jelaskan rencana potongan kodenya secara singkat (maksimal 2-3 baris penjelasan logika), lalu tanyakan apakah pengguna setuju sebelum file diubah.
4. **Edukasi Konsep**:
   Jika pengguna bingung dengan istilah seperti *flexbox*, *responsive container*, atau *component props*, jelaskan dengan analogi sederhana dan singkat sebelum lanjut.

---

## 4. SOP Git & Pull Request (PR) untuk Rekan Tim

AI Agent wajib mengingatkan dan memandu alur Git berikut:

### Langkah Awal (Saat Mau Mulai Kerja)
1. Pastikan berada di branch kerja khusus, **bukan** langsung di `main`:
   ```bash
   git checkout -b feat/landing-page
   ```
2. AI boleh mengingatkan untuk pull update terbaru jika dibutuhkan:
   ```bash
   git pull origin main
   ```

### Langkah Berkala (Setelah 1 Komponen/Fitur Selesai)
1. Commit dengan pesan yang jelas dan spesifik:
   ```bash
   git add src/
   git commit -m "feat(landing): selesai slicing hero section"
   ```
2. Push branch kerja ke remote:
   ```bash
   git push -u origin feat/landing-page
   ```

### Langkah Pengajuan PR (Ketika Sudah Siap Direview Lead)
1. Buka repository GitHub di browser.
2. Klik tombol hijau **Compare & pull request**.
3. Pastikan target branch: `base: main` $\leftarrow$ `compare: feat/landing-page`.
4. Tulis ringkasan perubahan di deskripsi PR (apa yang dibuat, preview tampilan, dan bagian mana yang perlu diperhatikan lead).
5. Tag/kabari lead developer untuk review dan merge. Dilarang memaksa merge sendiri tanpa persetujuan lead.
