/// The seven symbolic pairs, as identity only, plus the retired one.
///
/// The words a reader sees live in `lib/l10n/` and are resolved through
/// `localized_presentation.dart`: a mode carries no English text, so no screen
/// can accidentally show an untranslated label. `LEFT / RIGHT` and
/// `ADVANCE / RETREAT` remain symbolic, never physical navigation.
enum DecisionMode {
  yesNo,
  actWait,
  advanceRetreat,
  stayGo,
  keepLetGo,
  commitWithdraw,
  leftRight,

  /// Retired with ruleset v9.1. Offered nowhere; rendered in history so an
  /// old reading still shows the pair it was actually calculated for.
  forwardBackward;

  bool get isLegacy => this == DecisionMode.forwardBackward;

  /// The modes Home offers.
  static List<DecisionMode> get selectable =>
      values.where((mode) => !mode.isLegacy).toList(growable: false);
}

/// The engine's own English spelling of each pair.
///
/// Not display text: it is the wire vocabulary a `ReadingResponse` uses for
/// `winner` and for the keys of `percentages`, and the only way to tell which
/// side of a pair a saved reading named. Screens translate through it rather
/// than printing it, so changing a value here would break saved readings, not
/// just copy.
const englishChoiceLabels = <DecisionMode, ({String first, String second})>{
  DecisionMode.yesNo: (first: 'YES', second: 'NO'),
  DecisionMode.actWait: (first: 'ACT', second: 'WAIT'),
  DecisionMode.advanceRetreat: (first: 'ADVANCE', second: 'RETREAT'),
  DecisionMode.stayGo: (first: 'STAY', second: 'GO'),
  DecisionMode.keepLetGo: (first: 'KEEP', second: 'LET GO'),
  DecisionMode.commitWithdraw: (first: 'COMMIT', second: 'WITHDRAW'),
  DecisionMode.leftRight: (first: 'LEFT', second: 'RIGHT'),
  DecisionMode.forwardBackward: (first: 'FORWARD', second: 'BACKWARD'),
};

/// The Western Sun sign derived from the birth date — not a Chinese zodiac
/// animal and not a Vedic moon sign. The visible name is localized; only the
/// glyph and the artwork live here.
enum ZodiacSign {
  aries('♈', 'assets/zodiac/zodiac_01_aries.png'),
  taurus('♉', 'assets/zodiac/zodiac_02_taurus.png'),
  gemini('♊', 'assets/zodiac/zodiac_03_gemini.png'),
  cancer('♋', 'assets/zodiac/zodiac_04_cancer.png'),
  leo('♌', 'assets/zodiac/zodiac_05_leo.png'),
  virgo('♍', 'assets/zodiac/zodiac_06_virgo.png'),
  libra('♎', 'assets/zodiac/zodiac_07_libra.png'),
  scorpio('♏', 'assets/zodiac/zodiac_08_scorpio.png'),
  sagittarius('♐', 'assets/zodiac/zodiac_09_sagittarius.png'),
  capricorn('♑', 'assets/zodiac/zodiac_10_capricorn.png'),
  aquarius('♒', 'assets/zodiac/zodiac_11_aquarius.png'),
  pisces('♓', 'assets/zodiac/zodiac_12_pisces.png');

  const ZodiacSign(this.glyph, this.assetPath);

  final String glyph;
  final String assetPath;
}

ZodiacSign zodiacForDate(DateTime date) {
  final day = date.month * 100 + date.day;
  return switch (day) {
    >= 321 && <= 419 => ZodiacSign.aries,
    >= 420 && <= 520 => ZodiacSign.taurus,
    >= 521 && <= 620 => ZodiacSign.gemini,
    >= 621 && <= 722 => ZodiacSign.cancer,
    >= 723 && <= 822 => ZodiacSign.leo,
    >= 823 && <= 922 => ZodiacSign.virgo,
    >= 923 && <= 1022 => ZodiacSign.libra,
    >= 1023 && <= 1121 => ZodiacSign.scorpio,
    >= 1122 && <= 1221 => ZodiacSign.sagittarius,
    >= 1222 || <= 119 => ZodiacSign.capricorn,
    >= 120 && <= 218 => ZodiacSign.aquarius,
    _ => ZodiacSign.pisces,
  };
}

enum TimePeriod {
  now(null),
  morning((6, 12)),
  midday((12, 14)),
  afternoon((14, 18)),
  evening((18, 24));

  const TimePeriod(this.localHours);

  /// Local-hour bounds `[start, end)`, mirroring the engine's `PERIODS` table
  /// in `calculation-engine/src/time.js`. NOW has none: it is the instant of
  /// the Reveal tap, so it can never be over.
  final (int, int)? localHours;

  /// Whether this period is already fully behind the user at [localNow].
  ///
  /// The engine stays authoritative — it answers `period_elapsed` on its own
  /// earthly-branch segments, which can run slightly past the boundary below —
  /// so this only mutes a period that is over by its own definition and never
  /// disables one that is still running.
  bool hasElapsedAt(DateTime localNow) {
    final hours = localHours;
    if (hours == null) return false;
    // `hour` is 0–23, so a period ending at 24 never reads as elapsed and
    // evening stays selectable until midnight.
    return localNow.hour >= hours.$2;
  }
}

class LuckyWindow {
  const LuckyWindow(this.time, this.score);

  final String time;
  final int score;
}

class ReadingResult {
  const ReadingResult({
    required this.mode,
    required this.period,
    required this.winner,
    required this.winnerPercent,
    required this.counterpart,
    required this.counterpartPercent,
    required this.alignment,
    required this.windows,
  });

  final DecisionMode mode;
  final TimePeriod period;
  final String winner;
  final int winnerPercent;
  final String counterpart;
  final int counterpartPercent;
  final String alignment;
  final List<LuckyWindow> windows;
}
