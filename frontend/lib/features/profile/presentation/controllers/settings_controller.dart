import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/repositories/profile_repository_impl.dart';

const String kDoubleTapReactionKey = 'pref_double_tap_reaction';
const String kThemeModeKey = 'pref_theme_mode';
const String kCachedUserSettingsKey = 'pref_cached_user_settings_json';

/// Synchronous provider initialized at app boot before runApp()
final initialSettingsProvider = Provider<UserSettings>((ref) {
  return const UserSettings();
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, UserSettings>(() {
  return SettingsController();
});

final doubleTapReactionProvider = Provider<String>((ref) {
  final settings = ref.watch(settingsControllerProvider).value;
  return settings?.doubleTapReaction ?? '❤️';
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsControllerProvider).value;
  final themeStr = settings?.themeMode ?? 'system';
  if (themeStr == 'light') return ThemeMode.light;
  if (themeStr == 'dark') return ThemeMode.dark;
  return ThemeMode.system;
});

class SettingsController extends AsyncNotifier<UserSettings> {
  late ProfileRepository _repository;

  /// Loads settings directly from local device storage (SharedPreferences).
  /// Can be called at any time, anywhere in the app without network dependency.
  static Future<UserSettings> loadLocalSettings() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final cachedJsonStr = preferences.getString(kCachedUserSettingsKey);

      UserSettings settings;
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJsonStr);
          if (decoded is Map<String, dynamic>) {
            settings = UserSettings.fromJson(decoded);
          } else {
            settings = const UserSettings();
          }
        } catch (_) {
          settings = const UserSettings();
        }
      } else {
        settings = const UserSettings();
      }

      // Explicit local overrides take highest precedence for device preferences
      final savedTheme = preferences.getString(kThemeModeKey);
      final savedReaction = preferences.getString(kDoubleTapReactionKey);

      return settings.copyWith(
        themeMode: savedTheme ?? settings.themeMode,
        doubleTapReaction: savedReaction ?? settings.doubleTapReaction,
      );
    } catch (_) {
      return const UserSettings();
    }
  }

  /// Persists settings to local device storage immediately.
  static Future<void> saveLocalSettings(UserSettings settings) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(kThemeModeKey, settings.themeMode);
      await preferences.setString(kDoubleTapReactionKey, settings.doubleTapReaction);
      await preferences.setString(kCachedUserSettingsKey, jsonEncode(settings.toJson()));
    } catch (_) {}
  }

  @override
  FutureOr<UserSettings> build() async {
    _repository = ref.read(profileRepositoryProvider);

    // 1. Start with the preloaded local settings or load from storage immediately
    var initial = ref.watch(initialSettingsProvider);
    if (initial.userId.isEmpty && initial.themeMode == 'system') {
      initial = await loadLocalSettings();
    }

    // 2. Fetch latest settings from server in background if available
    _syncRemoteSettings(initial);

    return initial;
  }

  Future<void> _syncRemoteSettings(UserSettings fallback) async {
    try {
      final remoteSettings = await _repository.getUserSettings();
      final preferences = await SharedPreferences.getInstance();
      final savedTheme = preferences.getString(kThemeModeKey) ?? fallback.themeMode;
      final savedReaction = preferences.getString(kDoubleTapReactionKey) ?? fallback.doubleTapReaction;

      final merged = remoteSettings.copyWith(
        themeMode: savedTheme,
        doubleTapReaction: savedReaction,
      );

      await saveLocalSettings(merged);
      state = AsyncData(merged);
    } catch (_) {
      // If remote fails (offline, unauthenticated, etc.), retain local data
      if (state.value == null) {
        state = AsyncData(fallback);
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final remoteSettings = await _repository.getUserSettings();
      final preferences = await SharedPreferences.getInstance();
      final savedTheme = preferences.getString(kThemeModeKey) ?? (state.value?.themeMode ?? 'system');
      final savedReaction = preferences.getString(kDoubleTapReactionKey) ?? (state.value?.doubleTapReaction ?? '❤️');

      final merged = remoteSettings.copyWith(
        themeMode: savedTheme,
        doubleTapReaction: savedReaction,
      );

      await saveLocalSettings(merged);
      state = AsyncData(merged);
    } catch (_) {
      // If refresh fails, fall back to cached local settings rather than breaking UI
      final local = await loadLocalSettings();
      state = AsyncData(local);
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final currentData = state.value ?? await loadLocalSettings();
    final updatedData = currentData.withUpdatedSetting(key, value);

    // Immediate optimistic local update
    state = AsyncData(updatedData);
    await saveLocalSettings(updatedData);

    try {
      await _repository.updatePrivacySetting({key: value});
    } catch (e) {
      // Revert on failure
      state = AsyncData(currentData);
      await saveLocalSettings(currentData);
      rethrow;
    }
  }

  Future<void> setDoubleTapReaction(String reaction) async {
    final currentData = state.value ?? await loadLocalSettings();
    final updatedData = currentData.copyWith(doubleTapReaction: reaction);

    state = AsyncData(updatedData);
    await saveLocalSettings(updatedData);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';

    final currentData = state.value ?? await loadLocalSettings();
    final updatedData = currentData.copyWith(themeMode: modeStr);

    state = AsyncData(updatedData);
    await saveLocalSettings(updatedData);
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    // Clear cached settings upon account deletion
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(kCachedUserSettingsKey);
    } catch (_) {}
  }
}
