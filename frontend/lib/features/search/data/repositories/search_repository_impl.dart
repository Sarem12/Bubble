import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/bubble.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _dataSource;

  SearchRepositoryImpl(this._dataSource);

  @override
  Future<List<dynamic>> search(String query, {String? category}) {
    return _dataSource.search(query, category: category);
  }

  @override
  Future<List<Bubble>> searchBubbles(String query) async {
    final raw = await _dataSource.search(query, category: 'bubbles');
    return raw
        .whereType<Map>()
        .map((e) => Bubble.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<dynamic>> getExploreFeed({int limit = 20}) {
    return _dataSource.getExploreFeed(limit: limit);
  }

  @override
  Future<List<dynamic>> getTopPostsForBubble(
    String bubbleName, {
    int limit = 20,
  }) {
    return _dataSource.getTopPostsForBubble(bubbleName, limit: limit);
  }

  @override
  Future<void> createBubble({
    required String name,
    required String description,
    String type = 'PUBLIC',
    String? memberKey,
  }) {
    return _dataSource.createBubble(
      name: name,
      description: description,
      type: type,
      memberKey: memberKey,
    );
  }

  @override
  Future<void> joinBubble(String bubbleId, {String? memberKey}) {
    return _dataSource.joinBubble(bubbleId, memberKey: memberKey);
  }

  @override
  Future<void> updateBubbleNotifications(String bubbleId, bool enabled) {
    return _dataSource.updateBubbleNotifications(bubbleId, enabled);
  }

  @override
  Future<void> sendFriendRequest(String userId) {
    return _dataSource.sendFriendRequest(userId);
  }
}

final searchRemoteDataSourceProvider = Provider<SearchRemoteDataSource>((ref) {
  return SearchRemoteDataSource();
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final ds = ref.watch(searchRemoteDataSourceProvider);
  return SearchRepositoryImpl(ds);
});
