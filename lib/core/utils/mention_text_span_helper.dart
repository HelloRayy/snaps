import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:snapan_market/core/navigation/app_slide_page_route.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/profile/screens/profile_screen.dart';

/// Represents an active mention token currently being typed in a text field
class MentionToken {
  final String query;
  final int startOffset;
  final int endOffset;

  const MentionToken({
    required this.query,
    required this.startOffset,
    required this.endOffset,
  });
}

/// Helper to parse text containing @mentions, #hashtags, and URLs
/// into rich clickable text spans with No-Background Pure Accent Style,
/// and manage mention token detection & autocompletion.
class MentionTextSpanHelper {
  MentionTextSpanHelper._();

  static final RegExp mentionRegex = RegExp(
    r'((?:@|#)[a-zA-Z0-9_.]+|https?:\/\/[^\s]+)',
  );

  /// Builds a list of [InlineSpan]s with styled mentions/hashtags/links.
  static List<InlineSpan> buildSpans({
    required BuildContext context,
    required String text,
    TextStyle? defaultStyle,
    ValueChanged<String>? onUserClick,
    Color accentColor = AppColors.primary,
  }) {
    if (text.isEmpty) return const [];

    final matches = mentionRegex.allMatches(text);
    if (matches.isEmpty) {
      return [TextSpan(text: text, style: defaultStyle)];
    }

    final List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: defaultStyle,
          ),
        );
      }

      final matchedText = match.group(0)!;
      final isUrl = matchedText.startsWith('http');
      final isMention = matchedText.startsWith('@');
      final isHashtag = matchedText.startsWith('#');

      // Punctuation trimming: prevent trailing periods/commas from corrupting username
      String coreText = matchedText;
      String trailingPunctuation = '';
      if (isMention || isHashtag) {
        final puncMatch = RegExp(r'[.,!?:;]+$').firstMatch(matchedText);
        if (puncMatch != null) {
          trailingPunctuation = puncMatch.group(0)!;
          coreText = matchedText.substring(0, matchedText.length - trailingPunctuation.length);
        }
      }

      // If token is just "@" or "#" without characters after punctuation trimming, treat as normal text
      if ((isMention || isHashtag) && coreText.length <= 1) {
        spans.add(TextSpan(text: matchedText, style: defaultStyle));
        lastEnd = match.end;
        continue;
      }

      TapGestureRecognizer? recognizer;
      if (isMention) {
        final cleanUsername = coreText.substring(1);
        recognizer = TapGestureRecognizer()
          ..onTap = () {
            if (!context.mounted) return;
            if (onUserClick != null) {
              onUserClick(cleanUsername);
            } else {
              Navigator.push(
                context,
                AppSlidePageRoute(
                  builder: (_) => ProfileScreen(
                    username: cleanUsername,
                    onBack: () => Navigator.pop(context),
                  ),
                ),
              );
            }
          };
      }

      spans.add(
        TextSpan(
          text: coreText,
          recognizer: recognizer,
          style: TextStyle(
            color: accentColor,
            fontWeight: isMention ? FontWeight.w600 : FontWeight.w500,
            decoration: isUrl ? TextDecoration.underline : TextDecoration.none,
            decorationColor: accentColor,
            letterSpacing: -0.1,
          ),
        ),
      );

      if (trailingPunctuation.isNotEmpty) {
        spans.add(
          TextSpan(
            text: trailingPunctuation,
            style: defaultStyle,
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: defaultStyle,
        ),
      );
    }

    return spans;
  }

  /// Extracts the mention query currently being typed at the cursor position.
  static MentionToken? extractActiveMentionToken(TextEditingValue value) {
    if (!value.selection.isValid || value.selection.baseOffset < 0) return null;
    final cursor = value.selection.baseOffset;
    final textBeforeCursor = value.text.substring(0, cursor);

    final match = RegExp(r'(?:^|\s)@([a-zA-Z0-9_.]*)$').firstMatch(textBeforeCursor);
    if (match == null) return null;

    final query = match.group(1) ?? '';
    final atIndex = textBeforeCursor.lastIndexOf('@');
    if (atIndex < 0) return null;

    return MentionToken(
      query: query,
      startOffset: atIndex,
      endOffset: cursor,
    );
  }

  /// Replaces the active mention token with the selected username and advances cursor.
  static TextEditingValue applyMention(
    TextEditingValue current,
    MentionToken token,
    String username,
  ) {
    final cleanUsername = username.replaceAll('@', '').trim();
    final before = current.text.substring(0, token.startOffset);
    final after = current.text.substring(token.endOffset);
    final replacement = '@$cleanUsername ';
    final newText = '$before$replacement$after';
    final newCursor = before.length + replacement.length;

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }
}
