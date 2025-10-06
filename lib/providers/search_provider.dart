import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../data/models/category.dart';
import '../data/models/wallpaper.dart';
import '../data/repositories/wallpaper_repository.dart';
import 'app_config_provider.dart';

final searchProvider = StateNotifierProvider<SearchController, SearchState>((ref) {
  return SearchController(ref.watch(wallpaperRepositoryProvider));
});

enum SearchSegment { wallpapers, categories }

class SearchState {
  const SearchState({
    this.wallpapers = const <Wallpaper>[],
    this.categories = const <Category>[],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.segment = SearchSegment.wallpapers,
  });

  final List<Wallpaper> wallpapers;
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final String query;
  final SearchSegment segment;

  SearchState copyWith({
    List<Wallpaper>? wallpapers,
    List<Category>? categories,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? query,
    SearchSegment? segment,
  }) {
    return SearchState(
      wallpapers: wallpapers ?? this.wallpapers,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
      segment: segment ?? this.segment,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController(this._repository) : super(const SearchState());

  final WallpaperRepository _repository;

  Future<void> search(String term) async {
    if (term.trim().isEmpty) {
      state = state.copyWith(
        wallpapers: const <Wallpaper>[],
        categories: const <Category>[],
        query: term,
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true, query: term);
    try {
      if (state.segment == SearchSegment.wallpapers) {
        final results = await _repository.searchWallpapers(
          page: 1,
          count: AppConstants.defaultPageSize3Columns,
          keyword: term,
          order: WallpaperOrder.recent,
        );
        state = state.copyWith(wallpapers: results, isLoading: false);
      } else {
        final results = await _repository.searchCategories(term);
        state = state.copyWith(categories: results, isLoading: false);
      }
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  void setSegment(SearchSegment segment) {
    if (segment == state.segment) {
      return;
    }
    state = state.copyWith(segment: segment);
    if (state.query.trim().isNotEmpty) {
      search(state.query);
    }
  }

  void clear() {
    state = const SearchState();
  }
}
