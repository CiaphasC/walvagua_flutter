import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';

import '../core/theme/app_theme.dart';
import '../data/models/wallpaper.dart';
import 'favorite_toggle_button.dart';

const EdgeInsets _kTileContentPadding = EdgeInsets.all(12);

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
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
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
        _OverlayFooter(
          wallpaper: wallpaper,
          isFavorite: isFavorite,
          onFavorite: onFavorite,
        );

    Widget tile = InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              WallpaperImage(wallpaper: wallpaper),
              footer,
            ],
          ),
        ),
      ),
    );

    if (isFavorite) {
      final baseColor = Theme.of(context).colorScheme.primary;
      final glowColor = baseColor.withValues(alpha: 0.45);
      tile = GlowContainer(
        glowColor: glowColor,
        blurRadius: 18,
        spreadRadius: 1.2,
        borderRadius: borderRadius,
        animationDuration: const Duration(milliseconds: 280),
        child: tile,
      );
    }
    return tile;
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
      padding: _kTileContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            wallpaper.displayName,
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

class _OverlayFooter extends StatelessWidget {
  const _OverlayFooter({
    required this.wallpaper,
    required this.isFavorite,
    this.onFavorite,
  });

  final Wallpaper wallpaper;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final titleSize = width * 0.095; // proporcional al ancho
        final subtitleSize = width * 0.045;

        final titleStyle = theme
            .textTheme
            .titleLarge
            ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: titleSize.clamp(14, 28));

        final subtitleStyle = theme
            .textTheme
            .labelLarge
            ?.copyWith(color: const Color(0xFFFFC107), letterSpacing: 0.5, fontSize: subtitleSize.clamp(10, 16));

        return Stack(
          children: [
            // Degradado moderno con blur effect
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),
            // Contenido centrado con mejor tipografía
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          wallpaper.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: titleStyle?.copyWith(
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PREMIUM COLLECTION',
                          textAlign: TextAlign.center,
                          style: subtitleStyle?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Boton de favorito flotante mejorado
            if (onFavorite != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: FavoriteToggleButton(
                    isFavorite: isFavorite,
                    onPressed: onFavorite,
                    activeColor: AppColors.lightAccent,
                    inactiveColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.all(8),
                    iconSize: 20,
                    tooltip: 'Favorito',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Badge hexagonal eliminado segun requerimiento

class WallpaperTileFavoriteFooter extends StatelessWidget {
  const WallpaperTileFavoriteFooter({
    super.key,
    required this.data,
  });

  final WallpaperTileFooterData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _kTileContentPadding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              data.wallpaper.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (data.onFavorite != null)
            FavoriteToggleButton(
              isFavorite: data.isFavorite,
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
      padding: _kTileContentPadding,
      child: Text(
        wallpaper.displayName,
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

