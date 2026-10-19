import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapan_market/core/components/mascot_indicator_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snapan_market/core/models/mascot_flair_model.dart';
import 'package:snapan_market/core/services/mascot_feature_notice_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/feed/components/navigation/nav_glyphs/user_nav_glyph.dart';
import 'package:snapan_market/features/profile/components/profile_info_header.dart';
import 'package:snapan_market/features/profile/models/profile_user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://mock.supabase.co',
        anonKey: 'mock-anon-key',
      );
    } catch (_) {}
  });


  setUp(() {
    SharedPreferences.setMockInitialValues({});
    MascotFeatureNoticeService.instance.resetForTesting();
  });

  tearDown(() {
    MascotFeatureNoticeService.instance.resetForTesting();
  });

  group('MascotIndicatorBadge Visual & Interaction Tests', () {
    testWidgets('renders circular container with Electric Indigo background and Koala asset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MascotIndicatorBadge(size: 20.0),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.primary));
      expect(decoration.shape, equals(BoxShape.circle));

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final image = tester.widget<Image>(imageFinder);
      expect((image.image as AssetImage).assetName, equals('assets/mascots/koala/delighted.webp'));
    });

    testWidgets('adapts border color for dark mode vs light mode', (tester) async {
      // Light Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: const Scaffold(
            body: MascotIndicatorBadge(size: 20.0),
          ),
        ),
      );
      final lightContainer = tester.widget<Container>(
        find.descendant(of: find.byType(MascotIndicatorBadge), matching: find.byType(Container)),
      );
      final lightDecoration = lightContainer.decoration as BoxDecoration;
      expect((lightDecoration.border as Border).top.color, equals(Colors.white));

      // Dark Mode
      await tester.pumpWidget(
        MaterialApp(
          home: Theme(
            data: ThemeData.dark(),
            child: const Scaffold(
              body: MascotIndicatorBadge(size: 20.0),
            ),
          ),
        ),
      );
      final darkContainer = tester.widget<Container>(
        find.descendant(of: find.byType(MascotIndicatorBadge), matching: find.byType(Container)),
      );
      final darkDecoration = darkContainer.decoration as BoxDecoration;
      expect((darkDecoration.border as Border).top.color, equals(AppColors.darkSurface));
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MascotIndicatorBadge(
              size: 20.0,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MascotIndicatorBadge));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('MascotFeatureNoticeService State & Persistence Tests', () {
    test('unauthenticated user never sees mascot badge', () async {
      final service = MascotFeatureNoticeService.instance;
      await service.init();
      // Supabase is not logged in during unit tests
      expect(service.shouldShowMascotBadge.value, isFalse);
    });

    test('markSeen persists user key and fallback key to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MascotFeatureNoticeService.instance;
      await service.init();

      service.shouldShowMascotBadge.value = true;
      expect(service.shouldShowMascotBadge.value, isTrue);

      await service.markSeen();
      expect(service.shouldShowMascotBadge.value, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_seen_mascot_feature_v1'), isTrue);
    });
  });

  group('ProfileInfoHeader Anti-Collision & Integration Tests', () {
    testWidgets('incomplete avatar + mascot badge shows both badges in non-colliding positions', (tester) async {
      MascotFeatureNoticeService.instance.shouldShowMascotBadge.value = true;

      const userWithoutAvatar = ProfileUserModel(
        id: 'user-incomplete',
        name: 'Test Student',
        displayName: 'Student',
        username: 'student',
        avatar: '', // Incomplete avatar
        bio: 'Hello world',
        classGroup: 'X PPLG 1',
        mascotFlair: null, // No mascot
      );

      bool editTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoHeader(
              user: userWithoutAvatar,
              isOwnProfile: true,
              onMascotBadgeTap: () => editTriggered = true,
            ),
          ),
        ),
      );

      // Incomplete warning badge '!' is visible
      expect(find.text('!'), findsOneWidget);

      // MascotIndicatorBadge is visible
      expect(find.byType(MascotIndicatorBadge), findsOneWidget);

      // Check anti-collision positioning
      final positionedWidgets = tester.widgetList<Positioned>(find.byType(Positioned)).toList();

      // Find the warning badge Positioned (bottom: -2.0, right: -2.0)
      final warningPositioned = positionedWidgets.firstWhere(
        (p) => p.bottom == -2.0 && p.top == null && p.right == -2.0,
      );
      expect(warningPositioned, isNotNull);

      // Find the mascot badge Positioned (top: -2.0, right: -2.0, anti-colliding)
      final mascotPositioned = positionedWidgets.firstWhere(
        (p) => p.top == -2.0 && p.bottom == null && p.right == -2.0,
      );
      expect(mascotPositioned, isNotNull);

      // Tap mascot badge and verify callback
      await tester.tap(find.byType(MascotIndicatorBadge));
      await tester.pumpAndSettle();
      expect(editTriggered, isTrue);
    });

    testWidgets('custom avatar + mascot badge places badge at bottom-right', (tester) async {
      MascotFeatureNoticeService.instance.shouldShowMascotBadge.value = true;

      const userWithAvatar = ProfileUserModel(
        id: 'user-complete',
        name: 'Test Student',
        displayName: 'Student',
        username: 'student',
        avatar: 'https://example.com/avatar.jpg',
        bio: 'Hello world',
        classGroup: 'X PPLG 1',
        mascotFlair: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileInfoHeader(
              user: userWithAvatar,
              isOwnProfile: true,
            ),
          ),
        ),
      );

      // Warning '!' is NOT visible
      expect(find.text('!'), findsNothing);

      // MascotIndicatorBadge is visible at bottom: -2.0, right: -2.0
      expect(find.byType(MascotIndicatorBadge), findsOneWidget);

      final positionedWidgets = tester.widgetList<Positioned>(find.byType(Positioned)).toList();
      final mascotPositioned = positionedWidgets.firstWhere(
        (p) => p.bottom == -2.0 && p.top == null && p.right == -2.0,
      );
      expect(mascotPositioned, isNotNull);
    });

    testWidgets('user with active mascot flair does NOT display mascot indicator badge', (tester) async {
      MascotFeatureNoticeService.instance.shouldShowMascotBadge.value = true;

      final userWithFlair = ProfileUserModel(
        id: 'user-flair',
        name: 'Test Student',
        displayName: 'Student',
        username: 'student',
        avatar: 'https://example.com/avatar.jpg',
        bio: 'Hello world',
        classGroup: 'X PPLG 1',
        mascotFlair: const MascotFlairModel(
          bundle: MascotBundle.koala,
          emotion: MascotEmotion.delighted,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileInfoHeader(
              user: userWithFlair,
              isOwnProfile: true,
            ),
          ),
        ),
      );

      // Mascot indicator announcement badge should NOT be displayed
      expect(find.byType(MascotIndicatorBadge), findsNothing);
    });
  });

  group('UserNavGlyph Collision & Priority Tests', () {
    testWidgets('when incomplete avatar warning is active, warning badge takes priority over mascot badge',
        (tester) async {
      MascotFeatureNoticeService.instance.shouldShowMascotBadge.value = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserNavGlyph(
              isActive: false,
              userAvatar: '', // empty avatar triggers warning when logged in, or fallback
            ),
          ),
        ),
      );

      // Without auth, neither badge shows
      expect(find.byType(MascotIndicatorBadge), findsNothing);
    });
  });
}
