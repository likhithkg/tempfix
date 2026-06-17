import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {

  LocaleService._();

  static final LocaleService instance =
      LocaleService._();

  /// Main locale notifier
  final ValueNotifier<Locale?> localeNotifier =
      ValueNotifier<Locale?>(null);

  static const String _prefsKey =
      'km_selected_locale';

  /// Supported Languages
  final Map<String, Locale> supportedLanguages = {

    'English':
        const Locale('en'),

    'हिन्दी':
        const Locale('hi'),

    'ಕನ್ನಡ':
        const Locale('kn'),

    'தமிழ்':
        const Locale('ta'),

    'తెలుగు':
        const Locale('te'),

    'मराठी':
        const Locale('mr'),

    'മലയാളം':
        const Locale('ml'),
  };

  /// Reverse mapping
  Map<String, String> get _localeCodeToName => {

        for (var e in supportedLanguages.entries)

          e.value.languageCode: e.key
      };

  /// Initialize locale from saved prefs
  Future<void> init() async {

    final sp =
        await SharedPreferences.getInstance();

    final saved =
        sp.getString(_prefsKey);

    if (saved != null &&
        saved.isNotEmpty) {

      localeNotifier.value =
          Locale(saved);

    } else {

      /// Default locale
      localeNotifier.value =
          const Locale('en');
    }

    debugPrint(
      '🌐 Current Locale: '
      '${localeNotifier.value?.languageCode}',
    );
  }

  /// Set locale manually
  Future<void> setLocale(
    Locale? locale,
  ) async {

    final sp =
        await SharedPreferences.getInstance();

    if (locale == null) {

      await sp.remove(_prefsKey);

      localeNotifier.value =
          const Locale('en');

    } else {

      await sp.setString(
        _prefsKey,
        locale.languageCode,
      );

      localeNotifier.value = locale;
    }

    debugPrint(
      '✅ Locale Changed: '
      '${localeNotifier.value?.languageCode}',
    );
  }

  /// Set locale using display name
  Future<bool> setLocaleByName(
    String name,
  ) async {

    final locale =
        supportedLanguages[name];

    if (locale == null) {

      debugPrint(
        '❌ Unsupported language: $name',
      );

      return false;
    }

    await setLocale(locale);

    return true;
  }

  /// Get display language name
  String languageNameForLocale(
    Locale? locale,
  ) {

    if (locale == null) {

      return 'English';
    }

    return _localeCodeToName[
            locale.languageCode] ??
        'English';
  }

  /// Current selected language
  String get currentLanguageName {

    final loc =
        localeNotifier.value;

    return languageNameForLocale(loc);
  }

  /// Dropdown language names
  List<String> get languageNames =>

      supportedLanguages.keys.toList();

  /// Apply saved profile language
  Future<void> applyProfileLanguage(
    String? profileLanguageName,
  ) async {

    if (profileLanguageName == null ||
        profileLanguageName.isEmpty) {

      return;
    }

    final ok =
        await setLocaleByName(
      profileLanguageName,
    );

    if (!ok) {

      debugPrint(
        '⚠ Unknown profile language: '
        '$profileLanguageName',
      );
    }
  }

  /// Current locale getter
  Locale get currentLocale {

    return localeNotifier.value ??
        const Locale('en');
  }

  /// Current language code getter
  String get currentLanguageCode {

    return currentLocale.languageCode;
  }

  /// Check current language
  bool isCurrentLanguage(
    String languageCode,
  ) {

    return currentLanguageCode ==
        languageCode;
  }

  /// Reset locale
  Future<void> resetLocale() async {

    await setLocale(
      const Locale('en'),
    );
  }
}