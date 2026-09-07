import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _languageKey = 'selected_language';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  final SharedPreferences _preferences;

  StorageService(this._preferences);

  static Future<StorageService> create() async {
    final preferences = await SharedPreferences.getInstance();
    return StorageService(preferences);
  }

  Future<void> saveLanguage(String languageCode) async {
    await _preferences.setString(
      _languageKey,
      languageCode,
    );
  }

  String getLanguage() {
    return _preferences.getString(_languageKey) ?? 'en';
  }

  Future<void> clearLanguage() async {
    await _preferences.remove(_languageKey);
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _preferences.setBool(
      _onboardingCompletedKey,
      completed,
    );
  }

  bool isOnboardingCompleted() {
    return _preferences.getBool(
          _onboardingCompletedKey,
        ) ??
        false;
  }

  Future<void> clearOnboardingStatus() async {
    await _preferences.remove(
      _onboardingCompletedKey,
    );
  }

  Future<void> clearAll() async {
    await _preferences.clear();
  }
}