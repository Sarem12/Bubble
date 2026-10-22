import 'package:flutter/material.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../domain/entities/friendship.dart';

class ProfileFriendsTab extends StatelessWidget {
  final List<dynamic> friends;
  final bool isLoading;
  final String emptyMessage;
  final ValueChanged<String>? onFriendTap;

  const ProfileFriendsTab({
    super.key,
    required this.friends,
    this.isLoading = false,
    this.emptyMessage = 'No friends yet.',
    this.onFriendTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friends.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: LiquidGlassTheme.textSecondary(context)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final f = friends[index];
        final String friendUsername;
        final String friendDisplayName;
        final String friendId;
        final String friendAvatar;

        if (f is FriendUser) {
          friendId = f.id;
          friendUsername = f.username;
          friendDisplayName = f.displayName;
          friendAvatar = f.profilePictureUrl;
        } else if (f is Map) {
          friendId = (f['friend_id'] ?? f['target_user_id'] ?? f['user_id'] ?? f['id'] ?? '').toString();
          friendUsername = (f['friend_username'] ?? f['username'] ?? 'User').toString();
          final first = (f['friend_first_name'] ?? f['first_name'] ?? '').toString();
          final last = (f['friend_last_name'] ?? f['last_name'] ?? '').toString();
          final full = '$first $last'.trim();
          friendDisplayName = full.isNotEmpty ? full : friendUsername;
          friendAvatar = (f['friend_avatar'] ?? f['friend_profile_picture_url'] ?? f['profile_picture_url'] ?? f['avatar'] ?? '').toString();
        } else {
          friendId = '';
          friendUsername = 'User';
          friendDisplayName = 'User';
          friendAvatar = '';
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: LiquidGlassContainer(
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onTap: () {
              if (friendId.isNotEmpty && onFriendTap != null) {
                onFriendTap!(friendId);
              }
            },
            child: Row(
              children: [
                UserAvatar(imageUrl: friendAvatar, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        friendDisplayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: LiquidGlassTheme.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (friendUsername.isNotEmpty && friendDisplayName != friendUsername) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@$friendUsername',
                          style: TextStyle(
                            fontSize: 12,
                            color: LiquidGlassTheme.textSecondary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

