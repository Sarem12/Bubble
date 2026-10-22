import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/routes.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/ui_helpers.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/home/domain/entities/comment.dart';
import '../../features/home/data/repositories/post_repository_impl.dart';
import 'user_avatar.dart';
import 'liquid_glass.dart';
import '../emoji/emoji.dart';

class CommentTreeNodeView extends StatelessWidget {
  final CommentNode node;
  final int depth;
  final String? currentUserId;
  final Set<String> collapsedIds;
  final ValueChanged<String> onToggleCollapse;
  final ValueChanged<CommentNode> onReply;
  final ValueChanged<String> onDelete;
  final void Function(String id, String newText) onEdit;
  final ValueChanged<String> onUserTap;
  final void Function(CommentNode node, String emoji)? onReact;
  final ValueChanged<CommentNode>? onRemoveReaction;

  const CommentTreeNodeView({
    super.key,
    required this.node,
    this.depth = 0,
    this.currentUserId,
    required this.collapsedIds,
    required this.onToggleCollapse,
    required this.onReply,
    required this.onDelete,
    required this.onEdit,
    required this.onUserTap,
    this.onReact,
    this.onRemoveReaction,
  });

  void _showReactionPicker(BuildContext context) {
    AnimatedReactionBar.showModal(
      context,
      activeEmoji: node.userEmoji,
      onReact: (emoji) => onReact?.call(node, emoji),
      onRemoveReaction: () => onRemoveReaction?.call(node),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: node.content);
    showBubbleDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Comment'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Update your comment...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty && newText != node.content) {
                Navigator.pop(ctx);
                onEdit(node.id, newText);
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final confirmed = await showBubbleConfirmDialog(
      context: context,
      title: 'Delete Comment',
      message: 'Are you sure you want to delete this comment?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      onDelete(node.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthor = currentUserId != null && currentUserId == node.userId;
    final isCollapsed = collapsedIds.contains(node.id);
    final hasChildren = node.children.isNotEmpty;

    String displayName = '';
    if (node.firstName.isNotEmpty || node.lastName.isNotEmpty) {
      displayName = '${node.firstName} ${node.lastName}'.trim();
    } else if (node.username.isNotEmpty && node.username != 'User') {
      displayName = node.username;
    } else {
      displayName = 'User';
    }

    final timeAgo = DateHelpers.formatTimeAgo(node.createdAt);
    final isRoot = depth == 0;
    final avatarRadius = isRoot ? 17.0 : (depth == 1 ? 14.0 : 12.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (node.userId.isNotEmpty) onUserTap(node.userId);
                },
                child: UserAvatar(
                  imageUrl: node.profilePictureUrl,
                  radius: avatarRadius,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              if (node.userId.isNotEmpty) onUserTap(node.userId);
                            },
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : const Color(0xFF111827),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (node.username.isNotEmpty &&
                                    node.username != 'User' &&
                                    displayName != node.username)
                                  Text(
                                    '@${node.username}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white54 : Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (timeAgo.isNotEmpty)
                          Text(
                            '· $timeAgo',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.grey[500],
                            ),
                          ),
                        const Spacer(),
                        if (isAuthor)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: Icon(Icons.more_horiz, color: isDark ? Colors.white38 : Colors.grey[500]),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _showEditDialog(context);
                              } else if (val == 'delete') {
                                _confirmDelete(context);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(fontSize: 13, color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (depth > 0 && node.parentUsername != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Replying to @${node.parentUsername}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      node.content,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.25,
                        color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (node.reactionCounts.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: node.reactionCounts.entries.map((e) {
                          final isSelected = node.userEmoji == e.key;
                          return GestureDetector(
                            onTap: () {
                              if (isSelected) {
                                onRemoveReaction?.call(node);
                              } else {
                                onReact?.call(node, e.key);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? (isDark ? Colors.white.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.10)) : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey[100]),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? (isDark ? Colors.white.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.25)) : (isDark ? Colors.white.withValues(alpha: 0.10) : Colors.grey[300]!),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppEmoji(emoji: e.key, size: 13, animate: false),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${e.value}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (node.userEmoji != null) {
                              onRemoveReaction?.call(node);
                            } else {
                              onReact?.call(node, '❤️');
                            }
                          },
                          onLongPress: () => _showReactionPicker(context),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                node.userEmoji != null
                                    ? AppEmoji(emoji: node.userEmoji!, size: 14, animate: false)
                                    : const Text(
                                        '🤍',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                const SizedBox(width: 4),
                                Text(
                                  node.likesCount > 0 ? '${node.likesCount}' : 'React',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: node.userEmoji != null
                                        ? Colors.redAccent
                                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => onReply(node),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.reply_rounded,
                                  size: 13,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Reply',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (hasChildren) ...[
                          const SizedBox(width: 14),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => onToggleCollapse(node.id),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCollapsed
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_up_rounded,
                                    size: 14,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    isCollapsed
                                        ? '${node.totalDescendants} ${node.totalDescendants == 1 ? 'reply' : 'replies'}'
                                        : 'Hide',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasChildren && !isCollapsed)
          Padding(
            padding: EdgeInsets.only(left: depth >= 3 ? 12.0 : 20.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(left: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: node.children.map((child) => CommentTreeNodeView(
                  node: child,
                  depth: depth + 1,
                  currentUserId: currentUserId,
                  collapsedIds: collapsedIds,
                  onToggleCollapse: onToggleCollapse,
                  onReply: onReply,
                  onDelete: onDelete,
                  onEdit: onEdit,
                  onUserTap: onUserTap,
                  onReact: onReact,
                  onRemoveReaction: onRemoveReaction,
                )).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class CommentBottomSheet extends ConsumerStatefulWidget {
  final String postId;
  final ValueChanged<int>? onCommentCountChanged;
  final VoidCallback? onClose;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    this.onCommentCountChanged,
    this.onClose,
  });

  static void show(
    BuildContext context,
    String postId, {
    ValueChanged<int>? onCommentCountChanged,
  }) {
    showBubbleModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.75,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: LiquidGlassTheme.glassShadows(sheetContext, blur: 24),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LiquidGlassTheme.glassGradient(sheetContext),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: CommentBottomSheet(
                    postId: postId,
                    onCommentCountChanged: onCommentCountChanged,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  ConsumerState<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<CommentBottomSheet> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<dynamic> _comments = [];
  List<CommentNode> _rootNodes = [];
  final Set<String> _collapsedIds = {};
  Map<String, dynamic>? _replyingTo;

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void didUpdateWidget(CommentBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.postId != widget.postId) {
      setState(() {
        _isLoading = true;
        _comments = [];
        _rootNodes = [];
        _replyingTo = null;
      });
      _fetchComments();
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final roots = await ref.read(postRepositoryProvider).getComments(widget.postId);
      if (mounted) {
        setState(() {
          _rootNodes = roots;
          _isLoading = false;
        });
        final totalCount = roots.fold<int>(0, (sum, n) => sum + 1 + n.totalDescendants);
        widget.onCommentCountChanged?.call(totalCount);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final parentId = _replyingTo?['id']?.toString();
      await ref.read(postRepositoryProvider).createComment(
        widget.postId,
        text,
        parentReplyId: parentId,
      );

      if (parentId != null) {
        _collapsedIds.remove(parentId);
      }

      _replyController.clear();
      setState(() {
        _replyingTo = null;
        _isSubmitting = false;
      });
      _focusNode.unfocus();
      await _fetchComments();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        UiHelpers.showError(context, "Failed to submit comment.");
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await ref.read(postRepositoryProvider).deleteComment(commentId);
      if (mounted) {
        UiHelpers.showSuccess(context, "Comment deleted.");
        _fetchComments();
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showError(context, "Failed to delete comment.");
      }
    }
  }

  Future<void> _editComment(String commentId, String newContent) async {
    try {
      await ref.read(postRepositoryProvider).updateComment(commentId, newContent);
      if (mounted) {
        UiHelpers.showSuccess(context, "Comment updated.");
        _fetchComments();
      }
    } catch (e) {
      if (mounted) {
        UiHelpers.showError(context, "Failed to update comment.");
      }
    }
  }

  void _onReplySelected(CommentNode node) {
    setState(() {
      _replyingTo = {
        'id': node.id,
        'username': node.username,
      };
    });
    _focusNode.requestFocus();
  }

  void _toggleCollapse(String id) {
    setState(() {
      if (_collapsedIds.contains(id)) {
        _collapsedIds.remove(id);
      } else {
        _collapsedIds.add(id);
      }
    });
  }

  void _navigateToProfile(String userId) {
    if (userId.trim().isEmpty) return;
    Navigator.of(context).pop();
    appRouter.push('/user/$userId');
  }

  void _handleCommentReaction(CommentNode node, String emoji) async {
    final commentId = node.id;
    setState(() {
      final oldEmoji = node.comment['user_emoji']?.toString();
      final counts = Map<String, dynamic>.from(node.comment['reaction_counts'] ?? {});
      if (oldEmoji != null && counts.containsKey(oldEmoji)) {
        final currentCount = (counts[oldEmoji] as num).toInt();
        if (currentCount <= 1) {
          counts.remove(oldEmoji);
        } else {
          counts[oldEmoji] = currentCount - 1;
        }
      }
      counts[emoji] = ((counts[emoji] as num?)?.toInt() ?? 0) + 1;
      node.comment['reaction_counts'] = counts;
      node.comment['user_emoji'] = emoji;
      node.comment['likes_count'] = counts.values.fold<int>(0, (sum, val) => sum + (val as num).toInt());
    });

    try {
      await ref.read(postRepositoryProvider).reactToReply(commentId, emojiType: emoji);
    } catch (_) {
      _fetchComments();
    }
  }

  void _handleRemoveCommentReaction(CommentNode node) async {
    final commentId = node.id;
    final oldEmoji = node.comment['user_emoji']?.toString();
    if (oldEmoji == null) return;

    setState(() {
      final counts = Map<String, dynamic>.from(node.comment['reaction_counts'] ?? {});
      if (counts.containsKey(oldEmoji)) {
        final currentCount = (counts[oldEmoji] as num).toInt();
        if (currentCount <= 1) {
          counts.remove(oldEmoji);
        } else {
          counts[oldEmoji] = currentCount - 1;
        }
      }
      node.comment['reaction_counts'] = counts;
      node.comment['user_emoji'] = null;
      node.comment['likes_count'] = counts.values.fold<int>(0, (sum, val) => sum + (val as num).toInt());
    });

    try {
      await ref.read(postRepositoryProvider).removeReplyReaction(commentId);
    } catch (_) {
      _fetchComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(profileControllerProvider).value;
    final currentUserId = currentProfile?['id'];

    final rootNodes = _rootNodes;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Flexible(
                child: Text(
                "Top comments",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: LiquidGlassTheme.textPrimary(context),
                ),
              ),
              ),
              const SizedBox(width: 8),
              if (_comments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFCBD5E1),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    "${_comments.length}",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.x, size: 16, color: LiquidGlassTheme.textPrimary(context)),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : rootNodes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.messageCircleMore,
                            size: 48,
                            color: LiquidGlassTheme.textSecondary(context).withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No comments yet",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: LiquidGlassTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Start the conversation and share your thoughts.",
                            style: TextStyle(
                              fontSize: 13,
                              color: LiquidGlassTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: rootNodes.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        return CommentTreeNodeView(
                          node: rootNodes[index],
                          depth: 0,
                          currentUserId: currentUserId,
                          collapsedIds: _collapsedIds,
                          onToggleCollapse: _toggleCollapse,
                          onReply: _onReplySelected,
                          onDelete: _deleteComment,
                          onEdit: _editComment,
                          onUserTap: _navigateToProfile,
                          onReact: _handleCommentReaction,
                          onRemoveReaction: _handleRemoveCommentReaction,
                        );
                      },
                    ),
        ),
        Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        if (_replyingTo != null)
          Container(
            color: isDark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF1F3F6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(LucideIcons.reply, size: 15, color: LiquidGlassTheme.textSecondary(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Replying to @${_replyingTo!['username']}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LiquidGlassTheme.textPrimary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _replyingTo = null),
                  child: Icon(LucideIcons.x, size: 16, color: LiquidGlassTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F3F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _replyController,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 14,
                        color: LiquidGlassTheme.textPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: _replyingTo != null
                            ? "Reply to @${_replyingTo!['username']}..."
                            : "Add a comment...",
                        hintStyle: TextStyle(color: LiquidGlassTheme.textSecondary(context), fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                LiquidGlassIconButton(
                  icon: LucideIcons.send,
                  size: 38,
                  isLoading: _isSubmitting,
                  onPressed: _sendReply,
                  tooltip: 'Send comment',
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
