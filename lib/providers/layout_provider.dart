import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'app_config_provider.dart';

final layoutProvider = StateNotifierProvider<LayoutController, LayoutState>((ref) {
  return LayoutController(ref.watch(sharedPrefsProvider));
});

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

class LayoutController extends StateNotifier<LayoutState> {
  LayoutController(this._preferences)
      : super(
          LayoutState(
            wallpaperColumns: _preferences.getInt(AppConstants.sharedPrefsWallpaperColumnsKey) ??
                AppConstants.defaultWallpaperColumns,
            categoryLayout: _preferences.getString(AppConstants.sharedPrefsCategoryLayoutKey) ??
                AppConstants.defaultCategoryLayout,
          ),
        );

  final SharedPreferences _preferences;

  void setWallpaperColumns(int columns) {
    state = state.copyWith(wallpaperColumns: columns);
    _preferences.setInt(AppConstants.sharedPrefsWallpaperColumnsKey, columns);
  }

  void setCategoryLayout(String layout) {
    state = state.copyWith(categoryLayout: layout);
    _preferences.setString(AppConstants.sharedPrefsCategoryLayoutKey, layout);
  }
}
