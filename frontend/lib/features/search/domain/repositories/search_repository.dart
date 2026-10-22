import '../entities/bubble.dart';

abstract class SearchRepository {
  Future<List<dynamic>> search(String query, {String? category});
  Future<List<Bubble>> searchBubbles(String query);
  Future<List<dynamic>> getExploreFeed({int limit = 20});
  Future<List<dynamic>> getTopPostsForBubble(String bubbleName, {int limit = 20});
  Future<void> createBubble({
    required String name,
    required String description,
    String type = 'PUBLIC',
    String? memberKey,
  });
  Future<void> joinBubble(String bubbleId, {String? memberKey});
  Future<void> updateBubbleNotifications(String bubbleId, bool enabled);
  Future<void> sendFriendRequest(String userId);
}
