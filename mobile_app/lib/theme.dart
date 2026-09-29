import 'package:flutter/material.dart';

import 'app_locale.dart';

/// The bundled Noto families, ordered so the reader's own script is tried
/// first and the rest are still available for anything else on the screen —
/// a Japanese name typed into a Spanish UI, a Thai country name, an emoji.
///
/// Bundling rather than trusting the device: Android's own coverage for Han,
/// Devanagari and Thai varies by manufacturer and OS version, so a device
/// without them would otherwise draw tofu boxes. The last entry is left to the
/// platform, which is what covers anything Noto does not — including scripts
/// this app does not translate into.
abstract final class CompassFonts {
  static const latin = 'NotoSans';
  static const thai = 'NotoSansThai';
  static const devanagari = 'NotoSansDevanagari';
  static const japanese = 'NotoSansJP';
  static const simplifiedChinese = 'NotoSansSC';

  /// Every bundled family, with [preferred] moved to the front.
  ///
  /// Order matters for Han: Japanese and Simplified Chinese share thousands of
  /// codepoints but draw some of them differently, so whichever family comes
  /// first decides how a shared character looks. Putting the reader's own
  /// script first is what keeps 直 and 今 in the right shapes.
  static List<String> fallbackFor(AppLocale locale) {
    final preferred = switch (locale) {
      AppLocale.thai => thai,
      AppLocale.hindi => devanagari,
      AppLocale.japanese => japanese,
      AppLocale.simplifiedChinese => simplifiedChinese,
      // Latin-script languages, Vietnamese included: Noto Sans carries the
      // full Vietnamese diacritic set, including the stacked tone marks.
      AppLocale.english || AppLocale.vietnamese || AppLocale.spanish => latin,
    };
    return [
      preferred,
      for (final family in [
        latin,
        thai,
        devanagari,
        japanese,
        simplifiedChinese,
      ])
        if (family != preferred) family,
    ];
  }
}

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

/// The app theme for one language.
///
/// The only thing the language changes here is the font stack and the line
/// height: colours, sizes and shapes are identical, so no locale gets a
/// quietly different design. Line height is raised for the scripts that need
/// room — Thai vowel marks and tone marks stack above and below the line, and
/// Devanagari hangs conjuncts below it — rather than shrinking the text.
ThemeData buildCompassTheme([AppLocale locale = AppLocale.english]) {
  final fallback = CompassFonts.fallbackFor(locale);
  final family = fallback.first;
  // Thai and Devanagari clip at the tight English line heights; Japanese and
  // Chinese simply read better with a little more air. Vietnamese has stacked
  // diacritics and tone marks that need room to prevent lines feeling cramped.
  final lead = switch (locale) {
    AppLocale.thai || AppLocale.hindi => 1.22,
    AppLocale.vietnamese => 1.18,
    AppLocale.japanese || AppLocale.simplifiedChinese => 1.12,
    _ => 1.0,
  };

  // Flexible optical font sizing and line heights across languages:
  // - Vietnamese sentences are significantly more verbose (multi-syllable words)
  //   and contain stacked diacritics; oversized headlines feel overwhelming
  //   and wrap clumsily into 4 lines. Calibrating headline sizes to 23-24pt
  //   allows graceful 2-line flow with plenty of breathing room.
  // - Spanish is naturally 20-30% longer than English, benefiting from ~25pt.
  // - Japanese and Simplified Chinese use dense, full-em ideographs where 23.5pt
  //   matches the optical visual weight of 26.5pt Latin.
  // - Thai and Devanagari have tall vertical glyph components that look heavy
  //   at Latin 30pt; ~23.5pt keeps them balanced.
  // - English with our updated, more poetic copy stays comfortable at 26.5pt.
  final (
    displayLargeSize,
    headlineLargeSize,
    headlineMediumSize,
    bodyLargeSize,
    bodyMediumSize,
  ) = switch (locale) {
    AppLocale.vietnamese => (44.0, 23.0, 19.5, 15.0, 13.5),
    AppLocale.thai || AppLocale.hindi => (44.0, 23.5, 20.0, 15.0, 13.5),
    AppLocale.japanese || AppLocale.simplifiedChinese => (
      44.0,
      23.5,
      20.0,
      15.0,
      13.5,
    ),
    AppLocale.spanish => (48.0, 25.0, 21.0, 15.5, 13.5),
    AppLocale.english => (50.0, 26.5, 21.5, 16.0, 14.0),
  };

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
    fontFamily: family,
    fontFamilyFallback: fallback,
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: CompassColors.text,
        fontSize: displayLargeSize,
        height: 1.05 * lead,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        color: CompassColors.text,
        fontSize: headlineLargeSize,
        height: 1.22 * lead,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: CompassColors.text,
        fontSize: headlineMediumSize,
        // Left to the font's own metrics in the Latin-script languages, as it
        // always has been; only the scripts that clip get an explicit lead.
        height: lead == 1.0 ? null : 1.25 * lead,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: CompassColors.text,
        fontSize: bodyLargeSize,
        height: 1.5 * lead,
      ),
      bodyMedium: TextStyle(
        color: CompassColors.secondary,
        fontSize: bodyMediumSize,
        height: 1.45 * lead,
      ),
      bodySmall: TextStyle(
        color: CompassColors.secondary,
        fontSize: 12,
        height: 1.45 * lead,
      ),
      labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
