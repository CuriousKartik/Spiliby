import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class LocalDb {
  static const _kProfile = 'spiliby.profile';
  static const _kFriends = 'spiliby.friends';
  static const _kGroups = 'spiliby.groups';
  static const _kGroupMembers = 'spiliby.groupMembers';
  static const _kExpenses = 'spiliby.expenses';
  static const _kSettlements = 'spiliby.settlements';
  static const _kSettings = 'spiliby.settings';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<Map<String, dynamic>?> getProfile() async {
    final p = await _prefs;
    final raw = p.getString(_kProfile);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> setProfile(Map<String, dynamic>? profile) async {
    final p = await _prefs;
    if (profile == null) {
      await p.remove(_kProfile);
    } else {
      await p.setString(_kProfile, jsonEncode(profile));
    }
  }

  static Future<List<Map<String, dynamic>>> _getList(String key) async {
    final p = await _prefs;
    final raw = p.getString(key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> _setList(String key, List<Map<String, dynamic>> value) async {
    final p = await _prefs;
    await p.setString(key, jsonEncode(value));
  }

  static Future<List<Map<String, dynamic>>> getFriends() => _getList(_kFriends);
  static Future<void> setFriends(List<Map<String, dynamic>> v) => _setList(_kFriends, v);

  static Future<List<Map<String, dynamic>>> getGroups() => _getList(_kGroups);
  static Future<void> setGroups(List<Map<String, dynamic>> v) => _setList(_kGroups, v);

  static Future<List<Map<String, dynamic>>> getGroupMembers() => _getList(_kGroupMembers);
  static Future<void> setGroupMembers(List<Map<String, dynamic>> v) => _setList(_kGroupMembers, v);

  static Future<List<Map<String, dynamic>>> getExpenses() => _getList(_kExpenses);
  static Future<void> setExpenses(List<Map<String, dynamic>> v) => _setList(_kExpenses, v);

  static Future<List<Map<String, dynamic>>> getSettlements() => _getList(_kSettlements);
  static Future<void> setSettlements(List<Map<String, dynamic>> v) => _setList(_kSettlements, v);

  static Future<Map<String, dynamic>> getSettings() async {
    final p = await _prefs;
    final raw = p.getString(_kSettings);
    if (raw == null) return {'id': 'app', 'theme': 'light', 'notificationsEnabled': true};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> setSettings(Map<String, dynamic> settings) async {
    final p = await _prefs;
    await p.setString(_kSettings, jsonEncode(settings));
  }

  static Future<void> clearAll() async {
    final p = await _prefs;
    await Future.wait([
      p.remove(_kProfile),
      p.remove(_kFriends),
      p.remove(_kGroups),
      p.remove(_kGroupMembers),
      p.remove(_kExpenses),
      p.remove(_kSettlements),
      p.remove(_kSettings),
    ]);
  }
}