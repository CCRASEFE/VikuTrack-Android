// ==========================================
// ARCHIVO: lib/core/theme_controller.dart
// ==========================================

import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';

class AppColorOption {
  final String key;
  final String name;
  final Color color;

  const AppColorOption({
    required this.key,
    required this.name,
    required this.color,
  });
}

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  final _settingsRepository = SettingsRepository();

  static const List<AppColorOption> colorOptions = [
    AppColorOption(key: 'blue', name: 'Azul Océano', color: Colors.blue),
    AppColorOption(key: 'teal', name: 'Verde Esmeralda', color: Colors.teal),
    AppColorOption(key: 'purple', name: 'Púrpura Real', color: Colors.deepPurple),
    AppColorOption(key: 'orange', name: 'Terracota', color: Colors.deepOrange),
    AppColorOption(key: 'slate', name: 'Grafito', color: Colors.blueGrey),
    AppColorOption(key: 'green', name: 'Bosque', color: Colors.green),
  ];

  ThemeMode _themeMode = ThemeMode.system;
  AppColorOption _selectedColor = colorOptions.first;

  ThemeMode get themeMode => _themeMode;
  AppColorOption get selectedColor => _selectedColor;

  /// Carga la configuración guardada desde SQLite
  Future<void> loadTheme() async {
    final savedMode = await _settingsRepository.get('app_theme_mode');
    final savedColor = await _settingsRepository.get('app_theme_color');

    if (savedMode != null) {
      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    if (savedColor != null) {
      _selectedColor = colorOptions.firstWhere(
        (c) => c.key == savedColor,
        orElse: () => colorOptions.first,
      );
    }

    notifyListeners();
  }

  /// Cambia el modo (Sistema, Claro, Oscuro) y lo guarda en SQLite
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';

    await _settingsRepository.set('app_theme_mode', modeStr);
  }

  /// Cambia la paleta de color y la guarda en SQLite
  Future<void> setColorOption(AppColorOption option) async {
    _selectedColor = option;
    notifyListeners();

    await _settingsRepository.set('app_theme_color', option.key);
  }
}