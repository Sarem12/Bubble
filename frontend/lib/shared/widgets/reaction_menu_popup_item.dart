import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/utils/safe_haptics.dart';
import '../../features/profile/presentation/controllers/settings_controller.dart';
import '../emoji/emoji.dart';

class ReactionMenuPopupItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> post;
  final Function(String) onReact;
  final VoidCallback onRemoveReaction;

  const ReactionMenuPopupItem({
    super.key,
    required this.post,
    required this.onReact,
    required this.onRemoveReaction,
  });

  @override
  ConsumerState<ReactionMenuPopupItem> createState() =>
      _ReactionMenuPopupItemState();
}

class _ReactionMenuPopupItemState extends ConsumerState<ReactionMenuPopupItem> {
  @override
  Widget build(BuildContext context) {
    final activeEmoji = widget.post['user_emoji'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final configuredReactions = ref
        .watch(settingsControllerProvider)
        .value
        ?.topReactions;
    final topEmojis = configuredReactions == null || configuredReactions.isEmpty
        ? const ['❤️', '😂', '🔥', '👍', '😮']
        : configuredReactions;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1C1C1C).withValues(alpha: 0.92),
                        const Color(0xFF101010).withValues(alpha: 0.88),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.92),
                        const Color(0xFFF8F9FA).withValues(alpha: 0.88),
                      ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.09),
                width: 1.2,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...topEmojis.map((emoji) {
                    final isActive = activeEmoji == emoji;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: GestureDetector(
                        onTap: () {
                          SafeHaptics.lightImpact();
                          Navigator.of(context).pop();
                          if (isActive) {
                            widget.onRemoveReaction();
                          } else {
                            widget.onReact(emoji);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark
                                      ? Colors.white.withValues(alpha: 0.20)
                                      : Colors.black.withValues(alpha: 0.10))
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: isActive
                                ? Border.all(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: AppEmoji(
                            emoji: emoji,
                            size: 24,
                            animate: true,
                            enableTapAnimation: true,
                          ),
                        ),
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: GestureDetector(
                      onTap: () {
                        SafeHaptics.selectionClick();
                        Navigator.of(context).pop();
                        BubbleEmojiPicker.showModal(
                          context,
                          initialCategory: EmojiCategory.system,
                          onEmojiSelected: (BubbleEmoji emoji) {
                            if (widget.post['user_emoji'] == emoji.code) {
                              widget.onRemoveReaction();
                            } else {
                              widget.onReact(emoji.code);
                            }
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReactionMenuPopupEntry extends PopupMenuEntry<String> {
  final Map<String, dynamic> post;
  final Function(String) onReact;
  final VoidCallback onRemoveReaction;

  const ReactionMenuPopupEntry({
    super.key,
    required this.post,
    required this.onReact,
    required this.onRemoveReaction,
  });

  @override
  double get height => 50.0;

  @override
  bool represents(String? value) => false;

  @override
  State<ReactionMenuPopupEntry> createState() => _ReactionMenuPopupEntryState();
}

class _ReactionMenuPopupEntryState extends State<ReactionMenuPopupEntry> {
  @override
  Widget build(BuildContext context) {
    return ReactionMenuPopupItem(
      post: widget.post,
      onReact: widget.onReact,
      onRemoveReaction: widget.onRemoveReaction,
    );
  }
}
