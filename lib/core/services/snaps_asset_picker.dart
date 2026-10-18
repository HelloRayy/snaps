import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:snapan_market/core/services/media_upload_service.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

const double _kMiddleBarHeight = 44.0;

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

/// Instagram/Threads-style Split-View Media Picker Delegate:
/// - Hero Viewport 1:1 on the top half with instant tap image swap
/// - Middle Control Bar (44px) with album dropdown & multi-select toggle
/// - 3-column photo grid below with tap-swap and hold-to-preview gestures
/// - Header text-only blue "Selesai" button (#3D38F5)
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
  }) : super(
          shouldRevertGrid: false,
        );

  /// Asset currently being previewed in the upper Hero Viewport.
  final ValueNotifier<AssetEntity?> previewAsset =
      ValueNotifier<AssetEntity?>(null);

  /// Vertical offset of the Hero Viewport (0.0 = fully expanded, negative = collapsed).
  final ValueNotifier<double> viewerPosition = ValueNotifier<double>(0.0);

  /// Toggle for multi-selection mode (like Instagram's layered photos icon).
  final ValueNotifier<bool> isMultiSelect = ValueNotifier<bool>(false);

  /// Track scroll positions for collapse/expand animation.
  double _lastScrollOffset = 0.0;
  double _lastEndScrollOffset = 0.0;

  /// Track active path to reset preview when switching albums.
  PathWrapper<AssetPathEntity>? _lastTrackedPath;

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

  /// Initialize [previewAsset] with the first available asset if not yet set.
  Future<void> _initializePreviewAsset(
    DefaultAssetPickerProvider p,
    bool shouldDisplayAssets,
  ) async {
    if (previewAsset.value != null) {
      return;
    }

    if (p.selectedAssets.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (previewAsset.value == null && p.selectedAssets.isNotEmpty) {
          previewAsset.value = p.selectedAssets.first;
        }
      });
      return;
    }

    if (shouldDisplayAssets) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (previewAsset.value != null) return;
        AssetEntity? firstAsset;
        if (p.currentAssets.isNotEmpty) {
          firstAsset = p.currentAssets.first;
        } else {
          final list =
              await p.currentPath?.path.getAssetListRange(start: 0, end: 1);
          if (list != null && list.isNotEmpty) {
            firstAsset = list.first;
          }
        }
        if (firstAsset != null && previewAsset.value == null) {
          previewAsset.value = firstAsset;
          if (p.selectedAssets.isEmpty) {
            p.selectAsset(firstAsset);
          }
        }
      });
    }
  }

  /// Upper Hero Viewport (1:1 aspect ratio or responsive container) with instant swap & fade transition.
  Widget buildEntityViewer(BuildContext context) {
    final double height = previewHeight(context);
    final double width = MediaQuery.sizeOf(context).width;

    return Container(
      width: width,
      height: height,
      color: const Color(0xFF0F172A),
      child: ValueListenableBuilder<AssetEntity?>(
        valueListenable: previewAsset,
        builder: (context, asset, _) {
          if (asset == null) {
            return Center(
              child: Text(
                textDelegate.emptyList,
                style: const TextStyle(
                  fontFamily: 'SFPro',
                  color: Color(0xFF94A3B8),
                  fontSize: 14.0,
                ),
              ),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: SizedBox.expand(
              key: ValueKey<String>(asset.id),
              child: AssetEntityImage(
                asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(1200),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFF1E293B),
                    child: const Center(
                      child: CupertinoActivityIndicator(
                        color: Colors.white70,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF1E293B),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle,
                            color: Colors.white54,
                            size: 28.0,
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            textDelegate.loadFailed,
                            style: const TextStyle(
                              fontFamily: 'SFPro',
                              color: Colors.white70,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Middle Control Bar (44px): Left album dropdown & Right multi-select toggle button.
  Widget _buildMiddleControlBar(BuildContext context) {
    return Container(
      height: _kMiddleBarHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildAlbumDropdownButton(context),
          _buildMultiSelectToggleButton(context),
        ],
      ),
    );
  }

  Widget _buildAlbumDropdownButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isPermissionLimited && provider.isAssetsEmpty) {
          PhotoManager.presentLimited();
          return;
        }
        if (provider.currentPath == null) {
          return;
        }
        isSwitchingPath.value = !isSwitchingPath.value;
      },
      child: Selector<DefaultAssetPickerProvider, PathWrapper<AssetPathEntity>?>(
        selector: (_, p) => p.currentPath,
        builder: (context, p, _) {
          final AssetPathEntity? path = p?.path;
          final String pathName;
          if (path == null && isPermissionLimited) {
            pathName = textDelegate.changeAccessibleLimitedAssets;
          } else if (path != null) {
            pathName = isPermissionLimited && path.isAll
                ? textDelegate.accessiblePathName
                : pathNameBuilder?.call(path) ?? path.name;
          } else {
            pathName = '';
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(
                child: Text(
                  pathName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'SFPro',
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              ValueListenableBuilder<bool>(
                valueListenable: isSwitchingPath,
                builder: (_, bool switching, _) {
                  return AnimatedRotation(
                    turns: switching ? 0.5 : 0.0,
                    duration: switchingPathDuration,
                    child: const Icon(
                      CupertinoIcons.chevron_down,
                      size: 16.0,
                      color: AppColors.ink,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMultiSelectToggleButton(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isMultiSelect,
      builder: (context, bool isMulti, _) {
        final bool isSelectMultipleActive = isMulti && provider.maxAssets > 1;

        return Semantics(
          button: true,
          label: 'Pilih beberapa foto',
          toggled: isSelectMultipleActive,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20.0),
              onTap: () {
                HapticFeedback.lightImpact();
                if (provider.maxAssets <= 1) return;

                final nextState = !isMultiSelect.value;
                isMultiSelect.value = nextState;

                if (nextState) {
                  if (previewAsset.value != null &&
                      !provider.selectedAssets.contains(previewAsset.value)) {
                    provider.selectAsset(previewAsset.value!);
                  }
                } else {
                  if (provider.selectedAssets.length > 1) {
                    final AssetEntity keep = previewAsset.value != null &&
                            provider.selectedAssets.contains(previewAsset.value)
                        ? previewAsset.value!
                        : provider.selectedAssets.last;
                    provider.selectedAssets.clear();
                    provider.selectAsset(keep);
                    previewAsset.value = keep;
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: isSelectMultipleActive
                      ? AppColors.primary
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.square_on_square,
                      size: 16.0,
                      color: isSelectMultipleActive
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      'PILIH BEBERAPA',
                      style: TextStyle(
                        fontFamily: 'SFPro',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: isSelectMultipleActive
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handles grid scroll notifications to smoothly expand or collapse the Hero Viewport.
  bool _handleScroll(
    BuildContext context,
    ScrollNotification notification,
    double position,
    double reducedPosition,
  ) {
    if (gridScrollController.positions.isEmpty) return false;
    final bool isScrollUp =
        gridScrollController.position.userScrollDirection ==
            ScrollDirection.reverse;
    final bool isScrollDown =
        gridScrollController.position.userScrollDirection ==
            ScrollDirection.forward;

    if (notification is ScrollEndNotification) {
      _lastEndScrollOffset = gridScrollController.offset;
      if (position > reducedPosition && position < 0.0) {
        if (position < reducedPosition / 2) {
          viewerPosition.value = reducedPosition;
        } else {
          viewerPosition.value = 0.0;
        }
        return true;
      }
    }

    if (isScrollDown && gridScrollController.offset <= 0 && position < 0.0) {
      if (_lastScrollOffset > gridScrollController.offset) {
        viewerPosition.value = (viewerPosition.value +
                (_lastScrollOffset.abs() - gridScrollController.offset.abs()) *
                    3)
            .clamp(reducedPosition, 0.0);
      } else {
        viewerPosition.value = 0.0;
      }
    } else if (isScrollUp &&
        gridScrollController.offset > 0 &&
        position > reducedPosition) {
      final double delta =
          (gridScrollController.offset - _lastEndScrollOffset) * 1.5;
      viewerPosition.value = (0.0 - delta).clamp(reducedPosition, 0.0);
    }

    _lastScrollOffset =
        gridScrollController.hasClients ? gridScrollController.offset : 0.0;
    return false;
  }

  @override
  Widget androidLayout(BuildContext context) {
    appBarPreferredSize ??= appBar(context).preferredSize;
    final double appBarHeight = appBarPreferredSize!.height;

    return ChangeNotifierProvider<DefaultAssetPickerProvider>.value(
      value: provider,
      builder: (BuildContext context, _) =>
          Consumer<DefaultAssetPickerProvider>(
        builder: (context, p, _) {
          final bool hasAssetsToDisplay = p.hasAssetsToDisplay;
          final bool shouldBuildSpecialItems = assetsGridSpecialItemsFinalized(
            context: context,
            path: p.currentPath?.path,
          ).isNotEmpty;
          final bool shouldDisplayAssets =
              hasAssetsToDisplay || shouldBuildSpecialItems;

          if (_lastTrackedPath != p.currentPath) {
            _lastTrackedPath = p.currentPath;
            previewAsset.value = null;
          }

          _initializePreviewAsset(p, shouldDisplayAssets);

          return ValueListenableBuilder<double>(
            valueListenable: viewerPosition,
            builder: (BuildContext context, double position, _) {
              final double heroHeight = previewHeight(context);
              final double topWidgetHeight = heroHeight +
                  appBarHeight +
                  _kMiddleBarHeight +
                  MediaQuery.paddingOf(context).top;

              final double topReducedPosition = -heroHeight;
              final double clampedPosition =
                  position.clamp(topReducedPosition, 0.0);

              final Duration animationDuration =
                  clampedPosition == topReducedPosition || clampedPosition == 0.0
                      ? const Duration(milliseconds: 200)
                      : Duration.zero;

              final double topPadding = topWidgetHeight + clampedPosition;
              final double gridHeight = MediaQuery.sizeOf(context).height -
                  appBarHeight -
                  _kMiddleBarHeight -
                  MediaQuery.paddingOf(context).top;

              return Stack(
                children: <Widget>[
                  // 1. Grid of Photos
                  AnimatedPadding(
                    padding: EdgeInsets.only(top: topPadding),
                    duration: animationDuration,
                    child: SizedBox(
                      height: gridHeight,
                      width: MediaQuery.sizeOf(context).width,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification notification) =>
                            _handleScroll(
                          context,
                          notification,
                          clampedPosition,
                          topReducedPosition,
                        ),
                        child: _buildGrid(context, shouldDisplayAssets),
                      ),
                    ),
                  ),

                  // 2. Header AppBar + Hero Viewport + Middle Control Bar
                  AnimatedPositioned(
                    top: clampedPosition,
                    duration: animationDuration,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      height: topWidgetHeight,
                      child: AssetPickerAppBarWrapper(
                        appBar: appBar(context),
                        body: Container(
                          color: Colors.white,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              buildEntityViewer(context),
                              _buildMiddleControlBar(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Album list dropdown overlay
                  pathEntityListBackdrop(context),
                  _buildListAlbums(context),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget appleOSLayout(BuildContext context) => androidLayout(context);

  Widget _buildGrid(BuildContext context, bool shouldDisplayAssets) {
    appBarPreferredSize ??= appBar(context).preferredSize;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: shouldDisplayAssets
          ? MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.only(
                  top: -appBarPreferredSize!.height,
                ),
              ),
              child: RepaintBoundary(child: assetsGridBuilder(context)),
            )
          : loadingIndicator(context),
    );
  }

  Widget _buildListAlbums(BuildContext context) {
    appBarPreferredSize ??= appBar(context).preferredSize;
    return Consumer<DefaultAssetPickerProvider>(
      builder: (context, provider, _) {
        if (isAppleOS(context)) {
          return pathEntityListWidget(context);
        }

        return ValueListenableBuilder<bool>(
          valueListenable: isSwitchingPath,
          builder: (_, bool isSwitchingPath, _) => Transform.translate(
            offset: isSwitchingPath
                ? Offset(
                    0,
                    appBarPreferredSize!.height +
                        MediaQuery.paddingOf(context).top,
                  )
                : Offset.zero,
            child: Stack(
              children: <Widget>[pathEntityListWidget(context)],
            ),
          ),
        );
      },
    );
  }

  @override
  AssetPickerAppBar appBar(BuildContext context) {
    final AssetPickerAppBar bar = AssetPickerAppBar(
      leading: backButton(context),
      title: Text(
        textDelegate.select == 'Pilih' ? 'Pilih Foto' : textDelegate.select,
        style: const TextStyle(
          fontFamily: 'SFPro',
          fontSize: 17.0,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
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
          previewAsset.value = asset;

          final bool isMulti = (provider.maxAssets > 1) && isMultiSelect.value;
          if (!isMulti) {
            final bool isSelected = provider.selectedAssets.contains(asset);
            if (!isSelected) {
              provider.selectedAssets.clear();
              provider.selectAsset(asset);
            }
          } else {
            final bool isSelected = provider.selectedAssets.contains(asset);
            selectAsset(context, asset, index, isSelected);
          }
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          viewAsset(context, index, asset);
        },
        child: ValueListenableBuilder<AssetEntity?>(
          valueListenable: previewAsset,
          builder: (context, activeAsset, _) {
            final bool isPreviewed = activeAsset == asset;
            return Selector<DefaultAssetPickerProvider, String>(
              selector: (_, p) => p.selectedDescriptions,
              builder: (context, descriptions, _) {
                final bool isSelected = descriptions.contains(asset.toString());
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    border: isPreviewed
                        ? Border.all(color: AppColors.primary, width: 2.5)
                        : null,
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.18)
                        : (isPreviewed
                            ? Colors.black.withValues(alpha: 0.15)
                            : Colors.transparent),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
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

        return ValueListenableBuilder<bool>(
          valueListenable: isMultiSelect,
          builder: (context, bool multi, _) {
            final bool isMultiMode = multi && provider.maxAssets > 1;
            if (!isMultiMode && !isSelected) {
              return const SizedBox.shrink();
            }

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
                    ? (isMultiMode && selectIndex != -1
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
                  previewAsset.value = asset;
                  selectAsset(context, asset, index, isSelected);
                },
                child: innerSelector,
              ),
            );
          },
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
