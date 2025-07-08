import 'package:flutter/material.dart';
import 'package:auth_app/data/theme_manager.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  MapTheme _mapTheme = MapTheme.day;

  ThemeMode get themeMode => _themeMode;
  MapTheme get mapTheme => _mapTheme;

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  // ✅ Update theme based on map theme
  void updateMapTheme(MapTheme mapTheme) {
    _mapTheme = mapTheme;
    
    // ✅ Automatically switch to dark theme for dusk/night
    if (mapTheme == MapTheme.dusk || mapTheme == MapTheme.night) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  // ✅ Check if current theme should be dark
  bool get isDarkTheme => 
      _themeMode == ThemeMode.dark || 
      (_themeMode == ThemeMode.system && _mapTheme == MapTheme.dusk) ||
      (_themeMode == ThemeMode.system && _mapTheme == MapTheme.night);
}