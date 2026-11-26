import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/avatar/oreo_avatar_helper.dart';
import 'package:snapan_market/core/services/snaps_disk_image_cache.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Global flag to force default profile avatar across the entire app.
/// Set to false so that users with an avatar in the database display their photo,
/// while users without a photo gracefully fallback to DefaultProfileAvatar.
const bool kForceDefaultProfileAvatar = false;

/// Standard default profile avatar with neutral gray background and person silhouette icon,
/// matching standard mobile app design (Instagram/X/TikTok) when a user has no profile photo.
class DefaultProfileAvatar extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final BoxBorder? border;

  const DefaultProfileAvatar({
    super.key,
    required this.size,
    this.backgroundColor,
    this.iconColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE2E8F0);
    final defaultIcon = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? defaultBg,
        border: border,
      ),
      child: Center(
        child: Icon(
          CupertinoIcons.person_fill,
          size: (size * 0.56).clamp(10.0, 72.0),
          color: iconColor ?? defaultIcon,
        ),
      ),
    );
  }
}

/// Universal AppAvatar widget that handles forced default avatars and graceful fallbacks.
class AppAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final String? name;
  final String? username;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;
  final Color? iconColor;

  const AppAvatar({
    super.key,
    this.avatarUrl,
    required this.size,
    this.name,
    this.username,
    this.onTap,
    this.border,
    this.boxShadow,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = avatarUrl?.trim();
    if (kForceDefaultProfileAvatar || cleanUrl == null || cleanUrl.isEmpty) {
      Widget avatar = DefaultProfileAvatar(
        size: size,
        border: border,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
      );
      if (boxShadow != null && boxShadow!.isNotEmpty) {
        avatar = Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: boxShadow,
          ),
          child: avatar,
        );
      }
      if (onTap != null) {
        avatar = GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: avatar,
        );
      }
      return avatar;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = backgroundColor ?? (isDark ? AppColors.darkSurfaceElevated : const Color(0xFFE2E8F0));

    Widget content;
    if (cleanUrl.startsWith('preset:')) {
      final presetId = cleanUrl.substring(7);
      final preset = kOreoGradientPresets.firstWhere(
        (p) => p.id == presetId,
        orElse: () => kOreoGradientPresets[0],
      );
      final initialLetter = (name?.trim().isNotEmpty == true
          ? name!.trim()[0]
          : (username?.trim().isNotEmpty == true ? username!.trim()[0] : 'S')).toUpperCase();

      content = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: preset.colors,
            begin: preset.begin,
            end: preset.end,
          ),
        ),
        child: Center(
          child: Text(
            initialLetter,
            style: TextStyle(
              fontSize: (size * 0.42).clamp(10.0, 28.0),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (cleanUrl.startsWith('assets/')) {
      content = Image.asset(
        cleanUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => DefaultProfileAvatar(
          size: size,
          backgroundColor: backgroundColor,
          iconColor: iconColor,
        ),
      );
    } else {
      content = _CachedAvatarImage(
        url: cleanUrl,
        size: size,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
      );
    }

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: baseBg,
        shape: BoxShape.circle,
        border: border,
        boxShadow: boxShadow,
      ),
      child: ClipOval(child: content),
    );

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatar,
      );
    }
    return avatar;
  }
}

class _CachedAvatarImage extends StatefulWidget {
  final String url;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const _CachedAvatarImage({
    required this.url,
    required this.size,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<_CachedAvatarImage> createState() => _CachedAvatarImageState();
}

class _CachedAvatarImageState extends State<_CachedAvatarImage> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _CachedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _file = null;
      _load();
    }
  }

  Future<void> _load() async {
    final sync = SnapsDiskImageCache.instance.getCachedFileSync(widget.url);
    if (sync != null) {
      _file = sync;
      return;
    }
    final fetched = await SnapsDiskImageCache.instance.getOrFetch(widget.url);
    if (mounted && fetched != null) {
      setState(() => _file = fetched);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_file == null) {
      return DefaultProfileAvatar(
        size: widget.size,
        backgroundColor: widget.backgroundColor,
        iconColor: widget.iconColor,
      );
    }
    final cachePx = (widget.size * 3).round().clamp(96, 360);
    return Image.file(
      _file!,
      width: widget.size,
      height: widget.size,
      cacheWidth: cachePx,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => DefaultProfileAvatar(
        size: widget.size,
        backgroundColor: widget.backgroundColor,
        iconColor: widget.iconColor,
      ),
    );
  }
}
