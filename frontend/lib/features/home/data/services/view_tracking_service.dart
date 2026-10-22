import 'dart:async';
import '../../../../core/network/api_client.dart';

class ViewTrackingService {
  static final ViewTrackingService _instance = ViewTrackingService._internal();
  factory ViewTrackingService() => _instance;
  ViewTrackingService._internal();

  final Set<String> _viewedPostIds = {};
  final Map<String, Timer> _dwellTimers = {};
  final Set<String> _pendingViewQueue = {};
  Timer? _flushTimer;

  bool hasBeenViewed(String postId) => _viewedPostIds.contains(postId);

  void onVisibilityChanged(String postId, double visibleFraction) {
    if (postId.isEmpty || _viewedPostIds.contains(postId)) return;

    // Instagram standard: >= 50% visible on screen
    if (visibleFraction >= 0.5) {
      if (!_dwellTimers.containsKey(postId)) {
        _dwellTimers[postId] = Timer(const Duration(milliseconds: 500), () {
          _recordView(postId);
          _dwellTimers.remove(postId);
        });
      }
    } else {
      _dwellTimers[postId]?.cancel();
      _dwellTimers.remove(postId);
    }
  }

  void _recordView(String postId) {
    if (_viewedPostIds.add(postId)) {
      _pendingViewQueue.add(postId);
      _scheduleFlush();
    }
  }

  void _scheduleFlush() {
    _flushTimer ??= Timer(const Duration(seconds: 1), () {
      flush();
    });
  }

  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;

    // Immediately commit active dwell timers so posts currently on screen are marked viewed
    for (final entry in _dwellTimers.entries) {
      entry.value.cancel();
      if (_viewedPostIds.add(entry.key)) {
        _pendingViewQueue.add(entry.key);
      }
    }
    _dwellTimers.clear();

    if (_pendingViewQueue.isEmpty) return;

    final toFlush = List<String>.from(_pendingViewQueue);
    _pendingViewQueue.clear();

    await Future.wait(
      toFlush.map((postId) async {
        try {
          await ApiClient.dio.put('/posts/$postId/interactions/view');
        } catch (_) {}
      }),
    );
  }

  void dispose() {
    for (final timer in _dwellTimers.values) {
      timer.cancel();
    }
    _dwellTimers.clear();
    flush();
    _flushTimer?.cancel();
    _flushTimer = null;
  }
}
