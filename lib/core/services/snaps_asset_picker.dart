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

/// Custom builder delegate with Snaps Light Theme:
/// - 3-column larger picture grid (Threads/Instagram style)
/// - WCAG compliant primary color (#3D38F5)
/// - White checkmark indicator
/// - Rounded pill confirm button with radius and white text
class SnapsAssetPickerBuilderDelegate extends DefaultAssetPickerBuilderDelegate {
  SnapsAssetPickerBuilderDelegate({
    required super.provider,
    required super.initialPermission,
    super.gridCount = 3,
    super.pickerTheme,
    super.specialItems,
    super.textDelegate,
    super.themeColor,
  });

  @override
  Widget confirmButton(BuildContext context) {
    return Consumer<DefaultAssetPickerProvider>(
      builder: (context, p, child) {
        final bool isSelectedNotEmpty = p.isSelectedNotEmpty;
        final bool shouldAllowConfirm =
            isSelectedNotEmpty || p.previousSelectedAssets.isNotEmpty;

        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 14.0),
          child: MaterialButton(
            minWidth: 0,
            height: 32.0,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            color: AppColors.primary,
            disabledColor: const Color(0xFFE2E8F0),
            elevation: 0,
            highlightElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            onPressed: shouldAllowConfirm
                ? () {
                    Navigator.maybeOf(context)?.maybePop(p.selectedAssets);
                  }
                : null,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            child: Text(
              isSelectedNotEmpty && !isSingleAssetMode
                  ? '${textDelegate.confirm} (${p.selectedAssets.length}/${p.maxAssets})'
                  : textDelegate.confirm,
              style: TextStyle(
                fontFamily: 'SFPro',
                color: shouldAllowConfirm ? Colors.white : AppColors.muted,
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget selectIndicator(BuildContext context, int index, AssetEntity asset) {
    final Duration duration = switchingPathDuration * 0.75;
    return Selector<DefaultAssetPickerProvider, String>(
      selector: (_, DefaultAssetPickerProvider p) => p.selectedDescriptions,
      builder: (context, descriptions, child) {
        final bool selected = descriptions.contains(asset.toString());
        final int selectIndex = provider.selectedAssets.indexOf(asset);

        final Widget innerSelector = AnimatedContainer(
          duration: duration,
          width: 26.0,
          height: 26.0,
          decoration: BoxDecoration(
            border: !selected
                ? Border.all(
                    color: Colors.white,
                    width: 2.0,
                  )
                : null,
            color: selected ? AppColors.primary : const Color(0x33000000),
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
            child: selected
                ? (!isSingleAssetMode && selectIndex != -1
                    ? Text(
                        '${selectIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      )
                    : const Icon(
                        Icons.check,
                        size: 16.0,
                        color: Colors.white,
                      ))
                : const SizedBox.shrink(),
          ),
        );

        final Widget selectorWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            selectAsset(context, asset, index, selected);
          },
          child: Container(
            margin: const EdgeInsets.all(6.0),
            alignment: AlignmentDirectional.topEnd,
            child: innerSelector,
          ),
        );

        if (isPreviewEnabled) {
          return PositionedDirectional(
            top: 0,
            end: 0,
            child: selectorWidget,
          );
        }
        return selectorWidget;
      },
    );
  }

  @override
  Widget selectedBackdrop(BuildContext context, int index, AssetEntity asset) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: isPreviewEnabled
            ? () {
                viewAsset(context, index, asset);
              }
            : null,
        child: Consumer<DefaultAssetPickerProvider>(
          builder: (context, p, child) {
            final int selectIndex = p.selectedAssets.indexOf(asset);
            final bool selected = selectIndex != -1;
            return AnimatedContainer(
              duration: switchingPathDuration,
              decoration: BoxDecoration(
                border: selected
                    ? Border.all(color: AppColors.primary, width: 2.5)
                    : null,
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Service wrapper for in-app media picker styled with Snaps light theme.
class SnapsAssetPicker {
  SnapsAssetPicker._();

  /// Picks images using in-app grid asset picker with camera prepend tile.
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

    final delegate = SnapsAssetPickerBuilderDelegate(
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
                HapticFeedback.lightImpact();
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
            DefaultAssetPickerProvider, SnapsAssetPickerBuilderDelegate>(
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
