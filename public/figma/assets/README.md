# Gambar & ikon hasil export Figma

Letakkan file PNG/SVG/WebP di folder ini, lalu rujuk dengan path relatif
dari `public/figma/index.html`:

```html
<img src="./assets/nama-file.png" alt="..." />
```

Jangan pakai path absolut hasil export Figma (misalnya
`/Users/nama/Downloads/...`) karena tidak akan terbaca di browser.
