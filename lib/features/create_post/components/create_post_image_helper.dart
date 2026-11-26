import 'dart:io';
import 'package:flutter/material.dart';
import 'package:snapan_market/core/services/snaps_asset_picker.dart';
import 'package:snapan_market/core/services/supabase_service.dart';

class UploadImagesResult {
  final List<String> resolvedItems;
  final int failedCount;

  const UploadImagesResult({
    required this.resolvedItems,
    required this.failedCount,
  });

  bool get hasFailures => failedCount > 0;
  List<String> get uploadedUrls => resolvedItems
      .where((u) => u.startsWith('http://') || u.startsWith('https://'))
      .toList();
}

class CreatePostImageHelper {
  static Future<List<String>?> pickImages(BuildContext context, {required int remaining}) async {
    final pickedFiles = await SnapsAssetPicker.pickImages(context, maxImages: remaining);
    if (pickedFiles == null || pickedFiles.isEmpty) return null;
    return pickedFiles.map((f) => f.path).toList();
  }

  static Future<UploadImagesResult> uploadAllImages(
    List<String> images, {
    void Function(int completed, int total, double progress)? onProgress,
    int maxRetries = 2,
  }) async {
    if (images.isEmpty) {
      return const UploadImagesResult(resolvedItems: [], failedCount: 0);
    }

    final total = images.length;
    int completed = 0;
    int failedCount = 0;
    onProgress?.call(0, total, 0.0);

    final futures = images.map((img) async {
      if (img.startsWith('http://') || img.startsWith('https://')) {
        completed++;
        onProgress?.call(completed, total, completed / total);
        return img;
      }

      String? uploadedUrl;
      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          final file = File(img);
          if (!await file.exists()) break;
          final bytes = await file.readAsBytes();
          final fileName = img.split(Platform.pathSeparator).last;
          uploadedUrl = await SupabaseService.instance.uploadImage(
            bytes: bytes,
            fileName: fileName,
            bucket: 'market-media',
          );
          if (uploadedUrl != null &&
              (uploadedUrl.startsWith('http://') || uploadedUrl.startsWith('https://'))) {
            break;
          }
        } catch (e) {
          debugPrint('Error uploading image $img (attempt ${attempt + 1}): $e');
        }
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: 600 * (attempt + 1)));
        }
      }

      completed++;
      onProgress?.call(completed, total, completed / total);

      if (uploadedUrl != null &&
          (uploadedUrl.startsWith('http://') || uploadedUrl.startsWith('https://'))) {
        return uploadedUrl;
      }

      failedCount++;
      // Keep local path in UI state only for retry; never submit this to DB.
      return img;
    }).toList();

    final resolved = await Future.wait(futures);
    return UploadImagesResult(resolvedItems: resolved, failedCount: failedCount);
  }
}
