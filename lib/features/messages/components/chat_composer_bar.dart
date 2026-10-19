import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/services/snaps_asset_picker.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// ChatComposerBar sliced 1:1 from pen.dev Frame 1 (`snaps-design.pen` node `jXVwo`)
///
/// Structure:
/// - Height: 42.0 (expands dynamically for multiline input)
/// - Gap: 6.0
/// - Leading Button: 42x42 circle (frosted glass, shadow blur 35, offset 0, 8) with attachment icon
/// - Write Bar: Pill capsule (cornerRadius 21, frosted glass, shadow blur 35, offset 0, 8)
///   - Message TextField: SF Pro / Inter font, hint #999999
///   - Trailing:
///     - Empty: Symbol (Sticker/Emoji #727272)
///     - Active: Circular Send Button (36x36, Azure Blue #008BFF with arrow up)
class ChatComposerBar extends StatefulWidget {
  final ValueChanged<String> onSendMessage;
  final void Function(String text, List<String> images)? onSendMessageWithMedia;
  final VoidCallback? onAttachmentTap;
  final String placeholder;

  const ChatComposerBar({
    super.key,
    required this.onSendMessage,
    this.onSendMessageWithMedia,
    this.onAttachmentTap,
    this.placeholder = 'Message',
  });

  @override
  State<ChatComposerBar> createState() => _ChatComposerBarState();
}

class _ChatComposerBarState extends State<ChatComposerBar> {
  late final TextEditingController _controller;
  bool _canSend = false;
  bool _isSendPressed = false;
  final List<String> _attachedImages = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty || _attachedImages.isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _pickImages() async {
    HapticFeedback.selectionClick();
    if (widget.onAttachmentTap != null) {
      widget.onAttachmentTap!();
      return;
    }
    final remaining = 5 - _attachedImages.length;
    if (remaining <= 0) return;
    final picked = await SnapsAssetPicker.pickImages(context, maxImages: remaining);
    if (picked != null && picked.isNotEmpty && mounted) {
      setState(() {
        for (final file in picked) {
          if (_attachedImages.length < 5) {
            _attachedImages.add(file.path);
          }
        }
        _canSend = _controller.text.trim().isNotEmpty || _attachedImages.isNotEmpty;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachedImages.isEmpty) return;

    HapticFeedback.mediumImpact();
    final imagesToSend = List<String>.from(_attachedImages);
    if (imagesToSend.isNotEmpty && widget.onSendMessageWithMedia != null) {
      widget.onSendMessageWithMedia!(text, imagesToSend);
    } else {
      widget.onSendMessage(text);
    }
    _controller.clear();
    setState(() {
      _attachedImages.clear();
      _canSend = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: bottomInset > 0
            ? bottomInset + 8.0
            : (bottomPadding > 0 ? bottomPadding + 8.0 : 16.0),
        top: 6.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_attachedImages.isNotEmpty) ...[
            Container(
              height: 64.0,
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedImages.length + (_attachedImages.length < 5 ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(width: 8.0),
                itemBuilder: (context, index) {
                  if (index == _attachedImages.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 60.0,
                        height: 60.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                          color: const Color(0xFFF1F5F9),
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.plus,
                            size: 20.0,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }

                  final imagePath = _attachedImages[index];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          width: 60.0,
                          height: 60.0,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 0.8,
                            ),
                          ),
                          child: Image.file(
                            File(imagePath),
                            width: 60.0,
                            height: 60.0,
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
                              _canSend = _controller.text.trim().isNotEmpty || _attachedImages.isNotEmpty;
                            });
                          },
                          child: Container(
                            width: 20.0,
                            height: 20.0,
                            decoration: const BoxDecoration(
                              color: Color(0xCC000000),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 11.0,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // ===============================================================
              // 1. LEADING BUTTON (pen.dev jxdH0: 42x42 circle, frosted liquid glass + shadow)
              // ===============================================================
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 42.0,
                  height: 42.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 35.0,
                        offset: Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10.0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                      child: Container(
                        width: 42.0,
                        height: 42.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.72),
                              Colors.white.withValues(alpha: 0.45),
                            ],
                          ),
                          border: Border.all(
                            color: _attachedImages.isNotEmpty
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.90),
                            width: 1.2,
                          ),
                        ),
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.photo_on_rectangle,
                                color: _attachedImages.isNotEmpty
                                    ? AppColors.primary
                                    : const Color(0xFF1A1A1A),
                                size: 20.0,
                              ),
                              if (_attachedImages.isNotEmpty)
                                Positioned(
                                  top: -6.0,
                                  right: -6.0,
                                  child: Container(
                                    width: 16.0,
                                    height: 16.0,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${_attachedImages.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.w700,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

          const SizedBox(width: 6.0), // pen.dev gap: 6

          // ===============================================================
          // 2. WRITE BAR (pen.dev cXg3A: cornerRadius 21, height 42, frosted liquid glass + shadow)
          // ===============================================================
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 42.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(21.0),
                boxShadow: const [
                  // Diffuse outer shadow from pen.dev Frame 1 (#0000001f, y=8, blur=35)
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 35.0,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 42.0),
                    padding: const EdgeInsets.fromLTRB(14.0, 3.0, 3.0, 3.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(21.0),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.72),
                          Colors.white.withValues(alpha: 0.45),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.90),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Text Input
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _handleSend(),
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(
                              fontFamily: 'SFPro',
                              fontSize: 15.5,
                              color: Color(0xFF000000),
                              letterSpacing: -0.3,
                              height: 1.25,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.placeholder,
                              hintStyle: const TextStyle(
                                fontFamily: 'SFPro',
                                fontSize: 15.5,
                                color: Color(0xFF999999), // pen.dev #999999
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

                  // Trailing Action: Send Button when text exists, or Sticker/Emoji Symbol when empty
                  if (_canSend)
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isSendPressed = true),
                      onTapUp: (_) => setState(() => _isSendPressed = false),
                      onTapCancel: () => setState(() => _isSendPressed = false),
                      onTap: _handleSend,
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
                    const SizedBox(
                      width: 36.0,
                      height: 36.0,
                      child: Center(
                        child: Icon(
                          CupertinoIcons.smiley,
                          color: Color(0xFF727272), // pen.dev #727272
                          size: 21.0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
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
