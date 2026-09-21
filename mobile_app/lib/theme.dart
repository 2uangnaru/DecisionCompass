import 'package:flutter/material.dart';

abstract final class CompassColors {
  static const deep = Color(0xFF0A1020);
  static const raised = Color(0xFF111B2E);
  static const glass = Color(0xE31A2943);
  static const line = Color(0xFF35496A);
  static const text = Color(0xFFF4F7FC);
  static const secondary = Color(0xFFBAC6DB);
  static const muted = Color(0xFF8795AE);
  static const gold = Color(0xFFD8B66A);
  static const violet = Color(0xFF786FE8);
  static const blue = Color(0xFF2477C9);
  static const blueLight = Color(0xFF62B7E8);
  static const coral = Color(0xFFB95F62);
  static const teal = Color(0xFF4EBB91);
}

ThemeData buildCompassTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: CompassColors.violet,
        brightness: Brightness.dark,
        surface: CompassColors.raised,
      ).copyWith(
        primary: CompassColors.blueLight,
        secondary: CompassColors.gold,
        surface: CompassColors.raised,
        onSurface: CompassColors.text,
      );

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: CompassColors.deep,
    useMaterial3: true,
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: CompassColors.text,
        fontSize: 56,
        height: 1.05,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        color: CompassColors.text,
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: CompassColors.text,
        fontSize: 23,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: CompassColors.text,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: CompassColors.secondary,
        fontSize: 14,
        height: 1.45,
      ),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: CompassColors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CompassColors.glass,
      labelStyle: const TextStyle(color: CompassColors.secondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CompassColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CompassColors.blueLight),
      ),
    ),
  );
}
