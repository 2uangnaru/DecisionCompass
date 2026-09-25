import { evidence, clamp, round, mod } from './core.js';
import { skyAt } from './astronomy.js';

const modDouble = (x, n) => ((x % n) + n) % n;

export const NAKSHATRA_NAMES = Object.freeze([
  'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra',
  'Punarvasu', 'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni', 'Uttara Phalguni',
  'Hasta', 'Chitra', 'Swati', 'Vishakha', 'Anuradha', 'Jyeshtha',
  'Mula', 'Purva Ashadha', 'Uttara Ashadha', 'Shravana', 'Dhanishta', 'Shatabhisha',
  'Purva Bhadrapada', 'Uttara Bhadrapada', 'Revati',
]);

export const NAKSHATRA_VECTORS = Object.freeze([
  [.50, .40],   // 0: Ashwini
  [.40, .50],   // 1: Bharani
  [.20, .10],   // 2: Krittika
  [-.25, -.40], // 3: Rohini
  [.10, .30],   // 4: Mrigashira
  [-.30, .60],  // 5: Ardra
  [.40, .30],   // 6: Punarvasu
  [.60, -.20],  // 7: Pushya
  [-.40, .30],  // 8: Ashlesha
  [.50, -.20],  // 9: Magha
  [.30, .40],   // 10: Purva Phalguni
  [-.15, -.30], // 11: Uttara Phalguni
  [.50, .20],   // 12: Hasta
  [.30, .40],   // 13: Chitra
  [.20, .60],   // 14: Swati
  [.40, .20],   // 15: Vishakha
  [.20, -.20],  // 16: Anuradha
  [-.25, .40],  // 17: Jyeshtha
  [-.50, .70],  // 18: Mula
  [.40, .30],   // 19: Purva Ashadha
  [.30, -.30],  // 20: Uttara Ashadha
  [-.10, .20],  // 21: Shravana
  [.50, .30],   // 22: Dhanishta
  [-.30, .20],  // 23: Shatabhisha
  [.20, .50],   // 24: Purva Bhadrapada
  [-.20, -.30], // 25: Uttara Bhadrapada
  [.10, -.10],  // 26: Revati
]);

export function ayanamsaLahiri(ms) {
  const days = (ms - 946728000000.0) / 86400000.0;
  const years = days / 365.25;
  return 23.8617 + years * 0.01397;
}

export function toSidereal(tropicalLongitude, ayanamsa) {
  return modDouble(tropicalLongitude - ayanamsa, 360.0);
}

export function tithiVector(tithi) {
  const dayInFortnight = mod(tithi - 1, 15) + 1;
  const isWaxing = tithi <= 15;
  const isRikta = dayInFortnight === 4 || dayInFortnight === 9 || dayInFortnight === 14;
  const isPurna = dayInFortnight === 5 || dayInFortnight === 10 || dayInFortnight === 15;

  let a = isWaxing ? 0.20 : -0.15;
  if (isRikta) a -= 0.35;
  if (isPurna) a += 0.25;
  if (tithi === 30) a -= 0.30;

  const c = isWaxing ? 0.10 : -0.10;
  return [clamp(a), clamp(c)];
}

export function gocharaVector(house) {
  switch (house) {
    case 3: case 6: case 10: case 11:
      return [.45, .20];
    case 8:
      return [-.50, .40];
    case 12:
      return [-.35, .30];
    case 1:
      return [.10, -.10];
    case 2: case 4: case 5: case 7: case 9:
      return [.15, .05];
    default:
      return [0.0, 0.0];
  }
}

export function scoreVedic(ms, birth, natal) {
  const sky = skyAt(ms);
  const moonTropical = sky.positions.moon;
  const sunTropical = sky.positions.sun;

  if (moonTropical === undefined || sunTropical === undefined) {
    return { status: 'unavailable', evidence: evidence(0, 0, 0), diagnostics: {} };
  }

  const ayanamsa = ayanamsaLahiri(ms);
  const moonSidereal = toSidereal(moonTropical, ayanamsa);
  const sunSidereal = toSidereal(sunTropical, ayanamsa);

  const nakshatra = Math.floor(moonSidereal / (360.0 / 27.0)) % 27;
  const nakshatraVec = NAKSHATRA_VECTORS[nakshatra];

  const elongation = modDouble(moonTropical - sunTropical, 360.0);
  const tithi = Math.floor(elongation / 12.0) + 1;
  const karana = Math.floor(elongation / 6.0) + 1;
  const tithiVec = tithiVector(tithi);

  const natalMoonTropical = natal.positions ? natal.positions.moon : null;
  let natalMoonSidereal = null;
  let natalRashi = null;
  let transitRashi = null;
  let gocharaHouse = null;
  let gocharaVec = [0.0, 0.0];
  let hasGochara = false;

  if (natalMoonTropical !== undefined && natalMoonTropical !== null && birth.intervals && birth.intervals.length > 0) {
    const natalMs = birth.intervals[0].start;
    const natalAyanamsa = ayanamsaLahiri(natalMs);
    natalMoonSidereal = toSidereal(natalMoonTropical, natalAyanamsa);
    natalRashi = Math.floor(natalMoonSidereal / 30.0) % 12;
    transitRashi = Math.floor(moonSidereal / 30.0) % 12;
    gocharaHouse = mod(transitRashi - natalRashi, 12) + 1;
    gocharaVec = gocharaVector(gocharaHouse);
    hasGochara = true;
  }

  let a, c, coverage;
  if (hasGochara) {
    a = 0.40 * nakshatraVec[0] + 0.35 * gocharaVec[0] + 0.25 * tithiVec[0];
    c = 0.40 * nakshatraVec[1] + 0.35 * gocharaVec[1] + 0.25 * tithiVec[1];
    coverage = birth.clock !== null ? 1.0 : 0.85;
  } else {
    a = 0.60 * nakshatraVec[0] + 0.40 * tithiVec[0];
    c = 0.60 * nakshatraVec[1] + 0.40 * tithiVec[1];
    coverage = 0.65;
  }

  return {
    status: coverage === 0 ? 'unavailable' : coverage < 0.999999 ? 'partial' : 'calculated',
    evidence: evidence(clamp(a), clamp(c), coverage),
    diagnostics: {
      ayanamsaDegrees: round(ayanamsa),
      moonSiderealDegrees: round(moonSidereal),
      nakshatra: NAKSHATRA_NAMES[nakshatra],
      nakshatraIndex: nakshatra,
      tithi,
      karana,
      ...(gocharaHouse !== null ? { gocharaHouse } : {}),
      ...(natalRashi !== null ? { natalMoonRashi: natalRashi } : {}),
      ...(transitRashi !== null ? { transitMoonRashi: transitRashi } : {}),
    },
  };
}
