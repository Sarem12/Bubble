import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../emoji/emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../core/utils/ui_helpers.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/media_helpers.dart';
import '../../features/home/presentation/controllers/feed_controller.dart';
import '../providers/dynamic_dock_provider.dart';
import 'user_avatar.dart';
import 'liquid_glass.dart';
import '../../features/profile/presentation/controllers/settings_controller.dart';

import '../../features/home/domain/entities/post.dart';
import '../../features/home/data/repositories/post_repository_impl.dart';

class PostCard extends ConsumerStatefulWidget {
  final dynamic post;
  final VoidCallback? onReactionChanged;
  final bool isFullScreen;
  final void Function(double)? onVisibilityChanged;

  const PostCard({
    super.key, 
    required this.post, 
    this.onReactionChanged,
    this.isFullScreen = false,
    this.onVisibilityChanged,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> with SingleTickerProviderStateMixin {
  late Map<String, dynamic> _currentPost;
  String? _optimisticReaction;
  bool _isOptimistic = false;
  int _currentImageIndex = 0;

  static Map<String, dynamic> _extractMap(dynamic source) {
    if (source is FeedItem) return source.toJson();
    if (source is Map<String, dynamic>) return Map.from(source);
    if (source is Map) return Map<String, dynamic>.from(source);
    return {};
  }

  late AnimationController _burstAnimationController;
  bool _showReactionBurst = false;
  String _burstEmoji = '❤️';
  String? _recentlyReactedEmoji;
  Timer? _reactionAnimTimer;

  @override
  void initState() {
    super.initState();
    _currentPost = _extractMap(widget.post);
    _burstAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _showReactionBurst = false;
              _recentlyReactedEmoji = null;
            });
          }
        }
      });
  }

  @override
  void dispose() {
    _reactionAnimTimer?.cancel();
    _burstAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _currentPost = _extractMap(widget.post);
      _isOptimistic = false;
    }
  }

  void _triggerReactionAnimation(String emoji) {
    _reactionAnimTimer?.cancel();
    if (mounted) {
      setState(() {
        _showReactionBurst = true;
        _burstEmoji = emoji;
        _recentlyReactedEmoji = emoji;
      });
    }
    _burstAnimationController.forward(from: 0.0);
    _reactionAnimTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _recentlyReactedEmoji = null;
        });
      }
    });
  }

  Future<void> _handleReaction(String emoji) async {
    final postId = _currentPost['id'];
    
    _triggerReactionAnimation(emoji);

    setState(() {
      _isOptimistic = true;
      _optimisticReaction = emoji;
    });

    try {
      await ref.read(postRepositoryProvider).reactToPost(postId, emojiType: emoji);
      ref.read(feedControllerProvider.notifier).updatePostReaction(postId, emoji);
      widget.onReactionChanged?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOptimistic = false;
          _optimisticReaction = null;
          _recentlyReactedEmoji = null;
        });
        String errorMsg = "Failed to react.";
        if (e is DioException) {
          errorMsg = "Failed to react: ${e.response?.data?['error'] ?? e.message}";
        }
        UiHelpers.showError(context, errorMsg);
      }
    }
  }

  Future<void> _removeReaction() async {
    final postId = _currentPost['id'];
    _reactionAnimTimer?.cancel();
    _burstAnimationController.stop();
    setState(() {
      _isOptimistic = true;
      _optimisticReaction = null;
      _recentlyReactedEmoji = null;
      _showReactionBurst = false;
    });

    try {
      await ref.read(postRepositoryProvider).removeReaction(postId);
      ref.read(feedControllerProvider.notifier).updatePostReaction(postId, null);
      widget.onReactionChanged?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOptimistic = false;
        });
        String errorMsg = "Failed to remove reaction.";
        if (e is DioException) {
          errorMsg = "Failed to react: ${e.response?.data?['error'] ?? e.message}";
        }
        UiHelpers.showError(context, errorMsg);
      }
    }
  }

  void _triggerDoubleTapReaction() {
    final configuredReaction = ref.read(doubleTapReactionProvider);
    if (configuredReaction == 'none') return;

    final activeEmoji = _isOptimistic ? _optimisticReaction : _currentPost['user_emoji'];
    if (activeEmoji == configuredReaction) {
      _removeReaction();
    } else {
      _handleReaction(configuredReaction);
    }
  }

  Widget _buildBurstOverlay() {
    if (!_showReactionBurst) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _burstAnimationController,
            builder: (context, child) {
              final scale = TweenSequence<double>([
                TweenSequenceItem(
                  tween: Tween(begin: 0.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutBack)),
                  weight: 35,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 1.35, end: 1.05).chain(CurveTween(curve: Curves.easeInOut)),
                  weight: 40,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 1.05, end: 0.0).chain(CurveTween(curve: Curves.easeInBack)),
                  weight: 25,
                ),
              ]).evaluate(_burstAnimationController);

              final opacity = TweenSequence<double>([
                TweenSequenceItem(
                  tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
                  weight: 20,
                ),
                TweenSequenceItem(
                  tween: ConstantTween(1.0),
                  weight: 55,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
                  weight: 25,
                ),
              ]).evaluate(_burstAnimationController);

              final translateY = TweenSequence<double>([
                TweenSequenceItem(
                  tween: Tween(begin: 24.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutBack)),
                  weight: 35,
                ),
                TweenSequenceItem(
                  tween: Tween(begin: 0.0, end: -36.0).chain(CurveTween(curve: Curves.easeOutQuad)),
                  weight: 65,
                ),
              ]).evaluate(_burstAnimationController);

              return Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: AppEmoji(
                        emoji: _burstEmoji,
                        size: 92,
                        animate: true,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  
  bool _saveBounce = false;

  Future<void> _toggleSave() async {
    SafeHaptics.mediumImpact();
    final willSave = !(_currentPost['is_saved'] == true);
    setState(() {
      _currentPost['is_saved'] = willSave;
      _saveBounce = true;
    });
    Future.delayed(const Duration(milliseconds: 240), () {
      if (mounted) {
        setState(() => _saveBounce = false);
      }
    });

    try {
      await ref.read(postRepositoryProvider).savePost(_currentPost['id'], willSave);
      ref.read(feedControllerProvider.notifier).updatePostSaved(_currentPost['id'], willSave);
      if (!mounted) return;
      UiHelpers.showSuccess(
        context,
        willSave ? "Saved to collection" : "Removed from collection",
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentPost['is_saved'] = !willSave;
      });
      UiHelpers.showError(context, "Failed to update saved status.");
    }
  }
    
  void _onMenuSelected(String value) async {
    if (value == 'share') {
      _openShareDock();
    } else if (value == 'copy_link') {
      UiHelpers.showSuccess(context, "Link copied to clipboard");
    } else if (value == 'save') {
      _toggleSave();
    } else if (value == 'unfollow') {
      UiHelpers.showSuccess(context, "Unfollowed user");
    } else if (value == 'report') {
      try {
        await ref.read(postRepositoryProvider).reportPost(_currentPost['id']);
        if (!mounted) return;
        UiHelpers.showSuccess(context, "Post reported");
      } catch (e) {
        if (!mounted) return;
        UiHelpers.showError(context, "Failed to report post");
      }
    }
  }

  void _showLiquidGlassMenu() {
    final isSaved = _currentPost['is_saved'] == true;
    ref.read(dynamicDockProvider.notifier).setSelectionMode(
      count: 0,
      title: 'Post Options',
      onCancel: () {
        ref.read(dynamicDockProvider.notifier).resetToNavigation();
      },
      actions: [
        DynamicDockAction(
          icon: LucideIcons.smile,
          label: 'React',
          onTap: () {
            ref.read(dynamicDockProvider.notifier).openReactionBar(
              onReact: (emoji) {
                ref.read(dynamicDockProvider.notifier).closeReactionBar();
                _handleReaction(emoji);
              },
              onRemoveReaction: () {
                ref.read(dynamicDockProvider.notifier).closeReactionBar();
                _removeReaction();
              },
              activeEmoji: _currentPost['user_emoji'],
            );
          },
        ),
        DynamicDockAction(
          icon: LucideIcons.share,
          label: 'Share',
          onTap: () {
            _onMenuSelected('share');
          },
        ),
        DynamicDockAction(
          icon: LucideIcons.bookmark,
          label: isSaved ? 'Saved' : 'Save',
          onTap: () {
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
            _toggleSave();
          },
        ),
      ],
      popouts: [
        DynamicDockPopoutItem(
          icon: LucideIcons.copy,
          label: 'Copy Link',
          onTap: () {
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
            _onMenuSelected('copy_link');
          },
        ),
        DynamicDockPopoutItem(
          icon: LucideIcons.userMinus,
          label: 'Unfollow',
          onTap: () {
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
            _onMenuSelected('unfollow');
          },
        ),
        DynamicDockPopoutItem(
          icon: LucideIcons.flag,
          label: 'Report',
          iconColor: Colors.red,
          onTap: () {
            ref.read(dynamicDockProvider.notifier).resetToNavigation();
            _onMenuSelected('report');
          },
        ),
      ],
    );
  }

  void _openAuthorProfile() {
    final authorId = (_currentPost['author_id'] ?? _currentPost['user_id'] ?? _currentPost['author']?['id'] ?? _currentPost['author']?['_id'] ?? '').toString();
    if (authorId.isNotEmpty) {
      context.push('/user/$authorId');
    }
  }

  void _openPostDetail() {
    if (widget.isFullScreen) return;
    final postId = _currentPost['id']?.toString() ?? '';
    if (postId.isNotEmpty) {
      context.push('/post/$postId');
    }
  }

  void _openCommentsDock() {
    final postId = _currentPost['id']?.toString() ?? '';
    if (postId.isEmpty) return;

    SafeHaptics.lightImpact();
    ref.read(dynamicDockProvider.notifier).openComments(
      postId: postId,
      onCommentCountChanged: (count) {
        if (mounted) {
          setState(() {
            _currentPost['replies_count'] = count;
          });
        }
      },
    );
  }

  void _openShareDock() {
    final postId = _currentPost['id']?.toString() ?? '';
    if (postId.isEmpty) return;

    SafeHaptics.lightImpact();
    ref.read(dynamicDockProvider.notifier).openShare(
      postId: postId,
    );
  }


  
  @override
  Widget build(BuildContext context) {

    final mediaList = _currentPost['media'] as List?;
    final String? imageUrl = (mediaList != null && mediaList.isNotEmpty) ? mediaList[0]['url'] : null;
    
    final authorUsername = (_currentPost['author_username'] ?? _currentPost['username'] ?? 'User').toString();
    final authorFirstName = (_currentPost['author_first_name'] ?? _currentPost['first_name'] ?? '').toString();
    final authorLastName = (_currentPost['author_last_name'] ?? _currentPost['last_name'] ?? '').toString();
    final rawFullName = (_currentPost['author_full_name'] ?? _currentPost['full_name'] ?? '$authorFirstName $authorLastName').toString().trim();
    final author = rawFullName.isNotEmpty ? rawFullName : authorUsername;
    final authorPic = _currentPost['author_profile_picture_url'] ?? '';
    final rawBubbleName = (_currentPost['bubble_name'] ?? _currentPost['bubble']?['name'] ?? '').toString().trim();
    final bubbleType = (_currentPost['bubble_type'] ?? _currentPost['bubble']?['type'] ?? '').toString().toUpperCase();
    final isPersonal = bubbleType == 'PERSON' || rawBubbleName.isEmpty;
    final bubbleName = isPersonal ? '' : rawBubbleName;
    final content = _currentPost['content'] ?? '';
    final createdAt = DateTime.tryParse(_currentPost['created_at']?.toString() ?? '') ?? DateTime.now();
    
    final activeEmoji = _isOptimistic ? _optimisticReaction : _currentPost['user_emoji'];
    final reactions = _currentPost['reaction_counts'] as Map<String, dynamic>? ?? {};
    
    // Calculate optimistic counts
    Map<String, int> displayReactions = {};
    reactions.forEach((k, v) => displayReactions[k] = (v as num).toInt());
    
    if (_isOptimistic) {
      final oldEmoji = _currentPost['user_emoji'];
      if (oldEmoji != null && displayReactions.containsKey(oldEmoji)) {
        displayReactions[oldEmoji] = displayReactions[oldEmoji]! - 1;
        if (displayReactions[oldEmoji]! <= 0) displayReactions.remove(oldEmoji);
      }
      if (_optimisticReaction != null) {
        displayReactions[_optimisticReaction!] = (displayReactions[_optimisticReaction!] ?? 0) + 1;
      }
    }

    final hasAnyReaction = displayReactions.isNotEmpty;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget headerOverlay = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Author & Bubble pill - Liquid Glass Bubble Container
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.24),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.22),
                        ],
                        stops: const [0.0, 0.40, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.38),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _openAuthorProfile,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.60),
                                width: 1.2,
                              ),
                            ),
                            child: UserAvatar(
                              imageUrl: authorPic,
                              radius: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _openAuthorProfile,
                                child: Text(
                                  author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    shadows: [
                                      Shadow(color: Colors.black87, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                              if (bubbleName.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 3),
                                          child: const BubbleGlassIcon(
                                            icon: LucideIcons.bubbles,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                      TextSpan(
                                        text: bubbleName,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.90),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ] else if (rawFullName.isNotEmpty && rawFullName != authorUsername) ...[
                                Text(
                                  '@$authorUsername',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Menu Shower button - Circular Liquid Glass Bubble Button
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.24),
                        Colors.white.withValues(alpha: 0.08),
                        Colors.black.withValues(alpha: 0.22),
                      ],
                      stops: const [0.0, 0.40, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.38),
                      width: 1.1,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.ellipsis, color: Colors.white, size: 20),
                    onPressed: () {
                      SafeHaptics.selectionClick();
                      _showLiquidGlassMenu();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget headerNormal = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
      leading: GestureDetector(
        onTap: _openAuthorProfile,
        child: UserAvatar(
          imageUrl: authorPic,
          radius: 20,
        ),
      ),
      title: GestureDetector(
        onTap: _openAuthorProfile,
        child: Text(
          author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: LiquidGlassTheme.textPrimary(context),
          ),
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rawFullName.isNotEmpty && rawFullName != authorUsername)
            Text(
              '@$authorUsername',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: LiquidGlassTheme.textSecondary(context)),
            ),
          if (bubbleName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: const BubbleGlassIcon(icon: LucideIcons.bubbles, size: 13),
                      ),
                    ),
                    TextSpan(
                      text: 'in $bubbleName',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          LucideIcons.ellipsis,
          color: LiquidGlassTheme.textSecondary(context),
        ),
        onPressed: () {
          SafeHaptics.selectionClick();
          _showLiquidGlassMenu();
        },
      ),
    );

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mediaList != null && mediaList.isNotEmpty)
          if (mediaList.length > 1)
            SizedBox(
              height: widget.isFullScreen ? 450 : 400,
              width: double.infinity,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: mediaList.length,
                    onPageChanged: (idx) {
                      setState(() {
                        _currentImageIndex = idx;
                      });
                    },
                    itemBuilder: (context, idx) {
                      final itemUrl = mediaList[idx]['url']?.toString() ?? '';
                      return GestureDetector(
                        onTap: _openPostDetail,
                        onDoubleTap: _triggerDoubleTapReaction,
                        child: Image.network(
                          MediaHelpers.resolveUrl(itemUrl),
                          width: double.infinity,
                          height: double.infinity,
                          fit: widget.isFullScreen ? BoxFit.contain : BoxFit.cover,
                          cacheWidth: 1080,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[850],
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: headerOverlay,
                  ),
                  Positioned(
                    top: 56,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.24),
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.black.withValues(alpha: 0.22),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${mediaList.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        mediaList.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          width: _currentImageIndex == i ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: _currentImageIndex == i
                                ? LiquidGlassTheme.bubbleBlueGradient
                                : null,
                            color: _currentImageIndex == i
                                ? null
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: _currentImageIndex == i
                                ? [
                                    BoxShadow(
                                      color: LiquidGlassTheme.bubbleBlue.withValues(alpha: 0.18),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _openPostDetail,
              onDoubleTap: _triggerDoubleTapReaction,
              child: Stack(
                children: [
                  Hero(
                    tag: 'post_media_${_currentPost['id']}',
                    child: Image.network(
                      MediaHelpers.resolveUrl(imageUrl),
                      width: double.infinity,
                      height: widget.isFullScreen ? null : 400,
                      fit: widget.isFullScreen ? BoxFit.contain : BoxFit.cover,
                      cacheWidth: 1080,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: widget.isFullScreen ? 300 : 400,
                        color: Colors.grey[850],
                        child: const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: headerOverlay,
                  ),
                ],
              ),
            )
        else
          headerNormal,

        Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 2.0),
          child: Text(
            DateHelpers.formatTimeAgo(createdAt.toIso8601String()),
            style: TextStyle(
              color: LiquidGlassTheme.textSecondary(context),
              fontSize: 12,
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
          child: Text(
            content,
            style: TextStyle(
              fontSize: widget.isFullScreen ? 16 : 14,
              color: LiquidGlassTheme.textPrimary(context),
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: [
                    if (hasAnyReaction)
                      ...displayReactions.entries.map((e) {
                        final isRecentlyReacted = _recentlyReactedEmoji == e.key;
                        return GestureDetector(
                          onTap: () {
                            SafeHaptics.lightImpact();
                            if (activeEmoji == e.key) {
                              _removeReaction();
                            } else {
                              _handleReaction(e.key);
                            }
                          },
                          child: AnimatedScale(
                            scale: isRecentlyReacted ? 1.12 : 1.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutBack,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: activeEmoji == e.key
                                    ? (isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.10))
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.04)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: activeEmoji == e.key
                                      ? (isDark
                                          ? Colors.white.withValues(alpha: 0.35)
                                          : Colors.black.withValues(alpha: 0.25))
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : Colors.black.withValues(alpha: 0.06)),
                                  width: 1.1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppEmoji(
                                    emoji: e.key,
                                    size: 15,
                                    animate: isRecentlyReacted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${e.value}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: activeEmoji == e.key
                                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Comments action
              GestureDetector(
                onTap: _openCommentsDock,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.messageCircle,
                        size: 19,
                        color: LiquidGlassTheme.textSecondary(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_currentPost['replies_count'] ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: LiquidGlassTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Share action
              GestureDetector(
                onTap: _openShareDock,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Icon(
                    LucideIcons.share2,
                    size: 19,
                    color: LiquidGlassTheme.textSecondary(context),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Save action - Dynamic Bubble Bookmark with autofill system & haptic bounce
              GestureDetector(
                onTap: _toggleSave,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: AnimatedScale(
                    scale: _saveBounce ? 1.28 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: BubbleBookmarkIcon(
                      isSaved: _currentPost['is_saved'] == true,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!widget.isFullScreen)
          GestureDetector(
            onTap: _openCommentsDock,
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
              child: Builder(
                builder: (context) {
                  final repliesCount = (_currentPost['replies_count'] as num?)?.toInt() ?? 0;
                  final topComment = _currentPost['top_comment'] as Map<String, dynamic>?;

                  if (repliesCount <= 0) {
                    return Row(
                      children: [
                        Icon(LucideIcons.messageCircleMore, size: 16, color: LiquidGlassTheme.textSecondary(context)),
                        const SizedBox(width: 8),
                        Text(
                          "Add a comment...",
                          style: TextStyle(color: LiquidGlassTheme.textSecondary(context), fontSize: 13),
                        ),
                      ],
                    );
                  }

                  if (topComment != null && topComment['content'] != null) {
                    final topUser = topComment['username'] ?? 'User';
                    final topFirstName = topComment['first_name'] ?? '';
                    final topLastName = topComment['last_name'] ?? '';
                    final topFullName = '$topFirstName $topLastName'.trim();
                    final topDisplayName = topFullName.isNotEmpty ? topFullName : '@$topUser';
                    final topContent = topComment['content'] ?? '';
                    final topLikes = (topComment['likes_count'] as num?)?.toInt() ?? 0;
                    final topReplies = (topComment['replies_count'] as num?)?.toInt() ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.trendingUp, size: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            const SizedBox(width: 6),
                            Text(
                              "Top comments",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (repliesCount > 1) ...[
                              const SizedBox(width: 4),
                              Text(
                                "($repliesCount)",
                                style: TextStyle(fontSize: 11, color: LiquidGlassTheme.textSecondary(context)),
                              ),
                            ],
                            const Spacer(),
                            if (topLikes > 0 || topReplies > 0) ...[
                              if (topLikes > 0)
                                Text(
                                  '❤️ $topLikes',
                                  style: TextStyle(fontSize: 11, color: LiquidGlassTheme.textSecondary(context)),
                                ),
                              if (topLikes > 0 && topReplies > 0)
                                const SizedBox(width: 6),
                              if (topReplies > 0)
                                Text(
                                  '💬 $topReplies',
                                  style: TextStyle(fontSize: 11, color: LiquidGlassTheme.textSecondary(context)),
                                ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(fontSize: 13, color: LiquidGlassTheme.textPrimary(context)),
                            children: [
                              TextSpan(
                                text: '$topDisplayName  ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: topContent),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Icon(LucideIcons.trendingUp, size: 15, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      const SizedBox(width: 8),
                      Text(
                        "Top comments ($repliesCount)...",
                        style: TextStyle(color: LiquidGlassTheme.textPrimary(context), fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );

    Widget cardBody = GestureDetector(
      onDoubleTap: _triggerDoubleTapReaction,
      onLongPressStart: (details) {
        SafeHaptics.selectionClick();
        _showLiquidGlassMenu();
      },
      child: widget.isFullScreen
          ? Stack(
              children: [
                cardContent,
                _buildBurstOverlay(),
              ],
            )
          : Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  cardContent,
                  _buildBurstOverlay(),
                ],
              ),
            ),
    );

    if (widget.onVisibilityChanged != null) {
      cardBody = VisibilityDetector(
        key: Key('feed_post_${_currentPost['id']}'),
        onVisibilityChanged: (info) {
          widget.onVisibilityChanged!(info.visibleFraction);
        },
        child: cardBody,
      );
    }

    return RepaintBoundary(
      key: ValueKey('repaint_post_${_currentPost['id']}'),
      child: cardBody,
    );
  }
}
