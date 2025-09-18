import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mosaic.dart';

/// Service for persisting user data and preferences
class PersistenceService {
  static const String _keyUserId = 'user_id';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyFavoriteMosaics = 'favorite_mosaics';
  static const String _keyCachedMosaics = 'cached_mosaics';
  static const String _keyLastSync = 'last_sync';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotifications = 'notifications_enabled';
  static const String _keySelectedTeam = 'selected_team';
  static const String _keyViewMode = 'view_mode';

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Initialize the persistence service
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'PersistenceService not initialized. Call init() first.',
      );
    }
  }

  // User Authentication

  String? get userId {
    _checkInitialized();
    return _prefs.getString(_keyUserId);
  }

  set userId(String? value) {
    _checkInitialized();
    if (value != null) {
      _prefs.setString(_keyUserId, value);
    } else {
      _prefs.remove(_keyUserId);
    }
  }

  String? get authToken {
    _checkInitialized();
    return _prefs.getString(_keyAuthToken);
  }

  set authToken(String? value) {
    _checkInitialized();
    if (value != null) {
      _prefs.setString(_keyAuthToken, value);
    } else {
      _prefs.remove(_keyAuthToken);
    }
  }

  String? get username {
    _checkInitialized();
    return _prefs.getString(_keyUsername);
  }

  set username(String? value) {
    _checkInitialized();
    if (value != null) {
      _prefs.setString(_keyUsername, value);
    } else {
      _prefs.remove(_keyUsername);
    }
  }

  String? get email {
    _checkInitialized();
    return _prefs.getString(_keyEmail);
  }

  set email(String? value) {
    _checkInitialized();
    if (value != null) {
      _prefs.setString(_keyEmail, value);
    } else {
      _prefs.remove(_keyEmail);
    }
  }

  bool get isAuthenticated {
    _checkInitialized();
    return authToken != null && userId != null;
  }

  // User Preferences

  List<String> get favoriteMosaics {
    _checkInitialized();
    return _prefs.getStringList(_keyFavoriteMosaics) ?? [];
  }

  set favoriteMosaics(List<String> value) {
    _checkInitialized();
    _prefs.setStringList(_keyFavoriteMosaics, value);
  }

  void addFavorite(String mosaicId) {
    _checkInitialized();
    final favorites = favoriteMosaics;
    if (!favorites.contains(mosaicId)) {
      favorites.add(mosaicId);
      favoriteMosaics = favorites;
    }
  }

  void removeFavorite(String mosaicId) {
    _checkInitialized();
    final favorites = favoriteMosaics;
    favorites.remove(mosaicId);
    favoriteMosaics = favorites;
  }

  bool isFavorite(String mosaicId) {
    _checkInitialized();
    return favoriteMosaics.contains(mosaicId);
  }

  String get themeMode {
    _checkInitialized();
    return _prefs.getString(_keyThemeMode) ?? 'system';
  }

  set themeMode(String value) {
    _checkInitialized();
    _prefs.setString(_keyThemeMode, value);
  }

  bool get notificationsEnabled {
    _checkInitialized();
    return _prefs.getBool(_keyNotifications) ?? true;
  }

  set notificationsEnabled(bool value) {
    _checkInitialized();
    _prefs.setBool(_keyNotifications, value);
  }

  int? get selectedTeam {
    _checkInitialized();
    return _prefs.getInt(_keySelectedTeam);
  }

  set selectedTeam(int? value) {
    _checkInitialized();
    if (value != null) {
      _prefs.setInt(_keySelectedTeam, value);
    } else {
      _prefs.remove(_keySelectedTeam);
    }
  }

  String get viewMode {
    _checkInitialized();
    return _prefs.getString(_keyViewMode) ?? 'grid';
  }

  set viewMode(String value) {
    _checkInitialized();
    _prefs.setString(_keyViewMode, value);
  }

  // Data Caching

  List<Mosaic>? getCachedMosaics() {
    _checkInitialized();
    final jsonString = _prefs.getString(_keyCachedMosaics);
    if (jsonString == null) return null;

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Mosaic.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing cached mosaics: $e');
      return null;
    }
  }

  void cacheMosaics(List<Mosaic> mosaics) {
    _checkInitialized();
    try {
      final jsonList = mosaics.map((m) => m.toJson()).toList();
      final jsonString = json.encode(jsonList);
      _prefs.setString(_keyCachedMosaics, jsonString);
      _prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching mosaics: $e');
    }
  }

  DateTime? get lastSyncTime {
    _checkInitialized();
    final dateString = _prefs.getString(_keyLastSync);
    if (dateString == null) return null;

    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  bool get shouldRefreshCache {
    final lastSync = lastSyncTime;
    if (lastSync == null) return true;

    // Refresh cache if older than 5 minutes
    return DateTime.now().difference(lastSync).inMinutes > 5;
  }

  // Clear Methods

  Future<void> clearUserData() async {
    _checkInitialized();
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyAuthToken);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keySelectedTeam);
  }

  Future<void> clearCache() async {
    _checkInitialized();
    await _prefs.remove(_keyCachedMosaics);
    await _prefs.remove(_keyLastSync);
  }

  Future<void> clearAll() async {
    _checkInitialized();
    await _prefs.clear();
  }
}
