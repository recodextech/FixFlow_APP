import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class LanguageProvider extends ChangeNotifier {
  late Locale _locale;
  final PreferencesService _prefsService = PreferencesService();

  LanguageProvider() {
    _locale = Locale(_prefsService.getLanguage());
  }

  Locale get locale => _locale;

  String get currentLanguageCode => _locale.languageCode;

  bool get isEnglish => _locale.languageCode == 'en';

  bool get isSinhala => _locale.languageCode == 'si';

  /// Switches the app language. MaterialApp listens to this provider, so the
  /// theme (including the Sinhala font) and all localized text rebuild at once.
  Future<void> setLocale(Locale locale) async {
    // Compare by language only so Locale('si') and Locale('si', 'LK') are
    // treated as the same language.
    if (_locale.languageCode == locale.languageCode) return;

    _locale = Locale(locale.languageCode);
    notifyListeners();
    await _prefsService.setLanguage(locale.languageCode);
  }

  Future<void> switchLanguage(String languageCode) async {
    await setLocale(Locale(languageCode));
  }

  Future<void> switchBetweenLanguages() async {
    await switchLanguage(isEnglish ? 'si' : 'en');
  }
}
