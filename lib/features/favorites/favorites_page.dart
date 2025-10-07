import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/favorites_provider.dart';
import '../details/wallpaper_carousel_page.dart';
import '../../widgets/wallpaper_tile.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider).items;

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Tu lista de favoritos está vacía.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Marca un wallpaper como favorito para verlo aquí.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final wallpaper = favorites[index];
        return Stack(
          children: [
            WallpaperTile(
              wallpaper: wallpaper,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => WallpaperCarouselPage(
                      wallpapers: favorites,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              footerBuilder: (context, data) => WallpaperTileTitleFooter(wallpaper: data.wallpaper),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => ref.read(favoritesProvider.notifier).remove(wallpaper.imageId),
              ),
            ),
          ],
        );
      },
    );
  }
}
