import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapan_market/core/services/media_upload_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Interactive Modern Media Attachment Sheet
/// Sliced from modern camera & media drawer reference
///
/// Features:
/// - Rounded glassmorphism bottom sheet container (28px radius)
/// - Contextual instruction hint banner
/// - Trio Action Dock:
///   1. Gallery Shortcut (Left rounded square button)
///   2. Double-Ring Shutter Button (Center primary action with haptic impact)
///   3. Multi-Photo Picker (Right rounded square button for batch selection)
class MediaAttachmentBottomSheet extends StatefulWidget {
  final int maxImages;

  const MediaAttachmentBottomSheet({super.key, this.maxImages = 3});

  /// Opens the interactive media sheet and returns selected [XFile] list or null
  static Future<List<XFile>?> show(BuildContext context, {int maxImages = 3}) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet<List<XFile>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => MediaAttachmentBottomSheet(maxImages: maxImages),
    );
  }

  @override
  State<MediaAttachmentBottomSheet> createState() => _MediaAttachmentBottomSheetState();
}

class _MediaAttachmentBottomSheetState extends State<MediaAttachmentBottomSheet> {
  bool _isShutterPressed = false;
  bool _isPicking = false;

  Future<void> _handlePickFromGallery() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    HapticFeedback.selectionClick();

    try {
      final file = await MediaUploadService.instance.pickSingleImage(
        source: ImageSource.gallery,
      );
      if (mounted && file != null) {
        Navigator.of(context).pop([file]);
      } else if (mounted) {
        setState(() => _isPicking = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _handleCaptureFromCamera() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    HapticFeedback.heavyImpact();

    try {
      final file = await MediaUploadService.instance.pickSingleImage(
        source: ImageSource.camera,
      );
      if (mounted && file != null) {
        Navigator.of(context).pop([file]);
      } else if (mounted) {
        setState(() => _isPicking = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _handlePickMultiImages() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    HapticFeedback.selectionClick();

    try {
      final files = await MediaUploadService.instance.pickMultiImages(
        limit: widget.maxImages,
      );
      if (mounted && files.isNotEmpty) {
        Navigator.of(context).pop(files);
      } else if (mounted) {
        setState(() => _isPicking = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final sheetBg = isDark
        ? AppColors.darkSurfaceElevated.withValues(alpha: 0.96)
        : Colors.white.withValues(alpha: 0.96);

    final borderColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.8)
        : const Color(0xFFE2E8F0);

    final textMuted = isDark
        ? AppColors.darkTextSecondary
        : const Color(0xFF64748B);

    final iconBg = isDark
        ? AppColors.darkSurface
        : const Color(0xFFF1F5F9);

    final iconBorder = isDark
        ? AppColors.darkBorder
        : const Color(0xFFE2E8F0);

    final activeInk = isDark ? Colors.white : AppColors.ink;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 24.0,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.0, 12.0, 20.0, bottomPadding > 0 ? bottomPadding + 8.0 : 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. DRAG HANDLE PILL
              Container(
                width: 38.0,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),

              const SizedBox(height: 18.0),

              // 2. INSTRUCTION HINT BANNER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.camera_fill,
                      size: 14.0,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7.0),
                    Text(
                      'Tap rana untuk foto, atau pilih dari galeri',
                      style: TextStyle(
                        fontFamily: 'SFPro',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28.0),

              // 3. ACTION TRIO DOCK (1:1 styling referensi visual)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ACTION KIRI: SHORTCUT GALERI
                  _buildSideAction(
                    icon: CupertinoIcons.photo_on_rectangle,
                    label: 'Galeri',
                    bg: iconBg,
                    border: iconBorder,
                    ink: activeInk,
                    textMuted: textMuted,
                    onTap: _handlePickFromGallery,
                  ),

                  // ACTION TENGAH: DOUBLE-RING SHUTTER BUTTON
                  GestureDetector(
                    onTapDown: (_) => setState(() => _isShutterPressed = true),
                    onTapUp: (_) => setState(() => _isShutterPressed = false),
                    onTapCancel: () => setState(() => _isShutterPressed = false),
                    onTap: _handleCaptureFromCamera,
                    child: AnimatedScale(
                      scale: _isShutterPressed ? 0.92 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        width: 76.0,
                        height: 76.0,
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white : AppColors.ink,
                            width: 3.5,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white : AppColors.ink,
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? Colors.white : AppColors.ink).withValues(alpha: 0.25),
                                blurRadius: 10.0,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              CupertinoIcons.camera,
                              color: isDark ? AppColors.ink : Colors.white,
                              size: 28.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ACTION KANAN: BATCH MULTI-PHOTO
                  _buildSideAction(
                    icon: CupertinoIcons.square_stack_3d_down_right,
                    label: 'Multi Foto',
                    bg: iconBg,
                    border: iconBorder,
                    ink: activeInk,
                    textMuted: textMuted,
                    onTap: _handlePickMultiImages,
                  ),
                ],
              ),

              const SizedBox(height: 14.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideAction({
    required IconData icon,
    required String label,
    required Color bg,
    required Color border,
    required Color ink,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52.0,
            height: 52.0,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18.0),
              border: Border.all(color: border, width: 1.0),
            ),
            child: Center(
              child: Icon(
                icon,
                color: ink,
                size: 23.0,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SFPro',
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
