import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/favorites_provider.dart';
import '../details/wallpaper_detail_page.dart';

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
            Positioned.fill(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
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
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).cardColor,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: CachedNetworkImage(
                            imageUrl: wallpaper.imageThumb.isNotEmpty ? wallpaper.imageThumb : wallpaper.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.2),
                            ),
                            errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          wallpaper.imageName.isEmpty ? 'Sin nombre' : wallpaper.imageName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
