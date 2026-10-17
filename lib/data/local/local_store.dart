import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/json_utils.dart';

/// Thin wrapper over shared_preferences. Collections are stored as JSON blobs.
class LocalStore {
  LocalStore(this.prefs);

  final SharedPreferences prefs;

  List<Map<String, dynamic>> readList(String key) {
    final s = prefs.getString(key);
    if (s == null) return [];
    try {
      return mapList(jsonDecode(s));
    } catch (_) {
      return [];
    }
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> list) =>
      prefs.setString(key, jsonEncode(list));

  String? getString(String key) => prefs.getString(key);

  Future<void> setString(String key, String value) =>
      prefs.setString(key, value);

  Future<void> remove(String key) => prefs.remove(key);
}
