import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ValueNotifier<Locale> {
  LanguageController._() : super(const Locale('km'));

  static final instance = LanguageController._();
  static const _storageKey = 'app_locale';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_storageKey);
    value = code == 'en' ? const Locale('en') : const Locale('km');
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = locale.languageCode == 'en'
        ? const Locale('en')
        : const Locale('km');
    if (value == normalized) return;

    value = normalized;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, normalized.languageCode);
  }

  Future<void> toggle() {
    return setLocale(
      value.languageCode == 'km' ? const Locale('en') : const Locale('km'),
    );
  }
}
