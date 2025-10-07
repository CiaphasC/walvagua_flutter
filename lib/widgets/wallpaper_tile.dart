import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/models/wallpaper.dart';

/// Common data passed to the footer builder so custom layouts can reuse the
/// favorite toggle provided by the tile.
class WallpaperTileFooterData {
  const WallpaperTileFooterData({
    required this.wallpaper,
    required this.isFavorite,
    this.onFavorite,
  });

  final Wallpaper wallpaper;
  final bool isFavorite;
  final VoidCallback? onFavorite;
}

typedef WallpaperTileFooterBuilder = Widget Function(
  BuildContext context,
  WallpaperTileFooterData data,
);

class WallpaperTile extends StatelessWidget {
  const WallpaperTile({
    super.key,
    required this.wallpaper,
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
    this.footerBuilder,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final Wallpaper wallpaper;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final WallpaperTileFooterBuilder? footerBuilder;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final footer = footerBuilder?.call(
          context,
          WallpaperTileFooterData(
            wallpaper: wallpaper,
            isFavorite: isFavorite,
            onFavorite: onFavorite,
          ),
        ) ??
        WallpaperTileMetadataFooter(
          wallpaper: wallpaper,
          isFavorite: isFavorite,
          onFavorite: onFavorite,
        );

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: borderRadius.topLeft,
                  topRight: borderRadius.topRight,
                ),
                child: WallpaperImage(
                  wallpaper: wallpaper,
                ),
              ),
            ),
            footer,
          ],
        ),
      ),
    );
  }
}

class WallpaperTileMetadataFooter extends StatelessWidget {
  const WallpaperTileMetadataFooter({
    super.key,
    required this.wallpaper,
    required this.isFavorite,
    this.onFavorite,
  });

  final Wallpaper wallpaper;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            wallpaper.imageName.isEmpty ? 'Sin nombre' : wallpaper.imageName,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.remove_red_eye_outlined, size: 16),
              const SizedBox(width: 4),
              Text('${wallpaper.views}'),
              const SizedBox(width: 12),
              const Icon(Icons.download_outlined, size: 16),
              const SizedBox(width: 4),
              Text('${wallpaper.downloads}'),
              if (onFavorite != null) ...[
                const Spacer(),
                IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                  color: isFavorite ? Theme.of(context).colorScheme.primary : null,
                  onPressed: onFavorite,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class WallpaperTileFavoriteFooter extends StatelessWidget {
  const WallpaperTileFavoriteFooter({
    super.key,
    required this.data,
  });

  final WallpaperTileFooterData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.wallpaper.imageName.isEmpty ? 'Sin nombre' : data.wallpaper.imageName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (data.onFavorite != null)
            IconButton(
              icon: Icon(data.isFavorite ? Icons.favorite : Icons.favorite_border),
              onPressed: data.onFavorite,
            ),
        ],
      ),
    );
  }
}

class WallpaperTileTitleFooter extends StatelessWidget {
  const WallpaperTileTitleFooter({
    super.key,
    required this.wallpaper,
  });

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        wallpaper.imageName.isEmpty ? 'Sin nombre' : wallpaper.imageName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class WallpaperImage extends StatelessWidget {
  const WallpaperImage({
    super.key,
    required this.wallpaper,
    this.fit = BoxFit.cover,
  });

  final Wallpaper wallpaper;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final imageUrl = wallpaper.imageThumb.isNotEmpty ? wallpaper.imageThumb : wallpaper.imageUrl;
    final placeholderColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.2);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) => Container(color: placeholderColor),
      errorWidget: (context, url, error) => Container(
        color: placeholderColor,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
    );
  }
}
