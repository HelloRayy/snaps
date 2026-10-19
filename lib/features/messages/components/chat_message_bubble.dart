import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:snapan_market/features/feed/components/lightbox/media_lightbox_dialog.dart';
import 'package:snapan_market/features/messages/models/chat_message_model.dart';

/// Single chat message bubble matching 1:1 chat-bubble.tsx specs.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  bool _isImageUrl(String text) {
    final clean = text.trim();
    return (clean.startsWith('http://') || clean.startsWith('https://')) &&
        (clean.endsWith('.jpg') ||
            clean.endsWith('.jpeg') ||
            clean.endsWith('.png') ||
            clean.endsWith('.webp') ||
            clean.contains('/market-media/') ||
            clean.contains('/avatars/'));
  }

  Widget _buildMediaContent(BuildContext context, List<String> images) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < images.length; i++) ...[
          GestureDetector(
            onTap: () {
              MediaLightboxDialog.show(
                context: context,
                images: images,
                initialIndex: i,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: images[i].startsWith('http')
                  ? Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 160.0,
                          color: const Color(0x10000000),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 120.0,
                        color: const Color(0x10000000),
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      ),
                    )
                  : Image.file(
                      File(images[i]),
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          if (i < images.length - 1) const SizedBox(height: 6.0),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> effectiveImages = message.images.isNotEmpty
        ? message.images
        : (_isImageUrl(message.text) ? [message.text.trim()] : []);
    final bool hasImages = effectiveImages.isNotEmpty;
    final bool showText = message.text.isNotEmpty && !_isImageUrl(message.text);

    if (message.isMe) {
      // Outgoing message (Me) - Kumo Blue #1D64EC
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: const BoxDecoration(
                color: Color(0xFF1D64EC),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(4.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x101D64EC),
                    blurRadius: 4.0,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasImages) ...[
                    _buildMediaContent(context, effectiveImages),
                    if (showText) const SizedBox(height: 6.0),
                  ],
                  if (showText)
                    Text(
                      message.text,
                      style: const TextStyle(
                        fontFamily: 'SFPro',
                        fontSize: 14.5,
                        color: Colors.white,
                        height: 1.38,
                        letterSpacing: -0.1,
                      ),
                    ),
                  const SizedBox(height: 3.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timestamp,
                        style: TextStyle(
                          fontSize: 11.0,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      const Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 14.0,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Incoming message (Other user) - White compact card with subtle border
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                minWidth: 48.0,
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 13.0, vertical: 9.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                  bottomLeft: Radius.circular(4.0),
                ),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 4.0,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImages) ...[
                    _buildMediaContent(context, effectiveImages),
                    if (showText) const SizedBox(height: 6.0),
                  ],
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 8.0,
                    runSpacing: 2.0,
                    children: [
                      if (showText)
                        Text(
                          message.text,
                          style: const TextStyle(
                            fontFamily: 'SFPro',
                            fontSize: 14.5,
                            color: Color(0xFF0F172A),
                            height: 1.36,
                            letterSpacing: -0.1,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1.0),
                        child: Text(
                          message.timestamp,
                          style: const TextStyle(
                            fontFamily: 'SFPro',
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
