import 'package:snapan_market/core/models/mascot_flair_model.dart';

enum SearchResultsTab { top, latest, profiles }

class SuggestedAccount {
  final String id;
  final String username;
  final String fullName;
  final String avatar;
  final bool isVerified;
  final MascotFlairModel? mascotFlair;
  final String bio;
  final String followersCount;
  final bool isFollowing;

  const SuggestedAccount({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatar,
    this.isVerified = false,
    this.mascotFlair,
    required this.bio,
    required this.followersCount,
    this.isFollowing = false,
  });

  SuggestedAccount copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatar,
    bool? isVerified,
    MascotFlairModel? mascotFlair,
    String? bio,
    String? followersCount,
    bool? isFollowing,
  }) {
    return SuggestedAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      isVerified: isVerified ?? this.isVerified,
      mascotFlair: mascotFlair ?? this.mascotFlair,
      bio: bio ?? this.bio,
      followersCount: followersCount ?? this.followersCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

class TrendingTag {
  final String id;
  final String tag;
  final String posts;

  const TrendingTag({
    required this.id,
    required this.tag,
    required this.posts,
  });
}

const List<SuggestedAccount> kInitialSuggestedAccounts = [];

const List<TrendingTag> kTrendingTags = [];
