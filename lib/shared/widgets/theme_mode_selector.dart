import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/app_localizations.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:hru_atms/app/theme/theme_controller.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('Color mode'),
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ThemeModeButton(
                      mode: ThemeMode.system,
                      currentMode: mode,
                      icon: Icons.phone_android_rounded,
                      label: context.tr('System'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ThemeModeButton(
                      mode: ThemeMode.light,
                      currentMode: mode,
                      icon: Icons.light_mode_outlined,
                      label: context.tr('Light'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ThemeModeButton(
                      mode: ThemeMode.dark,
                      currentMode: mode,
                      icon: Icons.dark_mode_outlined,
                      label: context.tr('Dark'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.mode,
    required this.currentMode,
    required this.icon,
    required this.label,
  });

  final ThemeMode mode;
  final ThemeMode currentMode;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final selected = mode == currentMode;
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: selected ? AppColors.brandBlue : colors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => ThemeController.instance.setMode(mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.brandBlue : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.brandBlue,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : colors.onSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
