/// Classical Vedic (Jyotish) module: Lahiri Ayanamsa, 27 Nakshatras,
/// Panchanga (Tithi & Karana) and Chandra Gochara (Moon transit from natal Moon).
///
/// Designed to work deterministically and gracefully whether birth time
/// is known or unknown.
library;

import '../astronomy/astronomy.dart';
import '../core/core.dart';
import '../core/numbers.dart';
import '../time/local_time.dart';

const List<String> nakshatraNames = <String>[
  'Ashwini',
  'Bharani',
  'Krittika',
  'Rohini',
  'Mrigashira',
  'Ardra',
  'Punarvasu',
  'Pushya',
  'Ashlesha',
  'Magha',
  'Purva Phalguni',
  'Uttara Phalguni',
  'Hasta',
  'Chitra',
  'Swati',
  'Vishakha',
  'Anuradha',
  'Jyeshtha',
  'Mula',
  'Purva Ashadha',
  'Uttara Ashadha',
  'Shravana',
  'Dhanishta',
  'Shatabhisha',
  'Purva Bhadrapada',
  'Uttara Bhadrapada',
  'Revati',
];

/// Characteristic [action, change] vectors for the 27 Nakshatras.
/// Classical classification: Kshipra, Ugra, Mishra, Sthira, Mridu, Tikshna, Chara.
const List<List<double>> nakshatraVectors = <List<double>>[
  <double>[.50, .40],   // 0: Ashwini (Kshipra/Swift - Initiative & Action)
  <double>[.40, .50],   // 1: Bharani (Ugra/Fierce - Transformation/Drive)
  <double>[.20, .10],   // 2: Krittika (Mishra/Mixed - Direct/Discernment)
  <double>[-.25, -.40], // 3: Rohini (Sthira/Fixed - Holding, Preserving, Steady)
  <double>[.10, .30],   // 4: Mrigashira (Mridu/Gentle - Searching, Exploring)
  <double>[-.30, .60],  // 5: Ardra (Tikshna/Sharp - Storm, Disruption, Upheaval)
  <double>[.40, .30],   // 6: Punarvasu (Chara/Movable - Renewal, Revival)
  <double>[.60, -.20],  // 7: Pushya (Kshipra/Nourishing - Highest Auspiciousness)
  <double>[-.40, .30],  // 8: Ashlesha (Tikshna/Intense - Caution, Restraint)
  <double>[.50, -.20],  // 9: Magha (Ugra/Royal - Authority, Decisiveness)
  <double>[.30, .40],   // 10: Purva Phalguni (Ugra/Creative - Passion, Creation)
  <double>[-.15, -.30], // 11: Uttara Phalguni (Sthira/Fixed - Stability, Contracts)
  <double>[.50, .20],   // 12: Hasta (Kshipra/Skillful - Manifestation, Action)
  <double>[.30, .40],   // 13: Chitra (Mridu/Bright - Design, Opportunity)
  <double>[.20, .60],   // 14: Swati (Chara/Movable - Independence, Adaptability)
  <double>[.40, .20],   // 15: Vishakha (Mishra/Focused - Determination, Goal)
  <double>[.20, -.20],  // 16: Anuradha (Mridu/Devotional - Collaboration, Harmony)
  <double>[-.25, .40],  // 17: Jyeshtha (Tikshna/Seniority - Defensive, Protective)
  <double>[-.50, .70],  // 18: Mula (Tikshna/Root - Uprooting, Releasing, Pause)
  <double>[.40, .30],   // 19: Purva Ashadha (Ugra/Invincible - Courage, Triumph)
  <double>[.30, -.30],  // 20: Uttara Ashadha (Sthira/Victory - Enduring, Grounded)
  <double>[-.10, .20],  // 21: Shravana (Chara/Listening - Receptive, Reflection)
  <double>[.50, .30],   // 22: Dhanishta (Chara/Dynamic - Momentum, Progress)
  <double>[-.30, .20],  // 23: Shatabhisha (Chara/Healing - Guarded, Introspective)
  <double>[.20, .50],   // 24: Purva Bhadrapada (Ugra/Fiery - Intense, Visionary)
  <double>[-.20, -.30], // 25: Uttara Bhadrapada (Sthira/Wisdom - Patience, Depth)
  <double>[.10, -.10],  // 26: Revati (Mridu/Gentle - Graceful Completion)
];

/// Lahiri Ayanamsa calculation from UTC timestamp.
/// Epoch J2000 (2000-01-01 12:00:00 UTC) = 946728000000.0 ms.
double ayanamsaLahiri(double ms) {
  final days = (ms - 946728000000.0) / 86400000.0;
  final years = days / 365.25;
  return 23.8617 + years * 0.01397;
}

/// Converts tropical ecliptic longitude to sidereal longitude in [0, 360).
double toSidereal(double tropicalLongitude, double ayanamsa) {
  return jsModDouble(tropicalLongitude - ayanamsa, 360.0);
}

/// Tithi contribution [action, change].
/// Distinguishes Shukla Paksha (waxing, active) and Krishna Paksha (waning, reflective),
/// as well as Rikta Tithis (4, 9, 14 in each fortnight: caution/emptiness).
List<double> tithiVector(int tithi) {
  final dayInFortnight = jsMod(tithi - 1, 15) + 1;
  final isWaxing = tithi <= 15;
  final isRikta =
      dayInFortnight == 4 || dayInFortnight == 9 || dayInFortnight == 14;
  final isPurna =
      dayInFortnight == 5 || dayInFortnight == 10 || dayInFortnight == 15;

  var a = isWaxing ? 0.20 : -0.15;
  if (isRikta) a -= 0.35;
  if (isPurna) a += 0.25;
  if (tithi == 30) a -= 0.30; // Amavasya (new moon) stillness

  final c = isWaxing ? 0.10 : -0.10;
  return <double>[clampUnit(a), clampUnit(c)];
}

/// Gochara: House of transit Moon relative to natal Moon (1 to 12).
List<double> gocharaVector(int house) {
  return switch (house) {
    3 || 6 || 10 || 11 => const <double>[.45, .20], // Upachaya (Growth, Success, Action)
    8 => const <double>[-.50, .40],                  // Ashtama Chandra (Obstacle, Delay, Caution)
    12 => const <double>[-.35, .30],                 // Vyaya (Withdrawal, Rest, Letting Go)
    1 => const <double>[.10, -.10],                  // Mind/Lagna Moon
    2 || 4 || 5 || 7 || 9 => const <double>[.15, .05], // Supportive/Steady
    _ => const <double>[0.0, 0.0],
  };
}

/// Scores the Vedic astrology module for the reading instant [ms].
ModuleResult scoreVedic(double ms, BirthContext birth, NatalSky natal) {
  final sky = skyAt(ms);
  final moonTropical = sky.positions['moon'];
  final sunTropical = sky.positions['sun'];

  if (moonTropical == null || sunTropical == null) {
    return ModuleResult(Evidence(), const <String, Object?>{}, 'unavailable');
  }

  final ayanamsa = ayanamsaLahiri(ms);
  final moonSidereal = toSidereal(moonTropical, ayanamsa);

  // 1. Nakshatra at Reveal (0 to 26)
  final nakshatra = (moonSidereal / (360.0 / 27.0)).floor() % 27;
  final nakshatraVec = nakshatraVectors[nakshatra];

  // 2. Tithi (1 to 30) & Karana (1 to 60)
  final elongation = jsModDouble(moonTropical - sunTropical, 360.0);
  final tithi = (elongation / 12.0).floor() + 1;
  final karana = (elongation / 6.0).floor() + 1;
  final tithiVec = tithiVector(tithi);

  // 3. Chandra Gochara (Transit Moon relative to Natal Moon)
  final natalMoonTropical = natal.positions['moon'];
  double? natalMoonSidereal;
  int? natalRashi;
  int? transitRashi;
  int? gocharaHouse;
  var gocharaVec = const <double>[0.0, 0.0];
  var hasGochara = false;

  if (natalMoonTropical != null && birth.intervals.isNotEmpty) {
    final natalMs = birth.intervals[0].start;
    final natalAyanamsa = ayanamsaLahiri(natalMs);
    natalMoonSidereal = toSidereal(natalMoonTropical, natalAyanamsa);
    natalRashi = (natalMoonSidereal / 30.0).floor() % 12;
    transitRashi = (moonSidereal / 30.0).floor() % 12;
    gocharaHouse = jsMod(transitRashi - natalRashi, 12) + 1;
    gocharaVec = gocharaVector(gocharaHouse);
    hasGochara = true;
  }

  // Weight composition within Vedic module:
  // Nakshatra (40%) + Gochara (35%) + Tithi (25%) when Gochara is available.
  // Nakshatra (60%) + Tithi (40%) when birth Moon is unknown.
  double a;
  double c;
  double coverage;

  if (hasGochara) {
    a = 0.40 * nakshatraVec[0] + 0.35 * gocharaVec[0] + 0.25 * tithiVec[0];
    c = 0.40 * nakshatraVec[1] + 0.35 * gocharaVec[1] + 0.25 * tithiVec[1];
    coverage = birth.clock != null ? 1.0 : 0.85;
  } else {
    a = 0.60 * nakshatraVec[0] + 0.40 * tithiVec[0];
    c = 0.60 * nakshatraVec[1] + 0.40 * tithiVec[1];
    coverage = 0.65;
  }

  return ModuleResult(
    Evidence(clampUnit(a), clampUnit(c), coverage),
    <String, Object?>{
      'ayanamsaDegrees': roundTen(ayanamsa),
      'moonSiderealDegrees': roundTen(moonSidereal),
      'nakshatra': nakshatraNames[nakshatra],
      'nakshatraIndex': nakshatra,
      'tithi': tithi,
      'karana': karana,
      if (gocharaHouse != null) 'gocharaHouse': gocharaHouse,
      if (natalRashi != null) 'natalMoonRashi': natalRashi,
      if (transitRashi != null) 'transitMoonRashi': transitRashi,
    },
  );
}
