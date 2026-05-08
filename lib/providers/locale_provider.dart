import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  // 🔄 Change Language
  void setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  // 📥 Load Saved Language
  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString('language_code');

    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }
}