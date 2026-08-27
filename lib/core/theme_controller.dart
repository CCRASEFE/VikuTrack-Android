// ==========================================
// ARCHIVO: lib/core/theme_controller.dart
// ==========================================

import 'package:flutter/material.dart';
import '../repositories/settings_repository.dart';
import 'app_themes.dart';

class PaletteInfo {
  final AppPalette palette;
  final String key;
  final String title;
  final String subtitle;
  final List<Color> previewColors;

  const PaletteInfo({
    required this.palette,
    required this.key,
    required this.title,
    required this.subtitle,
    required this.previewColors,
  });
}

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  final _settingsRepository = SettingsRepository();

  static const List<PaletteInfo> palettes = [
    PaletteInfo(
      palette: AppPalette.blackGold,
      key: 'black_gold',
      title: '1. Black & Gold',
      subtitle: 'Minimalismo y lujo sobrio',
      previewColors: [Color(0xFF141414), Color(0xFF2B2B2B), Color(0xFFC9A227), Color(0xFFF6F1E4)],
    ),
    PaletteInfo(
      palette: AppPalette.royalSapphire,
      key: 'royal_sapphire',
      title: '2. Royal Sapphire',
      subtitle: 'Azul náutico imperial con acentos oro',
      previewColors: [Color(0xFF0E2A47), Color(0xFF1E4C7C), Color(0xFFC9A227), Color(0xFFF2EFE8)],
    ),
    PaletteInfo(
      palette: AppPalette.theNest,
      key: 'the_nest',
      title: '3. The Nest',
      subtitle: 'Verde pavo real & oro elegante',
      previewColors: [Color(0xFF0A2527), Color(0xFF0F6B6D), Color(0xFFD4AF37), Color(0xFFF8F8F5)],
    ),
    PaletteInfo(
      palette: AppPalette.financialStability,
      key: 'financial_stability',
      title: '4. Financial Stability',
      subtitle: 'Azul corporativo & celeste tecnológico',
      previewColors: [Color(0xFF0A3C6E), Color(0xFF1783C1), Color(0xFF1E1E1E), Color(0xFFFFFFFF)],
    ),
  ];

  ThemeMode _themeMode = ThemeMode.dark;
  AppPalette _activePalette = AppPalette.blackGold;

  ThemeMode get themeMode => _themeMode;
  AppPalette get activePalette => _activePalette;

  ThemeData get lightTheme => AppThemes.getTheme(_activePalette, Brightness.light);
  ThemeData get darkTheme => AppThemes.getTheme(_activePalette, Brightness.dark);

  /// Carga la configuración guardada desde SQLite
  Future<void> loadTheme() async {
    final savedMode = await _settingsRepository.get('app_theme_mode');
    final savedPalette = await _settingsRepository.get('app_palette');

    if (savedMode != null) {
      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    if (savedPalette != null) {
      _activePalette = AppPalette.values.firstWhere(
        (p) => p.name == savedPalette,
        orElse: () => AppPalette.blackGold,
      );
    }

    notifyListeners();
  }

  /// Cambia el modo (Claro / Oscuro / Sistema) y lo guarda en SQLite
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    String modeStr = 'system';
    if (mode == ThemeMode.light) modeStr = 'light';
    if (mode == ThemeMode.dark) modeStr = 'dark';

    await _settingsRepository.set('app_theme_mode', modeStr);
  }

  /// Cambia la paleta oficial activa y la guarda en SQLite
  Future<void> setPalette(AppPalette palette) async {
    _activePalette = palette;
    notifyListeners();

    await _settingsRepository.set('app_palette', palette.name);
  }

  /// Alterna rápidamente entre Modo Claro y Modo Oscuro
  Future<void> toggleMode() async {
    final nextMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}