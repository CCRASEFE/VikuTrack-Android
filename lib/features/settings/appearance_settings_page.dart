// ==========================================
// ARCHIVO: lib/features/settings/appearance_settings_page.dart
// ==========================================

import 'package:flutter/material.dart';
import '../../core/app_themes.dart';
import '../../core/theme_controller.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  final _controller = ThemeController.instance;

  Widget _buildThemeModeSelector(bool isDark) {
    return SegmentedButton<ThemeMode>(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const [
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text('Oscuro 🌙', style: TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text('Claro ☀️', style: TextStyle(fontSize: 12)),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          label: Text('Sistema 🌓', style: TextStyle(fontSize: 12)),
        ),
      ],
      selected: {_controller.themeMode},
      onSelectionChanged: (val) {
        if (val.isNotEmpty) {
          setState(() {
            _controller.setThemeMode(val.first);
          });
        }
      },
    );
  }

  Widget _buildPalettesList(bool isDark) {
    final themeColors = Theme.of(context).extension<AppThemeColors>();

    return Column(
      children: ThemeController.palettes.map((pInfo) {
        final isSelected = _controller.activePalette == pInfo.palette;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isSelected
                  ? (themeColors?.cardAccentText ?? Theme.of(context).colorScheme.primary)
                  : (themeColors?.cardBaseBorder ?? Colors.white24),
              width: isSelected ? 2.2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              setState(() {
                _controller.setPalette(pInfo.palette);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Muestras de color en círculos solapados
                  SizedBox(
                    width: 72,
                    height: 28,
                    child: Stack(
                      children: [
                        Positioned(left: 0, child: _colorCircle(pInfo.previewColors[0])),
                        Positioned(left: 14, child: _colorCircle(pInfo.previewColors[1])),
                        Positioned(left: 28, child: _colorCircle(pInfo.previewColors[2])),
                        Positioned(left: 42, child: _colorCircle(pInfo.previewColors[3])),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pInfo.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? (themeColors?.cardAccentText ?? Theme.of(context).colorScheme.primary)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pInfo.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: themeColors?.cardAccentText ?? Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.check, size: 16, color: Colors.black),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _colorCircle(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black38, width: 1.5),
      ),
    );
  }

  Widget _buildLivePreviewCard(bool isDark) {
    final themeColors = Theme.of(context).extension<AppThemeColors>();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: themeColors?.heroCardBorder ?? Colors.transparent),
      ),
      color: themeColors?.heroCardBg ?? Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: themeColors?.heroCardAccent ?? Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Dinero Libre Disponible',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: themeColors?.heroCardText ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soles Libres',
                      style: TextStyle(
                        fontSize: 11,
                        color: (themeColors?.heroCardText ?? Colors.white).withAlpha(180),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'S/ 4,850.00',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: themeColors?.heroCardAccent ?? Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: themeColors?.cardBaseBg ?? Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeColors?.cardBaseBorder ?? Colors.white24),
                  ),
                  child: Text(
                    'Vista Previa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeColors?.cardAccentText ?? Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Apariencia y Estilos'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildLivePreviewCard(isDark),
              const SizedBox(height: 24),

              Text(
                'Modo de Pantalla',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 10),
              _buildThemeModeSelector(isDark),
              const SizedBox(height: 28),

              Text(
                'Paletas de Color Oficiales',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona una de las 4 identidades visuales para toda la aplicación:',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _buildPalettesList(isDark),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}