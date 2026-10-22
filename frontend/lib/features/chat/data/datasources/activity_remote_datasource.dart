import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/activity_item.dart';

class ActivityRemoteDataSource {
  Future<ActivityFeedData> getActivityFeed({int limit = 30, int offset = 0}) async {
    try {
      debugPrint('[ActivityDataSource] Requesting GET /activity...');
      final response = await ApiClient.dio.get('/activity', queryParameters: {
        'limit': limit,
        'offset': offset,
      });
      debugPrint('[ActivityDataSource] GET /activity response status: ${response.statusCode}');
      
      dynamic raw = response.data;
      if (raw is String && raw.isNotEmpty) {
        try {
          raw = jsonDecode(raw);
        } catch (_) {}
      }
      if (raw is Map) {
        return ActivityFeedData.fromJson(Map<String, dynamic>.from(raw));
      }
      return ActivityFeedData(activities: [], friendRequests: []);
    } catch (e) {
      debugPrint('[ActivityDataSource] GET /activity failed: $e. Trying /notifications fallback...');
      try {
        final response = await ApiClient.dio.get('/notifications', queryParameters: {
          'limit': limit,
          'offset': offset,
        });
        dynamic raw = response.data;
        if (raw is String && raw.isNotEmpty) {
          try {
            raw = jsonDecode(raw);
          } catch (_) {}
        }
        if (raw is Map) {
          return ActivityFeedData.fromJson(Map<String, dynamic>.from(raw));
        }
      } catch (e2) {
        debugPrint('[ActivityDataSource] Fallback to /notifications failed: $e2');
      }

      // If full activity feed failed (e.g. backend not restarted yet), fallback to pending friend requests
      try {
        debugPrint('[ActivityDataSource] Trying /friends/requests fallback...');
        final reqs = await getPendingFriendRequests();
        if (reqs.isNotEmpty) {
          return ActivityFeedData(activities: [], friendRequests: reqs);
        }
      } catch (e3) {
        debugPrint('[ActivityDataSource] Fallback to /friends/requests also failed: $e3');
      }

      rethrow;
    }
  }

  Future<List<FriendRequestItem>> getPendingFriendRequests() async {
    try {
      final response = await ApiClient.dio.get('/friends/requests');
      dynamic raw = response.data;
      if (raw is String && raw.isNotEmpty) {
        try {
          raw = jsonDecode(raw);
        } catch (_) {}
      }
      if (raw is Map) {
        final mapData = Map<String, dynamic>.from(raw);
        final list = (mapData['requests'] ?? mapData['friend_requests']) as List? ?? [];
        return list
            .whereType<Map>()
            .map((e) => FriendRequestItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('[ActivityDataSource] Failed to fetch /friends/requests: $e');
    }
    return [];
  }

  Future<void> acceptFriendRequest(String userId) async {
    await ApiClient.dio.post('/friends/request/$userId/accept');
  }

  Future<void> declineFriendRequest(String userId) async {
    await ApiClient.dio.post('/friends/request/$userId/decline');
  }
}
