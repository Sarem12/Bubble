import '../entities/post.dart';
import '../entities/comment.dart';

abstract class PostRepository {
  Future<List<FeedItem>> getFeed({int limit = 20, String? cursor});
  Future<FeedItem> getPostById(String postId);
  Future<List<FeedItem>> getUserPosts(String userId, {int limit = 50});
  Future<String> uploadMedia(String filePath);
  Future<void> createPost({
    required String content,
    String? bubbleId,
    List<String>? bubbleIds,
    List<Map<String, String>>? media,
  });
  Future<void> reactToPost(String postId, {String emojiType = '❤️'});
  Future<void> removeReaction(String postId);
  Future<void> savePost(String postId, bool isSaved);
  Future<void> reportPost(String postId);

  Future<List<CommentNode>> getComments(String postId);
  Future<CommentNode> createComment(String postId, String content, {String? parentReplyId});
  Future<void> updateComment(String replyId, String newContent);
  Future<void> deleteComment(String replyId);
  Future<void> reactToReply(String replyId, {String emojiType = '❤️'});
  Future<void> removeReplyReaction(String replyId);
}
