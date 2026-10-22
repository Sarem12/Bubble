class EnrichedConversation {
  final String id;
  final String friendId;
  final String username;
  final String firstName;
  final String lastName;
  final String avatar;
  final String lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  EnrichedConversation({
    required this.id,
    required this.friendId,
    required this.username,
    this.firstName = '',
    this.lastName = '',
    required this.avatar,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  EnrichedConversation copyWith({
    String? id,
    String? friendId,
    String? username,
    String? firstName,
    String? lastName,
    String? avatar,
    String? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnrichedConversation(
      id: id ?? this.id,
      friendId: friendId ?? this.friendId,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory EnrichedConversation.fromJson(Map<String, dynamic> json) {
    return EnrichedConversation(
      id: (json['id'] ?? '').toString(),
      friendId: (json['friend_id'] ?? '').toString(),
      username: (json['username'] ?? 'Unknown').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      avatar: (json['avatar'] ?? json['profile_picture_url'] ?? '').toString(),
      lastMessage: (json['last_message'] ?? 'No messages yet').toString(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString()).toLocal() 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString()).toLocal() 
          : DateTime.now(),
    );
  }
}
