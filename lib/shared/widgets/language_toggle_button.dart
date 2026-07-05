import 'package:flutter/material.dart';
import 'package:hru_atms/app/l10n/language_controller.dart';

class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageController.instance,
      builder: (context, locale, child) {
        final isKhmer = locale.languageCode == 'km';
        return IconButton.filledTonal(
          onPressed: LanguageController.instance.toggle,
          icon: Icon(Icons.translate_rounded),
          tooltip: isKhmer ? 'English' : 'ខ្មែរ',
        );
      },
    );
  }
}
