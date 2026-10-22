class Bubble {
  final String id;
  final String name;
  final String description;
  final String type;
  final int membersCount;
  final bool isMember;
  final bool? notificationsEnabled;
  final DateTime? createdAt;

  const Bubble({
    required this.id,
    required this.name,
    this.description = '',
    this.type = 'PUBLIC',
    this.membersCount = 0,
    this.isMember = false,
    this.notificationsEnabled,
    this.createdAt,
  });

  String get formattedTag {
    if (name.startsWith('#')) return name;
    return '#$name';
  }

  Bubble copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    int? membersCount,
    bool? isMember,
    bool? notificationsEnabled,
    DateTime? createdAt,
  }) {
    return Bubble(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      membersCount: membersCount ?? this.membersCount,
      isMember: isMember ?? this.isMember,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Bubble.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v)?.toLocal();
      }
      return null;
    }

    return Bubble(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? 'PUBLIC').toString(),
      membersCount: json['members_count'] is num
          ? (json['members_count'] as num).toInt()
          : 0,
      isMember: json['is_member'] == true,
      notificationsEnabled: json['notifications_enabled'] is bool
          ? json['notifications_enabled'] as bool
          : null,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type,
    'members_count': membersCount,
    'is_member': isMember,
    if (notificationsEnabled != null)
      'notifications_enabled': notificationsEnabled,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };
}
