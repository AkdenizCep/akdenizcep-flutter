import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'settings_tile.dart';

import '../../../../shared/providers/theme_provider.dart';

class ThemeSelectionButton extends ConsumerWidget {
  final bool asSettingsTile;
  const ThemeSelectionButton({super.key, this.asSettingsTile = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final currentLabel = isDark ? 'Siyah Tema' : 'Beyaz Tema';

    if (asSettingsTile) {
      return SettingsTile(
        title: 'Görünüm',
        subtitle: themeMode == ThemeMode.system
            ? 'Sistem teması'
            : currentLabel,
        onTap: () => _showThemeSheet(context, ref, isDark),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showThemeSheet(context, ref, isDark),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
        label: Text(
          'Tema: $currentLabel',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text(
                    'Tema Seçimi',
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.light_mode_rounded,
                    color: Color(0xFFE8601C),
                  ),
                  title: const Text(
                    'Beyaz Tema',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: ref.read(themeModeProvider) == ThemeMode.light
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.light);
                    sheetContext.pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.dark_mode_rounded,
                    color: Color(0xFF135BEC),
                  ),
                  title: const Text(
                    'Siyah Tema',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: ref.read(themeModeProvider) == ThemeMode.dark
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.dark);
                    sheetContext.pop();
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.brightness_auto_outlined),
                  title: const Text('Sistem teması'),
                  trailing: ref.read(themeModeProvider) == ThemeMode.system
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(ThemeMode.system);
                    sheetContext.pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
