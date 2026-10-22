import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/core/models/mascot_flair_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mascot Bundles 21 Animals (bear -> tiger) Tests', () {
    test('Contains exactly 21 mascot bundles from bear to tiger', () {
      expect(MascotBundle.values.length, 21);
      expect(MascotBundle.values.first, MascotBundle.bear);
      expect(MascotBundle.values.last, MascotBundle.tiger);
    });

    test('All 21 mascot bundles have valid asset files for all emotions', () {
      for (final bundle in MascotBundle.values) {
        // Verify raw sheets exist
        final dirFile = File('${bundle.basePath}/directions.webp');
        final reactFile = File('${bundle.basePath}/reactions.webp');
        expect(dirFile.existsSync(), isTrue, reason: 'Missing directions.webp for ${bundle.name}');
        expect(reactFile.existsSync(), isTrue, reason: 'Missing reactions.webp for ${bundle.name}');

        // Verify all 9 sliced emotions exist
        for (final emotion in MascotEmotion.values) {
          final flair = MascotFlairModel(bundle: bundle, emotion: emotion);
          final emotionFile = File(flair.assetPath);
          expect(emotionFile.existsSync(), isTrue, reason: 'Missing ${flair.assetPath}');
          expect(emotionFile.lengthSync(), greaterThan(0), reason: 'Empty file ${flair.assetPath}');
        }
      }
    });

    test('MascotBundle.fromString parses all names case-insensitively', () {
      for (final bundle in MascotBundle.values) {
        expect(MascotBundle.fromString(bundle.name), bundle);
        expect(MascotBundle.fromString(bundle.name.toUpperCase()), bundle);
      }
      expect(MascotBundle.fromString('nonexistent'), isNull);
    });
  });
}
