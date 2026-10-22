import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_datasource.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remoteDataSource;

  PostRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<FeedItem>> getFeed({int limit = 20, String? cursor}) async {
    final rawList = await _remoteDataSource.getFeedPosts(limit: limit, cursor: cursor);
    return rawList
        .whereType<Map>()
        .map((e) => FeedItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<FeedItem> getPostById(String postId) async {
    final raw = await _remoteDataSource.getPostById(postId);
    return FeedItem.fromJson(raw);
  }

  @override
  Future<List<FeedItem>> getUserPosts(String userId, {int limit = 50}) async {
    final rawList = await _remoteDataSource.getUserPosts(userId, limit: limit);
    return rawList
        .whereType<Map>()
        .map((e) => FeedItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<String> uploadMedia(String filePath) {
    return _remoteDataSource.uploadMedia(filePath);
  }

  @override
  Future<void> createPost({
    required String content,
    String? bubbleId,
    List<String>? bubbleIds,
    List<Map<String, String>>? media,
  }) {
    return _remoteDataSource.createPost(
      content: content,
      bubbleId: bubbleId,
      bubbleIds: bubbleIds,
      media: media,
    );
  }

  @override
  Future<void> reactToPost(String postId, {String emojiType = '❤️'}) {
    return _remoteDataSource.reactToPost(postId, emojiType: emojiType);
  }

  @override
  Future<void> removeReaction(String postId) {
    return _remoteDataSource.removeReaction(postId);
  }

  @override
  Future<void> savePost(String postId, bool isSaved) {
    return _remoteDataSource.savePost(postId, isSaved);
  }

  @override
  Future<void> reportPost(String postId) {
    return _remoteDataSource.reportPost(postId);
  }

  @override
  Future<List<CommentNode>> getComments(String postId) async {
    final rawList = await _remoteDataSource.getComments(postId);
    return CommentNode.buildTree(rawList);
  }

  @override
  Future<CommentNode> createComment(
    String postId,
    String content, {
    String? parentReplyId,
  }) async {
    final raw = await _remoteDataSource.createComment(
      postId,
      content,
      parentReplyId: parentReplyId,
    );
    return CommentNode.fromJson(raw);
  }

  @override
  Future<void> updateComment(String replyId, String newContent) {
    return _remoteDataSource.updateComment(replyId, newContent);
  }

  @override
  Future<void> deleteComment(String replyId) {
    return _remoteDataSource.deleteComment(replyId);
  }

  @override
  Future<void> reactToReply(String replyId, {String emojiType = '❤️'}) {
    return _remoteDataSource.reactToReply(replyId, emojiType: emojiType);
  }

  @override
  Future<void> removeReplyReaction(String replyId) {
    return _remoteDataSource.removeReplyReaction(replyId);
  }
}

final postRemoteDataSourceProvider = Provider<PostRemoteDataSource>((ref) {
  return PostRemoteDataSource();
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final dataSource = ref.watch(postRemoteDataSourceProvider);
  return PostRepositoryImpl(dataSource);
});
