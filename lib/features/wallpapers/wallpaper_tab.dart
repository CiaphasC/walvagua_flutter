import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/wallpaper.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/layout_provider.dart';
import '../../providers/wallpaper_feed_provider.dart';
import '../../widgets/modern_shimmer.dart';
import '../details/wallpaper_carousel_page.dart';
import '../../widgets/wallpaper_tile.dart';

const double _kGridSpacing = 8.0;
const EdgeInsets _kGridPadding = EdgeInsets.all(_kGridSpacing);
const double _kMaxTileWidth = 360.0;
const double _kMediumTileWidth = 300.0;
const double _kSmallTileWidth = 240.0;
const int _kMaxDynamicColumns = 12;

class WallpaperTab extends ConsumerStatefulWidget {
  const WallpaperTab({super.key, required this.title, required this.request});

  final String title;
  final WallpaperFeedRequest request;

  @override
  ConsumerState<WallpaperTab> createState() => _WallpaperTabState();
}

class _WallpaperTabState extends ConsumerState<WallpaperTab> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    Future.microtask(() => ref.read(wallpaperFeedProvider(widget.request).notifier).loadInitial());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 420) {
      ref.read(wallpaperFeedProvider(widget.request).notifier).loadMore();
    }
  }

  _GridConfig _resolveGridConfig(BuildContext context, LayoutState layout) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = math.max(0.0, screenWidth - _kGridPadding.horizontal);

    if (availableWidth <= 0) {
      return const _GridConfig(columns: 1, aspectRatio: 0.68);
    }

    final int minColumns = math.max(1, layout.wallpaperColumns);
    final int maxColumns = math.max(minColumns, _kMaxDynamicColumns);
    int columns = minColumns;
    double tileWidth;

    while (true) {
      tileWidth = (availableWidth - _kGridSpacing * (columns - 1)) / columns;
      if (tileWidth <= _kMaxTileWidth || columns >= maxColumns) {
        break;
      }
      columns++;
    }

    tileWidth = (availableWidth - _kGridSpacing * (columns - 1)) / columns;

    double aspectRatio;
    if (tileWidth >= _kMediumTileWidth) {
      aspectRatio = 0.68;
    } else if (tileWidth >= _kSmallTileWidth) {
      aspectRatio = 0.7;
    } else {
      aspectRatio = 0.75;
    }

    return _GridConfig(columns: columns, aspectRatio: aspectRatio);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(wallpaperFeedProvider(widget.request));
    final layout = ref.watch(layoutProvider);
    final favorites = ref.watch(favoritesProvider);
    final gridConfig = _resolveGridConfig(context, layout);

    if (feedState.isLoading && feedState.items.isEmpty) {
      return ShimmerWallpaperGrid(
        columns: gridConfig.columns,
        aspectRatio: gridConfig.aspectRatio,
      );
    }

    if (feedState.error != null && feedState.items.isEmpty) {
      return _ErrorView(
        message: feedState.error!,
        onRetry: () => ref.read(wallpaperFeedProvider(widget.request).notifier).loadInitial(force: true),
      );
    }

    if (feedState.items.isEmpty) {
      return const _EmptyView();
    }

    final tiles = feedState.items
        .map((wallpaper) => _WallpaperSummary(
              wallpaper: wallpaper,
              isFavorite: favorites.contains(wallpaper.imageId),
            ))
        .toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(wallpaperFeedProvider(widget.request).notifier).refresh(),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: _kGridPadding,
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridConfig.columns,
                crossAxisSpacing: _kGridSpacing,
                mainAxisSpacing: _kGridSpacing,
                childAspectRatio: gridConfig.aspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final summary = tiles[index];
                  final animationDelay = Duration(milliseconds: 80 * (index % 6));
                  return WallpaperTile(
                    wallpaper: summary.wallpaper,
                    isFavorite: summary.isFavorite,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WallpaperCarouselPage(
                            wallpapers: feedState.items,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    onFavorite: () => ref.read(favoritesProvider.notifier).toggle(summary.wallpaper),
                  ).animate(delay: animationDelay).fadeIn(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                      ).scaleXY(
                        begin: 0.95,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                      );
                },
                childCount: tiles.length,
              ),
            ),
          ),
          if (feedState.hasMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _WallpaperSummary {
  const _WallpaperSummary({required this.wallpaper, required this.isFavorite});

  final Wallpaper wallpaper;
  final bool isFavorite;
}

class _GridConfig {
  const _GridConfig({
    required this.columns,
    required this.aspectRatio,
  });

  final int columns;
  final double aspectRatio;
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid({required this.config});

  final _GridConfig config;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: _kGridPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: config.columns,
        mainAxisSpacing: _kGridSpacing,
        crossAxisSpacing: _kGridSpacing,
        childAspectRatio: config.aspectRatio,
      ),
      itemBuilder: (context, index) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
      itemCount: 6,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Whoops! Algo salió mal.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'No encontramos wallpapers en esta sección.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
