import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapan_market/core/services/media_upload_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Interactive Modern Live Camera & Media Attachment Sheet
/// 1:1 Sliced from live camera drawer reference
///
/// Features:
/// - Full-bleed live camera viewfinder streaming real-time hardware sensor
/// - Automatic aspect ratio fill with top 28px rounded corners
/// - Contextual instruction hint banner overlay
/// - Trio Action Dock overlay:
///   1. Gallery Shortcut (Left frosted glass button)
///   2. Double-Ring Shutter Button (Center primary action with tactile haptic)
///   3. Flip Lens Button (Right frosted glass button to switch front/rear cameras)
/// - Flash mode toggle overlay (Auto / On / Off)
/// - Robust lifecycle management & clean sensor release on dispose
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
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => MediaAttachmentBottomSheet(maxImages: maxImages),
    );
  }

  @override
  State<MediaAttachmentBottomSheet> createState() => _MediaAttachmentBottomSheetState();
}

class _MediaAttachmentBottomSheetState extends State<MediaAttachmentBottomSheet>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _hasCameraPermission = true;
  bool _isShutterPressed = false;
  bool _isCapturing = false;
  bool _isPickingGallery = false;
  FlashMode _flashMode = FlashMode.auto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      controller.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initializeCamera([int cameraIndex = 0]) async {
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _hasCameraPermission = false);
        return;
      }

      final targetCamera = _cameras[cameraIndex.clamp(0, _cameras.length - 1)];
      await _cameraController?.dispose();

      final controller = CameraController(
        targetCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _cameraController = controller;
      await controller.initialize();
      if (controller.value.isInitialized) {
        try {
          await controller.setFlashMode(_flashMode);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _selectedCameraIndex = cameraIndex;
          _isCameraInitialized = true;
          _hasCameraPermission = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _hasCameraPermission = false;
        });
      }
    }
  }

  Future<void> _handleCaptureFromCamera() async {
    if (_isCapturing || _isPickingGallery) return;
    HapticFeedback.heavyImpact();

    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      setState(() => _isCapturing = true);
      try {
        final XFile photo = await controller.takePicture();
        if (mounted) {
          Navigator.of(context).pop([photo]);
        }
      } catch (e) {
        debugPrint('Capture error: $e');
        if (mounted) setState(() => _isCapturing = false);
      }
    } else {
      // Graceful fallback to native camera intent if live viewfinder is unavailable
      final fallback = await MediaUploadService.instance.pickSingleImage(
        source: ImageSource.camera,
      );
      if (mounted && fallback != null) {
        Navigator.of(context).pop([fallback]);
      }
    }
  }

  Future<void> _handleFlipCamera() async {
    if (_cameras.length < 2 || _isCapturing) return;
    HapticFeedback.selectionClick();
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initializeCamera(nextIndex);
  }

  Future<void> _handleToggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    HapticFeedback.selectionClick();

    FlashMode next;
    if (_flashMode == FlashMode.auto) {
      next = FlashMode.always;
    } else if (_flashMode == FlashMode.always) {
      next = FlashMode.off;
    } else {
      next = FlashMode.auto;
    }

    try {
      await controller.setFlashMode(next);
      if (mounted) setState(() => _flashMode = next);
    } catch (_) {}
  }

  Future<void> _handlePickFromGallery() async {
    if (_isPickingGallery || _isCapturing) return;
    setState(() => _isPickingGallery = true);
    HapticFeedback.selectionClick();

    try {
      final file = await MediaUploadService.instance.pickSingleImage(
        source: ImageSource.gallery,
      );
      if (mounted && file != null) {
        Navigator.of(context).pop([file]);
      } else if (mounted) {
        setState(() => _isPickingGallery = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isPickingGallery = false);
    }
  }

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.always:
      case FlashMode.torch:
        return CupertinoIcons.bolt_fill;
      case FlashMode.off:
        return CupertinoIcons.bolt_slash_fill;
      case FlashMode.auto:
        return CupertinoIcons.bolt_badge_a;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    // Viewfinder occupies ~62% of screen height
    final sheetHeight = screenHeight * 0.62;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28.0,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ===============================================================
            // 1. LIVE CAMERA VIEWFINDER STREAM
            // ===============================================================
            _buildLiveViewfinder(),

            // ===============================================================
            // 2. SHUTTER FLASH ANIMATION OVERLAY
            // ===============================================================
            if (_isCapturing)
              AnimatedOpacity(
                opacity: _isCapturing ? 0.75 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: Container(color: Colors.black),
              ),

            // ===============================================================
            // 3. TOP GRADIENT SHADE & CONTROLS
            // ===============================================================
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 36.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // DRAG HANDLE PILL
                    Container(
                      width: 38.0,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),

                    const SizedBox(height: 14.0),

                    // HEADER ROW: INSTRUCTION HINT + FLASH TOGGLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 38.0), // Balance spacer

                        // INSTRUCTION HINT PILL
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7.0,
                                    height: 7.0,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444), // Live camera red dot
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Text(
                                    'Tap rana untuk ambil foto',
                                    style: TextStyle(
                                      fontFamily: 'SFPro',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // FLASH MODE BUTTON
                        GestureDetector(
                          onTap: _handleToggleFlash,
                          child: Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.35),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 0.8,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                _flashIcon,
                                color: _flashMode == FlashMode.off
                                    ? Colors.white.withValues(alpha: 0.6)
                                    : const Color(0xFFFACC15),
                                size: 18.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===============================================================
            // 4. BOTTOM GRADIENT SHADE & TRIO ACTION DOCK
            // ===============================================================
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  24.0,
                  36.0,
                  24.0,
                  bottomPadding > 0 ? bottomPadding + 12.0 : 24.0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ACTION KIRI: SHORTCUT GALERI
                    _buildFloatingSideButton(
                      icon: CupertinoIcons.photo_on_rectangle,
                      label: 'Galeri',
                      onTap: _handlePickFromGallery,
                    ),

                    // ACTION TENGAH: DOUBLE-RING SHUTTER CAPTURE BUTTON
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isShutterPressed = true),
                      onTapUp: (_) => setState(() => _isShutterPressed = false),
                      onTapCancel: () => setState(() => _isShutterPressed = false),
                      onTap: _handleCaptureFromCamera,
                      child: AnimatedScale(
                        scale: _isShutterPressed ? 0.92 : 1.0,
                        duration: const Duration(milliseconds: 90),
                        curve: Curves.easeOutCubic,
                        child: Container(
                          width: 78.0,
                          height: 78.0,
                          padding: const EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 16.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Center(
                              child: _isCapturing
                                  ? const SizedBox(
                                      width: 24.0,
                                      height: 24.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : const Icon(
                                      CupertinoIcons.camera,
                                      color: Colors.black,
                                      size: 30.0,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ACTION KANAN: FLIP CAMERA (DEPAN / BELAKANG)
                    _buildFloatingSideButton(
                      icon: CupertinoIcons.camera_rotate,
                      label: 'Putar',
                      onTap: _handleFlipCamera,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveViewfinder() {
    final controller = _cameraController;

    if (_isCameraInitialized && controller != null && controller.value.isInitialized) {
      final previewSize = controller.value.previewSize;
      if (previewSize != null) {
        // In portrait mode, camera preview dimensions are inverted (width <-> height)
        return ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewSize.height,
                height: previewSize.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      }
      return CameraPreview(controller);
    }

    if (!_hasCameraPermission) {
      return Container(
        color: const Color(0xFF0F172A),
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.camera,
                color: Colors.white.withValues(alpha: 0.5),
                size: 54.0,
              ),
              const SizedBox(height: 14.0),
              const Text(
                'Izin kamera belum aktif',
                style: TextStyle(
                  fontFamily: 'SFPro',
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'Gunakan galeri untuk memilih foto perangkat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SFPro',
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(height: 18.0),
              GestureDetector(
                onTap: _handlePickFromGallery,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: const Text(
                    'Buka Galeri Foto',
                    style: TextStyle(
                      fontFamily: 'SFPro',
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loading Shimmer Placeholder
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28.0,
              height: 28.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              'Menghubungkan kamera...',
              style: TextStyle(
                fontFamily: 'SFPro',
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                width: 52.0,
                height: 52.0,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'SFPro',
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.2,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
