import 'package:flutter/material.dart';
import 'app_localizations.dart';

class LanguageController extends ChangeNotifier {
  static final LanguageController instance = LanguageController._internal();
  LanguageController._internal();

  String _currentLanguageCode = 'en';

  String get currentLanguageCode => _currentLanguageCode;

  Locale get currentLocale => Locale(_currentLanguageCode);

  AppLanguage get currentLanguage => AppLocalizations.getLanguage(_currentLanguageCode);

  List<AppLanguage> get supportedLanguages => AppLocalizations.supportedLanguages;

  void changeLanguage(String code) {
    if (_currentLanguageCode != code) {
      _currentLanguageCode = code;
      notifyListeners();
    }
  }

  String text(String key) => AppLocalizations.text(key, _currentLanguageCode);
}
