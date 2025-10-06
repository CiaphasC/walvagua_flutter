import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'app_config_provider.dart';

final searchHistoryProvider = StateNotifierProvider<SearchHistoryController, List<String>>((ref) {
  return SearchHistoryController(ref.watch(sharedPrefsProvider));
});

class SearchHistoryController extends StateNotifier<List<String>> {
  SearchHistoryController(this._preferences) : super(const <String>[]) {
    _load();
  }

  final SharedPreferences _preferences;

  void _load() {
    final raw = _preferences.getString(AppConstants.searchHistoryKey);
    if (raw == null || raw.isEmpty) {
      state = const <String>[];
      return;
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    state = decoded.map((e) => e.toString()).toList();
  }

  void add(String term) {
    if (term.trim().isEmpty) {
      return;
    }
    final updated = [term, ...state.where((element) => element.toLowerCase() != term.toLowerCase())];
    if (updated.length > 20) {
      updated.removeRange(20, updated.length);
    }
    state = updated;
    _save();
  }

  void clear() {
    state = const <String>[];
    _preferences.remove(AppConstants.searchHistoryKey);
  }

  void _save() {
    _preferences.setString(AppConstants.searchHistoryKey, jsonEncode(state));
  }
}
