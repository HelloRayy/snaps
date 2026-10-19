import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapan_market/core/services/snaps_asset_picker.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/feed/components/comment/comment_input_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.fluttercandies/photo_manager'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAssetPathList') {
          return <String, dynamic>{
            'data': <Map<String, dynamic>>[],
          };
        }
        if (methodCall.method == 'requestPermissionExtend') {
          return 1;
        }
        return null;
      },
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.fluttercandies/photo_manager'),
      null,
    );
  });

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

  group('SnapsInstaAssetPickerBuilderDelegate Tests', () {
    testWidgets('delegate initializes split-view properties with 3 columns', (WidgetTester tester) async {
      final provider = DefaultAssetPickerProvider(
        maxAssets: 5,
        pageSize: 90,
        requestType: RequestType.image,
      );
      final delegate = SnapsInstaAssetPickerBuilderDelegate(
        provider: provider,
        initialPermission: PermissionState.authorized,
        pickerTheme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.primary,
          ),
        ),
      );

      expect(delegate.gridCount, 3);
      expect(delegate.themeColor, AppColors.primary);
      expect(delegate.previewAsset.value, isNull);
      expect(delegate.viewerPosition.value, 0.0);
      expect(delegate.isMultiSelect.value, isTrue);

      await tester.pump(const Duration(milliseconds: 300));
      delegate.dispose();
    });

    testWidgets('previewHeight respects 45% screen height limit', (WidgetTester tester) async {
      final provider = DefaultAssetPickerProvider(
        maxAssets: 5,
        pageSize: 90,
        requestType: RequestType.image,
      );
      final delegate = SnapsInstaAssetPickerBuilderDelegate(
        provider: provider,
        initialPermission: PermissionState.authorized,
      );

      double? computedHeight;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: Builder(
              builder: (context) {
                computedHeight = delegate.previewHeight(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // 45% of 800 is 360, which is min(400, 360) = 360.
      expect(computedHeight, 360.0);

      await tester.pump(const Duration(milliseconds: 300));
      delegate.dispose();
    });

    testWidgets('confirmButton renders text-only button with blue primary color', (WidgetTester tester) async {
      final provider = DefaultAssetPickerProvider(
        maxAssets: 5,
        pageSize: 90,
        requestType: RequestType.image,
      );
      final delegate = SnapsInstaAssetPickerBuilderDelegate(
        provider: provider,
        initialPermission: PermissionState.authorized,
        textDelegate: const SnapsAssetPickerTextDelegate(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
            value: provider,
            child: Scaffold(
              body: Builder(
                builder: (context) => delegate.confirmButton(context),
              ),
            ),
          ),
        ),
      );

      // Verify TextButton is used (no solid pill MaterialButton)
      final textButtonFinder = find.byType(TextButton);
      expect(textButtonFinder, findsOneWidget);

      final textFinder = find.text('Selesai');
      expect(textFinder, findsOneWidget);

      // Initially disabled (no assets selected), color is slate/muted (0xFF94A3B8)
      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, const Color(0xFF94A3B8));

      await tester.pump(const Duration(milliseconds: 300));
      delegate.dispose();
    });

    testWidgets('backButton renders CupertinoIcons.xmark close icon', (WidgetTester tester) async {
      final provider = DefaultAssetPickerProvider(
        maxAssets: 5,
        pageSize: 90,
        requestType: RequestType.image,
      );
      final delegate = SnapsInstaAssetPickerBuilderDelegate(
        provider: provider,
        initialPermission: PermissionState.authorized,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => delegate.backButton(context),
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      delegate.dispose();
    });

    testWidgets('bottomActionBar returns SizedBox.shrink', (WidgetTester tester) async {
      final provider = DefaultAssetPickerProvider(
        maxAssets: 5,
        pageSize: 90,
        requestType: RequestType.image,
      );
      final delegate = SnapsInstaAssetPickerBuilderDelegate(
        provider: provider,
        initialPermission: PermissionState.authorized,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => delegate.bottomActionBar(context),
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      delegate.dispose();
    });
    test('SnapsAssetPickerBuilderDelegate is a subtype of SnapsInstaAssetPickerBuilderDelegate', () {
      final provider = DefaultAssetPickerProvider(
        maxAssets: 5,
        pageSize: 90,
        requestType: RequestType.image,
      );
      final delegate = SnapsAssetPickerBuilderDelegate(
        provider: provider,
        initialPermission: PermissionState.authorized,
      );

      expect(delegate, isA<SnapsInstaAssetPickerBuilderDelegate>());
      expect(delegate.gridCount, 3);
      expect(delegate.previewAsset.value, isNull);
      expect(delegate.isMultiSelect.value, isTrue);
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
