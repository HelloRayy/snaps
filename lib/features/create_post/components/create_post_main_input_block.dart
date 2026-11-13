import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:snapan_market/core/components/mention_suggestion_list.dart';
import 'package:snapan_market/core/constants/app_constants.dart';
import 'package:snapan_market/core/models/mascot_flair_model.dart';
import 'package:snapan_market/core/theme/app_colors.dart';
import 'package:snapan_market/core/ui/default_profile_avatar.dart';
import 'package:snapan_market/core/utils/mention_text_span_helper.dart';
import 'package:snapan_market/features/create_post/components/create_post_author_line.dart';
import 'package:snapan_market/features/create_post/components/create_post_bottom_sheets.dart';
import 'package:snapan_market/features/create_post/components/create_post_media_preview.dart';
import 'package:snapan_market/features/create_post/components/create_post_media_toolbar.dart';
import 'package:snapan_market/features/create_post/components/create_post_poll_builder.dart';
import 'package:snapan_market/features/create_post/components/create_post_selling_toggle.dart';
import 'package:snapan_market/features/create_post/models/create_post_types.dart';

class CreatePostMainInputBlock extends StatelessWidget {
  final PostMode postMode;
  final String currentUserName;
  final String currentUserAvatar;
  final TextEditingController captionController;
  final List<String> images;
  final PresetGif? selectedGif;
  final bool showPoll;
  final bool showEmojiBar;
  final List<TextEditingController> pollOptionControllers;
  final TopicOption? selectedTopic;
  final GlobalKey topicTriggerKey;
  final VoidCallback onPickImage;
  final ValueChanged<PresetGif?> onGifSelected;
  final VoidCallback onToggleEmoji;
  final VoidCallback onTogglePoll;
  final ValueChanged<TopicOption?> onTopicSelected;
  final ValueChanged<SchoolPlace?> onLocationSelected;
  final ValueChanged<bool> onToggleMode;
  final ValueChanged<int> onRemoveImage;
  final void Function(int oldIndex, int newIndex) onReorderImage;
  final VoidCallback onAddPollOption;
  final ValueChanged<int> onRemovePollOption;
  final VoidCallback onDismissPoll;
  final Duration pollDeadlineDuration;
  final ValueChanged<Duration> onPollDurationChanged;
  final bool pollAllowChangeVote;
  final ValueChanged<bool> onPollAllowChangeVoteChanged;
  final MascotFlairModel? selectedMascotFlair;
  final bool canUseMascot;
  final VoidCallback? onMascotTriggerTap;
  final GlobalKey? mascotTriggerKey;
  final bool isMascotDropdownOpen;
  final bool isVerified;

  const CreatePostMainInputBlock({
    super.key,
    required this.postMode,
    required this.currentUserName,
    required this.currentUserAvatar,
    required this.captionController,
    required this.images,
    required this.selectedGif,
    required this.showPoll,
    required this.showEmojiBar,
    required this.pollOptionControllers,
    required this.selectedTopic,
    required this.topicTriggerKey,
    required this.onPickImage,
    required this.onGifSelected,
    required this.onToggleEmoji,
    required this.onTogglePoll,
    required this.onTopicSelected,
    required this.onLocationSelected,
    required this.onToggleMode,
    required this.onRemoveImage,
    required this.onReorderImage,
    required this.onAddPollOption,
    required this.onRemovePollOption,
    required this.onDismissPoll,
    required this.pollDeadlineDuration,
    required this.onPollDurationChanged,
    required this.pollAllowChangeVote,
    required this.onPollAllowChangeVoteChanged,
    this.selectedMascotFlair,
    this.canUseMascot = true,
    this.onMascotTriggerTap,
    this.mascotTriggerKey,
    this.isMascotDropdownOpen = false,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Dynamic Thread Line (Behind Avatar, centered: 36/2 - 2/2 = 17.0)
          if (postMode == PostMode.thread)
            Positioned(
              left: 17.0,
              top: 42.0,
              bottom: 0.0,
              child: Container(
                width: 2.0,
                color: const Color(0xFFE2E8F0),
              ),
            ),

          // 2. Content Row: Avatar (top-aligned) + Main Input Column
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36.0,
                child: AppAvatar(
                  avatarUrl: currentUserAvatar,
                  size: 36.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  CreatePostAuthorLine(
                    authorName: currentUserName,
                    selectedTopic: selectedTopic,
                    topicTriggerKey: topicTriggerKey,
                    selectedMascotFlair: selectedMascotFlair,
                    canUseMascot: canUseMascot,
                    onMascotTriggerTap: onMascotTriggerTap,
                    mascotTriggerKey: mascotTriggerKey,
                    isMascotDropdownOpen: isMascotDropdownOpen,
                    isVerified: isVerified,
                    onTopicTriggerTap: () => CreatePostBottomSheets.showTopicPickerPopup(
                      context: context,
                      triggerKey: topicTriggerKey,
                      onTopicSelected: onTopicSelected,
                    ),
                    onTopicClear: () => onTopicSelected(null),
                  ),
                  const SizedBox(height: 2.0),
                  TextField(
                    controller: captionController,
                    minLines: 1,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      fontFamily: 'SFPro',
                      fontSize: 15.0,
                      color: AppColors.ink,
                      height: 1.35,
                    ),
                    decoration: InputDecoration(
                      hintText: postMode == PostMode.thread ? 'Apa yang baru?' : 'Ceritakan barang apa yang kamu jual...',
                      hintStyle: const TextStyle(
                        fontFamily: 'SFPro',
                        fontSize: 15.0,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: captionController,
                    builder: (context, value, _) {
                      final token = MentionTextSpanHelper.extractActiveMentionToken(value);
                      if (token == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: MentionSuggestionList(
                          query: token.query,
                          onSelectUser: (username) {
                            captionController.value = MentionTextSpanHelper.applyMention(
                              captionController.value,
                              token,
                              username,
                            );
                          },
                        ),
                      );
                    },
                  ),
                  if (images.isNotEmpty) ...[
                    const SizedBox(height: 12.0),
                    CreatePostImagesPreview(
                      images: images,
                      onAddImage: onPickImage,
                      onRemoveImage: onRemoveImage,
                      onReorderImage: onReorderImage,
                    ),
                  ],
                  if (selectedGif != null) ...[
                    const SizedBox(height: 10.0),
                    CreatePostGifPreview(gif: selectedGif!, onRemove: () => onGifSelected(null)),
                  ],
                  if (showPoll && postMode == PostMode.thread) ...[
                    CreatePostPollBuilder(
                      controllers: pollOptionControllers,
                      onAddOption: onAddPollOption,
                      onRemoveOption: onRemovePollOption,
                      onDismissPoll: onDismissPoll,
                      deadlineDuration: pollDeadlineDuration,
                      onDurationChanged: onPollDurationChanged,
                      allowChangeVote: pollAllowChangeVote,
                      onAllowChangeVoteChanged: onPollAllowChangeVoteChanged,
                    ),
                  ],
                  const SizedBox(height: 10.0),
                  CreatePostMediaToolbar(
                    showEmojiBar: showEmojiBar,
                    showPollBuilder: showPoll,
                    onPickImage: onPickImage,
                    onPickGif: () => CreatePostBottomSheets.showGifPickerBottomSheet(
                      context: context,
                      onGifSelected: onGifSelected,
                    ),
                    onToggleEmoji: onToggleEmoji,
                    onInsertEmoji: (e) => captionController.text += e,
                    onTogglePoll: onTogglePoll,
                    onPickTopic: () => CreatePostBottomSheets.showTopicPickerPopup(
                      context: context,
                      triggerKey: topicTriggerKey,
                      onTopicSelected: onTopicSelected,
                    ),
                    onPickLocation: () => CreatePostBottomSheets.showLocationPickerBottomSheet(
                      context: context,
                      onLocationSelected: onLocationSelected,
                    ),
                    onAudioTap: () {},
                  ),
                  if (AppConstants.enableCommerceMode) ...[
                    const SizedBox(height: 8.0),
                    CreatePostSellingToggle(
                      isProductMode: postMode == PostMode.product,
                      onToggle: onToggleMode,
                    ),
                    if (postMode == PostMode.product && images.isEmpty) ...[
                      const SizedBox(height: 6.0),
                      const Row(
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 13.0,
                            color: Color(0xFFEF4444),
                          ),
                          SizedBox(width: 5.0),
                          Text(
                            'Wajib tambahkan minimal 1 foto barang jualan',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFEF4444),
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
