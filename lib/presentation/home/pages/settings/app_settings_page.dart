import 'package:auth_app/presentation/widgets/gradient_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_app/common/providers/app_settings.dart';
import 'package:auth_app/common/providers/theme.dart';
import 'package:auth_app/data/theme_manager.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
      ),
      body: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SettingsSection(
                title: 'App Appearance',
                children: [
                  SwitchListTile(
                    activeColor: Theme.of(context).colorScheme.secondary,
                    activeTrackColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    inactiveThumbColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    title: const Text('Auto Theme'),
                    subtitle: const Text('Change theme based on time of day'),
                    value: settings.autoMapTheme,
                    onChanged: (v) async {
                      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                      if (!v) {
                        // Turning OFF auto: capture current auto-selected theme and set as manual
                        final current = ThemeManager.getCurrentTheme();
                        settings.setManualMapTheme(current);
                        await settings.setAutoMapTheme(false);
                        themeProvider.updateMapTheme(current);
                      } else {
                        // Turning ON auto: enable and immediately apply current dynamic theme
                        await settings.setAutoMapTheme(true);
                        themeProvider.updateMapTheme(ThemeManager.getCurrentTheme());
                      }
                    },
                  ),
                  if (!settings.autoMapTheme)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Theme (Manual)',
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 10),
                          _SmallTimeThemeIcons(
                            selected: settings.manualMapTheme,
                            onSelected: (val) {
                              settings.setManualMapTheme(val);
                              Provider.of<ThemeProvider>(context, listen: false).updateMapTheme(val);
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              _SettingsSection(
                title: 'Weather Effects',
                children: [
                  SwitchListTile(
                    activeColor: Theme.of(context).colorScheme.secondary,
                    activeTrackColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
                    inactiveThumbColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    title: const Text('Show Rain Animation'),
                    subtitle: const Text('Display rain overlay when it rains'),
                    value: settings.rainAnimationEnabled,
                    onChanged: (v) => settings.setRainAnimationEnabled(v),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SmallTimeThemeIcons extends StatelessWidget {
  final MapTheme selected;
  final ValueChanged<MapTheme> onSelected;
  const _SmallTimeThemeIcons({required this.selected, required this.onSelected});

  List<MapTheme> _timeThemes() {
    final all = MapTheme.values;
    final filtered = all.where((t) {
      final n = t.toString().split('.').last.toLowerCase();
      return n == 'dawn' || n == 'day' || n == 'dusk' || n == 'night';
    }).toList();
    return filtered.isNotEmpty ? filtered : all;
  }

  IconData _iconFor(String name) {
    if (name == 'dawn') return Icons.wb_twilight;
    if (name == 'day') return Icons.wb_sunny;
    if (name == 'dusk') return Icons.wb_twighlight; // fallback style
    if (name == 'night') return Icons.dark_mode;
    // generic fallbacks
    if (name.contains('dark') || name.contains('night')) return Icons.dark_mode;
    if (name.contains('light') || name.contains('day')) return Icons.wb_sunny;
    return Icons.tonality;
  }

  @override
  Widget build(BuildContext context) {
    final themes = _timeThemes();
    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: themes.map((t) {
        final name = t.toString().split('.').last;
        final isSel = t == selected;
        return Tooltip(
          message: name[0].toUpperCase() + name.substring(1),
          child: InkWell(
            onTap: () => onSelected(t),
            borderRadius: BorderRadius.circular(28),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 52,
              // decoration: BoxDecoration(
              //   shape: BoxShape.circle,
              //   // border: Border.all(width: 2, color: border),
              //   boxShadow: isSel
              //       ? [
              //           BoxShadow(
              //             color: cs.primary.withOpacity(0.2),
              //             blurRadius: 10,
              //             offset: const Offset(0, 4),
              //           )
              //         ]
              //       : [],
              // ),
              child: GradientWidget(
                colors: isSel ? [
                      cs.primary,
                      cs.secondary,
                    ] : [cs.onSurface, cs.onSurface],
                    child: Icon(_iconFor(name), size: 24, color: Colors.white,),
                  ),
                
              
            ),
          ),
        );
      }).toList(),
    );
  }
}