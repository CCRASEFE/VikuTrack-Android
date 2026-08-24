// ==========================================
// ARCHIVO: lib/features/settings/appearance_settings_page.dart
// ==========================================

import 'package:flutter/material.dart';
import '../../core/theme_controller.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  final _controller = ThemeController.instance;

  String _getModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Modo Claro';
      case ThemeMode.dark:
        return 'Modo Oscuro';
      case ThemeMode.system:
        return 'Automático';
    }
  }

  Widget _buildThemeModeSelector() {
    return SegmentedButton<ThemeMode>(
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text('Auto', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.brightness_auto, size: 14),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text('Claro', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.light_mode, size: 14),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text('Oscuro', style: TextStyle(fontSize: 12)),
          icon: Icon(Icons.dark_mode, size: 14),
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

  Widget _buildColorPaletteGrid(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: ThemeController.colorOptions.length,
      itemBuilder: (context, index) {
        final option = ThemeController.colorOptions[index];
        final isSelected = _controller.selectedColor.key == option.key;

        return Card(
          elevation: isSelected ? 3 : 0,
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? option.color : (isDark ? Colors.white24 : Colors.grey.shade300),
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _controller.setColorOption(option);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: option.color,
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    option.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? option.color : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLivePreviewCard(bool isDark) {
    final color = _controller.selectedColor.color;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.remove_red_eye_outlined, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Vista Previa del Estilo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo de Muestra',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black54),
                    ),
                    Text(
                      'S/ 4,850.00',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                FilledButton.tonal(
                  onPressed: () {},
                  child: const Text('Botón Muestra'),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Apariencia y Estilo'),
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
              const SizedBox(height: 4),
              Text(
                'Actualmente: ${_getModeLabel(_controller.themeMode)}',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 12),
              _buildThemeModeSelector(),
              const SizedBox(height: 28),

              Text(
                'Paleta de Colores',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Elige el color de acento principal de toda la aplicación:',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 12),
              _buildColorPaletteGrid(isDark),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}