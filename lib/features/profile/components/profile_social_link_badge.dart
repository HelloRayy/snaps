import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileSocialLinkBadge extends StatelessWidget {
  final String rawLink;

  const ProfileSocialLinkBadge({super.key, required this.rawLink});

  String _normalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://$trimmed';
  }

  ({bool isInstagram, IconData icon, String label}) _resolvePlatform(Uri uri) {
    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (host.contains('instagram.com')) {
      final handle = segments.isNotEmpty ? '@${segments.first.replaceAll('@', '')}' : 'Instagram';
      return (isInstagram: true, icon: LucideIcons.camera, label: handle);
    }
    if (host.contains('tiktok.com')) {
      final handle = segments.isNotEmpty ? '@${segments.first.replaceAll('@', '')}' : 'TikTok';
      return (isInstagram: false, icon: LucideIcons.music, label: handle);
    }
    if (host.contains('wa.me') || host.contains('whatsapp.com')) {
      return (isInstagram: false, icon: LucideIcons.messageCircle, label: 'WhatsApp');
    }
    if (host.contains('github.com')) {
      final handle = segments.isNotEmpty ? segments.first : 'GitHub';
      return (isInstagram: false, icon: LucideIcons.code, label: handle);
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return (isInstagram: false, icon: LucideIcons.play, label: 'YouTube');
    }
    if (host.contains('x.com') || host.contains('twitter.com')) {
      final handle = segments.isNotEmpty ? '@${segments.first.replaceAll('@', '')}' : 'X';
      return (isInstagram: false, icon: LucideIcons.atSign, label: handle);
    }
    return (
      isInstagram: false,
      icon: LucideIcons.link,
      label: host.isNotEmpty ? host : rawLink.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeUrl(rawLink);
    final uri = Uri.tryParse(normalized);
    if (uri == null || rawLink.trim().isEmpty) return const SizedBox.shrink();

    final platform = _resolvePlatform(uri);
    const linkColor = AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(6.0),
        onTap: () async {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (platform.isInstagram)
                CustomPaint(
                  size: const Size(14.0, 14.0),
                  painter: const _InstagramGlyphPainter(linkColor),
                )
              else
                Icon(platform.icon, size: 14.0, color: linkColor),
              const SizedBox(width: 5.0),
              Flexible(
                child: Text(
                  platform.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: linkColor,
                  ),
                ),
              ),
              const SizedBox(width: 2.0),
              Icon(
                LucideIcons.arrowUpRight,
                size: 13.0,
                color: linkColor.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstagramGlyphPainter extends CustomPainter {
  final Color color;
  const _InstagramGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(rect, stroke);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.22,
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.76, size.height * 0.24),
      0.9,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _InstagramGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
