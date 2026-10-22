import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/search_repository.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';

// Re-export for backward compatibility
export '../../data/repositories/search_repository_impl.dart'
    show searchRemoteDataSourceProvider, searchRepositoryProvider;

final searchDataSourceProvider = searchRemoteDataSourceProvider;

class SearchState {
  final String query;
  final String category;
  final AsyncValue<List<dynamic>> results;

  SearchState({required this.query, required this.category, required this.results});

  SearchState copyWith({String? query, String? category, AsyncValue<List<dynamic>>? results}) {
    return SearchState(
      query: query ?? this.query,
      category: category ?? this.category,
      results: results ?? this.results,
    );
  }
}

final searchControllerProvider = NotifierProvider<SearchController, SearchState>(() {
  return SearchController();
});

class SearchController extends Notifier<SearchState> {
  late SearchRepository _repository;

  @override
  SearchState build() {
    _repository = ref.read(searchRepositoryProvider);
    // Microtask to fetch initial data without breaking build phase
    Future.microtask(() => executeSearch());
    return SearchState(query: '', category: '#tech', results: const AsyncData([]));
  }

  void updateCategory(String newCategory) {
    state = state.copyWith(category: newCategory);
    executeSearch();
  }

  void updateQuery(String newQuery) {
    state = state.copyWith(query: newQuery);
    executeSearch();
  }

  int _searchId = 0;

  Future<void> executeSearch() async {
    final currentId = ++_searchId;
    state = state.copyWith(results: const AsyncLoading());
    try {
      List<dynamic> results;
      if (state.query.isEmpty) {
        results = await _repository.getTopPostsForBubble(state.category);
      } else {
        results = await _repository.search(state.query, category: state.category);
      }

      if (_searchId == currentId) {
        state = state.copyWith(results: AsyncData(results));
      }
    } catch (e, st) {
      if (_searchId == currentId) {
        state = state.copyWith(results: AsyncError(e, st));
      }
    }
  }

  Future<bool> sendFriendRequest(String userId) async {
    try {
      await ref.read(profileRepositoryProvider).sendFriendRequest(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> joinBubble(String bubbleId) async {
    try {
      await _repository.joinBubble(bubbleId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
