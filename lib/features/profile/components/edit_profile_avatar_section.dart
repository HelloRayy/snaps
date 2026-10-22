import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapan_market/core/components/mascot_flair_badge.dart';
import 'package:snapan_market/core/components/mascot_bundle_picker_button.dart';
import 'package:snapan_market/core/components/mascot_gallery_bottom_sheet.dart';
import 'package:snapan_market/core/models/mascot_flair_model.dart';
import 'package:snapan_market/core/services/media_cropper_service.dart';
import 'package:snapan_market/core/services/media_upload_service.dart';
import 'package:snapan_market/core/services/snaps_asset_picker.dart';
import 'package:snapan_market/core/services/supabase_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/ui/oreo_avatar_helper.dart';

/// Top section of Edit Profile with Name input, Circular Avatar with '+' badge,
/// and Mascot bundle & emotion picker (SNAPS-13) replacing rigid presets for beta pilot.
class EditProfileAvatarSection extends StatefulWidget {
  final TextEditingController nameController;
  final String currentAvatar;
  final ValueChanged<String> onAvatarChanged;
  final MascotFlairModel? currentMascotFlair;
  final ValueChanged<MascotFlairModel?> onMascotFlairChanged;
  final bool canUseMascot;

  const EditProfileAvatarSection({
    super.key,
    required this.nameController,
    required this.currentAvatar,
    required this.onAvatarChanged,
    this.currentMascotFlair,
    required this.onMascotFlairChanged,
    this.canUseMascot = true,
  });

  @override
  State<EditProfileAvatarSection> createState() => _EditProfileAvatarSectionState();
}

class _EditProfileAvatarSectionState extends State<EditProfileAvatarSection> {
  bool _isUploadingAvatar = false;

  Future<void> _handlePickAvatar() async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurfaceElevated : Colors.white;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.ink;
    final itemTitleColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final itemSubColor = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);
    final handleColor = isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1);

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ganti Foto Profil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Buka Galeri HP', style: TextStyle(fontWeight: FontWeight.w600, color: itemTitleColor)),
                subtitle: Text('Pilih foto profil dari galeri (Kompres 1080p)', style: TextStyle(color: itemSubColor)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text('Ambil Foto Kamera', style: TextStyle(fontWeight: FontWeight.w600, color: itemTitleColor)),
                subtitle: Text('Ambil selfie atau foto baru langsung', style: TextStyle(color: itemSubColor)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    XFile? picked;
    if (source == ImageSource.gallery) {
      final assets = await SnapsAssetPicker.pickImages(context, maxImages: 1);
      if (assets != null && assets.isNotEmpty) {
        picked = assets.first;
      }
    } else {
      picked = await MediaUploadService.instance.pickSingleImage(source: source);
    }
    if (picked == null || !mounted) return;

    // 1. In-App Pure Flutter Image Crop Modal (Pan, Pinch-to-Zoom, 1:1 Circle Mask)
    final cropped = await MediaCropperService.instance.cropAvatar(
      picked.path,
      context: context,
    );
    if (cropped == null || !mounted) return; // User cancelled cropping

    setState(() => _isUploadingAvatar = true);

    try {
      final bytes = await cropped.readAsBytes();
      final uploadedUrl = await SupabaseService.instance.uploadImage(
        bytes: bytes,
        fileName: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        bucket: 'avatars',
      );

      if (mounted) {
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          widget.onAvatarChanged(uploadedUrl);
        } else {
          // Fallback to local path if storage upload is not available
          widget.onAvatarChanged(cropped.path);
        }
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (mounted) {
        widget.onAvatarChanged(cropped.path);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8);
    final avatarBg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9);
    final badgeBorderColor = isDark ? AppColors.darkSurface : Colors.white;
    final dividerColor = AppColors.adaptiveDivider(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Nama Input (Left) & Avatar with '+' badge (Right)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Nama Form Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Name',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                        color: primaryTextColor,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    TextField(
                      controller: widget.nameController,
                      maxLength: 50,
                      style: TextStyle(
                        fontFamily: 'SFPro',
                        fontSize: 15.5,
                        fontWeight: FontWeight.normal,
                        color: primaryTextColor,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nama tampilan kamu',
                        hintStyle: TextStyle(
                          fontFamily: 'SFPro',
                          fontSize: 15.5,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14.0),

              // Right: Avatar with '+' badge (Clickable to change photo)
              GestureDetector(
                onTap: _handlePickAvatar,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 52.0,
                      height: 52.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: avatarBg,
                      ),
                      child: ClipOval(
                        child: _isUploadingAvatar
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : AppAvatar(
                                avatarUrl: widget.currentAvatar,
                                size: 52.0,
                              ),
                      ),
                    ),

                    // Black '+' badge on bottom right (borderless cutout, no shadow)
                    Positioned(
                      bottom: -2.0,
                      right: -2.0,
                      child: Container(
                        width: 20.0,
                        height: 20.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF101010),
                          border: Border.all(
                            color: badgeBorderColor,
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_rounded,
                            size: 13.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1.0, thickness: 0.8, color: dividerColor),

        if (widget.canUseMascot) ...[
          _buildMascotSection(),
          Divider(height: 1.0, thickness: 0.8, color: dividerColor),
        ],
      ],
    );
  }

  Widget _buildMascotSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBundle = widget.currentMascotFlair?.bundle ?? MascotBundle.koala;
    final curatedEmotions = [
      MascotEmotion.delighted, // Happy 😊
      MascotEmotion.heart,     // Love 😍
      MascotEmotion.sparkle,   // Sparkle ✨
      MascotEmotion.wink,      // Wink 😉
      MascotEmotion.surprised, // Surprised 😲
      MascotEmotion.sleepy,    // Sleepy 😴
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Pilihan Maskot Bundle',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A),
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimaryPastel : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: const Text(
                      'BARU',
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      MascotGalleryBottomSheet.show(
                        context,
                        selectedBundle: activeBundle,
                        onSelected: (bundle) {
                          widget.onMascotFlairChanged(
                            MascotFlairModel(
                              bundle: bundle,
                              emotion: widget.currentMascotFlair?.emotion ?? MascotEmotion.delighted,
                            ),
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Lihat Semua (21)',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.currentMascotFlair != null) ...[
                    const SizedBox(width: 12.0),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        widget.onMascotFlairChanged(null);
                      },
                      child: const Text(
                        'Hapus',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Mascot Bundle Picker Button (Directly opens bottom sheet catalog)
          MascotBundlePickerButton(
            selectedBundle: activeBundle,
            compact: false,
            onBundleSelected: (bundle) {
              widget.onMascotFlairChanged(
                MascotFlairModel(
                  bundle: bundle,
                  emotion: widget.currentMascotFlair?.emotion ?? MascotEmotion.delighted,
                ),
              );
            },
            onOpenGallery: () {
              MascotGalleryBottomSheet.show(
                context,
                selectedBundle: activeBundle,
                onSelected: (bundle) {
                  widget.onMascotFlairChanged(
                    MascotFlairModel(
                      bundle: bundle,
                      emotion: widget.currentMascotFlair?.emotion ?? MascotEmotion.delighted,
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 12.0),

          // Responsive Curated 3x2 Emotions Grid (Pure white cards with large touch targets)
          Center(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: curatedEmotions.map((emotion) {
                final isEmotionSelected = widget.currentMascotFlair != null &&
                    widget.currentMascotFlair!.bundle == activeBundle &&
                    widget.currentMascotFlair!.emotion == emotion;
                final itemFlair = MascotFlairModel(bundle: activeBundle, emotion: emotion);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onMascotFlairChanged(itemFlair);
                    },
                    borderRadius: BorderRadius.circular(12.0),
                    splashColor: AppColors.primary.withValues(alpha: 0.12),
                    highlightColor: AppColors.primary.withValues(alpha: 0.06),
                    child: Container(
                      width: 84.0,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isEmotionSelected
                            ? (isDark ? AppColors.darkPrimaryPastel : const Color(0xFFEFF6FF))
                            : (isDark ? AppColors.darkSurface : Colors.white),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isEmotionSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                          width: isEmotionSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 4.0,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MascotFlairBadge(
                            flair: itemFlair,
                            size: 34.0,
                            enableGradientFade: false,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            emotion.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: isEmotionSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isEmotionSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkTextSecondary : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

}
