import 'package:flutter/material.dart';
import 'package:planning_poker_app/themes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = defaultTheme;
  double? _previousScreenWidth;
  static const double SMART_PHONE_STANDARD_SCREEN_WIDTH = 419;

  ThemeData get themeData => _themeData;

  void setThemeData(double screenWidth) {
    if (_previousScreenWidth == null || _previousScreenWidth != screenWidth) {
      _previousScreenWidth = screenWidth;
      ThemeData newThemeData = screenWidth <= SMART_PHONE_STANDARD_SCREEN_WIDTH
          ? smartPhoneTheme
          : defaultTheme;

      if (_themeData != newThemeData) {
        _themeData = newThemeData;
        notifyListeners();
      }
    }
  }
}
