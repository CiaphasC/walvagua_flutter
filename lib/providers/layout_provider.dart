import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'app_config_provider.dart';

final layoutProvider = NotifierProvider<LayoutController, LayoutState>(
  LayoutController.new,
);

class LayoutState {
  const LayoutState({
    required this.wallpaperColumns,
    required this.categoryLayout,
  });

  final int wallpaperColumns;
  final String categoryLayout;

  LayoutState copyWith({int? wallpaperColumns, String? categoryLayout}) {
    return LayoutState(
      wallpaperColumns: wallpaperColumns ?? this.wallpaperColumns,
      categoryLayout: categoryLayout ?? this.categoryLayout,
    );
  }
}

class LayoutController extends Notifier<LayoutState> {
  LayoutController();

  late final SharedPreferences _preferences;

  @override
  LayoutState build() {
    _preferences = ref.watch(sharedPrefsProvider);
    return LayoutState(
      wallpaperColumns:
          _preferences.getInt(AppConstants.sharedPrefsWallpaperColumnsKey) ?? AppConstants.defaultWallpaperColumns,
      categoryLayout:
          _preferences.getString(AppConstants.sharedPrefsCategoryLayoutKey) ?? AppConstants.defaultCategoryLayout,
    );
  }

  void setWallpaperColumns(int columns) {
    state = state.copyWith(wallpaperColumns: columns);
    _preferences.setInt(AppConstants.sharedPrefsWallpaperColumnsKey, columns);
  }

  void setCategoryLayout(String layout) {
    state = state.copyWith(categoryLayout: layout);
    _preferences.setString(AppConstants.sharedPrefsCategoryLayoutKey, layout);
  }
}
