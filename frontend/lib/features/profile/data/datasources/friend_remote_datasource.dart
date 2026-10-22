import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../chat/domain/entities/activity_item.dart';

/// Remote datasource handling friendship operations:
/// fetching friends, friend requests, sending/accepting/declining requests, and removing friends.
class FriendRemoteDataSource {
  /// Fetches the current user's friends list
  Future<List<Map<String, dynamic>>> getFriends() async {
    final res = await ApiClient.dio.get('/friends');
    final rawList = res.data['friends'] as List? ?? [];
    return rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Fetches pending friend requests
  Future<List<FriendRequestItem>> getPendingRequests() async {
    try {
      final res = await ApiClient.dio.get('/friends/requests');
      final data = res.data;
      if (data is Map) {
        final list =
            (data['requests'] ?? data['friend_requests']) as List? ?? [];
        return list
            .whereType<Map>()
            .map(
              (e) => FriendRequestItem.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Sends a friend request to [targetUserId]
  Future<void> sendFriendRequest(String targetUserId) async {
    await ApiClient.dio.post(
      '/friends/request',
      data: {'target_user_id': targetUserId},
    );
  }

  /// Accepts a friend request from [userId]
  Future<void> acceptFriendRequest(String userId) async {
    await ApiClient.dio.post('/friends/request/$userId/accept');
  }

  /// Declines a friend request from [userId]
  Future<void> declineFriendRequest(String userId) async {
    await ApiClient.dio.post('/friends/request/$userId/decline');
  }

  /// Removes friendship with [userId]
  Future<void> removeFriend(String userId) async {
    await ApiClient.dio.delete('/friends/$userId');
  }

  Future<void> updateSettings(
    String userId,
    Map<String, dynamic> settings,
  ) async {
    await ApiClient.dio.patch('/friends/$userId/settings', data: settings);
  }

  Future<List<Map<String, dynamic>>> getBlocked() async {
    final response = await ApiClient.dio.get('/friends/blocked');
    final items = response.data['blocked_users'] as List? ?? [];
    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> unblock(String userId) async {
    await ApiClient.dio.delete('/friends/$userId/block');
  }
}

/// Provider for [FriendRemoteDataSource]
final friendRemoteDataSourceProvider = Provider<FriendRemoteDataSource>((ref) {
  return FriendRemoteDataSource();
});

/// Shared cache provider for friends list across dynamic dock panels and screens
final friendsListProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(friendRemoteDataSourceProvider).getFriends();
});

final blockedUsersProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(friendRemoteDataSourceProvider).getBlocked();
});
