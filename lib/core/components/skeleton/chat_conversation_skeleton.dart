import 'package:flutter/material.dart';
import 'package:snapan_market/core/components/skeleton/snaps_shimmer.dart';

/// Shimmer Skeleton for 1-on-1 Chat Conversation Screen
/// Emulates alternating incoming and outgoing chat bubbles during initial message fetch.
class ChatConversationSkeleton extends StatelessWidget {
  const ChatConversationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return SnapsShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
        children: [
          _ChatBubbleSkeletonItem(
            isMe: false,
            width: screenWidth * 0.58,
            height: 44.0,
          ),
          _ChatBubbleSkeletonItem(
            isMe: false,
            width: screenWidth * 0.72,
            height: 64.0,
          ),
          _ChatBubbleSkeletonItem(
            isMe: true,
            width: screenWidth * 0.48,
            height: 42.0,
          ),
          _ChatBubbleSkeletonItem(
            isMe: true,
            width: screenWidth * 0.65,
            height: 58.0,
          ),
          _ChatBubbleSkeletonItem(
            isMe: false,
            width: screenWidth * 0.50,
            height: 44.0,
          ),
          _ChatBubbleSkeletonItem(
            isMe: true,
            width: screenWidth * 0.38,
            height: 38.0,
          ),
        ],
      ),
    );
  }
}

class _ChatBubbleSkeletonItem extends StatelessWidget {
  final bool isMe;
  final double width;
  final double height;

  const _ChatBubbleSkeletonItem({
    required this.isMe,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? const Color(0xFF242626) : const Color(0xFFF1F3F5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20.0),
                topRight: const Radius.circular(20.0),
                bottomLeft: Radius.circular(isMe ? 20.0 : 4.0),
                bottomRight: Radius.circular(isMe ? 4.0 : 20.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
