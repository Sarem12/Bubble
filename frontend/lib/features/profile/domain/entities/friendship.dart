import '../../../../core/utils/media_helpers.dart';

class FriendUser {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String profilePictureUrl;
  final bool isBestFriend;
  final String state;

  const FriendUser({
    required this.id,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.profilePictureUrl = '',
    this.isBestFriend = false,
    this.state = 'accepted',
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    return username.isNotEmpty ? username : 'User';
  }

  String get resolvedAvatarUrl => MediaHelpers.resolveUrl(profilePictureUrl);

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    final friendId = (json['friend_id'] ??
            json['target_user_id'] ??
            json['user_id'] ??
            json['id'] ??
            '')
        .toString();

    final usernameVal = (json['friend_username'] ??
            json['username'] ??
            'User')
        .toString();

    final firstNameVal = (json['friend_first_name'] ??
            json['first_name'] ??
            '')
        .toString();

    final lastNameVal = (json['friend_last_name'] ??
            json['last_name'] ??
            '')
        .toString();

    final picVal = (json['friend_profile_picture_url'] ??
            json['profile_picture_url'] ??
            json['avatar_url'] ??
            '')
        .toString();

    return FriendUser(
      id: friendId,
      username: usernameVal,
      firstName: firstNameVal,
      lastName: lastNameVal,
      profilePictureUrl: picVal,
      isBestFriend: json['is_bestfriend'] == true,
      state: (json['state'] ?? 'accepted').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'profile_picture_url': profilePictureUrl,
    'is_bestfriend': isBestFriend,
    'state': state,
  };
}
