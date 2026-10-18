import 'dart:io';
import 'package:flutter/material.dart';
import 'package:snapan_market/core/services/snaps_asset_picker.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
class CreatePostImageHelper {
  static Future<List<String>?> pickImages(BuildContext context, {required int remaining}) async {
    final pickedFiles = await SnapsAssetPicker.pickImages(context, maxImages: remaining);
    if (pickedFiles == null || pickedFiles.isEmpty) return null;
    return pickedFiles.map((f) => f.path).toList();
  }

  static Future<List<String>> uploadAllImages(
    List<String> images, {
    void Function(int completed, int total, double progress)? onProgress,
  }) async {
    if (images.isEmpty) return [];

    final total = images.length;
    int completed = 0;
    onProgress?.call(0, total, 0.0);

    final futures = images.map((img) async {
      if (img.startsWith('http://') || img.startsWith('https://')) {
        completed++;
        onProgress?.call(completed, total, completed / total);
        return img;
      }
      try {
        final file = File(img);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final fileName = img.split(Platform.pathSeparator).last;
          final uploadedUrl = await SupabaseService.instance.uploadImage(
            bytes: bytes,
            fileName: fileName,
            bucket: 'market-media',
          );
          completed++;
          onProgress?.call(completed, total, completed / total);
          return uploadedUrl ?? img;
        }
      } catch (e) {
        debugPrint('Error uploading image $img: $e');
      }
      completed++;
      onProgress?.call(completed, total, completed / total);
      return img;
    }).toList();

    return await Future.wait(futures);
  }
}
