class AppConstants {
  AppConstants._();

  static const serverKey = 'WVVoU01HTklUVFpNZVRsNVpVYzRkVnB1WkcxTWJsSnNZbGhDZG1OdFJubGxVelY2WVZoU2JFd3paR3haYms1d1pFZFdaazlVYkcxTk1rVXhUVlJXWmxsWVFuZGlSMnhxV1ZoU2NHSXlOVXBhUmpscVlqSXdkV1F5Um5OaVF6VXlXVmRrTVZsWFVtZz0=';
  static const defaultPageSize2Columns = 12;
  static const defaultPageSize3Columns = 15;
  static const defaultWallpaperColumns = 2;
  static const defaultCategoryLayout = CategoryLayout.list;
  static const sharedPrefsThemeKey = 'prefs.theme.dark';
  static const sharedPrefsBaseUrlKey = 'prefs.base.url';
  static const sharedPrefsWallpaperColumnsKey = 'prefs.wallpaper.columns';
  static const sharedPrefsCategoryLayoutKey = 'prefs.category.layout';
  static const sharedPrefsFavoritesKey = 'prefs.favorites';
  static const sharedPrefsMenusKey = 'prefs.menus';
  static const sharedPrefsSettingsKey = 'prefs.settings.payload';
  static const sharedPrefsAppInfoKey = 'prefs.app.info';
  static const sharedPrefsLastSyncKey = 'prefs.last.sync';
  static const searchHistoryKey = 'prefs.search.history';
  static const splashDelay = Duration(milliseconds: 500);
  static const shimmerDelay = Duration(milliseconds: 1000);
}

class CategoryLayout {
  CategoryLayout._();
  static const list = 'list';
  static const grid2 = 'grid2';
}

class WallpaperFilterType {
  WallpaperFilterType._();
  static const both = 'both';
  static const wallpaper = 'wallpaper';
  static const live = 'live';
}

class WallpaperOrder {
  WallpaperOrder._();
  static const recent = 'recent';
  static const oldest = 'oldest';
  static const featured = 'featured';
  static const popular = 'popular';
  static const download = 'download';
  static const random = 'random';
}

class WallpaperAction {
  WallpaperAction._();
  static const apply = 'apply';
  static const download = 'download';
  static const share = 'share';
  static const setWith = 'setWith';
  static const crop = 'setCrop';
  static const setGif = 'setGif';
  static const setMp4 = 'setMp4';
}
