import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _radius = 14.0;

  static ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bgLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      bodyMedium: TextStyle(height: 1.4),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF13151A),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      surfaceTintColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Color(0xFF13151A),
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0F1F8),
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13.5),
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, letterSpacing: 0.2),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF13151A),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEEF0FB),
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.black.withOpacity(0.04)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF13151A)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF13151A),
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: Colors.grey.withOpacity(0.15), thickness: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primary : Colors.grey[300]),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primary.withOpacity(0.4) : Colors.grey[200]),
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryDark,
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceDark,
    ),
    fontFamily: 'Roboto',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.white),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Colors.white),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2, color: Colors.white),
      bodyMedium: TextStyle(height: 1.4, color: Colors.white70),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      surfaceTintColor: AppColors.surfaceDark,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceDark,
      surfaceTintColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDarkElevated,
      hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13.5),
      labelStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primaryDark.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, letterSpacing: 0.2),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.15)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceDarkElevated,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDarkElevated,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.08), thickness: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primaryDark : Colors.grey[600]),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? AppColors.primaryDark.withOpacity(0.4) : Colors.grey[800]),
    ),
  );
}
