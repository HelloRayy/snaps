import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/features/feed/components/lightbox/lightbox_image_viewer.dart';
import 'package:snapan_market/features/feed/components/lightbox/media_lightbox_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LightboxImageViewer Zoom & Gesture Tests', () {
    testWidgets(
      'Double tap toggles zoom between 1.0x and 2.5x and triggers onZoomChanged',
      (tester) async {
        bool? latestZoomed;
        bool? latestInteraction;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox.expand(
                child: LightboxImageViewer(
                  imageUrl: 'https://example.com/test_image.jpg',
                  screenWidth: 400.0,
                  onZoomChanged: (zoomed) => latestZoomed = zoomed,
                  onInteractionChanged: (interacting) => latestInteraction = interacting,
                ),
              ),
            ),
          ),
        );

        final interactiveViewerFinder = find.byType(InteractiveViewer);
        expect(interactiveViewerFinder, findsOneWidget);

        final InteractiveViewer viewer = tester.widget(interactiveViewerFinder);
        expect(viewer.minScale, 0.8);
        expect(viewer.maxScale, 4.5);
        expect(viewer.boundaryMargin, EdgeInsets.zero);

        // Initial state: not zoomed
        final TransformationController controller = viewer.transformationController!;
        expect(controller.value.getMaxScaleOnAxis(), 1.0);

        // Perform double tap at center
        await tester.tap(interactiveViewerFinder);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(interactiveViewerFinder);
        await tester.pumpAndSettle();

        // Should now be zoomed to 2.5x
        expect(latestZoomed, isTrue);
        expect(controller.value.getMaxScaleOnAxis(), closeTo(2.5, 0.05));

        // Second double tap resets zoom back to 1.0x
        await tester.tap(interactiveViewerFinder);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(interactiveViewerFinder);
        await tester.pumpAndSettle();

        expect(latestZoomed, isFalse);
        expect(controller.value.getMaxScaleOnAxis(), closeTo(1.0, 0.001));
        expect(latestInteraction, isNull);
      },
    );

    testWidgets(
      'InteractiveViewer interaction callbacks and spring-back animation to Matrix4.identity()',
      (tester) async {
        bool? latestInteraction;
        bool? latestZoomed;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox.expand(
                child: LightboxImageViewer(
                  imageUrl: 'https://example.com/test_image.jpg',
                  screenWidth: 400.0,
                  onZoomChanged: (zoomed) => latestZoomed = zoomed,
                  onInteractionChanged: (interacting) => latestInteraction = interacting,
                ),
              ),
            ),
          ),
        );

        final interactiveViewerFinder = find.byType(InteractiveViewer);
        final InteractiveViewer viewer = tester.widget(interactiveViewerFinder);
        final TransformationController controller = viewer.transformationController!;

        // 1. Interaction starts
        viewer.onInteractionStart?.call(ScaleStartDetails(pointerCount: 2));
        expect(latestInteraction, isTrue);

        // 2. Interaction updates with zoom > 1.02
        controller.value = Matrix4.identity()
          ..scaleByDouble(1.5, 1.5, 1.0, 1.0);
        viewer.onInteractionUpdate?.call(
          ScaleUpdateDetails(
            scale: 1.5,
            pointerCount: 2,
            focalPoint: const Offset(200, 300),
            localFocalPoint: const Offset(200, 300),
          ),
        );
        expect(latestZoomed, isTrue);
        expect(controller.value.getMaxScaleOnAxis(), closeTo(1.5, 0.01));

        // 3. Scale back near identity (<= 1.02)
        controller.value = Matrix4.identity()
          ..translateByDouble(10.0, 5.0, 0.0, 1.0)
          ..scaleByDouble(1.01, 1.01, 1.0, 1.0);

        // 4. Interaction ends -> triggers _animateReset()
        viewer.onInteractionEnd?.call(ScaleEndDetails(pointerCount: 0));
        expect(latestInteraction, isFalse);

        // Pump animation frames for spring back to identity
        await tester.pumpAndSettle();

        // Controller value must now be exactly Matrix4.identity()
        expect(controller.value, Matrix4.identity());
        expect(controller.value.getMaxScaleOnAxis(), 1.0);
        expect(latestZoomed, isFalse);
      },
    );
  });

  group('MediaLightboxDialog Gesture Conflict Prevention Tests', () {
    testWidgets(
      'Vertical drag dismiss is blocked while image is zoomed or interacting',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      MediaLightboxDialog.show(
                        context: context,
                        images: const ['https://example.com/test.jpg'],
                        initialIndex: 0,
                      );
                    },
                    child: const Text('Buka Lightbox'),
                  ),
                );
              },
            ),
          ),
        );

        // Open lightbox
        await tester.tap(find.text('Buka Lightbox'));
        await tester.pumpAndSettle();

        expect(find.byType(MediaLightboxDialog), findsOneWidget);

        // Double tap on image to zoom in
        final interactiveViewerFinder = find.byType(InteractiveViewer);
        await tester.tap(interactiveViewerFinder);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(interactiveViewerFinder);
        await tester.pumpAndSettle();

        // While zoomed: PageView should have NeverScrollableScrollPhysics
        final pageViewFinder = find.byType(PageView);
        final PageView pageView = tester.widget(pageViewFinder);
        expect(pageView.physics, isA<NeverScrollableScrollPhysics>());

        // Attempting vertical drag down while zoomed should NOT dismiss the dialog
        await tester.fling(
          find.byType(MediaLightboxDialog),
          const Offset(0.0, 400.0),
          800.0,
        );
        await tester.pumpAndSettle();

        // Dialog must remain open
        expect(find.byType(MediaLightboxDialog), findsOneWidget);

        // Double tap to unzoom
        await tester.tap(interactiveViewerFinder);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(interactiveViewerFinder);
        await tester.pumpAndSettle();

        // After unzoom: vertical drag down dismisses modal
        await tester.fling(
          find.byType(MediaLightboxDialog),
          const Offset(0.0, 500.0),
          1000.0,
        );
        await tester.pumpAndSettle();

        // Dialog is now dismissed
        expect(find.byType(MediaLightboxDialog), findsNothing);
      },
    );

    testWidgets(
      'Vertical drag up (swipe up) dismisses modal when not zoomed',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      MediaLightboxDialog.show(
                        context: context,
                        images: const ['https://example.com/test.jpg'],
                        initialIndex: 0,
                      );
                    },
                    child: const Text('Buka Lightbox'),
                  ),
                );
              },
            ),
          ),
        );

        // Open lightbox
        await tester.tap(find.text('Buka Lightbox'));
        await tester.pumpAndSettle();

        expect(find.byType(MediaLightboxDialog), findsOneWidget);

        // Fling upward (negative Y offset and velocity)
        await tester.fling(
          find.byType(MediaLightboxDialog),
          const Offset(0.0, -500.0),
          1000.0,
        );
        await tester.pumpAndSettle();

        // Dialog is now dismissed via swipe up
        expect(find.byType(MediaLightboxDialog), findsNothing);
      },
    );
  });
}
