import 'package:flutter/material.dart';

class LanguageManager extends ChangeNotifier {
  LanguageManager({
    Locale initialLocale = const Locale('en'),
  }) : _locale = initialLocale;

  Locale _locale;

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  void changeLanguage(String languageCode) {
    if (languageCode == _locale.languageCode) {
      return;
    }

    _locale = Locale(languageCode);
    notifyListeners();
  }

  void setLocale(Locale locale) {
    if (locale.languageCode == _locale.languageCode) {
      return;
    }

    _locale = locale;
    notifyListeners();
  }

  bool isEnglish() {
    return languageCode == 'en';
  }

  bool isHindi() {
    return languageCode == 'hi';
  }

  bool isMarathi() {
    return languageCode == 'mr';
  }

  bool isUrdu() {
    return languageCode == 'ur';
  }

  String get languageName {
    switch (languageCode) {
      case 'hi':
        return 'हिन्दी';
      case 'mr':
        return 'मराठी';
      case 'ur':
        return 'اردو';
      default:
        return 'English';
    }
  }
}