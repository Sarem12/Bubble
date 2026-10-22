import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../emoji/bubble_emoji.dart';

/// The visual mode of the Dynamic Liquid Dock
enum DynamicDockMode {
  /// Default 5-tab navigation bar (Home, Explore, Gallery, Inbox, Profile)
  navigation,

  /// Selection mode when items are selected (Count + Cancel + Actions)
  selection,

  /// Full Morphing Comments panel (morphs dock from 60px into full comments panel)
  comments,

  /// Full Morphing New Chat panel (morphs dock from 60px into friends/new chat picker)
  newChat,

  /// Full Morphing Emoji Picker panel (morphs dock from 60px into 380px animated emoji picker)
  emojiPicker,

  /// Full Morphing Share panel (morphs dock into friends/share picker)
  share,

  /// Quick Animated Reaction Bar (morphs dock into animated reaction bar with + expandable to emoji picker)
  reactionBar,

  /// Quick comment / reply text input dock
  quickComment,

  /// Photo Viewer action bar mode (Edit, Share, Post, Delete)
  photoViewer,

  /// Custom dock widget or tools provided by the active screen
  custom,
}

/// Action item for Contextual Selection / Toolbar in Dynamic Dock
class DynamicDockAction {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isPrimary;
  final String? badge;

  const DynamicDockAction({
    required this.icon,
    this.label,
    required this.onTap,
    this.isDestructive = false,
    this.isPrimary = false,
    this.badge,
  });
}

/// Pop-out button item that floats / pops up above the dynamic dock
class DynamicDockPopoutItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const DynamicDockPopoutItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });
}

/// State for the Dynamic Dock
class DynamicDockState {
  final DynamicDockMode mode;
  final bool isVisible;
  final bool isScrolled;

  // Selection Mode Properties
  final int selectionCount;
  final String? selectionTitle;
  final List<DynamicDockAction> selectionActions;
  final VoidCallback? onSelectionCancel;

  // Comments / Quick Comment Mode Properties
  final String? commentsPostId;
  final ValueChanged<int>? onCommentCountChanged;
  final String commentPlaceholder;
  final String? initialCommentText;
  final void Function(String text)? onCommentSend;
  final VoidCallback? onCommentClose;

  // New Chat Mode Properties
  final VoidCallback? onNewChatClose;

  // Share Mode Properties
  final String? sharePostId;
  final VoidCallback? onShareClose;

  // Emoji Picker Mode Properties
  final ValueChanged<BubbleEmoji>? onEmojiSelected;
  final EmojiCategory emojiInitialCategory;
  final String? emojiTitle;
  final VoidCallback? onEmojiClose;

  // Reaction Bar Mode Properties
  final String? reactionActiveEmoji;
  final ValueChanged<String>? onReactionSelected;
  final VoidCallback? onReactionRemoved;
  final VoidCallback? onReactionClose;

  // Pop-out Menu / Tools
  final bool isPopoutOpen;
  final List<DynamicDockPopoutItem> popoutItems;

  // Photo Viewer Mode Properties
  final VoidCallback? onPhotoEdit;
  final VoidCallback? onPhotoShare;
  final VoidCallback? onPhotoPost;
  final VoidCallback? onPhotoDelete;

  // Custom Mode
  final Widget? customWidget;

  const DynamicDockState({
    this.mode = DynamicDockMode.navigation,
    this.isVisible = true,
    this.isScrolled = false,
    this.selectionCount = 0,
    this.selectionTitle,
    this.selectionActions = const [],
    this.onSelectionCancel,
    this.commentsPostId,
    this.onCommentCountChanged,
    this.commentPlaceholder = 'Write a comment...',
    this.initialCommentText,
    this.onCommentSend,
    this.onCommentClose,
    this.onNewChatClose,
    this.sharePostId,
    this.onShareClose,
    this.onEmojiSelected,
    this.emojiInitialCategory = EmojiCategory.system,
    this.emojiTitle,
    this.onEmojiClose,
    this.reactionActiveEmoji,
    this.onReactionSelected,
    this.onReactionRemoved,
    this.onReactionClose,
    this.onPhotoEdit,
    this.onPhotoShare,
    this.onPhotoPost,
    this.onPhotoDelete,
    this.isPopoutOpen = false,
    this.popoutItems = const [],
    this.customWidget,
  });

  DynamicDockState copyWith({
    DynamicDockMode? mode,
    bool? isVisible,
    bool? isScrolled,
    int? selectionCount,
    String? selectionTitle,
    List<DynamicDockAction>? selectionActions,
    VoidCallback? onSelectionCancel,
    String? commentsPostId,
    ValueChanged<int>? onCommentCountChanged,
    String? commentPlaceholder,
    String? initialCommentText,
    void Function(String text)? onCommentSend,
    VoidCallback? onCommentClose,
    VoidCallback? onNewChatClose,
    String? sharePostId,
    VoidCallback? onShareClose,
    ValueChanged<BubbleEmoji>? onEmojiSelected,
    EmojiCategory? emojiInitialCategory,
    String? emojiTitle,
    VoidCallback? onEmojiClose,
    String? reactionActiveEmoji,
    ValueChanged<String>? onReactionSelected,
    VoidCallback? onReactionRemoved,
    VoidCallback? onReactionClose,
    bool? isPopoutOpen,
    List<DynamicDockPopoutItem>? popoutItems,
    Widget? customWidget,
  }) {
    return DynamicDockState(
      mode: mode ?? this.mode,
      isVisible: isVisible ?? this.isVisible,
      isScrolled: isScrolled ?? this.isScrolled,
      selectionCount: selectionCount ?? this.selectionCount,
      selectionTitle: selectionTitle ?? this.selectionTitle,
      selectionActions: selectionActions ?? this.selectionActions,
      onSelectionCancel: onSelectionCancel ?? this.onSelectionCancel,
      commentsPostId: commentsPostId ?? this.commentsPostId,
      onCommentCountChanged: onCommentCountChanged ?? this.onCommentCountChanged,
      commentPlaceholder: commentPlaceholder ?? this.commentPlaceholder,
      initialCommentText: initialCommentText ?? this.initialCommentText,
      onCommentSend: onCommentSend ?? this.onCommentSend,
      onCommentClose: onCommentClose ?? this.onCommentClose,
      onNewChatClose: onNewChatClose ?? this.onNewChatClose,
      sharePostId: sharePostId ?? this.sharePostId,
      onShareClose: onShareClose ?? this.onShareClose,
      onEmojiSelected: onEmojiSelected ?? this.onEmojiSelected,
      emojiInitialCategory: emojiInitialCategory ?? this.emojiInitialCategory,
      emojiTitle: emojiTitle ?? this.emojiTitle,
      onEmojiClose: onEmojiClose ?? this.onEmojiClose,
      reactionActiveEmoji: reactionActiveEmoji ?? this.reactionActiveEmoji,
      onReactionSelected: onReactionSelected ?? this.onReactionSelected,
      onReactionRemoved: onReactionRemoved ?? this.onReactionRemoved,
      onReactionClose: onReactionClose ?? this.onReactionClose,
      isPopoutOpen: isPopoutOpen ?? this.isPopoutOpen,
      popoutItems: popoutItems ?? this.popoutItems,
      customWidget: customWidget ?? this.customWidget,
    );
  }
}

/// Controller / Notifier for the Dynamic Dock
class DynamicDockNotifier extends Notifier<DynamicDockState> {
  @override
  DynamicDockState build() {
    return const DynamicDockState();
  }

  /// Reset to standard navigation dock
  void resetToNavigation() {
    state = DynamicDockState(isScrolled: state.isScrolled);
  }

  /// Set whether the active screen is scrolled down
  void setScrolled(bool scrolled) {
    if (state.isScrolled != scrolled) {
      state = state.copyWith(isScrolled: scrolled);
    }
  }

  /// Open full morphing comments panel inside the dock
  void openComments({
    required String postId,
    ValueChanged<int>? onCommentCountChanged,
    String? initialText,
    VoidCallback? onClose,
  }) {
    state = DynamicDockState(
      mode: DynamicDockMode.comments,
      isScrolled: state.isScrolled,
      commentsPostId: postId,
      onCommentCountChanged: onCommentCountChanged,
      initialCommentText: initialText,
      onCommentClose: onClose,
    );
  }

  /// Close comments panel and morph back to navigation
  void closeComments() {
    if (state.mode == DynamicDockMode.comments) {
      state.onCommentClose?.call();
      resetToNavigation();
    }
  }

  /// Open full morphing new chat picker panel inside the dock
  void openNewChat({
    VoidCallback? onClose,
  }) {
    state = DynamicDockState(
      mode: DynamicDockMode.newChat,
      isScrolled: state.isScrolled,
      onNewChatClose: onClose,
    );
  }

  /// Close new chat panel and morph back to navigation
  void closeNewChat() {
    if (state.mode == DynamicDockMode.newChat) {
      state.onNewChatClose?.call();
      resetToNavigation();
    }
  }

  /// Open full morphing share panel inside the dock
  void openShare({
    required String postId,
    VoidCallback? onClose,
  }) {
    state = DynamicDockState(
      mode: DynamicDockMode.share,
      isScrolled: state.isScrolled,
      sharePostId: postId,
      onShareClose: onClose,
    );
  }

  /// Close share panel and morph back to navigation
  void closeShare() {
    if (state.mode == DynamicDockMode.share) {
      state.onShareClose?.call();
      resetToNavigation();
    }
  }

  /// Open full morphing emoji picker panel inside the dock
  void openEmojiPicker({
    required ValueChanged<BubbleEmoji> onEmojiSelected,
    EmojiCategory initialCategory = EmojiCategory.system,
    String? title,
    VoidCallback? onClose,
  }) {
    state = DynamicDockState(
      mode: DynamicDockMode.emojiPicker,
      isScrolled: state.isScrolled,
      onEmojiSelected: onEmojiSelected,
      emojiInitialCategory: initialCategory,
      emojiTitle: title,
      onEmojiClose: onClose,
    );
  }

  /// Close emoji picker panel and morph back to navigation
  void closeEmojiPicker() {
    if (state.mode == DynamicDockMode.emojiPicker) {
      state.onEmojiClose?.call();
      resetToNavigation();
    }
  }

  /// Apply a picker selection and always dismiss the picker back to navigation.
  /// Resetting in `finally` prevents a callback failure from leaving the dock
  /// stuck in emoji-selection mode or keeping its pop-out actions visible.
  void completeEmojiSelection(BubbleEmoji emoji) {
    final onSelected = state.mode == DynamicDockMode.emojiPicker
        ? state.onEmojiSelected
        : null;
    try {
      onSelected?.call(emoji);
    } finally {
      resetToNavigation();
    }
  }

  /// Open quick morphing reaction bar inside the dock
  void openReactionBar({
    required ValueChanged<String> onReact,
    VoidCallback? onRemoveReaction,
    String? activeEmoji,
    VoidCallback? onClose,
  }) {
    state = DynamicDockState(
      mode: DynamicDockMode.reactionBar,
      isScrolled: state.isScrolled,
      onReactionSelected: onReact,
      onReactionRemoved: onRemoveReaction,
      reactionActiveEmoji: activeEmoji,
      onReactionClose: onClose,
    );
  }

  /// Close reaction bar and morph back to navigation
  void closeReactionBar() {
    if (state.mode == DynamicDockMode.reactionBar) {
      state.onReactionClose?.call();
      resetToNavigation();
    }
  }

  /// Switch to multi-selection mode with custom actions
  void setSelectionMode({
    required int count,
    String? title,
    required List<DynamicDockAction> actions,
    required VoidCallback onCancel,
    List<DynamicDockPopoutItem>? popouts,
  }) {
    state = DynamicDockState(
      mode: DynamicDockMode.selection,
      isScrolled: state.isScrolled,
      selectionCount: count,
      selectionTitle: title,
      selectionActions: actions,
      onSelectionCancel: onCancel,
      popoutItems: popouts ?? const [],
      isPopoutOpen: false,
    );
  }

  /// Update just the selected count in selection mode
  void updateSelectionCount(int count) {
    if (state.mode == DynamicDockMode.selection) {
      if (count <= 0) {
        state.onSelectionCancel?.call();
        resetToNavigation();
      } else {
        state = state.copyWith(selectionCount: count);
      }
    }
  }

  /// Switch to Quick Comment / Reply mode
  void setQuickCommentMode({
    String placeholder = 'Write a comment...',
    String? initialText,
    required void Function(String text) onSend,
    VoidCallback? onClose,
    List<DynamicDockPopoutItem>? popouts,
  }) {
    state = DynamicDockState(
      mode: DynamicDockMode.quickComment,
      isScrolled: state.isScrolled,
      commentPlaceholder: placeholder,
      initialCommentText: initialText,
      onCommentSend: onSend,
      onCommentClose: onClose,
      popoutItems: popouts ?? const [],
      isPopoutOpen: false,
    );
  }

  /// Switch to custom mode
  void setCustomMode({
    required Widget widget,
    List<DynamicDockPopoutItem>? popouts,
  }) {
    state = DynamicDockState(
      mode: DynamicDockMode.custom,
      isScrolled: state.isScrolled,
      customWidget: widget,
      popoutItems: popouts ?? const [],
      isPopoutOpen: false,
    );
  }

  /// Switch to Photo Viewer toolbar mode (Edit, Share, Post, Delete)
  void setPhotoViewerMode({
    required VoidCallback onEdit,
    required VoidCallback onShare,
    required VoidCallback onPost,
    required VoidCallback onDelete,
  }) {
    state = DynamicDockState(
      mode: DynamicDockMode.photoViewer,
      isScrolled: false,
      onPhotoEdit: onEdit,
      onPhotoShare: onShare,
      onPhotoPost: onPost,
      onPhotoDelete: onDelete,
    );
  }

  /// Toggle pop-out tools menu above the dock
  void togglePopout() {
    state = state.copyWith(isPopoutOpen: !state.isPopoutOpen);
  }

  /// Close pop-out menu
  void closePopout() {
    if (state.isPopoutOpen) {
      state = state.copyWith(isPopoutOpen: false);
    }
  }

  /// Hide the dock (e.g. full-screen media)
  void hide() {
    state = state.copyWith(isVisible: false);
  }

  /// Show the dock
  void show() {
    state = state.copyWith(isVisible: true);
  }

  /// Append text to comment input
  void appendCommentText(String text) {
    if (state.mode == DynamicDockMode.quickComment || state.mode == DynamicDockMode.comments) {
      final current = state.initialCommentText ?? '';
      final separator = (current.isNotEmpty && !current.endsWith(' ')) ? ' ' : '';
      state = state.copyWith(initialCommentText: '$current$separator$text');
    }
  }

  /// Set exact comment text
  void setCommentText(String text) {
    if (state.mode == DynamicDockMode.quickComment || state.mode == DynamicDockMode.comments) {
      state = state.copyWith(initialCommentText: text);
    }
  }
}

final dynamicDockProvider = NotifierProvider<DynamicDockNotifier, DynamicDockState>(
  () => DynamicDockNotifier(),
);
