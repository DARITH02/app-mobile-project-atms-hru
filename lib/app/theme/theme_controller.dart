import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);

  static final instance = ThemeController._();
  static const _storageKey = 'theme_mode';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    value = _fromStorage(preferences.getString(_storageKey));
  }

  Future<void> setMode(ThemeMode mode) async {
    if (value == mode) return;

    value = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, _toStorage(mode));
  }

  static ThemeMode _fromStorage(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _toStorage(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
