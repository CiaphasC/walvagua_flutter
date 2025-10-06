import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'app_config_provider.dart';

final themeProvider = StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController(ref.watch(sharedPrefsProvider));
});

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._preferences)
      : super(
          (_preferences.getBool(AppConstants.sharedPrefsThemeKey) ?? false)
              ? ThemeMode.dark
              : ThemeMode.light,
        );

  final SharedPreferences _preferences;

  void toggleTheme() {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _setTheme(next);
  }

  void setTheme(ThemeMode mode) {
    _setTheme(mode);
  }

  void _setTheme(ThemeMode mode) {
    state = mode;
    _preferences.setBool(AppConstants.sharedPrefsThemeKey, mode == ThemeMode.dark);
  }
}
