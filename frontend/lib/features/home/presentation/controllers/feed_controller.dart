import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/post_repository.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../data/services/view_tracking_service.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';

// Re-export for compatibility
export '../../data/repositories/post_repository_impl.dart' show postRemoteDataSourceProvider;

final postDataSourceProvider = postRemoteDataSourceProvider;

final feedControllerProvider = AsyncNotifierProvider<FeedController, List<FeedItem>>(() {
  return FeedController();
});

class FeedController extends AsyncNotifier<List<FeedItem>> {
  late PostRepository _repository;
  bool isCaughtUp = false;

  @override
  FutureOr<List<FeedItem>> build() async {
    _repository = ref.read(postRepositoryProvider);
    unawaited(ViewTrackingService().flush());
    return _fetchFeed();
  }

  Future<List<FeedItem>> _fetchFeed() async {
    final posts = await _repository.getFeed(limit: 20);
    final currentUserId = ref.read(profileControllerProvider).asData?.value.id;
    final unviewedPosts = posts.where((p) {
      if (currentUserId != null && currentUserId.isNotEmpty && p.authorId == currentUserId) {
        return false;
      }
      return !ViewTrackingService().hasBeenViewed(p.id);
    }).toList();
    if (unviewedPosts.isEmpty) {
      isCaughtUp = true;
    }
    return unviewedPosts;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    isCaughtUp = false;
    try {
      unawaited(ViewTrackingService().flush());
      final posts = await _fetchFeed();
      state = AsyncData(posts);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void updatePostReaction(String postId, String? emoji) {
    final currentList = state.value;
    if (currentList == null) return;

    final updated = currentList.map((post) {
      if (post.id != postId) return post;
      final newReactions = Map<String, int>.from(post.reactionCounts);
      final oldEmoji = post.userEmoji;

      if (oldEmoji != null && newReactions.containsKey(oldEmoji)) {
        final count = (newReactions[oldEmoji] ?? 1) - 1;
        if (count <= 0) {
          newReactions.remove(oldEmoji);
        } else {
          newReactions[oldEmoji] = count;
        }
      }

      if (emoji != null) {
        newReactions[emoji] = (newReactions[emoji] ?? 0) + 1;
      }

      return post.copyWith(
        userEmoji: emoji,
        clearUserEmoji: emoji == null,
        reactionCounts: newReactions,
      );
    }).toList();

    state = AsyncData(updated);
  }

  void updatePostSaved(String postId, bool isSaved) {
    final currentList = state.value;
    if (currentList == null) return;

    final updated = currentList.map((post) {
      if (post.id != postId) return post;
      return post.copyWith(isSaved: isSaved);
    }).toList();

    state = AsyncData(updated);
  }
}
