class CommentNode {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String firstName;
  final String lastName;
  final String profilePictureUrl;
  final String content;
  final String? parentId;
  final String? parentUsername;
  final DateTime createdAt;
  final int likesCount;
  final Map<String, int> reactionCounts;
  final int repliesCount;
  final String? userEmoji;
  final List<CommentNode> children;

  CommentNode({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    this.profilePictureUrl = '',
    required this.content,
    this.parentId,
    this.parentUsername,
    required this.createdAt,
    this.likesCount = 0,
    this.reactionCounts = const {},
    this.repliesCount = 0,
    this.userEmoji,
    List<CommentNode>? children,
  }) : children = children ?? [];

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    return username.isNotEmpty ? username : 'User';
  }

  int get totalDescendants {
    int count = children.length;
    for (final c in children) {
      count += c.totalDescendants;
    }
    return count;
  }

  Map<String, dynamic> get comment => {
    'id': id,
    'post_id': postId,
    'user_id': userId,
    'username': username,
    'content': content,
    'user_emoji': userEmoji,
    'reaction_counts': reactionCounts,
    'likes_count': likesCount,
    'replies_count': repliesCount,
    'first_name': firstName,
    'last_name': lastName,
    'profile_picture_url': profilePictureUrl,
  };

  CommentNode copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? firstName,
    String? lastName,
    String? profilePictureUrl,
    String? content,
    String? parentId,
    String? parentUsername,
    DateTime? createdAt,
    int? likesCount,
    Map<String, int>? reactionCounts,
    int? repliesCount,
    String? userEmoji,
    List<CommentNode>? children,
    bool clearUserEmoji = false,
  }) {
    return CommentNode(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      parentUsername: parentUsername ?? this.parentUsername,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      reactionCounts: reactionCounts ?? this.reactionCounts,
      repliesCount: repliesCount ?? this.repliesCount,
      userEmoji: clearUserEmoji ? null : (userEmoji ?? this.userEmoji),
      children: children ?? this.children,
    );
  }

  factory CommentNode.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    final rawReactions = json['reaction_counts'];
    final Map<String, int> reactions = {};
    if (rawReactions is Map) {
      rawReactions.forEach((k, v) {
        if (v is num && v.toInt() > 0) {
          reactions[k.toString()] = v.toInt();
        }
      });
    }

    final parentIdRaw = json['parent_reply_id'] ?? json['parent_id'];
    final parentUsernameRaw = json['parent_username'];
    final userEmojiVal = json['user_emoji']?.toString();

    return CommentNode(
      id: (json['id'] ?? '').toString(),
      postId: (json['post_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      username: (json['username'] ?? 'User').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      profilePictureUrl: (json['profile_picture_url'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      parentId: (parentIdRaw != null && parentIdRaw.toString().isNotEmpty)
          ? parentIdRaw.toString()
          : null,
      parentUsername: (parentUsernameRaw != null && parentUsernameRaw.toString().isNotEmpty)
          ? parentUsernameRaw.toString()
          : null,
      createdAt: parseDate(json['created_at']),
      likesCount: json['likes_count'] is num ? (json['likes_count'] as num).toInt() : 0,
      reactionCounts: reactions,
      repliesCount: json['replies_count'] is num ? (json['replies_count'] as num).toInt() : 0,
      userEmoji: (userEmojiVal != null && userEmojiVal.isNotEmpty) ? userEmojiVal : null,
    );
  }

  static List<CommentNode> buildTree(List<dynamic> rawList) {
    final Map<String, CommentNode> nodeMap = {};
    final List<CommentNode> allNodes = [];

    for (final item in rawList) {
      final map = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
      final node = CommentNode.fromJson(map);
      nodeMap[node.id] = node;
      allNodes.add(node);
    }

    final List<CommentNode> roots = [];
    for (final node in allNodes) {
      final pId = node.parentId;
      if (pId != null && pId.isNotEmpty && nodeMap.containsKey(pId)) {
        nodeMap[pId]!.children.add(node);
      } else {
        roots.add(node);
      }
    }
    return roots;
  }
}
