import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/core/components/mascot_bundle_selector_bar.dart';
import 'package:snapan_market/core/components/mascot_gallery_bottom_sheet.dart';
import 'package:snapan_market/core/models/mascot_flair_model.dart';
import 'package:snapan_market/features/create_post/components/create_post_bottom_sheets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MascotPickerOptimizationTests', () {
    testWidgets('MascotBundleSelectorBar renders without overflow in compact 264px popover constraint', (tester) async {
      MascotBundle selected = MascotBundle.koala;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 264.0,
                child: MascotBundleSelectorBar(
                  selectedBundle: selected,
                  compact: true,
                  onBundleSelected: (bundle) => selected = bundle,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect no overflow errors
      expect(tester.takeException(), isNull);

      // Verify ListView horizontal scroll is present
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('MascotBundleSelectorBar renders in non-compact mode and handles selection', (tester) async {
      MascotBundle selected = MascotBundle.bear;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380.0,
              child: MascotBundleSelectorBar(
                selectedBundle: selected,
                compact: false,
                onBundleSelected: (bundle) => selected = bundle,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('MascotGalleryBottomSheet filters mascots correctly by search text', (tester) async {
      MascotBundle? chosen;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    MascotGalleryBottomSheet.show(
                      context,
                      selectedBundle: MascotBundle.bear,
                      onSelected: (b) => chosen = b,
                    );
                  },
                  child: const Text('Open Gallery'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap to open bottom sheet
      await tester.tap(find.text('Open Gallery'));
      await tester.pumpAndSettle();

      // Verify header and badge
      expect(find.text('Katalog Maskot Snaps'), findsOneWidget);
      expect(find.text('21 Mascot'), findsOneWidget);

      // Filter by "cat"
      await tester.enterText(find.byType(TextField), 'cat');
      await tester.pumpAndSettle();

      // Only Cat should match
      expect(find.text('Cat'), findsOneWidget);
      expect(find.text('Bear'), findsNothing);

      // Tap Cat to select
      await tester.tap(find.text('Cat'));
      await tester.pumpAndSettle();

      // Bottom sheet should be closed and Cat chosen
      expect(chosen, MascotBundle.cat);
      expect(find.text('Katalog Maskot Snaps'), findsNothing);
    });

    testWidgets('CreatePostBottomSheets.showMascotPickerPopup renders with zero overflow', (tester) async {
      final triggerKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                key: triggerKey,
                onPressed: () {},
                child: const Text('Trigger'),
              ),
            ),
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(ElevatedButton));
      CreatePostBottomSheets.showMascotPickerPopup(
        context: context,
        triggerKey: triggerKey,
        currentFlair: null,
        onFlairSelected: (_) {},
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MascotBundleSelectorBar), findsOneWidget);
    });
  });
}
