import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/wallpaper.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/favorites_provider.dart';

class WallpaperDetailPage extends ConsumerStatefulWidget {
  const WallpaperDetailPage({
    super.key,
    required this.wallpaperId,
    this.initialWallpaper,
  });

  final String wallpaperId;
  final Wallpaper? initialWallpaper;

  @override
  ConsumerState<WallpaperDetailPage> createState() => _WallpaperDetailPageState();
}

enum _ApplyTarget { home, lock, both }

class _WallpaperDetailPageState extends ConsumerState<WallpaperDetailPage> {
  Wallpaper? _wallpaper;
  bool _loading = false;
  String? _error;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _wallpaper = widget.initialWallpaper;
    Future.microtask(_loadDetails);
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = ref.read(wallpaperRepositoryProvider);
      final detail = await repository.fetchWallpaperDetail(widget.wallpaperId);
      await repository.updateView(widget.wallpaperId);
      if (mounted && detail != null) {
        setState(() {
          _wallpaper = detail;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallpaper = _wallpaper;
    final favoritesState = ref.watch(favoritesProvider);
    final isFavorite = wallpaper != null && favoritesState.contains(wallpaper.imageId);

    return Scaffold(
      appBar: AppBar(
        title: Text(wallpaper?.imageName.isNotEmpty == true ? wallpaper!.imageName : 'Detalle'),
      ),
      body: wallpaper == null
          ? _buildPlaceholder(context)
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    AspectRatio(
                      aspectRatio: wallpaper.type.toLowerCase() == 'square' ? 1 : 2 / 3,
                      child: CachedNetworkImage(
                        imageUrl: wallpaper.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, size: 72),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  wallpaper.imageName.isEmpty ? 'Sin nombre' : wallpaper.imageName,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                                onPressed: () => ref.read(favoritesProvider.notifier).toggle(wallpaper),
                                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (!_isDynamicMedia(wallpaper))
                                _ActionChip(
                                  icon: Icons.wallpaper_rounded,
                                  label: 'Aplicar',
                                  onTap: () => _handleApply(wallpaper),
                                ),
                              _ActionChip(
                                icon: Icons.download_rounded,
                                label: 'Guardar',
                                onTap: () => _handleDownload(wallpaper),
                              ),
                              _ActionChip(
                                icon: Icons.share_rounded,
                                label: 'Compartir',
                                onTap: () => _handleShare(wallpaper),
                              ),
                              _ActionChip(
                                icon: Icons.info_outline_rounded,
                                label: 'Información',
                                onTap: () => _showInfo(context, wallpaper),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _DetailMetadata(wallpaper: wallpaper),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_processing)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: const LinearProgressIndicator(minHeight: 4),
                  ),
              ],
            ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'No pudimos cargar el detalle.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadDetails,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool _isDynamicMedia(Wallpaper wallpaper) {
    final type = wallpaper.type.toLowerCase();
    return type.contains('gif') || type.contains('live') || type.contains('mp4');
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
              _ApplyOption(target: _ApplyTarget.home, title: 'Pantalla principal', icon: Icons.phone_android_rounded),
              _ApplyOption(target: _ApplyTarget.lock, title: 'Pantalla de bloqueo', icon: Icons.lock_rounded),
              _ApplyOption(target: _ApplyTarget.both, title: 'Ambas pantallas', icon: Icons.mobile_friendly_rounded),
            ],
          ),
        );
      },
    );
    if (target == null) {
      return;
    }
    setState(() => _processing = true);
    try {
      final file = await _downloadToStorage(wallpaper, temporary: true);
      final location = switch (target) {
        _ApplyTarget.home => WallpaperManager.HOME_SCREEN,
        _ApplyTarget.lock => WallpaperManager.LOCK_SCREEN,
        _ApplyTarget.both => WallpaperManager.BOTH_SCREEN,
      };
      final success = await WallpaperManager.setWallpaperFromFile(file.path, location);
      if (success) {
        _showSnackBar('Fondo aplicado correctamente.');
      } else {
        _showSnackBar('No fue posible aplicar el fondo.');
      }
    } catch (error) {
      _showSnackBar('No se pudo aplicar: $error');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _handleDownload(Wallpaper wallpaper) async {
    setState(() => _processing = true);
    try {
      final file = await _downloadToStorage(wallpaper);
      await ref.read(wallpaperRepositoryProvider).updateDownload(wallpaper.imageId);
      _showSnackBar('Guardado en ${file.parent.path}');
    } catch (error) {
      _showSnackBar('No se pudo guardar: $error');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _handleShare(Wallpaper wallpaper) async {
    setState(() => _processing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await _downloadToStorage(wallpaper, temporary: true);
      final link = 'https://play.google.com/store/apps/details?id=com.wall.vaguada';
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
        setState(() => _processing = false);
      }
    }
  }

  Future<File> _downloadToStorage(Wallpaper wallpaper, {bool temporary = false}) async {
    final cacheFile = await DefaultCacheManager().getSingleFile(wallpaper.imageUrl);
    final extension = _resolveExtension(wallpaper.imageUrl, wallpaper.mime);
    final sanitizedName = _sanitizeFileName(
      wallpaper.imageName.isEmpty ? 'wallvagua_${wallpaper.imageId}' : wallpaper.imageName,
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
    if (mimeLower.contains('mp4')) return '.mp4';
    return '.jpg';
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^A-Za-z0-9-_]+'), '_');
  }

  void _showInfo(BuildContext context, Wallpaper wallpaper) {
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
                Text('Información', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _InfoRow(label: 'Nombre', value: wallpaper.imageName.isEmpty ? 'Sin nombre' : wallpaper.imageName),
                _InfoRow(label: 'Categoría', value: wallpaper.categoryName.isEmpty ? 'General' : wallpaper.categoryName),
                _InfoRow(label: 'Resolución', value: wallpaper.resolution.isEmpty ? 'N/D' : wallpaper.resolution),
                _InfoRow(label: 'Tamaño', value: wallpaper.size.isEmpty ? 'N/D' : wallpaper.size),
                _InfoRow(label: 'Tipo', value: wallpaper.type.isEmpty ? 'Imagen' : wallpaper.type),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailMetadata extends StatelessWidget {
  const _DetailMetadata({required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wallpaper.categoryName.isNotEmpty)
          Text(
            'Categoría: ${wallpaper.categoryName}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.remove_red_eye_outlined, size: 18),
            const SizedBox(width: 4),
            Text('${wallpaper.views}'),
            const SizedBox(width: 16),
            const Icon(Icons.download_outlined, size: 18),
            const SizedBox(width: 4),
            Text('${wallpaper.downloads}'),
          ],
        ),
        if (wallpaper.tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Etiquetas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: wallpaper.tags
                .split(',')
                .where((tag) => tag.trim().isNotEmpty)
                .map((tag) => Chip(label: Text(tag.trim())))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
