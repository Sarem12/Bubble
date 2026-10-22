class ActivityItem {
  final String id;
  final String type; // post_reaction, post_reply, comment_reply, reply_reaction, friend_request, friend_accepted
  final String actorId;
  final String actorUsername;
  final String actorFirstName;
  final String actorLastName;
  final String actorAvatar;
  final String? postId;
  final String? postContent;
  final String? postMediaUrl;
  final String? replyId;
  final String? replyContent;
  final String? parentReplyId;
  final String? emoji;
  final String? state;
  final DateTime createdAt;

  ActivityItem({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorUsername,
    this.actorFirstName = '',
    this.actorLastName = '',
    this.actorAvatar = '',
    this.postId,
    this.postContent,
    this.postMediaUrl,
    this.replyId,
    this.replyContent,
    this.parentReplyId,
    this.emoji,
    this.state,
    required this.createdAt,
  });

  String get actorDisplayName {
    final full = '$actorFirstName $actorLastName'.trim();
    if (full.isNotEmpty) return full;
    if (actorUsername.isNotEmpty) return actorUsername;
    return 'Someone';
  }

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      actorId: (json['actor_id'] ?? '').toString(),
      actorUsername: (json['actor_username'] ?? '').toString(),
      actorFirstName: (json['actor_first_name'] ?? '').toString(),
      actorLastName: (json['actor_last_name'] ?? '').toString(),
      actorAvatar: (json['actor_avatar'] ?? '').toString(),
      postId: json['post_id']?.toString(),
      postContent: json['post_content']?.toString(),
      postMediaUrl: json['post_media_url']?.toString(),
      replyId: json['reply_id']?.toString(),
      replyContent: json['reply_content']?.toString(),
      parentReplyId: json['parent_reply_id']?.toString(),
      emoji: json['emoji']?.toString(),
      state: json['state']?.toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class FriendRequestItem {
  final String id;
  final String userId;
  final String username;
  final String firstName;
  final String lastName;
  final String profilePictureUrl;
  final DateTime createdAt;

  FriendRequestItem({
    required this.id,
    required this.userId,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.profilePictureUrl = '',
    required this.createdAt,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    if (username.isNotEmpty) return username;
    return 'Someone';
  }

  factory FriendRequestItem.fromJson(Map<String, dynamic> json) {
    return FriendRequestItem(
      id: (json['id'] ?? json['user_id'] ?? json['target_user_id'] ?? '').toString(),
      userId: (json['user_id'] ?? json['sender_id'] ?? json['target_user_id'] ?? json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      profilePictureUrl: (json['profile_picture_url'] ?? json['avatar'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class ActivityFeedData {
  final List<ActivityItem> activities;
  final List<FriendRequestItem> friendRequests;

  ActivityFeedData({
    required this.activities,
    required this.friendRequests,
  });

  factory ActivityFeedData.fromJson(Map<String, dynamic> json) {
    final rawActs = json['activities'] as List? ?? [];
    final acts = rawActs
        .whereType<Map>()
        .map((e) => ActivityItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final rawReqs = (json['friend_requests'] ?? json['requests']) as List? ?? [];
    final reqs = rawReqs
        .whereType<Map>()
        .map((e) => FriendRequestItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ActivityFeedData(
      activities: acts,
      friendRequests: reqs,
    );
  }
}
