import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/features/feed/components/comment/comment_images_section.dart';
import 'package:snapan_market/features/feed/components/post_card/adaptive_carousel_card.dart';
import 'package:snapan_market/features/feed/components/post_card/dynamic_feed_image.dart';

void main() {
  group('CommentImagesSection parity tests', () {
    testWidgets('Empty images renders SizedBox.shrink', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CommentImagesSection(images: []),
          ),
        ),
      );

      expect(find.byType(CommentImagesSection), findsOneWidget);
      expect(find.byType(DynamicFeedImage), findsNothing);
      expect(find.byType(AdaptiveCarouselCard), findsNothing);
    });

    testWidgets('Single image renders DynamicFeedImage with maxHeight 360 and borderRadius 14', (tester) async {
      List<String>? clickedImages;
      int? clickedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: CommentImagesSection(
                  images: const ['https://example.com/img1.jpg'],
                  onImageClick: (images, index) {
                    clickedImages = images;
                    clickedIndex = index;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final dynamicImageFinder = find.byType(DynamicFeedImage);
      expect(dynamicImageFinder, findsOneWidget);

      final dynamicImage = tester.widget<DynamicFeedImage>(dynamicImageFinder);
      expect(dynamicImage.maxHeight, 360.0);
      expect(dynamicImage.borderRadius, 14.0);
      expect(dynamicImage.imageUrl, 'https://example.com/img1.jpg');

      // Tap on image
      await tester.tap(dynamicImageFinder);
      expect(clickedImages, const ['https://example.com/img1.jpg']);
      expect(clickedIndex, 0);
    });

    testWidgets('Two portrait/square cached images render 50/50 split Row', (tester) async {
      const url1 = 'https://example.com/p1.jpg';
      const url2 = 'https://example.com/p2.jpg';
      AdaptiveCarouselCard.ratioCache[url1] = 0.8; // Portrait (4:5)
      AdaptiveCarouselCard.ratioCache[url2] = 1.0; // Square (1:1)

      List<String>? clickedImages;
      int? clickedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: CommentImagesSection(
                  images: const [url1, url2],
                  onImageClick: (images, index) {
                    clickedImages = images;
                    clickedIndex = index;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveCarouselCard), findsNWidgets(2));
      // 50/50 split uses Row with Expanded
      expect(find.byType(Expanded), findsNWidgets(2));
      expect(find.byType(SingleChildScrollView), findsNothing);

      // Verify tapping second image
      await tester.tap(find.byType(AdaptiveCarouselCard).at(1));
      expect(clickedImages, const [url1, url2]);
      expect(clickedIndex, 1);
    });

    testWidgets('Three images render SingleChildScrollView with AdaptiveCarouselCard items', (tester) async {
      const imgs = [
        'https://example.com/1.jpg',
        'https://example.com/2.jpg',
        'https://example.com/3.jpg',
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: CommentImagesSection(images: imgs),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(AdaptiveCarouselCard), findsNWidgets(3));

      final firstCard = tester.widget<AdaptiveCarouselCard>(find.byType(AdaptiveCarouselCard).first);
      expect(firstCard.height, 170.0);
      expect(firstCard.borderRadius, 14.0);
    });
  });
}
