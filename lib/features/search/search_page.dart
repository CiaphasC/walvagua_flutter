import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category.dart';
import '../../data/models/wallpaper.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/search_history_provider.dart';
import '../../providers/search_provider.dart';
import '../details/wallpaper_detail_page.dart';
import '../wallpapers/category_wallpaper_page.dart';
import '../../widgets/wallpaper_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final query = ref.read(searchProvider).query;
    _controller = TextEditingController(text: query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final history = ref.watch(searchHistoryProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Busca wallpapers o categorías',
            border: InputBorder.none,
          ),
          onSubmitted: (value) => _onSearch(value, history),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _onSearch(_controller.text, history),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              _controller.clear();
              ref.read(searchProvider.notifier).clear();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<SearchSegment>(
              segments: const [
                ButtonSegment(value: SearchSegment.wallpapers, label: Text('Wallpapers'), icon: Icon(Icons.photo_library_rounded)),
                ButtonSegment(value: SearchSegment.categories, label: Text('Categorías'), icon: Icon(Icons.category_rounded)),
              ],
              selected: {searchState.segment},
              onSelectionChanged: (value) {
                if (value.isNotEmpty) {
                  ref.read(searchProvider.notifier).setSegment(value.first);
                }
              },
            ),
          ),
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchState.query.isEmpty
                    ? _HistorySection(history: history, onSelect: (term) {
                        _controller.text = term;
                        _onSearch(term, history);
                      })
                    : searchState.segment == SearchSegment.wallpapers
                        ? _WallpaperResults(
                            wallpapers: searchState.wallpapers,
                            favorites: favorites.items,
                          )
                        : _CategoryResults(categories: searchState.categories),
          ),
        ],
      ),
    );
  }

  void _onSearch(String value, List<String> history) {
    final query = value.trim();
    if (query.isEmpty) {
      return;
    }
    ref.read(searchHistoryProvider.notifier).add(query);
    ref.read(searchProvider.notifier).search(query);
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history, required this.onSelect});

  final List<String> history;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_toggle_off_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              const Text('Empieza buscando tu wallpaper favorito'),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return ListTile(
          leading: const Icon(Icons.history_rounded),
          title: Text(item),
          onTap: () => onSelect(item),
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }
}

class _WallpaperResults extends ConsumerWidget {
  const _WallpaperResults({required this.wallpapers, required this.favorites});

  final List<Wallpaper> wallpapers;
  final List<Wallpaper> favorites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (wallpapers.isEmpty) {
      return const _EmptyResults(message: 'No encontramos wallpapers con ese término.');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: wallpapers.length,
      itemBuilder: (context, index) {
        final wallpaper = wallpapers[index];
        final isFavorite = favorites.any((item) => item.imageId == wallpaper.imageId);
        return WallpaperTile(
          wallpaper: wallpaper,
          isFavorite: isFavorite,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WallpaperDetailPage(
                  wallpaperId: wallpaper.imageId,
                  initialWallpaper: wallpaper,
                ),
              ),
            );
          },
          onFavorite: () => ref.read(favoritesProvider.notifier).toggle(wallpaper),
          footerBuilder: (context, data) => WallpaperTileFavoriteFooter(data: data),
        );
      },
    );
  }
}

class _CategoryResults extends StatelessWidget {
  const _CategoryResults({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const _EmptyResults(message: 'No encontramos categorías con ese término.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return ListTile(
          leading: const Icon(Icons.category_rounded),
          title: Text(category.name),
          subtitle: Text('${category.totalWallpapers} wallpapers'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CategoryWallpaperPage(category: category),
              ),
            );
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
