import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class PostRemoteDataSource {
  Future<List<Map<String, dynamic>>> getMyNotificationSettings() async {
    final response = await ApiClient.dio.get('/posts/me/notifications');
    final items = response.data as List? ?? [];
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> updateNotificationSettings(
    String postId,
    Map<String, String> settings,
  ) async {
    await ApiClient.dio.patch('/posts/$postId/notifications', data: settings);
  }

  Future<List<dynamic>> getFeedPosts({int limit = 20, String? cursor}) async {
    final response = await ApiClient.dio.get(
      '/feed',
      queryParameters: {
      'limit': limit,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return response.data['items'] ?? [];
  }

  Future<String> uploadMedia(String filePath) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await ApiClient.dio.post(
      '/media/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data['url'] as String;
  }

  Future<void> createPost({
    required String content,
    String? bubbleId,
    List<String>? bubbleIds,
    List<Map<String, String>>? media,
  }) async {
    final effectiveBubbleId =
        bubbleId ??
        (bubbleIds != null && bubbleIds.isNotEmpty ? bubbleIds.first : null);
    await ApiClient.dio.post(
      '/posts',
      data: {
      'content': content,
      'bubble_id': ?effectiveBubbleId,
      'bubble_ids': effectiveBubbleId != null ? [effectiveBubbleId] : [],
      if (media != null && media.isNotEmpty) 'media': media,
      },
    );
  }

  Future<void> reactToPost(String postId, {String emojiType = 'heart'}) async {
    await ApiClient.dio.put(
      '/posts/$postId/interactions/react',
      data: {'emoji_type': emojiType},
    );
  }

  Future<void> removeReaction(String postId) async {
    await ApiClient.dio.delete('/posts/$postId/interactions/react');
  }

  Future<void> reportPost(String postId) async {
    await ApiClient.dio.post('/posts/$postId/report');
  }

  Future<void> savePost(String postId, bool isSaved) async {
    await ApiClient.dio.put(
      '/posts/$postId/interactions/save',
      data: {'is_saved': isSaved},
    );
  }

  Future<Map<String, dynamic>> getPostById(String postId) async {
    final response = await ApiClient.dio.get('/posts/$postId');
    return Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getUserPosts(String userId, {int limit = 50}) async {
    final response = await ApiClient.dio.get(
      '/feed/user/$userId',
      queryParameters: {'limit': limit},
    );
    return response.data['items'] ?? [];
  }

  Future<List<dynamic>> getComments(String postId) async {
    final response = await ApiClient.dio.get('/posts/$postId/replies');
    return response.data['items'] ?? [];
  }

  Future<Map<String, dynamic>> createComment(
    String postId,
    String content, {
    String? parentReplyId,
  }) async {
    final response = await ApiClient.dio.post(
      '/posts/$postId/replies',
      data: {
      'content': content,
      if (parentReplyId != null && parentReplyId.isNotEmpty)
        'parent_reply_id': parentReplyId,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updateComment(String replyId, String newContent) async {
    await ApiClient.dio.put('/replies/$replyId', data: {'content': newContent});
  }

  Future<void> deleteComment(String replyId) async {
    await ApiClient.dio.delete('/replies/$replyId');
  }

  Future<void> reactToReply(String replyId, {String emojiType = '❤️'}) async {
    await ApiClient.dio.put(
      '/replies/$replyId/interactions/react',
      data: {'emoji_type': emojiType},
    );
  }

  Future<void> removeReplyReaction(String replyId) async {
    await ApiClient.dio.delete('/replies/$replyId/interactions/react');
  }
}
