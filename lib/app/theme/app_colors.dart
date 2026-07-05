import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hru_atms/app/theme/theme_controller.dart';

abstract final class AppColors {
  static const brandBlue = Color(0xFF145DA0);
  static const brandTeal = Color(0xFF00A6A6);
  static const mutedText = Color(0xFF637083);
  static const orange = Color(0xFFDB6B2F);
  static const purple = Color(0xFF6B5DD3);
  static const green = Color(0xFF2E7D32);
  static const rose = Color(0xFFC0395A);

  static bool get isDark {
    final mode = ThemeController.instance.value;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return SchedulerBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  static Color get background =>
      isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FB);
  static Color get surface => isDark ? const Color(0xFF101827) : Colors.white;
  static Color get surfaceAlt =>
      isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC);
  static Color get border =>
      isDark ? const Color(0xFF243247) : const Color(0xFFE6EBF2);
  static Color get primaryText =>
      isDark ? const Color(0xFFEAF1FB) : const Color(0xFF172033);
  static Color get bodyText =>
      isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
  static Color get bodyTextHistory =>
      isDark ? const Color(0xFFCBD5E1) : const Color.fromARGB(255, 42, 45, 48);

  static Color get bottomBar => isDark ? const Color(0xFF101827) : Colors.white;
}
