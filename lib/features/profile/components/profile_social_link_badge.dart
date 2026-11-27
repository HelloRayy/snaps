import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileSocialLinkBadge extends StatelessWidget {
  final String rawLink;

  const ProfileSocialLinkBadge({super.key, required this.rawLink});

  String _normalizeUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('@')) {
      return 'https://instagram.com/${trimmed.substring(1)}';
    }
    final withScheme = (trimmed.startsWith('http://') || trimmed.startsWith('https://'))
        ? trimmed
        : 'https://$trimmed';
    final parsed = Uri.tryParse(withScheme);
    if (parsed != null &&
        (parsed.host.contains('instagram.com') ||
            parsed.host.contains('tiktok.com') ||
            parsed.host.contains('x.com') ||
            parsed.host.contains('twitter.com'))) {
      return parsed.replace(queryParameters: const {}).toString().replaceAll(RegExp(r'\?$'), '');
    }
    return withScheme;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final inkColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: () async {
          try {
            if (platform.isInstagram && platform.label.startsWith('@')) {
              final handle = platform.label.substring(1);
              final igAppUri = Uri.parse('instagram://user?username=$handle');
              final launchedApp = await launchUrl(
                igAppUri,
                mode: LaunchMode.externalApplication,
              );
              if (launchedApp) return;
            }
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {}
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: borderColor, width: 0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (platform.isInstagram)
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Color(0xFFF58529),
                      Color(0xFFDD2A7B),
                      Color(0xFF8134AF),
                    ],
                  ).createShader(bounds),
                  child: CustomPaint(
                    size: const Size(14.5, 14.5),
                    painter: const _InstagramGlyphPainter(Colors.white),
                  ),
                )
              else
                Icon(platform.icon, size: 14.0, color: inkColor),
              const SizedBox(width: 6.0),
              Flexible(
                child: Text(
                  platform.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: inkColor,
                  ),
                ),
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
