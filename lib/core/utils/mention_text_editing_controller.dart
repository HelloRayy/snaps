import 'package:flutter/material.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/utils/mention_text_span_helper.dart';

/// Custom TextEditingController that dynamically highlights @mentions and #hashtags
/// in real-time with Electric Indigo (AppColors.primary) as the user types in text inputs.
class MentionTextEditingController extends TextEditingController {
  final Color mentionColor;

  MentionTextEditingController({
    super.text,
    this.mentionColor = AppColors.primary,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) {
      return TextSpan(style: style, text: '');
    }

    final spans = MentionTextSpanHelper.buildHighlightSpans(
      text: text,
      defaultStyle: style,
      accentColor: mentionColor,
    );

    return TextSpan(
      style: style,
      children: spans,
    );
  }
}
