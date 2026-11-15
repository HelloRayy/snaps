import 'package:flutter/material.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// Card container matching Material 3 spec component catalog
/// with interactive preview container and spec details.
class M3ComponentSpecCard extends StatelessWidget {
  final String title;
  final String description;
  final String? sourcePath;
  final Widget preview;
  final Widget? specDetails;

  const M3ComponentSpecCard({
    super.key,
    required this.title,
    required this.description,
    this.sourcePath,
    required this.preview,
    this.specDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final previewBg = isDark ? const Color(0xFF1E2022) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF0F172A);
    final textMuted = isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (sourcePath != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          sourcePath!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10.5,
                            color: textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Interactive Component Stage (M3 Canvas Box)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
            decoration: BoxDecoration(
              color: previewBg,
              border: Border.symmetric(
                horizontal: BorderSide(color: borderColor, width: 0.8),
              ),
            ),
            alignment: Alignment.center,
            child: preview,
          ),

          // Technical Specs Footer (Tokens, padding, rules)
          if (specDetails != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: specDetails!,
            ),
        ],
      ),
    );
  }
}
