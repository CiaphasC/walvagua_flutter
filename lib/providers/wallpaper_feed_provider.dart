import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../data/models/paged_response.dart';
import '../data/models/wallpaper.dart';
import '../data/repositories/wallpaper_repository.dart';
import 'app_config_provider.dart';
import 'layout_provider.dart';

final wallpaperFeedProvider =
    NotifierProvider.family<WallpaperFeedController, WallpaperFeedState, WallpaperFeedRequest>(
  WallpaperFeedController.new,
);

class WallpaperFeedRequest {
  const WallpaperFeedRequest({
    required this.order,
    required this.filter,
    required this.category,
  });

  final String order;
  final String filter;
  final String category;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is WallpaperFeedRequest &&
        other.order == order &&
        other.filter == filter &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(order, filter, category);

  @override
  String toString() => 'WallpaperFeedRequest(order: $order, filter: $filter, category: $category)';
}

class WallpaperFeedState {
  const WallpaperFeedState({
    this.items = const <Wallpaper>[],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.page = 0,
    this.totalPages = 1,
  });

  final List<Wallpaper> items;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  WallpaperFeedState copyWith({
    List<Wallpaper>? items,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    int? page,
    int? totalPages,
  }) {
    return WallpaperFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : error ?? this.error,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class WallpaperFeedController extends Notifier<WallpaperFeedState> {
  WallpaperFeedController(this._request);

  final WallpaperFeedRequest _request;
  late final WallpaperRepository _repository;
  late int _pageSize;
  int? _lastColumns;

  bool _hasInitialised = false;
  bool _isLoadingMore = false;
  WallpaperFeedState _cachedState = const WallpaperFeedState();

  @override
  WallpaperFeedState build() {
    _repository = ref.watch(wallpaperRepositoryProvider);
    final columns = ref.watch(layoutProvider.select((value) => value.wallpaperColumns));
    _pageSize = columns == 3 ? AppConstants.defaultPageSize3Columns : AppConstants.defaultPageSize2Columns;
    if (_lastColumns != null && _lastColumns != columns && _hasInitialised) {
      Future.microtask(refresh);
    }
    _lastColumns = columns;
    return _cachedState;
  }

  @override
  set state(WallpaperFeedState value) {
    _cachedState = value;
    super.state = value;
  }

  Future<void> loadInitial({bool force = false}) async {
    if (_hasInitialised && !force) {
      return;
    }
    _hasInitialised = true;
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadPage(page: 1, replace: true);
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true, clearError: true);
    await _loadPage(page: 1, replace: true);
    state = state.copyWith(isRefreshing: false);
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !state.hasMore) {
      return;
    }
    _isLoadingMore = true;
    final nextPage = state.page + 1;
    await _loadPage(page: nextPage, replace: false);
    _isLoadingMore = false;
  }

  Future<void> _loadPage({required int page, required bool replace}) async {
    try {
      final PagedResponse<Wallpaper> response = await _repository.fetchWallpapers(
        page: page,
        count: _pageSize,
        filter: _request.filter,
        order: _request.order,
        category: _request.category,
      );
      final items = replace ? response.items : <Wallpaper>[...state.items, ...response.items];
      state = state.copyWith(
        items: items,
        isLoading: false,
        isRefreshing: false,
        page: response.page,
        totalPages: response.totalPages,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: error.toString(),
      );
    }
  }
}
