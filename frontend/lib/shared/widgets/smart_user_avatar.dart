import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_cache_provider.dart';
import 'user_avatar.dart';

class SmartUserAvatar extends ConsumerWidget {
  final String userId;
  final double radius;
  final bool showUsername;
  final bool useDisplayName;
  final TextStyle? usernameStyle;
  final Axis direction;
  final String? heroTag;
  final VoidCallback? onTap;
  final bool enableNavigation;

  const SmartUserAvatar({
    super.key,
    required this.userId,
    this.radius = 20,
    this.showUsername = false,
    this.useDisplayName = false,
    this.usernameStyle,
    this.direction = Axis.horizontal,
    this.heroTag,
    this.onTap,
    this.enableNavigation = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userCacheProvider(userId));

    final child = userAsync.when(
      data: (user) {
        if (!showUsername) {
          return UserAvatar(
            imageUrl: user.profilePictureUrl,
            radius: radius,
            heroTag: heroTag,
          );
        }
        final nameToShow = useDisplayName ? user.displayName : user.username;
        
        if (direction == Axis.vertical) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(
                imageUrl: user.profilePictureUrl,
                radius: radius,
                heroTag: heroTag,
              ),
              const SizedBox(height: 6),
              Text(
                nameToShow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: usernameStyle ?? const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              imageUrl: user.profilePictureUrl,
              radius: radius,
              heroTag: heroTag,
            ),
            const SizedBox(width: 8),
            Text(nameToShow, style: usernameStyle ?? const TextStyle(fontWeight: FontWeight.bold)),
          ],
        );
      },
      loading: () {
        if (!showUsername) {
          return UserAvatar(radius: radius); // Placeholder
        }
        if (direction == Axis.vertical) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(radius: radius),
              const SizedBox(height: 6),
              Container(
                width: 44,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(radius: radius),
            const SizedBox(width: 8),
            const SizedBox(width: 50, height: 10, child: LinearProgressIndicator()),
          ],
        );
      },
      error: (_, _) {
        if (!showUsername) {
          return UserAvatar(radius: radius); // Placeholder
        }
        if (direction == Axis.vertical) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UserAvatar(radius: radius),
              const SizedBox(height: 6),
              Text('Unknown', style: usernameStyle),
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(radius: radius),
            const SizedBox(width: 8),
            Text('Unknown', style: usernameStyle),
          ],
        );
      },
    );

    if (onTap != null || enableNavigation) {
      return GestureDetector(
        onTap: onTap ??
            () {
              if (userId.isNotEmpty) {
                context.push('/user/$userId');
              }
            },
        child: child,
      );
    }

    return child;
  }
}
