import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.white,
      ),
    );

    final List<AssetEntity>? result = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: maxImages,
        requestType: RequestType.image,
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
      ),
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
                  size: 28.0,
                  color: AppColors.primary,
                ),
                SizedBox(height: 6.0),
                Text(
                  'Kamera',
                  style: TextStyle(
                    fontFamily: 'SFPro',
                    fontSize: 12.0,
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
