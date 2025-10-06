import 'dart:convert';

import 'menu_tab.dart';

class SettingsPayload {
  SettingsPayload({
    required this.status,
    required this.app,
    required this.menus,
    required this.settings,
    this.ads,
    this.adsStatus,
    this.adsPlacement,
    this.license,
  });

  final String status;
  final AppInfo app;
  final List<MenuTab> menus;
  final SettingsInfo settings;
  final AdsConfig? ads;
  final AdsStatus? adsStatus;
  final AdsPlacement? adsPlacement;
  final LicenseInfo? license;

  factory SettingsPayload.fromJson(Map<String, dynamic> json) {
    final menusJson = json['menus'] as List<dynamic>?;
    return SettingsPayload(
      status: json['status']?.toString() ?? '',
      app: AppInfo.fromJson(json['app'] as Map<String, dynamic>? ?? const {}),
      menus: menusJson == null
          ? []
          : menusJson.map((e) => MenuTab.fromJson(e as Map<String, dynamic>)).toList(),
      settings: SettingsInfo.fromJson(json['settings'] as Map<String, dynamic>? ?? const {}),
      ads: json['ads'] == null ? null : AdsConfig.fromJson(json['ads'] as Map<String, dynamic>),
      adsStatus: json['ads_status'] == null
          ? null
          : AdsStatus.fromJson(json['ads_status'] as Map<String, dynamic>),
      adsPlacement: json['ads_placement'] == null
          ? null
          : AdsPlacement.fromJson(json['ads_placement'] as Map<String, dynamic>),
      license: json['license'] == null
          ? null
          : LicenseInfo.fromJson(json['license'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'app': app.toJson(),
      'menus': menus.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      if (ads != null) 'ads': ads!.toJson(),
      if (adsStatus != null) 'ads_status': adsStatus!.toJson(),
      if (adsPlacement != null) 'ads_placement': adsPlacement!.toJson(),
      if (license != null) 'license': license!.toJson(),
    };
  }

  String toRawJson() => jsonEncode(toJson());
}

class AppInfo {
  AppInfo({
    required this.packageName,
    required this.status,
    required this.redirectUrl,
  });

  final String packageName;
  final String status;
  final String redirectUrl;

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      packageName: json['package_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '1',
      redirectUrl: json['redirect_url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'package_name': packageName,
        'status': status,
        'redirect_url': redirectUrl,
      };
}

class SettingsInfo {
  SettingsInfo({
    required this.privacyPolicy,
    required this.moreAppsUrl,
    required this.providers,
    required this.notificationTopic,
  });

  final String privacyPolicy;
  final String moreAppsUrl;
  final String providers;
  final String notificationTopic;

  factory SettingsInfo.fromJson(Map<String, dynamic> json) {
    return SettingsInfo(
      privacyPolicy: json['privacy_policy']?.toString() ?? '',
      moreAppsUrl: json['more_apps_url']?.toString() ?? '',
      providers: json['providers']?.toString() ?? '',
      notificationTopic: json['fcm_notification_topic']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'privacy_policy': privacyPolicy,
        'more_apps_url': moreAppsUrl,
        'providers': providers,
        'fcm_notification_topic': notificationTopic,
      };
}

class AdsConfig {
  AdsConfig({
    required this.adStatus,
    required this.adType,
  });

  final String adStatus;
  final String adType;

  factory AdsConfig.fromJson(Map<String, dynamic> json) {
    return AdsConfig(
      adStatus: json['ad_status']?.toString() ?? '',
      adType: json['ad_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'ad_status': adStatus,
        'ad_type': adType,
      };
}

class AdsStatus {
  AdsStatus({
    required this.isOn,
  });

  final bool isOn;

  factory AdsStatus.fromJson(Map<String, dynamic> json) {
    final status = json['ad_status']?.toString() ?? 'off';
    return AdsStatus(isOn: status.toLowerCase() == 'on');
  }

  Map<String, dynamic> toJson() => {
        'ad_status': isOn ? 'on' : 'off',
      };
}

class AdsPlacement {
  AdsPlacement({
    required this.banner,
    required this.interstitial,
  });

  final bool banner;
  final bool interstitial;

  factory AdsPlacement.fromJson(Map<String, dynamic> json) {
    bool parseFlag(dynamic value) => (value?.toString() ?? '0') == '1';
    return AdsPlacement(
      banner: parseFlag(json['banner']),
      interstitial: parseFlag(json['interstitial']),
    );
  }

  Map<String, dynamic> toJson() => {
        'banner': banner ? '1' : '0',
        'interstitial': interstitial ? '1' : '0',
      };
}

class LicenseInfo {
  LicenseInfo({
    required this.itemId,
    required this.itemName,
    required this.buyer,
    required this.licenseType,
  });

  final String itemId;
  final String itemName;
  final String buyer;
  final String licenseType;

  factory LicenseInfo.fromJson(Map<String, dynamic> json) {
    return LicenseInfo(
      itemId: json['item_id']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      buyer: json['buyer']?.toString() ?? '',
      licenseType: json['license_type']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'item_name': itemName,
        'buyer': buyer,
        'license_type': licenseType,
      };
}
