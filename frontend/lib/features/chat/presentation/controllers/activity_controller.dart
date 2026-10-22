import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/activity_remote_datasource.dart';
import '../../domain/entities/activity_item.dart';
import '../../../profile/data/datasources/friend_remote_datasource.dart';

final activityDataSourceProvider = Provider((ref) => ActivityRemoteDataSource());

final activityControllerProvider =
    AsyncNotifierProvider<ActivityController, ActivityFeedData>(() {
  return ActivityController();
});

// Alias for backwards compatibility so any existing callers watch the single source of truth
final activityFeedProvider = activityControllerProvider;

class ActivityController extends AsyncNotifier<ActivityFeedData> {
  late ActivityRemoteDataSource _dataSource;

  @override
  FutureOr<ActivityFeedData> build() async {
    _dataSource = ref.read(activityDataSourceProvider);
    return await _dataSource.getActivityFeed();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _dataSource.getActivityFeed());
  }

  Future<bool> acceptRequest(String userId) async {
    try {
      await ref.read(friendRemoteDataSourceProvider).acceptFriendRequest(userId);
      ref.invalidate(friendsListProvider);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> declineRequest(String userId) async {
    try {
      await ref.read(friendRemoteDataSourceProvider).declineFriendRequest(userId);
      ref.invalidate(friendsListProvider);
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}
