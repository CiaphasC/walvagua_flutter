import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/utils/base64_utils.dart';
import '../models/menu_tab.dart';
import '../models/settings_payload.dart';
import '../services/api_service.dart';

class AppRepository {
  AppRepository(this._preferences);

  final SharedPreferences _preferences;

  Future<ServerKeyInfo> decodeServerKey() async {
    final decoded = Base64Utils.tripleDecode(AppConstants.serverKey);
    final parts = decoded.split('_applicationId_');
    if (parts.length != 2) {
      throw const FormatException('Clave de servidor inválida');
    }
    final rawBaseUrl = parts.first.trim();
    final baseUrl = _resolvePlatformBaseUrl(rawBaseUrl);
    final appId = parts.last.trim();
    return ServerKeyInfo(baseUrl: baseUrl, applicationId: appId);
  }

  Future<SettingsPayload> fetchSettings({
    required String baseUrl,
    required String packageName,
  }) async {
    final api = ApiService(baseUrl);
    final payload = await api.get(
      'api.php',
      query: <String, dynamic>{
        'get_settings': '',
        'package_name': packageName,
      },
    );
    if (payload.isEmpty) {
      throw const FormatException('Respuesta de ajustes vacía');
    }
    return SettingsPayload.fromJson(payload);
  }

  Future<void> cacheInitialData(SettingsPayload payload, String baseUrl) async {
    await _preferences.setString(AppConstants.sharedPrefsBaseUrlKey, baseUrl);
    await _preferences.setString(
      AppConstants.sharedPrefsSettingsKey,
      jsonEncode(payload.settings.toJson()),
    );
    await _preferences.setString(
      AppConstants.sharedPrefsAppInfoKey,
      jsonEncode(payload.app.toJson()),
    );
    await _preferences.setString(
      AppConstants.sharedPrefsMenusKey,
      jsonEncode(payload.menus.map((e) => e.toJson()).toList()),
    );
    await _preferences.setString(
      AppConstants.sharedPrefsLastSyncKey,
      DateTime.now().toIso8601String(),
    );
  }

  String? getCachedBaseUrl() => _preferences.getString(AppConstants.sharedPrefsBaseUrlKey);

  SettingsInfo? readCachedSettings() {
    final raw = _preferences.getString(AppConstants.sharedPrefsSettingsKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    return SettingsInfo.fromJson(map);
  }

  AppInfo? readCachedAppInfo() {
    final raw = _preferences.getString(AppConstants.sharedPrefsAppInfoKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    return AppInfo.fromJson(map);
  }

  List<MenuTab> readCachedMenus() {
    final raw = _preferences.getString(AppConstants.sharedPrefsMenusKey);
    if (raw == null || raw.isEmpty) {
      return <MenuTab>[];
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (item) =>
              MenuTab.fromJson((item as Map<dynamic, dynamic>).map((key, value) => MapEntry(key.toString(), value))),
        )
        .toList();
  }
}

class ServerKeyInfo {
  const ServerKeyInfo({required this.baseUrl, required this.applicationId});

  final String baseUrl;
  final String applicationId;
}

String _resolvePlatformBaseUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host != 'localhost') {
    return url;
  }

  final replacementHost = () {
    if (kIsWeb) {
      return '127.0.0.1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }();

  return uri.replace(host: replacementHost).toString();
}
