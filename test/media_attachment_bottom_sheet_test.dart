import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/features/feed/components/comment/comment_input_bar.dart';
import 'package:snapan_market/features/feed/components/sheets/media_attachment_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaAttachmentBottomSheet Tests', () {
    testWidgets('Renders hint banner, gallery button, shutter ring, and multi foto button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaAttachmentBottomSheet(),
          ),
        ),
      );
      await tester.pump();

      // Verify instruction banner text
      expect(find.text('Tap rana untuk foto, atau pilih dari galeri'), findsOneWidget);

      // Verify side action buttons
      expect(find.text('Galeri'), findsOneWidget);
      expect(find.text('Multi Foto'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(CupertinoIcons.photo_on_rectangle), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.camera), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.square_stack_3d_down_right), findsOneWidget);
    });
  });

  group('CommentInputBar Attachment Integration Tests', () {
    testWidgets('Renders leading camera/clip button and placeholder correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentInputBar(
              onSubmitComment: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(CupertinoIcons.paperclip), findsOneWidget);
      expect(find.text('Tulis balasan...'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.smiley), findsOneWidget);
    });

    testWidgets('Triggers onSubmitComment when submitting text without media', (tester) async {
      String submittedText = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentInputBar(
              onSubmitComment: (text) {
                submittedText = text;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Enter text
      await tester.enterText(find.byType(TextField), 'Halo ini komentar tes');
      await tester.pump();

      // Send button should now be visible (arrow_up)
      expect(find.byIcon(CupertinoIcons.arrow_up), findsOneWidget);

      // Tap send button
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pump();

      expect(submittedText, equals('Halo ini komentar tes'));
    });
  });
}
