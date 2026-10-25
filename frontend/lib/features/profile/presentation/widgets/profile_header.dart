import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/user_profile.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile user;
  final bool isMe;
  final bool isFriend;
  final VoidCallback? onEditProfile;
  final VoidCallback? onToggleFriend;
  final VoidCallback? onMessage;

  const ProfileHeader({
    super.key,
    required this.user,
    this.isMe = false,
    this.isFriend = false,
    this.onEditProfile,
    this.onToggleFriend,
    this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroTag = isMe ? 'my_profile_avatar' : 'user_avatar_${user.id}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        children: [
          // Avatar with liquid reflection ring
          GestureDetector(
            onTap: isMe ? onEditProfile : null,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: UserAvatar(
                    radius: 46,
                    imageUrl: user.profilePictureUrl,
                    heroTag: heroTag,
                  ),
                ),
                if (isMe)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LiquidGlassTheme.bubbleBlueGradient,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        PhosphorIconsFill.pencilSimple,
                        size: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Full Name
          Text(
            user.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: LiquidGlassTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 2),

          // Username handle
          Text(
            '@${user.username}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LiquidGlassTheme.textSecondary(context),
              fontSize: 13,
            ),
          ),

          // Bio
          if (user.bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              user.bio,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: LiquidGlassTheme.textPrimary(
                  context,
                ).withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),

          // Action Buttons
          if (isMe)
            Row(
              children: [
                Expanded(
                  child: LiquidGlassButton(
                    height: 40,
                    isPrimary: false,
                    onPressed: onEditProfile,
                    label: 'Edit Profile',
                    icon: Icon(
                      PhosphorIconsRegular.userGear,
                      size: 16,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LiquidGlassButton(
                    height: 40,
                    isPrimary: false,
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: 'Check out @${user.username} on Bubble!',
                        ),
                      );
                    },
                    label: 'Share Profile',
                    icon: Icon(
                      PhosphorIconsRegular.shareNetwork,
                      size: 16,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: LiquidGlassButton(
                    height: 40,
                    label: isFriend ? 'Remove Friend' : 'Add Friend',
                    isPrimary: !isFriend,
                    icon: Icon(
                      isFriend
                          ? PhosphorIconsRegular.userMinus
                          : PhosphorIconsRegular.userPlus,
                      size: 16,
                      color: isFriend
                          ? Colors.redAccent
                          : LiquidGlassTheme.textPrimary(context),
                    ),
                    onPressed: onToggleFriend,
                  ),
                ),
                if (onMessage != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: LiquidGlassButton(
                      height: 40,
                      isPrimary: false,
                      label: 'Message',
                      icon: Icon(
                        PhosphorIconsRegular.chatCircleText,
                        size: 16,
                        color: LiquidGlassTheme.textPrimary(context),
                      ),
                      onPressed: onMessage,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
