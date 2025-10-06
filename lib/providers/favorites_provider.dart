import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../data/models/wallpaper.dart';
import 'app_config_provider.dart';

final favoritesProvider = StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  return FavoritesController(ref.watch(sharedPrefsProvider));
});

class FavoritesState {
  const FavoritesState({this.items = const <Wallpaper>[]});

  final List<Wallpaper> items;

  bool contains(String id) => items.any((element) => element.imageId == id);
}

class FavoritesController extends StateNotifier<FavoritesState> {
  FavoritesController(this._preferences) : super(const FavoritesState()) {
    _loadFavorites();
  }

  final SharedPreferences _preferences;

  Future<void> _loadFavorites() async {
    final raw = _preferences.getString(AppConstants.sharedPrefsFavoritesKey);
    if (raw == null || raw.isEmpty) {
      state = const FavoritesState(items: <Wallpaper>[]);
      return;
    }
    final List<dynamic> jsonList = jsonDecode(raw) as List<dynamic>;
    final favorites = jsonList
        .map((item) => Wallpaper.fromJson((item as Map<dynamic, dynamic>).map((key, value) => MapEntry(key.toString(), value))))
        .toList();
    state = FavoritesState(items: favorites);
  }

  void toggle(Wallpaper wallpaper) {
    final exists = state.items.any((item) => item.imageId == wallpaper.imageId);
    if (exists) {
      remove(wallpaper.imageId);
    } else {
      add(wallpaper);
    }
  }

  void add(Wallpaper wallpaper) {
    final updated = <Wallpaper>[...state.items];
    if (!updated.any((item) => item.imageId == wallpaper.imageId)) {
      updated.insert(0, wallpaper);
      state = FavoritesState(items: updated);
      _persist();
    }
  }

  void remove(String id) {
    final updated = state.items.where((item) => item.imageId != id).toList();
    state = FavoritesState(items: updated);
    _persist();
  }

  void clear() {
    state = const FavoritesState(items: <Wallpaper>[]);
    _preferences.remove(AppConstants.sharedPrefsFavoritesKey);
  }

  void _persist() {
    final raw = jsonEncode(state.items.map((e) => e.toJson()).toList());
    _preferences.setString(AppConstants.sharedPrefsFavoritesKey, raw);
  }
}
