import '../../../../core/utils/media_helpers.dart';

class UserProfile {
  final String id;
  final String username;
  final String type;
  final String firstName;
  final String lastName;
  final String bio;
  final String profilePictureUrl;
  final DateTime? createdAt;
  final DateTime? birthday;
  final DateTime? lastActiveAt;
  final int postsCount;
  final int friendsCount;
  final int bubblesCount;
  final bool isFriend;

  const UserProfile({
    required this.id,
    required this.username,
    this.type = 'PUBLIC',
    this.firstName = '',
    this.lastName = '',
    this.bio = '',
    this.profilePictureUrl = '',
    this.createdAt,
    this.birthday,
    this.lastActiveAt,
    this.postsCount = 0,
    this.friendsCount = 0,
    this.bubblesCount = 0,
    this.isFriend = false,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    if (username.isNotEmpty && username != 'Unknown') return username;
    return 'User';
  }

  dynamic operator [](String key) {
    if (key == 'id') return id;
    if (key == 'username') return username;
    if (key == 'type') return type;
    if (key == 'first_name') return firstName;
    if (key == 'last_name') return lastName;
    if (key == 'bio') return bio;
    if (key == 'profile_picture_url' || key == 'avatar_url')
      return profilePictureUrl;
    if (key == 'posts_count') return postsCount;
    if (key == 'friends_count') return friendsCount;
    if (key == 'bubbles_count') return bubblesCount;
    if (key == 'is_friend') return isFriend;
    return null;
  }

  String get resolvedAvatarUrl => MediaHelpers.resolveUrl(profilePictureUrl);

  String get lastActiveFormatted {
    if (lastActiveAt == null) return 'Offline';
    final diff = DateTime.now().difference(lastActiveAt!.toLocal());
    if (diff.inMinutes < 1) return 'Active just now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    return 'Active ${diff.inDays}d ago';
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? type,
    String? firstName,
    String? lastName,
    String? bio,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? birthday,
    DateTime? lastActiveAt,
    int? postsCount,
    int? friendsCount,
    int? bubblesCount,
    bool? isFriend,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      type: type ?? this.type,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      birthday: birthday ?? this.birthday,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      postsCount: postsCount ?? this.postsCount,
      friendsCount: friendsCount ?? this.friendsCount,
      bubblesCount: bubblesCount ?? this.bubblesCount,
      isFriend: isFriend ?? this.isFriend,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v)?.toLocal();
      }
      return null;
    }

    final pUrl = (json['profile_picture_url'] ?? json['avatar_url'] ?? '')
        .toString();

    return UserProfile(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? 'User').toString(),
      type: (json['type'] ?? 'PUBLIC').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      profilePictureUrl: pUrl,
      createdAt: parseNullableDate(json['created_at']),
      birthday: parseNullableDate(json['birthday']),
      lastActiveAt: parseNullableDate(json['last_active_at']),
      postsCount: json['posts_count'] is num
          ? (json['posts_count'] as num).toInt()
          : 0,
      friendsCount: json['friends_count'] is num
          ? (json['friends_count'] as num).toInt()
          : 0,
      bubblesCount: json['bubbles_count'] is num
          ? (json['bubbles_count'] as num).toInt()
          : 0,
      isFriend: json['is_friend'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'type': type,
    'first_name': firstName,
    'last_name': lastName,
    'bio': bio,
    'profile_picture_url': profilePictureUrl,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (birthday != null) 'birthday': birthday!.toIso8601String(),
    if (lastActiveAt != null) 'last_active_at': lastActiveAt!.toIso8601String(),
    'posts_count': postsCount,
    'friends_count': friendsCount,
    'bubbles_count': bubblesCount,
    'is_friend': isFriend,
  };
}
