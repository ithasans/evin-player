import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFavorites = 'favorite_song_ids';
  static const String _keyDownloads = 'downloaded_songs_map';
  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keyLanguage = 'app_language_code';
  static const String _keyLastSongId = 'last_played_song_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Set<String> getFavoriteIds() {
    final list = _prefs.getStringList(_keyFavorites) ?? [];
    return list.toSet();
  }

  Future<void> saveFavoriteIds(Set<String> ids) async {
    await _prefs.setStringList(_keyFavorites, ids.toList());
  }

  Map<String, String> getDownloadedPaths() {
    final raw = _prefs.getString(_keyDownloads);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDownloadedPaths(Map<String, String> map) async {
    await _prefs.setString(_keyDownloads, json.encode(map));
  }

  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'dark';
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String getLanguageCode() {
    return _prefs.getString(_keyLanguage) ?? 'ar';
  }

  Future<void> saveLanguageCode(String code) async {
    await _prefs.setString(_keyLanguage, code);
  }

  String? getLastPlayedSongId() {
    return _prefs.getString(_keyLastSongId);
  }

  Future<void> saveLastPlayedSongId(String songId) async {
    await _prefs.setString(_keyLastSongId, songId);
  }
}
