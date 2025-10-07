import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'app_config_provider.dart';

final themeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

class ThemeController extends Notifier<ThemeMode> {
  ThemeController();

  late final SharedPreferences _preferences;

  @override
  ThemeMode build() {
    _preferences = ref.watch(sharedPrefsProvider);
    final isDark = _preferences.getBool(AppConstants.sharedPrefsThemeKey) ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

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
