import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category.dart';
import '../../data/models/wallpaper.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/search_history_provider.dart';
import '../../providers/search_provider.dart';
import '../details/wallpaper_carousel_page.dart';
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final iconColor = theme.iconTheme.color ?? theme.colorScheme.onSurface;
    final glowColor = primary.withValues(alpha: 0.3);

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
            icon: GlowIcon(
              Icons.search_rounded,
              color: iconColor,
              glowColor: glowColor,
              blurRadius: 20,
            ),
            onPressed: () => _onSearch(_controller.text, history),
          ),
          IconButton(
            icon: GlowIcon(
              Icons.close_rounded,
              color: iconColor,
              glowColor: glowColor,
              blurRadius: 16,
            ),
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
              segments: [
                ButtonSegment(
                  value: SearchSegment.wallpapers,
                  label: GlowText(
                    'Wallpapers',
                    style: theme.textTheme.titleSmall,
                    glowColor: glowColor,
                    blurRadius: 14,
                  ),
                  icon: GlowIcon(
                    Icons.photo_library_rounded,
                    color: iconColor,
                    glowColor: glowColor,
                    blurRadius: 18,
                  ),
                ),
                ButtonSegment(
                  value: SearchSegment.categories,
                  label: GlowText(
                    'Categor�as',
                    style: theme.textTheme.titleSmall,
                    glowColor: glowColor,
                    blurRadius: 14,
                  ),
                  icon: GlowIcon(
                    Icons.category_rounded,
                    color: iconColor,
                    glowColor: glowColor,
                    blurRadius: 18,
                  ),
                ),
              ],
              selected: {searchState.segment},
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
                      : theme.colorScheme.surface,
                ),
                overlayColor: WidgetStateProperty.all(primary.withValues(alpha: 0.08)),
                side: WidgetStateProperty.resolveWith(
                  (states) => BorderSide(
                    color: states.contains(WidgetState.selected)
                        ? primary.withValues(alpha: 0.6)
                        : theme.dividerColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
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
        final theme = Theme.of(context);
        return GlowContainer(
          color: theme.cardColor.withValues(alpha: 0.92),
          glowColor: theme.colorScheme.primary.withValues(alpha: 0.18),
          blurRadius: 16,
          spreadRadius: 0.6,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: GlowIcon(
              Icons.history_rounded,
              color: theme.iconTheme.color,
              glowColor: theme.colorScheme.primary.withValues(alpha: 0.18),
              blurRadius: 14,
            ),
            title: Text(item),
            onTap: () => onSelect(item),
          ),
        );
      },
      separatorBuilder: (context, index) => const Divider(height: 1),
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
                builder: (_) => WallpaperCarouselPage(
                  wallpapers: wallpapers,
                  initialIndex: index,
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
        final theme = Theme.of(context);
        final glowColor = theme.colorScheme.primary.withValues(alpha: 0.2);
        return GlowContainer(
          color: theme.cardColor.withValues(alpha: 0.93),
          glowColor: glowColor,
          blurRadius: 20,
          spreadRadius: 0.7,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            leading: GlowIcon(
              Icons.category_rounded,
              color: theme.iconTheme.color,
              glowColor: glowColor,
              blurRadius: 16,
            ),
            title: GlowText(
              category.name,
              style: theme.textTheme.titleMedium,
              glowColor: glowColor,
              blurRadius: 18,
            ),
            subtitle: Text('${category.totalWallpapers} wallpapers'),
            trailing: GlowIcon(
              Icons.chevron_right_rounded,
              color: theme.iconTheme.color,
              glowColor: glowColor,
              blurRadius: 14,
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryWallpaperPage(category: category),
                ),
              );
            },
          ),
        );
      },
      separatorBuilder: (context, index) => const Divider(height: 1),
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
