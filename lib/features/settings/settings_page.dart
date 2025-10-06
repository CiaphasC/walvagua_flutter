import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../providers/app_config_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/layout_provider.dart';
import '../../providers/search_history_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((value) {
      if (mounted) {
        setState(() => _packageInfo = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final layoutState = ref.watch(layoutProvider);
    final appConfig = ref.watch(appConfigProvider);
    final settings = appConfig.settings;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        SwitchListTile.adaptive(
          title: const Text('Tema oscuro'),
          subtitle: const Text('Mejor para tu vista y batería'),
          value: themeMode == ThemeMode.dark,
          onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_active_rounded),
          title: const Text('Notificaciones'),
          subtitle: const Text('Administra las alertas del sistema'),
          onTap: _openNotificationSettings,
        ),
        ListTile(
          leading: const Icon(Icons.grid_view_rounded),
          title: const Text('Columnas de wallpaper'),
          subtitle: Text('${layoutState.wallpaperColumns} columnas'),
          onTap: () => _showWallpaperColumnsDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.category_rounded),
          title: const Text('Vista de categorías'),
          subtitle: Text(layoutState.categoryLayout == CategoryLayout.list ? 'Lista' : '2 columnas'),
          onTap: () => _showCategoryLayoutDialog(context),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cleaning_services_rounded),
          title: const Text('Vaciar caché de imágenes'),
          subtitle: const Text('Libera espacio borrando miniaturas almacenadas'),
          onTap: () => _clearCache(context),
        ),
        ListTile(
          leading: const Icon(Icons.history_rounded),
          title: const Text('Borrar historial de búsqueda'),
          onTap: () {
            ref.read(searchHistoryProvider.notifier).clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Historial eliminado.')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.favorite_border),
          title: const Text('Limpiar favoritos'),
          onTap: () {
            ref.read(favoritesProvider.notifier).clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Se eliminaron los favoritos.')),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Política de privacidad'),
          onTap: () => _openUrl(settings?.privacyPolicy ?? ''),
        ),
        ListTile(
          leading: const Icon(Icons.star_rate_rounded),
          title: const Text('Calificanos'),
          onTap: () => _openUrl('https://play.google.com/store/apps/details?id=${_packageInfo?.packageName ?? 'com.wall.vaguada'}'),
        ),
        ListTile(
          leading: const Icon(Icons.share_rounded),
          title: const Text('Compartir app'),
          onTap: () => SharePlus.instance.share(
            ShareParams(
              text:
                  'Descarga WallVagua en https://play.google.com/store/apps/details?id=${_packageInfo?.packageName ?? 'com.wall.vaguada'}',
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.apps_rounded),
          title: const Text('Más aplicaciones'),
          onTap: () => _openUrl(settings?.moreAppsUrl ?? ''),
        ),
        const Divider(),
        if (_packageInfo != null)
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Acerca de'),
            subtitle: Text('Versión ${_packageInfo!.version}+${_packageInfo!.buildNumber}'),
          ),
      ],
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await DefaultCacheManager().emptyCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Caché limpiada.')),
    );
  }

  void _openNotificationSettings() {
    AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  void _showWallpaperColumnsDialog(BuildContext context) {
    final controller = ref.read(layoutProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('2 columnas'),
                onTap: () {
                  controller.setWallpaperColumns(2);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('3 columnas'),
                onTap: () {
                  controller.setWallpaperColumns(3);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryLayoutDialog(BuildContext context) {
    final controller = ref.read(layoutProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Vista de lista'),
                onTap: () {
                  controller.setCategoryLayout(CategoryLayout.list);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Vista en cuadrícula'),
                onTap: () {
                  controller.setCategoryLayout(CategoryLayout.grid2);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    if (url.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace no disponible.')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace.')),
      );
    }
  }
}

