import '../../../../core/utils/media_helpers.dart';

class PostMedia {
  final String id;
  final String mediaType;
  final String url;
  final int? width;
  final int? height;
  final int sortOrder;

  const PostMedia({
    required this.id,
    required this.mediaType,
    required this.url,
    this.width,
    this.height,
    this.sortOrder = 0,
  });

  String get resolvedUrl => MediaHelpers.resolveUrl(url);

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      id: (json['id'] ?? '').toString(),
      mediaType: (json['media_type'] ?? json['type'] ?? 'image').toString(),
      url: (json['url'] ?? '').toString(),
      width: json['width'] is num ? (json['width'] as num).toInt() : null,
      height: json['height'] is num ? (json['height'] as num).toInt() : null,
      sortOrder: json['sort_order'] is num ? (json['sort_order'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'media_type': mediaType,
    'url': url,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    'sort_order': sortOrder,
  };
}

class TopComment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String firstName;
  final String lastName;
  final String profilePictureUrl;
  final String content;
  final DateTime createdAt;
  final int likesCount;
  final int repliesCount;

  const TopComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.profilePictureUrl = '',
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.repliesCount = 0,
  });

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    return username.isNotEmpty ? username : 'User';
  }

  factory TopComment.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    return TopComment(
      id: (json['id'] ?? '').toString(),
      postId: (json['post_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      username: (json['username'] ?? 'User').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      profilePictureUrl: (json['profile_picture_url'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: parseDate(json['created_at']),
      likesCount: json['likes_count'] is num ? (json['likes_count'] as num).toInt() : 0,
      repliesCount: json['replies_count'] is num ? (json['replies_count'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'user_id': userId,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'profile_picture_url': profilePictureUrl,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'likes_count': likesCount,
    'replies_count': repliesCount,
  };
}

class FeedItem {
  final String id;
  final String content;
  final DateTime createdAt;
  final String authorId;
  final String authorUsername;
  final String authorFirstName;
  final String authorLastName;
  final String authorPicture;
  final String bubbleId;
  final String bubbleName;
  final int likesCount;
  final Map<String, int> reactionCounts;
  final int repliesCount;
  final String? userEmoji;
  final bool isSaved;
  final List<PostMedia> media;
  final TopComment? topComment;

  const FeedItem({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.authorId,
    required this.authorUsername,
    this.authorFirstName = '',
    this.authorLastName = '',
    this.authorPicture = '',
    this.bubbleId = '',
    this.bubbleName = '',
    this.likesCount = 0,
    this.reactionCounts = const {},
    this.repliesCount = 0,
    this.userEmoji,
    this.isSaved = false,
    this.media = const [],
    this.topComment,
  });

  String get authorDisplayName {
    final full = '$authorFirstName $authorLastName'.trim();
    if (full.isNotEmpty) return full;
    return authorUsername.isNotEmpty ? authorUsername : 'User';
  }

  bool get hasMedia => media.isNotEmpty;

  dynamic operator [](String key) {
    if (key == 'id') return id;
    if (key == 'content') return content;
    if (key == 'created_at') return createdAt.toIso8601String();
    if (key == 'author_id' || key == 'user_id') return authorId;
    if (key == 'author_username' || key == 'username') return authorUsername;
    if (key == 'author_first_name' || key == 'first_name') return authorFirstName;
    if (key == 'author_last_name' || key == 'last_name') return authorLastName;
    if (key == 'author_profile_picture_url' ||
        key == 'author_picture' ||
        key == 'profile_picture_url') {
      return authorPicture;
    }
    if (key == 'bubble_id') return bubbleId;
    if (key == 'bubble_name') return bubbleName;
    if (key == 'likes_count') return likesCount;
    if (key == 'reaction_counts') return reactionCounts;
    if (key == 'replies_count') return repliesCount;
    if (key == 'user_emoji') return userEmoji;
    if (key == 'is_saved') return isSaved;
    if (key == 'media') return media.map((m) => m.toJson()).toList();
    if (key == 'top_comment') return topComment?.toJson();
    return null;
  }

  FeedItem copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    String? authorId,
    String? authorUsername,
    String? authorFirstName,
    String? authorLastName,
    String? authorPicture,
    String? bubbleId,
    String? bubbleName,
    int? likesCount,
    Map<String, int>? reactionCounts,
    int? repliesCount,
    String? userEmoji,
    bool? isSaved,
    List<PostMedia>? media,
    TopComment? topComment,
    bool clearUserEmoji = false,
  }) {
    return FeedItem(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorFirstName: authorFirstName ?? this.authorFirstName,
      authorLastName: authorLastName ?? this.authorLastName,
      authorPicture: authorPicture ?? this.authorPicture,
      bubbleId: bubbleId ?? this.bubbleId,
      bubbleName: bubbleName ?? this.bubbleName,
      likesCount: likesCount ?? this.likesCount,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      repliesCount: repliesCount ?? this.repliesCount,
      userEmoji: clearUserEmoji ? null : (userEmoji ?? this.userEmoji),
      isSaved: isSaved ?? this.isSaved,
      media: media ?? this.media,
      topComment: topComment ?? this.topComment,
    );
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawReactions = json['reaction_counts'];
    final Map<String, int> parsedReactions = {};
    if (rawReactions is Map) {
      rawReactions.forEach((k, v) {
        if (v is num && v.toInt() > 0) {
          parsedReactions[k.toString()] = v.toInt();
        }
      });
    }

    final rawMedia = json['media'];
    final List<PostMedia> mediaList = [];
    if (rawMedia is List) {
      for (final item in rawMedia) {
        if (item is Map<String, dynamic>) {
          mediaList.add(PostMedia.fromJson(item));
        } else if (item is Map) {
          mediaList.add(PostMedia.fromJson(Map<String, dynamic>.from(item)));
        } else if (item is String) {
          mediaList.add(PostMedia(id: '', mediaType: 'image', url: item));
        }
      }
    }

    final rawTopComment = json['top_comment'];
    TopComment? parsedTopComment;
    if (rawTopComment is Map<String, dynamic>) {
      parsedTopComment = TopComment.fromJson(rawTopComment);
    } else if (rawTopComment is Map) {
      parsedTopComment = TopComment.fromJson(Map<String, dynamic>.from(rawTopComment));
    }

    final authorPic = (json['author_profile_picture_url'] ??
            json['author_picture'] ??
            json['profile_picture_url'] ??
            '')
        .toString();

    final userEmojiVal = json['user_emoji']?.toString();

    return FeedItem(
      id: (json['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: parseDate(json['created_at']),
      authorId: (json['author_id'] ?? json['user_id'] ?? '').toString(),
      authorUsername: (json['author_username'] ?? json['username'] ?? 'User').toString(),
      authorFirstName: (json['author_first_name'] ?? json['first_name'] ?? '').toString(),
      authorLastName: (json['author_last_name'] ?? json['last_name'] ?? '').toString(),
      authorPicture: authorPic,
      bubbleId: (json['bubble_id'] ?? '').toString(),
      bubbleName: (json['bubble_name'] ?? '').toString(),
      likesCount: json['likes_count'] is num ? (json['likes_count'] as num).toInt() : 0,
      reactionCounts: parsedReactions,
      repliesCount: json['replies_count'] is num ? (json['replies_count'] as num).toInt() : 0,
      userEmoji: (userEmojiVal != null && userEmojiVal.isNotEmpty) ? userEmojiVal : null,
      isSaved: json['is_saved'] == true,
      media: mediaList,
      topComment: parsedTopComment,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'created_at': createdAt.toIso8601String(),
    'author_id': authorId,
    'author_username': authorUsername,
    'author_first_name': authorFirstName,
    'author_last_name': authorLastName,
    'author_profile_picture_url': authorPicture,
    'bubble_id': bubbleId,
    'bubble_name': bubbleName,
    'likes_count': likesCount,
    'reaction_counts': reactionCounts,
    'replies_count': repliesCount,
    'user_emoji': userEmoji,
    'is_saved': isSaved,
    'media': media.map((m) => m.toJson()).toList(),
    if (topComment != null) 'top_comment': topComment!.toJson(),
  };
}
