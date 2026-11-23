import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:snapan_market/core/services/media_upload_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Indonesian localization delegate for WeChat Asset Picker
class SnapsAssetPickerTextDelegate extends EnglishAssetPickerTextDelegate {
  const SnapsAssetPickerTextDelegate();

  @override
  String get confirm => 'Selesai';

  @override
  String get cancel => 'Batal';

  @override
  String get edit => 'Edit';

  @override
  String get gifIndicator => 'GIF';

  @override
  String get loadFailed => 'Gagal memuat';

  @override
  String get original => 'Ukuran Asli';

  @override
  String get preview => 'Pratinjau';

  @override
  String get select => 'Pilih';

  @override
  String get emptyList => 'Belum ada foto';

  @override
  String get unableToAccessAll => 'Tidak dapat mengakses semua foto di perangkat';

  @override
  String get viewingLimitedAssetsTip => 'Hanya menampilkan foto yang diizinkan untuk aplikasi.';

  @override
  String get changeAccessibleLimitedAssets => 'Ketuk untuk memperbarui izin foto';

  @override
  String get accessAllTip =>
      'Snaps hanya dapat mengakses sebagian foto. Buka Pengaturan untuk mengizinkan akses ke semua foto.';

  @override
  String get goToSystemSettings => 'Buka Pengaturan HP';

  @override
  String get accessLimitedAssets => 'Lanjutkan dengan akses terbatas';
}

/// Snaps Media Picker Delegate:
/// - Full 3-column photo grid layout (no hero preview clutter)
/// - Multiple pictures selection enabled by default
/// - Header text-only blue "Selesai" button (#3D38F5)
/// - Smooth fullscreen preview on long press with dark backdrop and 1080p preview cache
class SnapsInstaAssetPickerBuilderDelegate
    extends DefaultAssetPickerBuilderDelegate {
  SnapsInstaAssetPickerBuilderDelegate({
    required super.provider,
    required super.initialPermission,
    super.gridCount = 3,
    super.pickerTheme,
    super.specialItems,
    super.textDelegate,
    super.themeColor,
    super.locale,
    super.keepScrollOffset,
    super.previewThumbnailSize = const ThumbnailSize(1080, 1920),
  }) : super(
          shouldRevertGrid: false,
        );

  /// Retained for backward-compatibility.
  final ValueNotifier<AssetEntity?> previewAsset =
      ValueNotifier<AssetEntity?>(null);

  /// Retained for backward-compatibility.
  final ValueNotifier<double> viewerPosition = ValueNotifier<double>(0.0);

  /// Multi-selection mode active by default (supports multiple pictures).
  final ValueNotifier<bool> isMultiSelect = ValueNotifier<bool>(true);

  @override
  void dispose() {
    if (!keepScrollOffset) {
      previewAsset.dispose();
      viewerPosition.dispose();
      isMultiSelect.dispose();
    }
    super.dispose();
  }

  /// Responsive height of the Hero Viewport (width or max 45% of screen height).
  double previewHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double target = size.width;
    final double maxHeight = size.height * 0.45;
    return min(target, maxHeight);
  }

  /// Retained for backward-compatibility.
  Widget buildEntityViewer(BuildContext context) => const SizedBox.shrink();

  @override
  AssetPickerAppBar appBar(BuildContext context) {
    final AssetPickerAppBar bar = AssetPickerAppBar(
      leading: backButton(context),
      title: Semantics(
        onTapHint: semanticsTextDelegate.sActionSwitchPathLabel,
        child: pathEntitySelector(context),
      ),
      actions: <Widget>[confirmButton(context)],
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
    );
    appBarPreferredSize ??= bar.preferredSize;
    return bar;
  }

  @override
  Widget androidLayout(BuildContext context) {
    return AssetPickerAppBarWrapper(
      appBar: appBar(context),
      body: Consumer<DefaultAssetPickerProvider>(
        builder: (context, p, _) {
          final bool shouldDisplayAssets = p.hasAssetsToDisplay ||
              assetsGridSpecialItemsFinalized(
                context: context,
                path: p.currentPath?.path,
              ).isNotEmpty;

          return AnimatedSwitcher(
            duration: switchingPathDuration,
            child: shouldDisplayAssets
                ? Stack(
                    children: <Widget>[
                      RepaintBoundary(
                        child: Column(
                          children: <Widget>[
                            Expanded(child: assetsGridBuilder(context)),
                            bottomActionBar(context),
                          ],
                        ),
                      ),
                      pathEntityListBackdrop(context),
                      pathEntityListWidget(context),
                    ],
                  )
                : loadingIndicator(context),
          );
        },
      ),
    );
  }

  @override
  Widget appleOSLayout(BuildContext context) => androidLayout(context);

  @override
  Widget backButton(BuildContext context) {
    return IconButton(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      icon: const Icon(
        CupertinoIcons.xmark,
        size: 22.0,
        color: AppColors.ink,
      ),
      onPressed: () {
        Navigator.maybeOf(context)?.maybePop();
      },
    );
  }

  /// Clean text-only "Selesai" button in AppColors.primary (#3D38F5), without pill background.
  @override
  Widget confirmButton(BuildContext context) {
    return Consumer<DefaultAssetPickerProvider>(
      builder: (context, p, child) {
        final bool isSelectedNotEmpty = p.isSelectedNotEmpty;
        final bool shouldAllowConfirm =
            isSelectedNotEmpty || p.previousSelectedAssets.isNotEmpty;

        return ValueListenableBuilder<bool>(
          valueListenable: isMultiSelect,
          builder: (context, multi, _) {
            final String label;
            if (multi && p.selectedAssets.length > 1) {
              label = '${textDelegate.confirm} (${p.selectedAssets.length})';
            } else {
              label = textDelegate.confirm;
            }

            return TextButton(
              onPressed: shouldAllowConfirm
                  ? () {
                      Navigator.maybeOf(context)?.maybePop(p.selectedAssets);
                    }
                  : null,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                splashFactory: NoSplash.splashFactory,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'SFPro',
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: shouldAllowConfirm
                      ? AppColors.primary
                      : const Color(0xFF94A3B8),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget bottomActionBar(BuildContext context) => const SizedBox.shrink();

  /// Tile backdrop handler:
  /// - Tap: Instantly updates [previewAsset] in the Hero Viewport & selects the asset without opening full-screen view.
  /// - Long-press: Medium haptic feedback & opens full-screen detail preview [viewAsset].
  @override
  Widget selectedBackdrop(BuildContext context, int index, AssetEntity asset) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final bool isSelected = provider.selectedAssets.contains(asset);
          selectAsset(context, asset, index, isSelected);
        },
        onLongPress: () {
          viewAsset(context, index, asset);
        },
        child: Selector<DefaultAssetPickerProvider, String>(
          selector: (_, p) => p.selectedDescriptions,
          builder: (context, descriptions, _) {
            final int selectIndex = provider.selectedAssets.indexOf(asset);
            final bool isSelected = selectIndex != -1;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2.5)
                    : null,
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Fullscreen preview with dark theme and 1080p hardware thumbnail cache to eliminate white space.
  @override
  Future<void> viewAsset(
    BuildContext context,
    int? index,
    AssetEntity currentAsset,
  ) async {
    final p = provider;
    if (!p.selectedAssets.contains(currentAsset) && p.selectedMaximumAssets) {
      return;
    }
    final revert = effectiveShouldRevertGrid(context);
    final List<AssetEntity> current;
    final List<AssetEntity> selected = p.selectedAssets;
    final int effectiveIndex;

    if (index == null) {
      current = revert ? p.selectedAssets.reversed.toList(growable: false) : p.selectedAssets;
      effectiveIndex = max(0, selected.indexOf(currentAsset));
    } else {
      current = p.currentAssets;
      effectiveIndex = revert ? current.length - index - 1 : index;
    }

    if (current.isEmpty) return;

    final ThemeData darkViewerTheme =
        AssetPicker.themeData(AppColors.primary, light: false).copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      canvasColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: Color(0xFF0F172A),
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
    );

    final result = await AssetPickerViewer.pushToViewer<DefaultAssetPickerProvider>(
      context,
      currentIndex: effectiveIndex,
      previewAssets: current,
      themeData: darkViewerTheme,
      previewThumbnailSize: const ThumbnailSize(1080, 1920),
      selectPredicate: selectPredicate,
      selectedAssets: selected,
      selectorProvider: p,
      specialPickerType: specialPickerType,
      maxAssets: p.maxAssets,
      shouldReversePreview: revert,
      shouldAutoplayPreview: shouldAutoplayPreview,
      enableLivePhoto: enableLivePhoto,
      useRootNavigator: viewerUseRootNavigator,
      pageRouteSettings: viewerPageRouteSettings,
      pageRouteBuilder: viewerPageRouteBuilder,
    );
    if (result != null && context.mounted) {
      Navigator.maybeOf(context)?.maybePop(result);
    }
  }

  /// Circular selection indicator on grid tiles:
  /// - Checked badge (#3D38F5 with white check or order number 1, 2, 3) when selected.
  /// - Translucent circle with 2px white border when in multi-select mode.
  @override
  Widget selectIndicator(BuildContext context, int index, AssetEntity asset) {
    final Duration duration = switchingPathDuration * 0.75;

    return Selector<DefaultAssetPickerProvider, String>(
      selector: (_, DefaultAssetPickerProvider p) => p.selectedDescriptions,
      builder: (context, descriptions, _) {
        final bool isSelected = descriptions.contains(asset.toString());
        final int selectIndex = provider.selectedAssets.indexOf(asset);

        final Widget innerSelector = AnimatedContainer(
          duration: duration,
          width: 24.0,
          height: 24.0,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            ),
            color: isSelected ? AppColors.primary : const Color(0x33000000),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 4.0,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: isSelected
                ? (selectIndex != -1
                    ? Text(
                        '${selectIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                        size: 15.0,
                        color: Colors.white,
                      ))
                : const SizedBox.shrink(),
          ),
        );

        return PositionedDirectional(
          top: 6.0,
          end: 6.0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              selectAsset(context, asset, index, isSelected);
            },
            child: innerSelector,
          ),
        );
      },
    );
  }
}

/// Backward-compatible alias for [SnapsInstaAssetPickerBuilderDelegate].
class SnapsAssetPickerBuilderDelegate
    extends SnapsInstaAssetPickerBuilderDelegate {
  SnapsAssetPickerBuilderDelegate({
    required super.provider,
    required super.initialPermission,
    super.gridCount = 3,
    super.pickerTheme,
    super.specialItems,
    super.textDelegate,
    super.themeColor,
    super.locale,
    super.keepScrollOffset,
  });
}

/// Service wrapper for in-app media picker styled with Snaps light theme & Instagram split view.
class SnapsAssetPicker {
  SnapsAssetPicker._();

  /// Picks images using in-app Instagram-style split-view asset picker with camera prepend tile.
  static Future<List<XFile>?> pickImages(
    BuildContext context, {
    int maxImages = 5,
  }) async {
    XFile? cameraCapturedFile;

    final ThemeData lightPickerTheme =
        AssetPicker.themeData(AppColors.primary, light: true).copyWith(
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.white,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.ink,
      ),
    );

    const permissionOption = PermissionRequestOption(
      androidPermission: AndroidPermission(
        type: RequestType.image,
        mediaLocation: false,
      ),
    );

    final PermissionState ps = await AssetPicker.permissionCheck(
      requestOption: permissionOption,
    );

    final DefaultAssetPickerProvider provider = DefaultAssetPickerProvider(
      maxAssets: maxImages,
      pageSize: 90,
      pathThumbnailSize: defaultPathThumbnailSize,
      selectedAssets: null,
      requestType: RequestType.image,
    );

    final delegate = SnapsInstaAssetPickerBuilderDelegate(
      provider: provider,
      initialPermission: ps,
      gridCount: 3,
      pickerTheme: lightPickerTheme,
      textDelegate: const SnapsAssetPickerTextDelegate(),
      specialItems: [
        SpecialItem(
          position: SpecialItemPosition.prepend,
          builder: (
            BuildContext context,
            AssetPathEntity? path,
            PermissionState state,
          ) {
            return _CameraTile(
              onTap: () async {
                final picked = await MediaUploadService.instance.pickSingleImage(
                  source: ImageSource.camera,
                );
                if (picked != null && context.mounted) {
                  cameraCapturedFile = picked;
                  Navigator.of(context).pop();
                }
              },
            );
          },
        ),
      ],
    );

    if (!context.mounted) return null;

    final List<AssetEntity>? result =
        await AssetPicker.pickAssetsWithDelegate<AssetEntity, AssetPathEntity,
            DefaultAssetPickerProvider, SnapsInstaAssetPickerBuilderDelegate>(
      context,
      delegate: delegate,
      permissionRequestOption: permissionOption,
    );

    if (cameraCapturedFile != null) {
      return [cameraCapturedFile!];
    }

    if (result == null || result.isEmpty) {
      return null;
    }

    final List<XFile> xFiles = [];
    for (final entity in result) {
      final file = await entity.file;
      if (file != null) {
        xFiles.add(XFile(file.path));
      }
    }
    return xFiles.isNotEmpty ? xFiles : null;
  }
}

/// Square camera tile prepended at index 0 of asset picker grid
class _CameraTile extends StatelessWidget {
  final VoidCallback onTap;

  const _CameraTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ambil foto dengan kamera',
      child: Material(
        color: const Color(0xFFF1F5F9),
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.camera_fill,
                  size: 32.0,
                  color: AppColors.primary,
                ),
                SizedBox(height: 6.0),
                Text(
                  'Kamera',
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
