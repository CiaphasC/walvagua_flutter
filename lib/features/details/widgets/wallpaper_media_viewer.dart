import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart';

import '../../../data/models/wallpaper.dart';

/// Visualizador reutilizable que muestra el contenido de un wallpaper.
/// Gestiona imágenes estáticas, GIFs y vídeos con soporte para escritorio y móvil.
class WallpaperMediaViewer extends StatelessWidget {
  const WallpaperMediaViewer({
    super.key,
    required this.wallpaper,
    this.showVideoBadge = true,
  });

  final Wallpaper wallpaper;
  final bool showVideoBadge;

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;
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
          showBadge: showVideoBadge,
        );
      }
      return _VideoWallpaperPlayer(
        mediaUrl: wallpaper.contentUrl,
        placeholderUrl: placeholderUrl,
        placeholderColor: placeholderColor,
        showBadge: showVideoBadge,
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
    this.showBadge = true,
  });

  final String mediaUrl;
  final String? placeholderUrl;
  final Color placeholderColor;
  final bool showBadge;

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
        if (widget.showBadge) const _VideoBadge(),
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
    this.showBadge = true,
  });

  final String mediaUrl;
  final String? placeholderUrl;
  final Color placeholderColor;
  final bool showBadge;

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
          _error = Exception('Media URL vacía');
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
      final message = rawMessage.isEmpty || rawMessage.contains('Media URL vacía')
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
        if (widget.showBadge) const _VideoBadge(),
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
