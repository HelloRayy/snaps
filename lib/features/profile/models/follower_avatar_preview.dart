class FollowerAvatarPreview {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final bool isMutual;

  const FollowerAvatarPreview({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.isMutual = false,
  });

  factory FollowerAvatarPreview.fromMap(
    Map<String, dynamic> map, {
    bool isMutual = false,
  }) {
    final profileData = map['follower'] is Map<String, dynamic>
        ? map['follower'] as Map<String, dynamic>
        : map;

    return FollowerAvatarPreview(
      id: profileData['id']?.toString() ?? '',
      username: profileData['username']?.toString() ?? '',
      displayName: profileData['display_name'] as String? ??
          profileData['full_name'] as String?,
      avatarUrl: profileData['avatar_url'] as String?,
      isMutual: (map['is_mutual'] as bool?) ?? isMutual,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'is_mutual': isMutual,
    };
  }
}
