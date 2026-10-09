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
  static const geometric = 'Montserrat';
  static const display = 'Montserrat';
  static const cormorant = 'CormorantGaramond';
  static const latin = 'Montserrat';
  static const latinFallback = 'NotoSans';
  static const thai = 'NotoSansThai';
  static const devanagari = 'NotoSansDevanagari';
  static const japanese = 'NotoSansJP';
  static const simplifiedChinese = 'NotoSansSC';
  static const korean = 'NotoSansKR';

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
      AppLocale.korean => korean,
      // Latin-script languages, Vietnamese included: Montserrat carries
      // beautiful geometric curves with full Vietnamese diacritics coverage,
      // backed by Noto Sans.
      AppLocale.english ||
      AppLocale.vietnamese ||
      AppLocale.spanish => geometric,
    };
    return [
      preferred,
      for (final family in [
        geometric,
        latinFallback,
        thai,
        devanagari,
        japanese,
        simplifiedChinese,
        korean,
      ])
        if (family != preferred) family,
    ];
  }

  /// Display font fallback stack for headlines and brand titles.
  /// For Latin-based languages (Vietnamese, English, Spanish), Montserrat
  /// sits at the front to give AstraCue its celestial geometric identity.
  /// For non-Latin scripts (Thai, Hindi, Japanese, Chinese), the script's native
  /// family leads so glyphs always render faithfully.
  static List<String> displayFallbackFor(AppLocale locale) {
    return switch (locale) {
      AppLocale.english ||
      AppLocale.vietnamese ||
      AppLocale.spanish => [display, ...fallbackFor(locale)],
      _ => fallbackFor(locale),
    };
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
  final displayFallback = CompassFonts.displayFallbackFor(locale);
  final displayFamily = displayFallback.first;
  // Thai and Devanagari clip at the tight English line heights; Japanese and
  // Chinese simply read better with a little more air. Vietnamese has stacked
  // diacritics and tone marks that need room to prevent lines feeling cramped.
  final lead = switch (locale) {
    AppLocale.thai || AppLocale.hindi => 1.22,
    AppLocale.vietnamese => 1.18,
    AppLocale.japanese ||
    AppLocale.simplifiedChinese ||
    AppLocale.korean => 1.12,
    _ => 1.0,
  };

  // Flexible optical font sizing and line heights across languages:
  // - Vietnamese sentences are significantly more verbose (multi-syllable words)
  //   and contain stacked diacritics; oversized headlines feel overwhelming
  //   and wrap clumsily into 4 lines. Calibrating headline sizes to 23-24pt
  //   allows graceful 2-line flow with plenty of breathing room.
  // - Spanish is naturally 20-30% longer than English, benefiting from ~25pt.
  // - Japanese, Simplified Chinese, and Korean use dense ideographs/syllables
  //   where 23.5pt matches the optical visual weight of 26.5pt Latin.
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
    AppLocale.japanese ||
    AppLocale.simplifiedChinese ||
    AppLocale.korean => (44.0, 23.5, 20.0, 15.0, 13.5),
    AppLocale.spanish => (46.0, 23.5, 20.5, 15.0, 13.5),
    AppLocale.english => (46.0, 23.5, 20.5, 15.5, 14.0),
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
    fontFamily: displayFamily,
    fontFamilyFallback: displayFallback,
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: displayFamily,
        fontFamilyFallback: displayFallback,
        color: CompassColors.text,
        fontSize: displayLargeSize,
        height: 1.08 * lead,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
      headlineLarge: TextStyle(
        fontFamily: displayFamily,
        fontFamilyFallback: displayFallback,
        color: CompassColors.text,
        fontSize: headlineLargeSize,
        height: 1.25 * lead,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFamily,
        fontFamilyFallback: displayFallback,
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
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: CompassColors.text,
        side: const BorderSide(color: CompassColors.line),
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
    // Without this, a SnackBar takes `colorScheme.inverseSurface`, which on a
    // dark theme is a *light* colour: every notice in the app arrived as a
    // near-white box over a near-black screen. Material's reasoning is that an
    // inverted surface draws the eye, which is true on a light app and wrong
    // here — the notices say small things ("the language changed", "that
    // period is nearly over") and should read as part of the app rather than
    // as an alarm.
    //
    // `raised` with a `line` border is what the sheets and cards already use,
    // so a notice now looks like the surfaces it floats above.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CompassColors.raised,
      contentTextStyle: const TextStyle(
        color: CompassColors.text,
        fontSize: 13.5,
        height: 1.35,
      ),
      // Gold is the app's accent; the action is the only tappable thing in
      // the bar and has to be findable without being louder than the message.
      actionTextColor: CompassColors.gold,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: CompassColors.line),
      ),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      elevation: 6,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CelestialPageTransitionsBuilder(),
        TargetPlatform.iOS: CelestialPageTransitionsBuilder(),
        TargetPlatform.macOS: CelestialPageTransitionsBuilder(),
        TargetPlatform.windows: CelestialPageTransitionsBuilder(),
        TargetPlatform.linux: CelestialPageTransitionsBuilder(),
      },
    ),
  );
}

/// A custom ethereal page transition designed for AstraCue's celestial atmosphere.
///
/// Replaces Android's rigid Material 3 Zoom with a tranquil, weightless flow:
/// - Entering page: Smooth fade-in (opacity 0 -> 1) with subtle vertical drift (upward ~20px)
///   using [Curves.easeOutCubic].
/// - Covered / background page: Soft dimming (1.0 -> 0.88) without harsh scaling,
///   keeping the starry cosmos stable and peaceful.
/// - Returning / popping page: Gently glides downward and dissolves away.
class CelestialPageTransitionsBuilder extends PageTransitionsBuilder {
  const CelestialPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    final slideIn = Tween<Offset>(
      begin: const Offset(0.0, 0.035),
      end: Offset.zero,
    ).animate(curved);

    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final fadeOut = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(secondaryCurved);

    return FadeTransition(
      opacity: fadeOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(position: slideIn, child: child),
      ),
    );
  }
}
