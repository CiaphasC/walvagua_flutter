import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import 'app_config_provider.dart';

final searchHistoryProvider = NotifierProvider<SearchHistoryController, List<String>>(
  SearchHistoryController.new,
);

class SearchHistoryController extends Notifier<List<String>> {
  SearchHistoryController();

  late final SharedPreferences _preferences;

  @override
  List<String> build() {
    _preferences = ref.watch(sharedPrefsProvider);
    final raw = _preferences.getString(AppConstants.searchHistoryKey);
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => e.toString()).toList();
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
