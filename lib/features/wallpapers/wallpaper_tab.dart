import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/wallpaper.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/layout_provider.dart';
import '../../providers/wallpaper_feed_provider.dart';
import '../details/wallpaper_detail_page.dart';
import '../../widgets/wallpaper_tile.dart';

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

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(wallpaperFeedProvider(widget.request));
    final layout = ref.watch(layoutProvider);
    final favorites = ref.watch(favoritesProvider);

    if (feedState.isLoading && feedState.items.isEmpty) {
      return const _LoadingGrid();
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
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: layout.wallpaperColumns,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: layout.wallpaperColumns == 2 ? 0.68 : 0.7,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final summary = tiles[index];
                  return WallpaperTile(
                    wallpaper: summary.wallpaper,
                    isFavorite: summary.isFavorite,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WallpaperDetailPage(
                            wallpaperId: summary.wallpaper.imageId,
                            initialWallpaper: summary.wallpaper,
                          ),
                        ),
                      );
                    },
                    onFavorite: () => ref.read(favoritesProvider.notifier).toggle(summary.wallpaper),
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

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (_, __) {
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
