import '../../../../core/network/api_client.dart';

class SearchRemoteDataSource {
  Future<List<dynamic>> search(String query, {String? category}) async {
    final cat = (category ?? 'All').toLowerCase();
    
    if (cat == 'users') {
      final response = await ApiClient.dio.get(
        '/search/users',
        queryParameters: {if (query.isNotEmpty) 'q': query},
      );
      return response.data is List ? response.data : [];
    } else if (cat == 'bubbles') {
      final response = await ApiClient.dio.get(
        '/search/bubbles',
        queryParameters: {if (query.isNotEmpty) 'q': query},
      );
      return response.data is List ? response.data : [];
    } else if (cat == 'posts') {
      final response = await ApiClient.dio.get(
        '/search/posts',
        queryParameters: {if (query.isNotEmpty) 'q': query},
      );
      return response.data is List ? response.data : [];
    } else {
      // Default to /search/all
      final response = await ApiClient.dio.get(
        '/search/all',
        queryParameters: {if (query.isNotEmpty) 'q': query},
      );
      final data = response.data;
      if (data is Map) {
        final List<dynamic> combined = [];
        if (data['users'] is List) combined.addAll(data['users']);
        if (data['bubbles'] is List) combined.addAll(data['bubbles']);
        if (data['posts'] is List) {
          combined.addAll(data['posts']);
        } else {
          try {
            final postRes = await ApiClient.dio.get(
              '/search/posts',
              queryParameters: {if (query.isNotEmpty) 'q': query},
            );
            if (postRes.data is List) {
              combined.addAll(postRes.data);
            }
          } catch (_) {}
        }
        return combined;
      }
      return [];
    }
  }

  Future<List<dynamic>> getExploreFeed({int limit = 20}) async {
    final response = await ApiClient.dio.get(
      '/feed/explore',
      queryParameters: {'limit': limit},
    );
    return response.data['items'] ?? [];
  }

  Future<List<dynamic>> getTopPostsForBubble(
    String bubbleName, {
    int limit = 20,
  }) async {
    final clean = bubbleName.replaceAll('#', '').trim().toLowerCase();
    try {
      final response = await ApiClient.dio.get(
        '/search/bubbles/$clean/top',
        queryParameters: {'limit': limit},
      );
      if (response.data is List && (response.data as List).isNotEmpty) {
        return response.data;
      }
    } catch (_) {}

    try {
      final postRes = await ApiClient.dio.get(
        '/search/posts',
        queryParameters: {'q': clean, 'limit': limit},
      );
      if (postRes.data is List && (postRes.data as List).isNotEmpty) {
        return postRes.data;
      }
    } catch (_) {}

    return getExploreFeed(limit: limit);
  }

  Future<void> createBubble({
    required String name,
    required String description,
    String type = 'PUBLIC',
    String? memberKey,
  }) async {
    await ApiClient.dio.post(
      '/bubbles',
      data: {
      'name': name.replaceAll(' ', '_').toLowerCase(),
      'description': description,
      'type': type.toUpperCase(),
      if (memberKey != null && memberKey.isNotEmpty) 'member_key': memberKey,
      },
    );
  }

  Future<void> joinBubble(String bubbleId, {String? memberKey}) async {
    await ApiClient.dio.post(
      '/bubbles/$bubbleId/join',
      data: {
      if (memberKey != null && memberKey.isNotEmpty) 'member_key': memberKey,
      },
    );
  }

  Future<void> updateBubbleNotifications(String bubbleId, bool enabled) async {
    await ApiClient.dio.patch(
      '/bubbles/$bubbleId/notifications',
      data: {'notifications_enabled': enabled},
    );
  }

  Future<void> sendFriendRequest(String userId) async {
    await ApiClient.dio.post(
      '/friends/request',
      data: {'target_user_id': userId},
    );
  }
}
