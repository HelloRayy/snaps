# Copy Desain Figma ke Website

Halaman kerja statis ada di `public/figma/` dan bisa dibuka di
`http://localhost:5173/figma/` saat `npm run dev` jalan. Halaman ini terpisah
dari aplikasi React di `src/`, jadi hasil copy dari Figma tidak bisa merusak
halaman utama.

## File yang dipakai

| File | Isi |
| :--- | :--- |
| `public/figma/index.html` | Struktur halaman, area tempel HTML |
| `public/figma/style.css` | Reset, token warna, area tempel CSS |
| `public/figma/script.js` | Area tempel JS interaksi |
| `public/figma/assets/` | Gambar dan ikon hasil export Figma |

## Langkah copy dari Figma

1. Jalankan `npm run dev`, buka `http://localhost:5173/figma/`.
2. Di Figma, pilih frame yang mau dijadikan halaman.
3. Ambil kodenya lewat salah satu cara:
   - **Dev Mode** → panel Code → pilih HTML/CSS → Copy.
   - Plugin exporter seperti **Figma to Code (HTML, Tailwind, Flutter)** atau
     **Anima**.
4. Tempel HTML ke dalam `<main id="figma-root">` di `index.html`, ganti
   `<section data-figma-placeholder>`.
5. Tempel CSS ke bagian `PASTE CSS FIGMA` di `style.css`.
6. Tempel JS ke bagian `PASTE JS FIGMA` di `script.js`.
7. Export aset gambar ke `public/figma/assets/`, lalu ubah `src` hasil export
   menjadi path relatif `./assets/nama-file.png`.

Setiap kali file disimpan, Vite langsung reload halamannya.

## Yang perlu dirapikan setelah paste

- **Hapus `<!DOCTYPE>`, `<html>`, `<head>`, dan `<body>`** dari hasil export.
  Yang ditempel cukup isi body-nya saja.
- **Gambar**: URL absolut hasil export (misalnya `/Users/...`) pasti rusak.
  Ganti ke `./assets/...` atau hotlink bila memang dari Figma CDN.
- **Ukuran tetap**: `width: 1440px` bikin halaman geser di HP. Ganti dengan
  `max-width` + `width: 100%`, atau bungkus dengan container.
- **Posisi absolut**: export Figma sering menghasilkan
  `position: absolute; left: 137px`. Untuk section yang isinya teks/gambar
  dinamis, ubah ke flex/grid supaya tidak tumpang tindih saat layar sempit.
- **Font**: halaman ini sudah memuat Inter. Kalau desain memakai font lain,
  tambahkan `<link>` Google Fonts di `<head>` dan daftarkan di
  `--font-sans`/`font-family`.
- **Warna**: pakai token di `style.css` (`var(--primary)`, `var(--ink)`, dst.)
  daripada hex hasil export, supaya konsisten dengan brand Snaps.

## Kalau hasil export-nya React + Tailwind

Halaman `/figma/` ini hanya memuat CSS biasa, jadi class Tailwind tidak akan
terbaca. Untuk export model itu, komponennya dipindah ke `src/ui/` dan
dipasang lewat React. Beri tahu agen kalau mau jalur ini.
