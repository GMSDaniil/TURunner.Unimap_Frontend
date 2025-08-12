import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auth_app/data/theme_manager.dart';

/// Stores user-customisable application settings that influence
/// map behaviour and visualisation.
class AppSettingsProvider extends ChangeNotifier {
  static const _keyAutoMapTheme = 'autoMapTheme';
  static const _keyManualMapTheme = 'manualMapTheme';
  static const _keyRainAnimationEnabled = 'rainAnimationEnabled';

  bool _autoMapTheme = true; // default: follow time of day
  MapTheme _manualMapTheme = MapTheme.day; // used when auto disabled
  bool _rainAnimationEnabled = true; // show rain overlay when raining

  bool get autoMapTheme => _autoMapTheme;
  MapTheme get manualMapTheme => _manualMapTheme;
  bool get rainAnimationEnabled => _rainAnimationEnabled;

  AppSettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _autoMapTheme = prefs.getBool(_keyAutoMapTheme) ?? true;
    final storedTheme = prefs.getString(_keyManualMapTheme);
    if (storedTheme != null) {
      _manualMapTheme = MapTheme.values.firstWhere(
        (e) => e.toString().split('.').last == storedTheme,
        orElse: () => MapTheme.day,
      );
    }
    _rainAnimationEnabled = prefs.getBool(_keyRainAnimationEnabled) ?? true;
    notifyListeners();
  }

  Future<void> setAutoMapTheme(bool value) async {
    if (_autoMapTheme == value) return;
    _autoMapTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoMapTheme, value);
    notifyListeners();
  }

  Future<void> setManualMapTheme(MapTheme theme) async {
    if (_manualMapTheme == theme) return;
    _manualMapTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyManualMapTheme, theme.toString().split('.').last);
    notifyListeners();
  }

  Future<void> setRainAnimationEnabled(bool value) async {
    if (_rainAnimationEnabled == value) return;
    _rainAnimationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRainAnimationEnabled, value);
    notifyListeners();
  }
}
