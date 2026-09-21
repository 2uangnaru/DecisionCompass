enum DecisionMode {
  yesNo('YES / NO', 'YES', 'NO', 'Testing openness against resistance'),
  actWait('ACT / WAIT', 'ACT', 'WAIT', 'Balancing momentum against patience'),
  advanceRetreat(
    'ADVANCE / RETREAT',
    'ADVANCE',
    'RETREAT',
    'Reading expansion against withdrawal',
  ),
  stayGo('STAY / GO', 'STAY', 'GO', 'Comparing roots with movement'),
  keepLetGo(
    'KEEP / LET GO',
    'KEEP',
    'LET GO',
    'Weighing continuity against release',
  ),
  forwardBackward(
    'FORWARD / BACKWARD',
    'FORWARD',
    'BACKWARD',
    'Tracing forward motion against returning energy',
  ),
  leftRight(
    'LEFT / RIGHT',
    'LEFT',
    'RIGHT',
    'Balancing receptive and expressive polarity',
  );

  const DecisionMode(this.label, this.first, this.second, this.ritualCopy);

  final String label;
  final String first;
  final String second;
  final String ritualCopy;
}

enum ZodiacSign {
  aries('♈', 'Aries'),
  taurus('♉', 'Taurus'),
  gemini('♊', 'Gemini'),
  cancer('♋', 'Cancer'),
  leo('♌', 'Leo'),
  virgo('♍', 'Virgo'),
  libra('♎', 'Libra'),
  scorpio('♏', 'Scorpio'),
  sagittarius('♐', 'Sagittarius'),
  capricorn('♑', 'Capricorn'),
  aquarius('♒', 'Aquarius'),
  pisces('♓', 'Pisces');

  const ZodiacSign(this.glyph, this.label);

  final String glyph;
  final String label;
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
  now('NOW'),
  morning('Morning'),
  midday('Midday'),
  afternoon('Afternoon'),
  evening('Evening');

  const TimePeriod(this.label);
  final String label;
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
