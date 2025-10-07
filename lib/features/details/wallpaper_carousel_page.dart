import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/wallpaper.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/favorites_provider.dart';
import 'widgets/wallpaper_media_viewer.dart';

class WallpaperCarouselPage extends ConsumerStatefulWidget {
  const WallpaperCarouselPage({
    super.key,
    required this.wallpapers,
    required this.initialIndex,
  });

  final List<Wallpaper> wallpapers;
  final int initialIndex;

  @override
  ConsumerState<WallpaperCarouselPage> createState() =>
      _WallpaperCarouselPageState();
}

class _WallpaperCarouselPageState
    extends ConsumerState<WallpaperCarouselPage> {
  late List<Wallpaper> _wallpapers;
  late int _currentIndex;
  final Map<String, Wallpaper> _detailCache = {};
  // Cache palette results so quick swipes reuse previously derived schemes.
  final Map<String, ColorScheme> _paletteCache = {};
  // Guard against launching more than one palette computation per image.
  final Set<String> _paletteInFlight = {};
  ColorScheme? _currentScheme;
  bool _processingAction = false;
  String? _detailError;
  String? _loadingDetailId;

  @override
  void initState() {
    super.initState();
    _wallpapers = List<Wallpaper>.from(widget.wallpapers);
    _currentIndex = _wallpapers.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _wallpapers.length - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _wallpapers.isEmpty) {
        return;
      }
      final wallpaper = _wallpapers[_currentIndex];
      _ensureDetails(wallpaper);
      unawaited(_updateColorsFor(wallpaper));
    });
  }

  @override
  void didUpdateWidget(covariant WallpaperCarouselPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.wallpapers, widget.wallpapers)) {
      _wallpapers = List<Wallpaper>.from(widget.wallpapers);
      if (_wallpapers.isNotEmpty) {
        _currentIndex =
            _currentIndex.clamp(0, _wallpapers.length - 1);
      } else {
        _currentIndex = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_wallpapers.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No hay wallpapers disponibles.')),
      );
    }

    final theme = Theme.of(context);
    final scheme = _currentScheme ?? theme.colorScheme;
    final wallpaper = _wallpapers[_currentIndex];
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(wallpaper.imageId);
    final isLoadingDetail = _loadingDetailId == wallpaper.imageId;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        surfaceTintColor: scheme.primary,
        title: Text(
          wallpaper.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                child: _WallpaperBackdrop(
                  key: ValueKey('${wallpaper.imageId}_backdrop'),
                  wallpaper: wallpaper,
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.surface.withValues(alpha: 0.25),
                      scheme.surface.withValues(alpha: 0.65),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: CarouselSlider.builder(
                    itemCount: _wallpapers.length,
                    itemBuilder: (context, index, realIndex) {
                      final item = _wallpapers[index];
                      return _CarouselItem(
                        wallpaper: item,
                        scheme: scheme,
                      );
                    },
                    options: CarouselOptions(
                      initialPage: _currentIndex,
                      viewportFraction: 0.85,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.15,
                      enableInfiniteScroll: false,
                      onPageChanged: _handlePageChanged,
                      padEnds: false,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: _MetadataCard(
                    wallpaper: wallpaper,
                    scheme: scheme,
                    isLoading: isLoadingDetail,
                    errorMessage: _detailError,
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ActionBar(
                wallpaper: wallpaper,
                scheme: scheme,
                processing: _processingAction,
                onApply: () => _handleApply(wallpaper),
                onDownload: () => _handleDownload(wallpaper),
                onShare: () => _handleShare(wallpaper),
                onFavorite: () =>
                    ref.read(favoritesProvider.notifier).toggle(wallpaper),
                onInfo: () => _showInfoDialog(context, wallpaper),
                isFavorite: isFavorite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePageChanged(int index, CarouselPageChangedReason reason) {
    if (index == _currentIndex) {
      return;
    }
    setState(() {
      _currentIndex = index;
      _detailError = null;
    });
    final wallpaper = _wallpapers[index];
    _ensureDetails(wallpaper);
    unawaited(_updateColorsFor(wallpaper));
  }

  Future<void> _ensureDetails(Wallpaper wallpaper) async {
    if (_detailCache.containsKey(wallpaper.imageId)) {
      return;
    }
    setState(() {
      _loadingDetailId = wallpaper.imageId;
      _detailError = null;
    });
    try {
      final repository = ref.read(wallpaperRepositoryProvider);
      final detail = await repository.fetchWallpaperDetail(wallpaper.imageId);
      if (detail != null) {
        await repository.updateView(wallpaper.imageId);
        if (!mounted) {
          return;
        }
        setState(() {
          _detailCache[wallpaper.imageId] = detail;
          final itemIndex = _wallpapers
              .indexWhere((element) => element.imageId == wallpaper.imageId);
          if (itemIndex != -1) {
            _wallpapers[itemIndex] = detail;
          }
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _detailError = error.toString();
      });
    } finally {
      if (mounted && _loadingDetailId == wallpaper.imageId) {
        setState(() {
          _loadingDetailId = null;
        });
      }
    }
  }

  Future<void> _updateColorsFor(Wallpaper wallpaper) async {
    final theme = Theme.of(context);
    final base = theme.colorScheme;
    final imageUrl = wallpaper.displayUrl.isNotEmpty
        ? wallpaper.displayUrl
        : (wallpaper.imageUrl.isNotEmpty ? wallpaper.imageUrl : '');
    if (imageUrl.isEmpty) {
      setState(() => _currentScheme = base);
      return;
    }

    final cached = _paletteCache[imageUrl];
    if (cached != null) {
      setState(() => _currentScheme = cached);
      return;
    }

    if (_paletteInFlight.contains(imageUrl)) {
      return;
    }
    _paletteInFlight.add(imageUrl);

    try {
      final provider = NetworkImage(imageUrl);
      final scheme = await ColorScheme.fromImageProvider(
        provider: provider,
        brightness: theme.brightness,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _paletteCache[imageUrl] = scheme;
        _currentScheme = scheme;
      });
    } catch (_) {
      try {
        final palette = await PaletteGenerator.fromImageProvider(
          NetworkImage(imageUrl),
          maximumColorCount: 12,
        );
        final seedColor =
            palette.dominantColor?.color ?? palette.vibrantColor?.color;
        if (!mounted) {
          return;
        }
        final derivedScheme = seedColor != null
            ? ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: theme.brightness,
              )
            : base;
        setState(() {
          _paletteCache[imageUrl] = derivedScheme;
          _currentScheme = derivedScheme;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() => _currentScheme = base);
      }
    } finally {
      _paletteInFlight.remove(imageUrl);
    }
  }

  Future<void> _handleApply(Wallpaper wallpaper) async {
    if (!Platform.isAndroid) {
      _showSnackBar('Esta acción solo está disponible en Android.');
      return;
    }
    final target = await showModalBottomSheet<_ApplyTarget>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _ApplyOption(
                target: _ApplyTarget.home,
                title: 'Pantalla principal',
                icon: Icons.phone_android_rounded,
              ),
              _ApplyOption(
                target: _ApplyTarget.lock,
                title: 'Pantalla de bloqueo',
                icon: Icons.lock_rounded,
              ),
              _ApplyOption(
                target: _ApplyTarget.both,
                title: 'Ambas pantallas',
                icon: Icons.mobile_friendly_rounded,
              ),
            ],
          ),
        );
      },
    );
    if (target == null) {
      return;
    }
    setState(() => _processingAction = true);
    try {
      final file = await _downloadToStorage(wallpaper, temporary: true);
      final location = switch (target) {
        _ApplyTarget.home => WallpaperManager.HOME_SCREEN,
        _ApplyTarget.lock => WallpaperManager.LOCK_SCREEN,
        _ApplyTarget.both => WallpaperManager.BOTH_SCREEN,
      };
      final success =
          await WallpaperManager.setWallpaperFromFile(file.path, location);
      if (success) {
        _showSnackBar('Fondo aplicado correctamente.');
      } else {
        _showSnackBar('No fue posible aplicar el fondo.');
      }
    } catch (error) {
      _showSnackBar('No se pudo aplicar: $error');
    } finally {
      if (mounted) {
        setState(() => _processingAction = false);
      }
    }
  }

  Future<void> _handleDownload(Wallpaper wallpaper) async {
    setState(() => _processingAction = true);
    try {
      final file = await _downloadToStorage(wallpaper);
      await ref
          .read(wallpaperRepositoryProvider)
          .updateDownload(wallpaper.imageId);
      _showSnackBar('Guardado en ${file.parent.path}');
    } catch (error) {
      _showSnackBar('No se pudo guardar: $error');
    } finally {
      if (mounted) {
        setState(() => _processingAction = false);
      }
    }
  }

  Future<void> _handleShare(Wallpaper wallpaper) async {
    setState(() => _processingAction = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _downloadToStorage(wallpaper, temporary: true);
      const link =
          'https://play.google.com/store/apps/details?id=com.wall.vaguada';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Descarga este wallpaper de WallVagua $link',
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo compartir: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _processingAction = false);
      }
    }
  }

  Future<File> _downloadToStorage(
    Wallpaper wallpaper, {
    bool temporary = false,
  }) async {
    final sourceUrl = wallpaper.contentUrl;
    if (sourceUrl.isEmpty) {
      throw Exception('Recurso no disponible para este wallpaper.');
    }
    final cacheFile = await DefaultCacheManager().getSingleFile(sourceUrl);
    final extension = _resolveExtension(sourceUrl, wallpaper.mime);
    final sanitizedName = _sanitizeFileName(
      wallpaper.imageName.isEmpty
          ? 'wallvagua_${wallpaper.imageId}'
          : wallpaper.imageName,
    );
    final fileName = '$sanitizedName$extension';
    final Directory targetDir;
    if (temporary) {
      targetDir = await getTemporaryDirectory();
    } else {
      final downloads = await _resolveDownloadsDirectory();
      targetDir = downloads ?? await getApplicationDocumentsDirectory();
    }
    final targetPath = p.join(targetDir.path, fileName);
    final targetFile = File(targetPath);
    await targetFile.parent.create(recursive: true);
    if (targetFile.existsSync()) {
      await targetFile.delete();
    }
    return cacheFile.copy(targetFile.path);
  }

  Future<Directory?> _resolveDownloadsDirectory() async {
    try {
      return await getDownloadsDirectory();
    } catch (_) {
      return null;
    }
  }

  String _resolveExtension(String url, String mime) {
    final extFromUrl = p.extension(url);
    if (extFromUrl.isNotEmpty && extFromUrl.length <= 5) {
      return extFromUrl;
    }
    final mimeLower = mime.toLowerCase();
    if (mimeLower.contains('png')) return '.png';
    if (mimeLower.contains('gif')) return '.gif';
    if (mimeLower.contains('mp4') || mimeLower.contains('octet-stream')) {
      return '.mp4';
    }
    return '.jpg';
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^A-Za-z0-9-_]+'), '_');
  }

  void _showInfoDialog(BuildContext context, Wallpaper wallpaper) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Información',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'Nombre', value: wallpaper.displayName),
                _InfoRow(
                  label: 'Categoría',
                  value: wallpaper.categoryName.isEmpty
                      ? 'General'
                      : wallpaper.categoryName,
                ),
                _InfoRow(
                  label: 'Resolución',
                  value: wallpaper.resolution.isEmpty
                      ? 'N/D'
                      : wallpaper.resolution,
                ),
                _InfoRow(
                  label: 'Tamaño',
                  value: wallpaper.size.isEmpty ? 'N/D' : wallpaper.size,
                ),
                _InfoRow(
                  label: 'Tipo',
                  value: wallpaper.type.isEmpty ? 'Imagen' : wallpaper.type,
                ),
                _InfoRow(label: 'Vistas', value: '${wallpaper.views}'),
                _InfoRow(label: 'Descargas', value: '${wallpaper.downloads}'),
                const SizedBox(height: 12),
                if (wallpaper.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: wallpaper.tags
                        .split(',')
                        .where((tag) => tag.trim().isNotEmpty)
                        .map((tag) => Chip(label: Text(tag.trim())))
                        .toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WallpaperBackdrop extends StatelessWidget {
  const _WallpaperBackdrop({super.key, required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: WallpaperMediaViewer(
              wallpaper: wallpaper,
              showVideoBadge: false,
            ),
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

class _CarouselItem extends StatelessWidget {
  const _CarouselItem({required this.wallpaper, required this.scheme});

  final Wallpaper wallpaper;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final aspectRatio =
        wallpaper.type.toLowerCase() == 'square' ? 1.0 : 2 / 3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final slotWidth = constraints.maxWidth;
        final slotHeight = constraints.maxHeight;
        final isUltraTall = slotHeight > slotWidth * 1.3;
        final edgePadding = isUltraTall ? 12.0 : 24.0;

        double targetHeight = slotHeight * (isUltraTall ? 1.7 : 1.28);
        double targetWidth = targetHeight * aspectRatio;

        final maxWidth = slotWidth * (isUltraTall ? 1.45 : 1.25);
        final minWidth = slotWidth * 0.78;
        if (targetWidth > maxWidth) {
          targetWidth = maxWidth;
          targetHeight = targetWidth / aspectRatio;
        } else if (targetWidth < minWidth) {
          targetWidth = minWidth;
          targetHeight = targetWidth / aspectRatio;
        }

        final minHeight = slotHeight * (isUltraTall ? 1.25 : 1.05);
        if (targetHeight < minHeight) {
          targetHeight = minHeight;
          targetWidth = targetHeight * aspectRatio;
        }

        final verticalOffset = (slotHeight - targetHeight) / 2;
        final horizontalOffset = (slotWidth - targetWidth) / 2;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: edgePadding),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: verticalOffset,
                left: horizontalOffset,
                width: targetWidth,
                height: targetHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: WallpaperMediaViewer(wallpaper: wallpaper),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _StatChips(
                  scheme: scheme,
                  views: wallpaper.views,
                  downloads: wallpaper.downloads,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChips extends StatelessWidget {
  const _StatChips({
    required this.scheme,
    required this.views,
    required this.downloads,
  });

  final ColorScheme scheme;
  final int views;
  final int downloads;

  @override
  Widget build(BuildContext context) {
    final background = scheme.primaryContainer.withValues(alpha: 0.82);
    final foreground = scheme.onPrimaryContainer;
    final borderColor = scheme.primary.withValues(alpha: 0.3);

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _StatChip(
          icon: Icons.remove_red_eye_outlined,
          label: '$views',
          background: background,
          foreground: foreground,
          borderColor: borderColor,
        ),
        _StatChip(
          icon: Icons.download_outlined,
          label: '$downloads',
          background: background,
          foreground: foreground,
          borderColor: borderColor,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({
    required this.wallpaper,
    required this.scheme,
    required this.isLoading,
    required this.errorMessage,
  });

  final Wallpaper wallpaper;
  final ColorScheme scheme;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && errorMessage == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          if (isLoading) const SizedBox(height: 12),
          if (errorMessage != null) ...[
            if (isLoading) const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.wallpaper,
    required this.scheme,
    required this.processing,
    required this.onApply,
    required this.onDownload,
    required this.onShare,
    required this.onFavorite,
    required this.onInfo,
    required this.isFavorite,
  });

  final Wallpaper wallpaper;
  final ColorScheme scheme;
  final bool processing;
  final VoidCallback onApply;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback onInfo;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final background = scheme.surface.withValues(alpha: 0.94);
    final foreground = scheme.onSurface;
    final primary = scheme.primary;
    final onPrimary = scheme.onPrimary;
    final secondary = scheme.secondaryContainer;
    final onSecondary = scheme.onSecondaryContainer;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (processing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: processing ? null : onApply,
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.wallpaper_rounded),
                      label: const Text('Aplicar'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: processing ? null : onDownload,
                      style: FilledButton.styleFrom(
                        backgroundColor: secondary.withValues(alpha: 0.75),
                        foregroundColor: onSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Descargar'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: processing ? null : onShare,
                      style: FilledButton.styleFrom(
                        backgroundColor: secondary.withValues(alpha: 0.65),
                        foregroundColor: onSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Compartir'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: processing ? null : onInfo,
                      style: FilledButton.styleFrom(
                        backgroundColor: secondary.withValues(alpha: 0.55),
                        foregroundColor: onSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('Información'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: processing ? null : onFavorite,
                      style: FilledButton.styleFrom(
                        backgroundColor: isFavorite
                            ? primary.withValues(alpha: 0.9)
                            : secondary.withValues(alpha: 0.55),
                        foregroundColor:
                            isFavorite ? onPrimary : onSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_outline_rounded,
                      ),
                      label: Text(isFavorite ? 'Quitar' : 'Favorito'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  wallpaper.categoryName.isEmpty
                      ? 'General'
                      : wallpaper.categoryName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground.withValues(alpha: 0.72),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ApplyTarget { home, lock, both }

class _ApplyOption extends StatelessWidget {
  const _ApplyOption({
    required this.target,
    required this.title,
    required this.icon,
  });

  final _ApplyTarget target;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => Navigator.of(context).pop(target),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
