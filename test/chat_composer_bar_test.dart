import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/messages/components/chat_composer_bar.dart';

void main() {
  group('ChatComposerBar Modern Unified Pill Widget Tests', () {
    testWidgets('renders unified pill with placeholder and photo icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatComposerBar(
              placeholder: 'Ketik pesan...',
              onSendMessage: (_) {},
            ),
          ),
        ),
      );

      // Verify placeholder
      expect(find.text('Ketik pesan...'), findsOneWidget);

      // Verify photo attachment icon inside pill
      expect(find.byIcon(CupertinoIcons.photo_on_rectangle), findsOneWidget);

      // When empty, emoji smiley icon is displayed
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.arrow_up), findsNothing);
    });

    testWidgets('typing text switches trailing action to send button with brand primary color', (tester) async {
      String? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatComposerBar(
              placeholder: 'Tulis sesuatu...',
              onSendMessage: (msg) => sentMessage = msg,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'Halo bro apa kabar?');
      await tester.pumpAndSettle();

      // Verify send arrow up appears and smiley disappears
      expect(find.byIcon(CupertinoIcons.arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsNothing);

      // Verify send button background uses AppColors.primary
      final sendButtonContainer = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(CupertinoIcons.arrow_up),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = sendButtonContainer.decoration as BoxDecoration;
      expect(decoration.color, AppColors.primary);

      // Tap send
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up));
      await tester.pumpAndSettle();

      // Verify callback triggered and textfield cleared
      expect(sentMessage, 'Halo bro apa kabar?');
      expect(find.text('Halo bro apa kabar?'), findsNothing);
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);
    });
  });
}
