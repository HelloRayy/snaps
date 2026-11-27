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

  ({IconData icon, String label, Color color}) _resolvePlatform(Uri uri) {
    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (host.contains('instagram.com')) {
      final handle = segments.isNotEmpty ? '@${segments.first.replaceAll('@', '')}' : 'Instagram';
      return (icon: LucideIcons.instagram, label: handle, color: const Color(0xFFE1306C));
    }
    if (host.contains('tiktok.com')) {
      final handle = segments.isNotEmpty ? '@${segments.first.replaceAll('@', '')}' : 'TikTok';
      return (icon: LucideIcons.music, label: handle, color: const Color(0xFF0F172A));
    }
    if (host.contains('wa.me') || host.contains('whatsapp.com')) {
      return (icon: LucideIcons.messageCircle, label: 'WhatsApp', color: const Color(0xFF25D366));
    }
    if (host.contains('github.com')) {
      final handle = segments.isNotEmpty ? segments.first : 'GitHub';
      return (icon: LucideIcons.github, label: handle, color: const Color(0xFF24292E));
    }
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return (icon: LucideIcons.youtube, label: 'YouTube', color: const Color(0xFFFF0000));
    }
    if (host.contains('x.com') || host.contains('twitter.com')) {
      final handle = segments.isNotEmpty ? '@${segments.first.replaceAll('@', '')}' : 'X';
      return (icon: LucideIcons.atSign, label: handle, color: const Color(0xFF0F172A));
    }
    return (
      icon: LucideIcons.link,
      label: host.isNotEmpty ? host : rawLink.trim(),
      color: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizeUrl(rawLink);
    final uri = Uri.tryParse(normalized);
    if (uri == null || rawLink.trim().isEmpty) return const SizedBox.shrink();

    final platform = _resolvePlatform(uri);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = isDark && platform.color == const Color(0xFF0F172A)
        ? Colors.white
        : platform.color;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: () async {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.22),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(platform.icon, size: 13.5, color: badgeColor),
              const SizedBox(width: 5.0),
              Flexible(
                child: Text(
                  platform.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
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
