# [SNAPS-84] feat(mention): add tag mention @username in many pages

> **Ticket Metadata**:
> - **Sequence**: SNAPS-84
> - **Priority**: HIGH
> - **Domain**: `mention / autocomplete / profile / chat / feed`
> - **Status**: Ticket (Unstarted)

---

## 1. Problem Statement & User Context

- **Kondisi Saat Ini**:
  - Utilitas parsing mention `MentionTextSpanHelper` sudah ada dan digunakan pada `PostCaptionText`, `PostCommentItem`, dan `CommentReplyTile`.
  - Namun, di halaman-halaman vital lainnya seperti **Direct Messages (`ChatMessageBubble`)** dan **Bio Profil Pengguna (`ProfileInfoHeader`)**, teks `@username` masih dirender menggunakan widget `Text` biasa tanpa parsing tautan interaktif maupun navigasi ke profil tujuan.
  - Saat pengguna mengetik komentar baru (`CommentInputBar`), membuat postingan baru (`CreatePostMainInputBlock`), atau mengetik pesan di DM (`ChatComposerBar`), belum tersedia mekanisme input autocomplete/suggestion popup saat karakter `@` diketik untuk memilih akun pengguna secara instan.

- **Kebutuhan Fitur**:
  1. Integrasi `MentionTextSpanHelper` secara konsisten pada balon chat percakapan DM (`ChatMessageBubble`) dan teks bio profil (`ProfileInfoHeader`).
  2. Penyediaan popup/overlay rekomendasi pengguna (mention suggestion) saat pengguna mengetik simbol `@` pada input komentar dan pembuatan postingan.
  3. Memastikan klik pada teks `@username` mengarahkan pengguna langsung ke `ProfileScreen(username: cleanUsername)`.

---

## 2. Target File Scope

| File Path | Peran & Perubahan |
| :--- | :--- |
| [`lib/features/messages/components/chat_message_bubble.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/messages/components/chat_message_bubble.dart) | Mengganti `Text(message.text)` dengan `RichText` / `Text.rich` menggunakan `MentionTextSpanHelper.buildSpans` |
| [`lib/features/profile/components/profile_info_header.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/profile/components/profile_info_header.dart) | Mengintegrasikan `MentionTextSpanHelper` pada `user.bio` |
| [`lib/features/feed/components/comment/comment_input_bar.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/features/feed/components/comment/comment_input_bar.dart) | Deteksi pengetikan token `@` dan trigger overlay saran akun |
| [`lib/core/components/mention_suggestion_overlay.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/core/components/mention_suggestion_overlay.dart) | **(Baru/Reusable)** Komponen overlay daftar suggestion username berbasis query profil Supabase |
| [`lib/core/utils/mention_text_span_helper.dart`](file:///home/rayhan/Windows-D/project/snapan-market-mobile/lib/core/utils/mention_text_span_helper.dart) | Penyesuaian styling dan tap handling adaptif tema (bubble me vs incoming) |

---

## 3. Step-by-Step Technical Approach

### Langkah 1: Integrasi Mention di Chat Bubble DM
1. Buka `ChatMessageBubble`.
2. Pada pesan keluar (`message.isMe`):
   - Gunakan `MentionTextSpanHelper.buildSpans` dengan `accentColor: Colors.white` (atau underline tegas dengan kontras tinggi) agar tetap terbaca jelas di atas latar belakang biru `#1D64EC`.
3. Pada pesan masuk:
   - Gunakan `MentionTextSpanHelper.buildSpans` dengan `accentColor: AppColors.primary`.
4. Pasang recognizer navigasi ke `ProfileScreen` saat mention diklik.

### Langkah 2: Integrasi Mention di Bio Profil
1. Di `ProfileInfoHeader`, ubah blok rendering `user.bio` dari `Text(user.bio)` menjadi `Text.rich(TextSpan(children: MentionTextSpanHelper.buildSpans(...)))`.
2. Pastikan navigasi ke profil lain berjalan mulus tanpa merusak stack navigasi profil saat ini.

### Langkah 3: Mention Autocomplete Suggestion
1. Buat helper `MentionSuggestionOverlay` yang memantau controller teks saat cursor berada tepat setelah simbol `@`.
2. Ambil query username dari cache lokal atau query ringan `SupabaseService.instance.searchUsers(query)`.
3. Saat salah satu user dipilih, gantikan token `@query` menjadi `@username ` dan kembalikan fokus ke textfield.

---

## 4. Definition of Done (DoD)

- [ ] Teks `@username` di dalam bubble chat DM (`ChatMessageBubble`) dapat diklik dan membuka profil pengguna yang bersangkutan.
- [ ] Teks `@username` di bio profil (`ProfileInfoHeader`) terformat sebagai mention aktif dan dapat diklik.
- [ ] Warna mention pada pesan keluar di DM tetap kontras dan memenuhi standar keterbacaan (WCAG).
- [ ] Tidak terjadi crash saat parsing teks dengan multiple mentions, karakter tanda baca, atau emoji di samping `@username`.
- [ ] Lolos static analysis `flutter analyze` dengan 0 errors.
