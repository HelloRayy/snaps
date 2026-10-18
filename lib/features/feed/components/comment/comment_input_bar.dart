import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/features/feed/components/sheets/media_attachment_bottom_sheet.dart';

/// CommentInputBar Widget
/// 100% Sliced 1:1 from Web React CommentInputBar.tsx
///
/// Features:
/// - Floating white capsule pill dock with backdrop shadow
/// - User profile avatar (32x32)
/// - Flexible text input field with contextual placeholder
/// - Send CTA Button (dark pill with tactile feedback)
/// - Replying-to status banner with "Batal" cancel action
class CommentInputBar extends StatefulWidget {
  final String? replyToUser;
  final String? targetAuthor;
  final String? userAvatar;
  final ValueChanged<String> onSubmitComment;
  final void Function(String text, List<XFile> images)? onSubmitCommentWithMedia;
  final VoidCallback? onCancelReply;
  final ValueChanged<String>? onDraftChange;

  const CommentInputBar({
    super.key,
    this.replyToUser,
    this.targetAuthor,
    this.userAvatar,
    required this.onSubmitComment,
    this.onSubmitCommentWithMedia,
    this.onCancelReply,
    this.onDraftChange,
  });
  @override
  State<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends State<CommentInputBar> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  bool _hasText = false;
  bool _isSendPressed = false;
  List<XFile> _attachedImages = [];
  String _cleanUsername(String raw) =>
      raw.trim().replaceAll('@', '').replaceAll(' ', '_');

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    _textController.addListener(_onTextChanged);

    if (widget.replyToUser != null) {
      final clean = _cleanUsername(widget.replyToUser!);
      final prefix = '@$clean ';
      _textController.text = prefix;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: prefix.length),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CommentInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyToUser != null) {
      final clean = _cleanUsername(widget.replyToUser!);
      final prefix = '@$clean ';
      if (oldWidget.replyToUser != widget.replyToUser || !_textController.text.startsWith(prefix)) {
        // Strip any existing mention prefix if present and apply the new target
        final remainingText = _textController.text.replaceFirst(RegExp(r'^@[a-zA-Z0-9_.]+\s*'), '');
        _textController.text = '$prefix$remainingText';
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    final hasVal = text.trim().isNotEmpty;
    if (hasVal != _hasText) {
      setState(() {
        _hasText = hasVal;
      });
    }
    widget.onDraftChange?.call(text);
  }

  Future<void> _openMediaPicker() async {
    final pickedFiles = await MediaAttachmentBottomSheet.show(context);
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _attachedImages.addAll(pickedFiles);
        if (_attachedImages.length > 3) {
          _attachedImages = _attachedImages.sublist(0, 3);
        }
      });
    }
  }

  void _handleSubmit() {
    var text = _textController.text.trim();
    if (widget.replyToUser != null) {
      final clean = _cleanUsername(widget.replyToUser!);
      final prefix = '@$clean ';
      if (!text.startsWith(prefix) && !text.startsWith('@$clean')) {
        text = '$prefix$text';
      }
    }
    if (text.isEmpty && _attachedImages.isEmpty) return;
    HapticFeedback.lightImpact();
    if (_attachedImages.isNotEmpty && widget.onSubmitCommentWithMedia != null) {
      widget.onSubmitCommentWithMedia!(text, List.from(_attachedImages));
    } else {
      widget.onSubmitComment(text);
    }
    _textController.clear();
    setState(() {
      _attachedImages.clear();
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholder = widget.replyToUser != null
        ? 'Balas @${widget.replyToUser!.replaceAll('@', '')}...'
        : widget.targetAuthor != null
            ? 'Balas @${widget.targetAuthor!.replaceAll('@', '')}...'
            : 'Tulis balasan...';

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: bottomInset > 0
            ? bottomInset + 8.0
            : (bottomPadding > 0 ? bottomPadding + 6.0 : 12.0),
        top: 6.0,
      ),
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===============================================================
          // 0. REPLY PREVIEW BANNER (pen.dev Frame 1 Reply node HvRsZ)
          // ===============================================================
          if (widget.replyToUser != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      color: isDark
                          ? AppColors.darkSurfaceElevated.withValues(alpha: 0.85)
                          : Colors.white.withValues(alpha: 0.75),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.90),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Vertical brand indicator line (Snapan Primary #3D38F5)
                        Container(
                          width: 2.5,
                          height: 24.0,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13.0,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Membalas ',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: '@${widget.replyToUser!.replaceAll('@', '')}',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            widget.onCancelReply?.call();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 15.0,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ===============================================================
          // ATTACHMENT PREVIEW STRIP
          // ===============================================================
          if (_attachedImages.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              height: 64.0,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _attachedImages.length + (_attachedImages.length < 3 ? 1 : 0),
                separatorBuilder: (_, index) => const SizedBox(width: 8.0),
                itemBuilder: (context, index) {
                  if (index == _attachedImages.length) {
                    return GestureDetector(
                      onTap: _openMediaPicker,
                      child: Container(
                        width: 64.0,
                        height: 64.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.plus,
                            size: 20.0,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }

                  final file = _attachedImages[index];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 64.0,
                        height: 64.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11.0),
                          child: Image.file(
                            File(file.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: -4.0,
                        right: -4.0,
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _attachedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            width: 20.0,
                            height: 20.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF334155) : const Color(0xFF1E293B),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 10.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          // ===============================================================
          // FRAME 1: Leading Button + Write Bar (pen.dev jXVwo)
          // ===============================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. LEADING BUTTON (pen.dev jxdH0: 42x42 circle, frosted liquid glass + shadow)
              GestureDetector(
                onTap: _openMediaPicker,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42.0,
                      height: 42.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
                        border: Border.all(
                          color: _attachedImages.isNotEmpty
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                          width: _attachedImages.isNotEmpty ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _attachedImages.isNotEmpty
                              ? CupertinoIcons.camera_fill
                              : CupertinoIcons.paperclip,
                          color: _attachedImages.isNotEmpty
                              ? AppColors.primary
                              : (isDark ? AppColors.darkTextPrimary : const Color(0xFF1A1A1A)),
                          size: 20.0,
                        ),
                      ),
                    ),
                    if (_attachedImages.isNotEmpty)
                      Positioned(
                        top: -2.0,
                        right: -2.0,
                        child: Container(
                          width: 17.0,
                          height: 17.0,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${_attachedImages.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 6.0), // pen.dev gap: 6

              // 2. WRITE BAR (Clean Flat Capsule Bordered)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 42.0),
                  padding: const EdgeInsets.fromLTRB(14.0, 3.0, 3.0, 3.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(21.0),
                    color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Text Input
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 4,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSubmit(),
                          style: TextStyle(
                            fontFamily: 'SFPro',
                            fontSize: 15.5,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF000000),
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                          decoration: InputDecoration(
                            hintText: placeholder,
                            hintStyle: TextStyle(
                              fontFamily: 'SFPro',
                              fontSize: 15.5,
                              color: isDark ? AppColors.darkTextDisabled : const Color(0xFF999999),
                              letterSpacing: -0.3,
                              height: 1.25,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 7.0),
                          ),
                        ),
                      ),

                      const SizedBox(width: 4.0),

                      // Trailing Action: Send Button when text exists or media attached
                      if (_hasText || _attachedImages.isNotEmpty)
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isSendPressed = true),
                          onTapUp: (_) => setState(() => _isSendPressed = false),
                          onTapCancel: () => setState(() => _isSendPressed = false),
                          onTap: _handleSubmit,
                          child: AnimatedScale(
                            scale: _isSendPressed ? 0.90 : 1.0,
                            duration: const Duration(milliseconds: 90),
                            curve: Curves.easeOutCubic,
                            child: Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFF008BFF), // pen.dev Azure Blue #008BFF
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.arrow_up,
                                  size: 19.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          width: 36.0,
                          height: 36.0,
                          child: Center(
                            child: Icon(
                              CupertinoIcons.smiley,
                              color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8),
                              size: 22.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


