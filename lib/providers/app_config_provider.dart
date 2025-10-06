import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../data/models/menu_tab.dart';
import '../data/models/settings_payload.dart';
import '../data/repositories/app_repository.dart';
import '../data/repositories/wallpaper_repository.dart';
import '../data/services/api_service.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepository(ref.watch(sharedPrefsProvider));
});

final appConfigProvider = StateNotifierProvider<AppConfigController, AppConfigState>((ref) {
  return AppConfigController(
    ref.watch(appRepositoryProvider),
    ref.watch(sharedPrefsProvider),
  );
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final state = ref.watch(appConfigProvider);
  final baseUrl = state.baseUrl;
  if (baseUrl == null || baseUrl.isEmpty) {
    throw StateError('Base URL no inicializada');
  }
  return ApiService(baseUrl);
});

final wallpaperRepositoryProvider = Provider<WallpaperRepository>((ref) {
  return WallpaperRepository(ref.watch(apiServiceProvider));
});

class AppConfigState {
  const AppConfigState({
    this.isLoading = false,
    this.isReady = false,
    this.isUsingCache = false,
    this.errorMessage,
    this.baseUrl,
    this.menus = const <MenuTab>[],
    this.settings,
    this.app,
  });

  final bool isLoading;
  final bool isReady;
  final bool isUsingCache;
  final String? errorMessage;
  final String? baseUrl;
  final List<MenuTab> menus;
  final SettingsInfo? settings;
  final AppInfo? app;

  AppConfigState copyWith({
    bool? isLoading,
    bool? isReady,
    bool? isUsingCache,
    String? errorMessage,
    bool clearError = false,
    String? baseUrl,
    List<MenuTab>? menus,
    SettingsInfo? settings,
    AppInfo? app,
  }) {
    return AppConfigState(
      isLoading: isLoading ?? this.isLoading,
      isReady: isReady ?? this.isReady,
      isUsingCache: isUsingCache ?? this.isUsingCache,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      baseUrl: baseUrl ?? this.baseUrl,
      menus: menus ?? this.menus,
      settings: settings ?? this.settings,
      app: app ?? this.app,
    );
  }
}

class AppConfigController extends StateNotifier<AppConfigState> {
  AppConfigController(this._repository, this._preferences) : super(const AppConfigState());

  final AppRepository _repository;
  final SharedPreferences _preferences;

  Future<void> initialize() async {
    if (state.isLoading || state.isReady) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final serverInfo = await _repository.decodeServerKey();
      final packageInfo = await PackageInfo.fromPlatform();
      var packageName = packageInfo.packageName;
      final targetPlatform = defaultTargetPlatform;
      final isMobilePlatform = targetPlatform == TargetPlatform.android || targetPlatform == TargetPlatform.iOS;

      if (serverInfo.applicationId != packageName) {
        if (isMobilePlatform) {
          throw StateError(
            'El applicationId no coincide con la licencia. Esperado ${serverInfo.applicationId}, pero se encontró $packageName',
          );
        }
        packageName = serverInfo.applicationId;
      }

      final settingsPayload = await _repository.fetchSettings(
        baseUrl: serverInfo.baseUrl,
        packageName: packageName,
      );

      if (settingsPayload.status.toLowerCase() != 'ok') {
        throw StateError('El servidor respondió con estado ${settingsPayload.status}');
      }

      final menus = settingsPayload.menus.isNotEmpty ? settingsPayload.menus : _defaultMenus();

      await _repository.cacheInitialData(settingsPayload, serverInfo.baseUrl);
      await _preferences.setString(
        AppConstants.sharedPrefsMenusKey,
        jsonEncode(menus.map((e) => e.toJson()).toList()),
      );

      state = state.copyWith(
        isLoading: false,
        isReady: true,
        isUsingCache: false,
        baseUrl: serverInfo.baseUrl,
        menus: menus,
        settings: settingsPayload.settings,
        app: settingsPayload.app,
      );
    } catch (error) {
      final usedCache = await _tryLoadCachedConfig(error);
      if (!usedCache) {
        state = state.copyWith(
          isLoading: false,
          isReady: false,
          errorMessage: error.toString(),
        );
      }
    }
  }

  Future<bool> _tryLoadCachedConfig(Object error) async {
    final cachedBaseUrl = _repository.getCachedBaseUrl();
    final cachedMenus = _repository.readCachedMenus();
    final cachedSettings = _repository.readCachedSettings();

    if (cachedBaseUrl == null || cachedBaseUrl.isEmpty || cachedSettings == null || cachedMenus.isEmpty) {
      return false;
    }

    state = state.copyWith(
      isLoading: false,
      isReady: true,
      isUsingCache: true,
      baseUrl: cachedBaseUrl,
      menus: cachedMenus,
      settings: cachedSettings,
      app: _repository.readCachedAppInfo(),
      errorMessage: error.toString(),
    );
    return true;
  }

  List<MenuTab> _defaultMenus() {
    return <MenuTab>[
      MenuTab(
        id: 'recent',
        title: 'Recent',
        order: WallpaperOrder.recent,
        filter: WallpaperFilterType.wallpaper,
        category: '0',
      ),
      MenuTab(
        id: 'featured',
        title: 'Featured',
        order: WallpaperOrder.featured,
        filter: WallpaperFilterType.both,
        category: '0',
      ),
      MenuTab(
        id: 'popular',
        title: 'Popular',
        order: WallpaperOrder.popular,
        filter: WallpaperFilterType.wallpaper,
        category: '0',
      ),
      MenuTab(
        id: 'random',
        title: 'Random',
        order: WallpaperOrder.random,
        filter: WallpaperFilterType.wallpaper,
        category: '0',
      ),
      MenuTab(
        id: 'live',
        title: 'Live Wallpaper',
        order: WallpaperOrder.recent,
        filter: WallpaperFilterType.live,
        category: '0',
      ),
    ];
  }
}
