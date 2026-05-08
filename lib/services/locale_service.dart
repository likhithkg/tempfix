// lib/services/locale_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  /// Notifier that main.dart listens to.
  /// If null, system locale is used (MaterialApp will fall back).
  final ValueNotifier<Locale?> localeNotifier = ValueNotifier<Locale?>(null);

  static const _prefsKey = 'km_selected_locale';

  /// Map of display language names (as used in your Dropdown) to Locale objects.
  /// Keep this list in sync with the dropdown values in ProfilePage.
  final Map<String, Locale> supportedLanguages = {
    'English': const Locale('en'),
    'हिन्दी': const Locale('hi'),
    'ಕನ್ನಡ': const Locale('kn'),
    'தமிழ்': const Locale('ta'),
    'తెలుగు': const Locale('te'),
    'मराठी': const Locale('mr'),
  };

  /// Reverse map for convenience (locale.languageCode -> display name)
  Map<String, String> get _localeCodeToName =>
      {for (var e in supportedLanguages.entries) e.value.languageCode: e.key};

  /// Initialize the service and load saved locale (call at app start).
  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      // saved is languageCode (eg 'en', 'hi')
      localeNotifier.value = Locale(saved);
    } else {
      localeNotifier.value = null; // use system locale
    }
  }

  /// Set the locale directly and persist it.
  Future<void> setLocale(Locale? locale) async {
    final sp = await SharedPreferences.getInstance();
    if (locale == null) {
      await sp.remove(_prefsKey);
      localeNotifier.value = null;
    } else {
      await sp.setString(_prefsKey, locale.languageCode);
      localeNotifier.value = locale;
    }
  }

  /// Set locale using the display language name (e.g. 'हिन्दी').
  /// Returns true if succeeded (language found).
  Future<bool> setLocaleByName(String name) async {
    final locale = supportedLanguages[name];
    if (locale == null) return false;
    await setLocale(locale);
    return true;
  }

  /// Return the display language name for a given locale (or default to 'English').
  String languageNameForLocale(Locale? locale) {
    if (locale == null) return 'English';
    return _localeCodeToName[locale.languageCode] ?? 'English';
  }

  /// Try to get the currently saved language display name (or fallback).
  String get currentLanguageName {
    final loc = localeNotifier.value;
    return languageNameForLocale(loc);
  }

  /// Returns a list of display names for UI (dropdowns).
  List<String> get languageNames => supportedLanguages.keys.toList();

  /// Utility: converts saved language name (from Profile) to Locale and sets it.
  /// Use this if profile language is saved as display name.
  Future<void> applyProfileLanguage(String? profileLanguageName) async {
    if (profileLanguageName == null || profileLanguageName.isEmpty) return;
    final ok = await setLocaleByName(profileLanguageName);
    if (!ok) {
      // if unknown name, ignore and keep existing locale
    }
  }
}
