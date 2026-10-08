import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/config/providers.dart';

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences(ref.watch(sharedPreferencesProvider));
});

class AppPreferences {
  AppPreferences(this._preferences);

  static const _onboardingCompleted = 'onboarding_completed';
  static const _languageCode = 'language_code';
  static const _themeMode = 'theme_mode';

  final SharedPreferences _preferences;

  bool get onboardingCompleted =>
      _preferences.getBool(_onboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) {
    return _preferences.setBool(_onboardingCompleted, value);
  }

  String get languageCode => _preferences.getString(_languageCode) ?? 'vi';

  Future<void> setLanguageCode(String value) {
    return _preferences.setString(_languageCode, value);
  }

  String get themeMode => _preferences.getString(_themeMode) ?? 'system';

  Future<void> setThemeMode(String value) {
    return _preferences.setString(_themeMode, value);
  }
}
