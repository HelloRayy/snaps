import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/core/services/snaps_asset_picker.dart';
import 'package:snapan_market/features/feed/components/comment/comment_input_bar.dart';

void main() {
  group('SnapsAssetPickerTextDelegate Tests', () {
    test('textDelegate returns Indonesian localized strings', () {
      const delegate = SnapsAssetPickerTextDelegate();
      expect(delegate.confirm, 'Selesai');
      expect(delegate.cancel, 'Batal');
      expect(delegate.edit, 'Edit');
      expect(delegate.emptyList, 'Belum ada foto');
      expect(delegate.loadFailed, 'Gagal memuat');
      expect(delegate.original, 'Ukuran Asli');
      expect(delegate.preview, 'Pratinjau');
      expect(delegate.select, 'Pilih');
      expect(delegate.goToSystemSettings, 'Buka Pengaturan HP');
    });
  });

  group('CommentInputBar Media Attachment Tests', () {
    testWidgets('Renders attachment button and submits comment text', (WidgetTester tester) async {
      String? submittedText;
      List<String>? submittedMedia;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentInputBar(
              onSubmitComment: (text) => submittedText = text,
              onSubmitCommentWithMedia: (text, media) {
                submittedText = text;
                submittedMedia = media;
              },
            ),
          ),
        ),
      );

      // Verify attachment photo icon is present in leading button
      expect(find.byIcon(CupertinoIcons.photo_on_rectangle), findsOneWidget);

      // Enter text
      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'Halo dari tes Snaps');
      await tester.pump();

      // Verify send button is shown
      final sendButton = find.byIcon(CupertinoIcons.arrow_up);
      expect(sendButton, findsOneWidget);

      await tester.tap(sendButton);
      await tester.pump();

      expect(submittedText, 'Halo dari tes Snaps');
      expect(submittedMedia, isEmpty);
    });
  });
}
