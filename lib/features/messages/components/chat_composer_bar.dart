import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapan_market/core/services/snaps_asset_picker.dart';
import 'package:snapan_market/core/theme/app_colors.dart';

/// ChatComposerBar - Modern Unified Pill (Instagram & Threads style)
///
/// Architecture:
/// - Unified pill container (radius 24dp) wrapping integrated media button, text input, and send action
/// - Brand primary action color (#3D38F5 / AppColors.primary)
/// - Adaptive dark & light mode support
/// - Smooth multiline auto-expansion up to 5 lines
class ChatComposerBar extends StatefulWidget {
  final ValueChanged<String> onSendMessage;
  final void Function(String text, List<String> images)? onSendMessageWithMedia;
  final VoidCallback? onAttachmentTap;
  final String placeholder;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final String? initialText;

  const ChatComposerBar({
    super.key,
    required this.onSendMessage,
    this.onSendMessageWithMedia,
    this.onAttachmentTap,
    this.placeholder = 'Message',
    this.onTap,
    this.focusNode,
    this.initialText,
  });

  @override
  State<ChatComposerBar> createState() => _ChatComposerBarState();
}

class _ChatComposerBarState extends State<ChatComposerBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _internalFocusNode = false;
  bool _canSend = false;
  bool _isSendPressed = false;
  final List<String> _attachedImages = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _canSend = _controller.text.trim().isNotEmpty;
    _controller.addListener(_handleTextChanged);
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _internalFocusNode = true;
    }
    _focusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      widget.onTap?.call();
    }
  }

  void _handleTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty || _attachedImages.isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_internalFocusNode) {
      _focusNode.dispose();
    }
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
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final barBorderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final inputBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final inputBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: barBgColor,
        border: Border(
          top: BorderSide(
            color: barBorderColor,
            width: 0.8,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        top: 8.0,
        bottom: isKeyboardOpen
            ? 8.0
            : (bottomPadding > 0 ? bottomPadding + 4.0 : 12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ATTACHED IMAGES PREVIEW STRIP
          if (_attachedImages.isNotEmpty) ...[
            Container(
              height: 64.0,
              margin: const EdgeInsets.only(bottom: 8.0),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedImages.length + (_attachedImages.length < 5 ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(width: 8.0),
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
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            width: 1.0,
                          ),
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        ),
                        child: Center(
                          child: Icon(
                            CupertinoIcons.plus,
                            size: 20.0,
                            color: iconColor,
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
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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

          // 2. DOCKED INPUT ROW (3 Elements: Media + Rounded Rect 15px Input + Send/Emoji Action)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // A. Attachment Button
              GestureDetector(
                onTap: _pickImages,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: inputBorderColor,
                      width: 0.8,
                    ),
                  ),
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.photo_on_rectangle,
                          size: 19.0,
                          color: _attachedImages.isNotEmpty
                              ? AppColors.primary
                              : iconColor,
                        ),
                        if (_attachedImages.isNotEmpty)
                          Positioned(
                            top: -4.0,
                            right: -4.0,
                            child: Container(
                              width: 15.0,
                              height: 15.0,
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
              const SizedBox(width: 8.0),

              // B. Rounded Rectangle Input Box (Radius 15px, Capped 110px max height)
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 38.0,
                    maxHeight: 110.0,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: inputBgColor,
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(
                      color: inputBorderColor,
                      width: 0.8,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onTap: widget.onTap,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(
                      fontFamily: 'SFPro',
                      fontSize: 15.0,
                      color: textColor,
                      letterSpacing: -0.2,
                      height: 1.3,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(
                        fontFamily: 'SFPro',
                        fontSize: 15.0,
                        color: hintColor,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),

              // C. Send Button or Emoji Action
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: _canSend
                    ? GestureDetector(
                        key: const ValueKey('send_button'),
                        onTapDown: (_) => setState(() => _isSendPressed = true),
                        onTapUp: (_) => setState(() => _isSendPressed = false),
                        onTapCancel: () => setState(() => _isSendPressed = false),
                        onTap: _handleSend,
                        child: AnimatedScale(
                          scale: _isSendPressed ? 0.90 : 1.0,
                          duration: const Duration(milliseconds: 90),
                          curve: Curves.easeOutCubic,
                          child: Container(
                            width: 38.0,
                            height: 38.0,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.arrow_up,
                                size: 20.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        key: const ValueKey('emoji_button'),
                        onTap: () => HapticFeedback.selectionClick(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 38.0,
                          height: 38.0,
                          decoration: BoxDecoration(
                            color: inputBgColor,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: inputBorderColor,
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.emoji_emotions_outlined,
                              color: iconColor,
                              size: 20.0,
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
