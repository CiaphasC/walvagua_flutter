import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';
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
  ConsumerState<WallpaperDetailPage> createState() =>
      _WallpaperDetailPageState();
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
    final isFavorite =
        wallpaper != null && favoritesState.contains(wallpaper.imageId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          wallpaper?.imageName.isNotEmpty == true
              ? wallpaper!.imageName
              : 'Detalle',
        ),
      ),
      body: wallpaper == null
          ? _buildPlaceholder(context)
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    AspectRatio(
                      aspectRatio: wallpaper.type.toLowerCase() == 'square'
                          ? 1
                          : 2 / 3,
                      child: GlowContainer(
                        color: Colors.transparent,
                        glowColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.28),
                        blurRadius: 32,
                        spreadRadius: 1.4,
                        borderRadius: BorderRadius.circular(24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: _WallpaperMediaViewer(wallpaper: wallpaper),
                        ),
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
                                  wallpaper.displayName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                              ),
                              IconButton.filledTonal(
                                tooltip: isFavorite
                                    ? 'Quitar de favoritos'
                                    : 'Agregar a favoritos',
                                onPressed: () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(wallpaper),
                                icon: GlowIcon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).iconTheme.color,
                                  glowColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(
                                        alpha: isFavorite ? 0.4 : 0.2,
                                      ),
                                  blurRadius: isFavorite ? 24 : 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              if (!wallpaper.isDynamicMedia)
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
              Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'No pudimos cargar el detalle.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
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
    setState(() => _processing = true);
    try {
      final file = await _downloadToStorage(wallpaper, temporary: true);
      final location = switch (target) {
        _ApplyTarget.home => WallpaperManager.HOME_SCREEN,
        _ApplyTarget.lock => WallpaperManager.LOCK_SCREEN,
        _ApplyTarget.both => WallpaperManager.BOTH_SCREEN,
      };
      final success = await WallpaperManager.setWallpaperFromFile(
        file.path,
        location,
      );
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
      await ref
          .read(wallpaperRepositoryProvider)
          .updateDownload(wallpaper.imageId);
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
      final link =
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
        setState(() => _processing = false);
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
    if (mimeLower.contains('mp4') || mimeLower.contains('octet-stream'))
      return '.mp4';
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WallpaperMediaViewer extends StatelessWidget {
  const _WallpaperMediaViewer({required this.wallpaper});

  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context) {
    final placeholderColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;
    final displayUrl = wallpaper.displayUrl;
    if (wallpaper.isVideo) {
      final placeholderUrl = displayUrl.isNotEmpty
          ? displayUrl
          : (wallpaper.imageThumb.isNotEmpty ? wallpaper.imageThumb : null);
      if (Platform.isWindows) {
        return _WindowsWallpaperVideoPlayer(
          mediaUrl: wallpaper.contentUrl,
          placeholderUrl: placeholderUrl,
          placeholderColor: placeholderColor,
        );
      }
      return _VideoWallpaperPlayer(
        mediaUrl: wallpaper.contentUrl,
        placeholderUrl: placeholderUrl,
        placeholderColor: placeholderColor,
      );
    }
    if (displayUrl.isEmpty) {
      return Container(color: placeholderColor);
    }
    return CachedNetworkImage(
      imageUrl: displayUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: placeholderColor),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image_outlined, size: 72),
    );
  }
}

class _WindowsWallpaperVideoPlayer extends StatefulWidget {
  const _WindowsWallpaperVideoPlayer({
    required this.mediaUrl,
    required this.placeholderColor,
    this.placeholderUrl,
  });

  final String mediaUrl;
  final String? placeholderUrl;
  final Color placeholderColor;

  @override
  State<_WindowsWallpaperVideoPlayer> createState() =>
      _WindowsWallpaperVideoPlayerState();
}

class _WindowsWallpaperVideoPlayerState
    extends State<_WindowsWallpaperVideoPlayer>
    with AutomaticKeepAliveClientMixin {
  late final Player _player;
  late final VideoController _controller;
  StreamSubscription<String>? _errorSubscription;
  bool _initialized = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _player = Player(configuration: const PlayerConfiguration());
    _controller = VideoController(_player);
    _errorSubscription = _player.stream.error.listen((message) {
      if (!mounted || message.isEmpty) {
        return;
      }
      setState(() {
        _error = message;
      });
    });
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _error = null;
      _initialized = false;
    });
    try {
      await _player.stop();
    } catch (_) {
      // Ignore stop errors when nothing is playing yet.
    }
    try {
      var source = widget.mediaUrl;
      try {
        final file = await DefaultCacheManager().getSingleFile(widget.mediaUrl);
        source = file.uri.toString();
      } catch (_) {
        // Si falla la cache, continuamos con la URL remota.
      }
      await _player.setPlaylistMode(PlaylistMode.single);
      await _player.setVolume(0);
      await _player.open(Playlist([Media(source)]), play: true);
      await _controller.waitUntilFirstFrameRendered;
      if (!mounted) {
        return;
      }
      setState(() {
        _initialized = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _WindowsWallpaperVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _initialize();
    }
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Widget _buildPlaceholder() {
    final color = widget.placeholderColor;
    final url = widget.placeholderUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(color: color),
        errorWidget: (context, _, error) => Container(
          color: color,
          alignment: Alignment.center,
          child: const Icon(
            Icons.videocam_off_rounded,
            color: Colors.white70,
            size: 48,
          ),
        ),
      );
    }
    return Container(color: color);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final placeholderColor = widget.placeholderColor;
    if (_error != null) {
      final rawMessage = _error?.toString() ?? '';
      final message = rawMessage.isEmpty
          ? 'No se pudo reproducir la animación.'
          : rawMessage.replaceFirst('Exception: ', '');
      return Container(
        color: placeholderColor,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _initialize,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (!_initialized) {
      return _buildPlaceholder();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Video(controller: _controller, controls: null, fit: BoxFit.cover),
        const _VideoBadge(),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _VideoWallpaperPlayer extends StatefulWidget {
  const _VideoWallpaperPlayer({
    required this.mediaUrl,
    required this.placeholderColor,
    this.placeholderUrl,
  });

  final String mediaUrl;
  final String? placeholderUrl;
  final Color placeholderColor;

  @override
  State<_VideoWallpaperPlayer> createState() => _VideoWallpaperPlayerState();
}

class _VideoWallpaperPlayerState extends State<_VideoWallpaperPlayer>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _initialized = false;
  Object? _error;
  bool _usingFile = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant _VideoWallpaperPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaUrl != widget.mediaUrl) {
      _initializeController();
    }
  }

  Future<void> _initializeController({bool forceFile = false}) async {
    final previous = _controller;
    _controller = null;
    _initialized = false;
    _error = null;
    if (!forceFile) {
      _usingFile = false;
    }
    if (previous != null) {
      await previous.pause();
      await previous.dispose();
    }
    if (widget.mediaUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _error = Exception('Media URL vacia');
        });
      }
      return;
    }
    final shouldUseFile = forceFile || (Platform.isWindows && !_usingFile);
    VideoPlayerController controller;
    try {
      if (shouldUseFile) {
        final file = await DefaultCacheManager().getSingleFile(widget.mediaUrl);
        controller = VideoPlayerController.file(file)
          ..setLooping(true)
          ..setVolume(0);
      } else {
        controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.mediaUrl))
              ..setLooping(true)
              ..setVolume(0);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
      });
      return;
    }

    controller.addListener(() {
      final value = controller.value;
      if (!mounted || !value.hasError) {
        return;
      }
      final description = value.errorDescription ?? 'Error de reproducción';
      if (_error == null || _error.toString() != description) {
        setState(() {
          _error = description;
        });
      }
    });

    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _initialized = true;
        _usingFile = shouldUseFile;
      });
      unawaited(controller.play());
    } catch (error) {
      await controller.dispose();
      if (Platform.isWindows && !forceFile) {
        await _initializeController(forceFile: true);
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
      });
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final placeholderColor = widget.placeholderColor;
    if (_error != null) {
      final rawMessage = _error?.toString() ?? '';
      final message =
          rawMessage.isEmpty || rawMessage.contains('Media URL vacia')
          ? 'No se pudo reproducir la animación.'
          : rawMessage.replaceFirst('Exception: ', '');
      return Container(
        color: placeholderColor,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => _initializeController(
                forceFile: Platform.isWindows && !_usingFile,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    final controller = _controller;
    if (controller == null ||
        !_initialized ||
        !controller.value.isInitialized) {
      final fallback = widget.placeholderUrl;
      if (fallback != null && fallback.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: fallback,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: placeholderColor),
          errorWidget: (context, url, error) => Container(
            color: placeholderColor,
            alignment: Alignment.center,
            child: const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white70,
              size: 48,
            ),
          ),
        );
      }
      return Container(color: placeholderColor);
    }
    final videoSize = controller.value.size;
    final width = videoSize.width <= 0 ? 1.0 : videoSize.width;
    final height = videoSize.height <= 0 ? 1.0 : videoSize.height;
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: width,
            height: height,
            child: VideoPlayer(controller),
          ),
        ),
        const _VideoBadge(),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
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
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
