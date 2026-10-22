class UserSettings {
  final String userId;
  final String notificationState;
  final String invitationState;
  final String globalReactionNotifications;
  final String globalCommentNotifications;
  final String globalReplyNotifications;
  final String messageNotifications;
  final String allowNewChats;
  final List<String> topReactions;
  final String doubleTapReaction;
  final String themeMode;
  final Map<String, dynamic> rawData;

  const UserSettings({
    this.userId = '',
    this.notificationState = 'all',
    this.invitationState = 'all',
    this.globalReactionNotifications = 'all',
    this.globalCommentNotifications = 'all',
    this.globalReplyNotifications = 'all',
    this.messageNotifications = 'all',
    this.allowNewChats = 'everyone',
    this.topReactions = const [],
    this.doubleTapReaction = '❤️',
    this.themeMode = 'system',
    this.rawData = const {},
  });

  dynamic operator [](String key) {
    if (key == 'user_id') return userId;
    if (key == 'notification_state') return notificationState;
    if (key == 'invitation_state') return invitationState;
    if (key == 'global_reaction_notifications') return globalReactionNotifications;
    if (key == 'global_comment_notifications') return globalCommentNotifications;
    if (key == 'global_reply_notifications') return globalReplyNotifications;
    if (key == 'message_notifications') return messageNotifications;
    if (key == 'allow_new_chats') return allowNewChats;
    if (key == 'top_reactions') return topReactions;
    if (key == 'double_tap_reaction') return doubleTapReaction;
    if (key == 'theme_mode') return themeMode;
    return rawData[key];
  }

  UserSettings copyWith({
    String? userId,
    String? notificationState,
    String? invitationState,
    String? globalReactionNotifications,
    String? globalCommentNotifications,
    String? globalReplyNotifications,
    String? messageNotifications,
    String? allowNewChats,
    List<String>? topReactions,
    String? doubleTapReaction,
    String? themeMode,
    Map<String, dynamic>? rawData,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      notificationState: notificationState ?? this.notificationState,
      invitationState: invitationState ?? this.invitationState,
      globalReactionNotifications:
          globalReactionNotifications ?? this.globalReactionNotifications,
      globalCommentNotifications:
          globalCommentNotifications ?? this.globalCommentNotifications,
      globalReplyNotifications:
          globalReplyNotifications ?? this.globalReplyNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      allowNewChats: allowNewChats ?? this.allowNewChats,
      topReactions: topReactions ?? this.topReactions,
      doubleTapReaction: doubleTapReaction ?? this.doubleTapReaction,
      themeMode: themeMode ?? this.themeMode,
      rawData: rawData ?? this.rawData,
    );
  }

  UserSettings withUpdatedSetting(String key, dynamic value) {
    final newRaw = Map<String, dynamic>.from(rawData);
    newRaw[key] = value;

    return copyWith(
      userId: key == 'user_id' ? value.toString() : null,
      notificationState: key == 'notification_state' ? value.toString() : null,
      invitationState: key == 'invitation_state' ? value.toString() : null,
      globalReactionNotifications:
          key == 'global_reaction_notifications' ? value.toString() : null,
      globalCommentNotifications:
          key == 'global_comment_notifications' ? value.toString() : null,
      globalReplyNotifications:
          key == 'global_reply_notifications' ? value.toString() : null,
      messageNotifications: key == 'message_notifications' ? value.toString() : null,
      allowNewChats: key == 'allow_new_chats' ? value.toString() : null,
      topReactions: key == 'top_reactions' && value is List
          ? List<String>.from(value.map((e) => e.toString()))
          : null,
      doubleTapReaction: key == 'double_tap_reaction' ? value.toString() : null,
      themeMode: key == 'theme_mode' ? value.toString() : null,
      rawData: newRaw,
    );
  }

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    final rawTop = json['top_reactions'];
    final List<String> parsedTop = [];
    if (rawTop is List) {
      for (final e in rawTop) {
        parsedTop.add(e.toString());
      }
    }

    return UserSettings(
      userId: (json['user_id'] ?? '').toString(),
      notificationState: (json['notification_state'] ?? 'all').toString(),
      invitationState: (json['invitation_state'] ?? 'all').toString(),
      globalReactionNotifications:
          (json['global_reaction_notifications'] ?? 'all').toString(),
      globalCommentNotifications:
          (json['global_comment_notifications'] ?? 'all').toString(),
      globalReplyNotifications: (json['global_reply_notifications'] ?? 'all').toString(),
      messageNotifications: (json['message_notifications'] ?? 'all').toString(),
      allowNewChats: (json['allow_new_chats'] ?? 'everyone').toString(),
      topReactions: parsedTop,
      doubleTapReaction: (json['double_tap_reaction'] ?? '❤️').toString(),
      themeMode: (json['theme_mode'] ?? 'system').toString(),
      rawData: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'notification_state': notificationState,
    'invitation_state': invitationState,
    'global_reaction_notifications': globalReactionNotifications,
    'global_comment_notifications': globalCommentNotifications,
    'global_reply_notifications': globalReplyNotifications,
    'message_notifications': messageNotifications,
    'allow_new_chats': allowNewChats,
    'top_reactions': topReactions,
    'double_tap_reaction': doubleTapReaction,
    'theme_mode': themeMode,
    ...rawData,
  };
}
