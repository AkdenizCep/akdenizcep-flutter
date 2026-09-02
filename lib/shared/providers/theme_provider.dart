import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModePrefKey = 'app_theme_mode_preference';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadPersistedTheme();
    return ThemeMode.system;
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeModePrefKey);
      if (saved == 'light') {
        state = ThemeMode.light;
      } else if (saved == 'dark') {
        state = ThemeMode.dark;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.light) {
        await prefs.setString(_themeModePrefKey, 'light');
      } else if (mode == ThemeMode.dark) {
        await prefs.setString(_themeModePrefKey, 'dark');
      } else {
        await prefs.remove(_themeModePrefKey);
      }
    } catch (_) {}
  }
}
