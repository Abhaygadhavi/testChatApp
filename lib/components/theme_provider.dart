import 'package:flutter/material.dart';

enum AppTheme {
  dark,
  light,
  systemDefault,
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        _themeMode = ThemeMode.dark;
        break;
      case AppTheme.light:
        _themeMode = ThemeMode.light;
        break;
      case AppTheme.systemDefault:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }
}
