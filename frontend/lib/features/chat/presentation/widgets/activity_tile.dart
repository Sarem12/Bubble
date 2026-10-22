import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/safe_haptics.dart';
import '../../../../core/utils/date_helpers.dart';
import '../../../../core/utils/media_helpers.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../domain/entities/activity_item.dart';
import '../../../../shared/emoji/emoji.dart';

class ActivityTile extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback? onAcceptFriend;
  final VoidCallback? onDeclineFriend;

  const ActivityTile({
    super.key,
    required this.activity,
    this.onAcceptFriend,
    this.onDeclineFriend,
  });

  String _formatEmoji(String? emoji) => SystemEmojiRegistry.toDisplayChar(emoji);

  String _truncate(String? text, int maxLength) {
    if (text == null) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final emojiChar = _formatEmoji(activity.emoji);

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          SafeHaptics.lightImpact();
          if (activity.postId != null && activity.postId!.isNotEmpty) {
            context.push('/post/${activity.postId}');
          } else if (activity.actorId.isNotEmpty) {
            context.push('/user/${activity.actorId}');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatarWithBadge(context, emojiChar),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style.copyWith(
                        fontSize: 14,
                        height: 1.3,
                        color: LiquidGlassTheme.textPrimary(context),
                      ),
                      children: [
                        TextSpan(
                          text: activity.actorUsername,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: LiquidGlassTheme.textPrimary(context),
                          ),
                        ),
                        TextSpan(
                          text: ' ${_buildActionText(emojiChar)}',
                          style: TextStyle(
                            color: LiquidGlassTheme.textPrimary(context),
                          ),
                        ),
                        TextSpan(
                          text: '  ${DateHelpers.formatTimeAgo(activity.createdAt.toIso8601String())}',
                          style: TextStyle(
                            color: LiquidGlassTheme.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activity.type == 'friend_request' && onAcceptFriend != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        LiquidGlassButton(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          label: 'Confirm',
                          isPrimary: true,
                          onPressed: onAcceptFriend,
                        ),
                        if (onDeclineFriend != null)
                          LiquidGlassButton(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            label: 'Delete',
                            isPrimary: false,
                            onPressed: onDeclineFriend,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTrailing(context),
          ],
        ),
      ),
    ));
  }

  Widget _buildAvatarWithBadge(BuildContext context, String emojiChar) {
    Widget badgeContent;
    Color badgeColor;

    switch (activity.type) {
      case 'post_reaction':
      case 'reply_reaction':
        badgeColor = Colors.redAccent.withValues(alpha: 0.15);
        badgeContent = AppEmoji(
          emoji: activity.emoji ?? emojiChar,
          size: 13,
          animate: true,
        );
        break;
      case 'post_reply':
      case 'comment_reply':
        badgeColor = const Color(0xFF8B5CF6);
        badgeContent = const Icon(PhosphorIconsFill.chatCircleDots, size: 10, color: Colors.white);
        break;
      case 'friend_request':
        badgeColor = Colors.green;
        badgeContent = const Icon(PhosphorIconsBold.userPlus, size: 10, color: Colors.white);
        break;
      case 'friend_accepted':
        badgeColor = Colors.purple;
        badgeContent = const Icon(PhosphorIconsBold.userCheck, size: 10, color: Colors.white);
        break;
      default:
        badgeColor = Colors.grey;
        badgeContent = const Icon(PhosphorIconsBold.bell, size: 10, color: Colors.white);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            if (activity.actorId.isEmpty) return;
            SafeHaptics.lightImpact();
            context.push('/user/${activity.actorId}');
          },
          child: UserAvatar(imageUrl: activity.actorAvatar, radius: 22),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
            ),
            alignment: Alignment.center,
            child: badgeContent,
          ),
        ),
      ],
    );
  }

  String _buildActionText(String emojiChar) {
    switch (activity.type) {
      case 'post_reaction':
        return 'reacted $emojiChar to your post.';
      case 'post_reply':
        if (activity.replyContent != null && activity.replyContent!.isNotEmpty) {
          return 'commented: "${_truncate(activity.replyContent, 35)}"';
        }
        return 'commented on your post.';
      case 'comment_reply':
        if (activity.replyContent != null && activity.replyContent!.isNotEmpty) {
          return 'replied: "${_truncate(activity.replyContent, 35)}"';
        }
        return 'replied to your comment.';
      case 'reply_reaction':
        return 'reacted $emojiChar to your comment.';
      case 'friend_request':
        return 'sent you a friend request.';
      case 'friend_accepted':
        return 'accepted your friend request.';
      default:
        return 'interacted with your content.';
    }
  }

  Widget _buildTrailing(BuildContext context) {
    if (activity.type == 'friend_request') {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (activity.postMediaUrl != null && activity.postMediaUrl!.isNotEmpty) {
      final resolvedUrl = MediaHelpers.resolveUrl(activity.postMediaUrl!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(
              color: LiquidGlassTheme.specularBorderColor(context),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(
              resolvedUrl,
              fit: BoxFit.cover,
              cacheWidth: 120,
              cacheHeight: 120,
              errorBuilder: (_, _, _) => Icon(
                PhosphorIconsRegular.image,
                size: 20,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    if (activity.postContent != null && activity.postContent!.isNotEmpty) {
      return LiquidGlassContainer(
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(5),
        borderRadius: BorderRadius.circular(10),
        hasBlur: false,
        child: Center(
          child: Text(
            activity.postContent!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: LiquidGlassTheme.textPrimary(context),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
