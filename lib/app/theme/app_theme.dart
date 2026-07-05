import 'package:flutter/material.dart';
import 'package:hru_atms/app/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandBlue,
        primary: AppColors.brandBlue,
        secondary: AppColors.brandTeal,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.notoSansKhmerTextTheme(),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: Brightness.dark,
      primary: const Color(0xFF7DB7FF),
      secondary: const Color(0xFF5EE0DE),
      surface: const Color(0xFF101827),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      textTheme: GoogleFonts.notoSansKhmerTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF101827),
        foregroundColor: Colors.white,
      ),
      drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF101827)),
      dividerTheme: const DividerThemeData(color: Color(0xFF243247)),
      cardColor: const Color(0xFF101827),
    );
  }
}
