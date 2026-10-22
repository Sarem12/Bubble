import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/comment_bottom_sheet.dart';
import '../../../../shared/widgets/liquid_glass.dart';
import '../../../../shared/widgets/post_card.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/comment.dart';
import '../../data/repositories/post_repository_impl.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  FeedItem? _post;
  List<CommentNode> _rootNodes = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSubmitting = false;
  final Set<String> _collapsedIds = {};
  Map<String, dynamic>? _replyingTo;

  final TextEditingController _replyController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final postRepo = ref.read(postRepositoryProvider);
      final results = await Future.wait([
        postRepo.getPostById(widget.postId),
        postRepo.getComments(widget.postId),
      ]);
      final post = results[0] as FeedItem;
      final comments = results[1] as List<CommentNode>;

      if (mounted) {
        setState(() {
          _post = post;
          _rootNodes = comments;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _fetchRepliesOnly() async {
    try {
      final comments = await ref.read(postRepositoryProvider).getComments(widget.postId);
      if (mounted) {
        setState(() {
          _rootNodes = comments;
        });
      }
    } catch (_) {}
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final parentId = (_replyingTo != null && _replyingTo!['id'] != null)
          ? _replyingTo!['id'].toString()
          : null;

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
      await _fetchRepliesOnly();
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
        _fetchRepliesOnly();
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
        _fetchRepliesOnly();
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
    context.push('/user/$userId');
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
      _fetchRepliesOnly();
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
      _fetchRepliesOnly();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(profileControllerProvider).value;
    final currentUserId = currentProfile?['id'];

    final rootNodes = _rootNodes;
    final topPadding = MediaQuery.paddingOf(context).top + kToolbarHeight;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const LiquidGlassAppBar(title: Text('Post')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Failed to load post."),
                      const SizedBox(height: 12),
                      LiquidGlassButton(
                        label: "Retry",
                        onPressed: _fetchDetails,
                      ),
                    ],
                  ),
                )
              : _post == null
                  ? const Center(child: Text("Post not found."))
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.only(top: topPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PostCard(
                                  post: _post!,
                                  isFullScreen: true,
                                ),
                                const Divider(height: 24),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Flexible(
                                        child: Text(
                                        "Top comments",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (rootNodes.isNotEmpty)
                                        LiquidGlassPill(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                                          label: "${rootNodes.length}",
                                        ),
                                    ],
                                  ),
                                ),

                                if (rootNodes.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(40.0),
                                    child: Center(
                                      child: Column(
                                        children: [
                                          Icon(
                                            PhosphorIconsRegular.chatCircleDots,
                                            size: 40,
                                            color: Colors.grey.withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'No comments yet. Be the first!',
                                            style: TextStyle(
                                              color: LiquidGlassTheme.textSecondary(context),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ...rootNodes.map((rootNode) => CommentTreeNodeView(
                                    node: rootNode,
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
                                  )),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),

                        // Active Reply Banner
                        if (_replyingTo != null)
                          LiquidGlassContainer(
                            borderRadius: BorderRadius.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  PhosphorIconsRegular.arrowBendUpLeft,
                                  size: 15,
                                  color: LiquidGlassTheme.textSecondary(context),
                                ),
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
                                  child: Icon(
                                    PhosphorIconsRegular.x,
                                    size: 16,
                                    color: LiquidGlassTheme.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Input field
                        LiquidGlassContainer(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: SafeArea(
                            top: false,
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
                                      style: TextStyle(
                                        color: LiquidGlassTheme.textPrimary(context),
                                        fontSize: 14,
                                      ),
                                      minLines: 1,
                                      maxLines: 4,
                                      decoration: InputDecoration(
                                        hintText: _replyingTo != null
                                            ? "Reply to @${_replyingTo!['username']}..."
                                            : "Add a comment...",
                                        hintStyle: TextStyle(
                                          color: LiquidGlassTheme.textSecondary(context),
                                          fontSize: 14,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                LiquidGlassIconButton(
                                  icon: PhosphorIconsFill.paperPlaneTilt,
                                  size: 40,
                                  isLoading: _isSubmitting,
                                  onPressed: _sendReply,
                                  tooltip: 'Post reply',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
