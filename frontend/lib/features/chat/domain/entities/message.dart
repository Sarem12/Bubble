class Reaction {
  final String userId;
  final String emoji;

  const Reaction({required this.userId, required this.emoji});

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      userId: (json['user_id'] ?? '').toString(),
      emoji: (json['emoji'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'emoji': emoji,
  };
}

class Message {
  final String id;
  final String conversationId;
  final String topic;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
  final List<Reaction> reactions;
  final bool isOptimistic;

  const Message({
    required this.id,
    required this.conversationId,
    required this.topic,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.createdAt,
    this.readAt,
    this.reactions = const [],
    this.isOptimistic = false,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? topic,
    String? senderId,
    String? recipientId,
    String? content,
    DateTime? createdAt,
    DateTime? readAt,
    List<Reaction>? reactions,
    bool? isOptimistic,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      topic: topic ?? this.topic,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      reactions: reactions ?? this.reactions,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }

  factory Message.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['message'] is Map<String, dynamic>)
        ? rawJson['message'] as Map<String, dynamic>
        : rawJson;

    final rawReactions = json['reactions'];
    List<Reaction> parsedReactions = [];
    if (rawReactions is List) {
      for (final r in rawReactions) {
        if (r is Map<String, dynamic>) {
          parsedReactions.add(Reaction.fromJson(r));
        }
      }
    }

    return Message(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      topic: (json['topic'] ?? 'main').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      recipientId: (json['recipient_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString())?.toLocal() : null,
      reactions: parsedReactions,
      isOptimistic: json['is_optimistic'] == true,
    );
  }
}
