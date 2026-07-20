import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences for simple flags and small values.
/// Structured data (tasks, habits, goals, user) lives in DatabaseService;
/// this is only for lightweight app state like "has onboarding finished".
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    await init();
    return _prefs!.getBool(key) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    await init();
    await _prefs!.setBool(key, value);
  }

  Future<String?> getString(String key) async {
    await init();
    return _prefs!.getString(key);
  }

  Future<void> setString(String key, String value) async {
    await init();
    await _prefs!.setString(key, value);
  }

  Future<void> remove(String key) async {
    await init();
    await _prefs!.remove(key);
  }
}
