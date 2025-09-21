import 'package:flutter/material.dart';

class LangProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void toggle() {
    _locale =
        _locale.languageCode == 'en' ? const Locale('vi') : const Locale('en');
    notifyListeners();
  }
}
