// Dumps an astronomy parity corpus straight out of the Node engine.
//
// Positions are compared bit-for-bit on the Dart side, because the VSOP and
// lunar series are ported term for term in the same summation order. A
// mismatch means the port drifted, not that the model is "close enough".

import { emitFixture } from './lib.mjs';
import { longitude, skyAt, natalSky, aspect, western, cosmic } from '../../src/astronomy.js';
import { birthContext, parseInstant } from '../../src/time.js';
import { CATEGORIES } from '../../src/core.js';

const BODIES = ['sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn'];

const INSTANTS = [
  '1900-01-01T00:00:00.000Z', '1923-07-04T11:11:11.000Z', '1950-12-25T18:00:00.000Z',
  '1969-07-20T20:17:40.000Z', '1985-03-31T01:30:00.000Z', '1998-06-21T07:30:00.000Z',
  '2000-01-01T12:00:00.000Z', '2011-12-30T12:00:00.000Z', '2020-02-29T00:00:00.000Z',
  '2026-09-18T08:00:00.000Z', '2026-09-18T08:30:00.000Z', '2026-03-08T07:30:00.000Z',
  '2026-11-01T05:30:00.000Z', '2050-06-15T03:21:09.000Z', '2099-12-31T23:59:59.000Z',
];

const BIRTHS = [
  { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN' },
  { birthDate: '1998-06-21', birthTime: null, birthCountry: 'VN' },
  { birthDate: '1974-11-03', birthTime: '01:30', birthCountry: 'US' },
  { birthDate: '1900-01-01', birthTime: null, birthCountry: 'VN' },
  { birthDate: '2011-12-30', birthTime: '12:00', birthCountry: 'WS' },
  { birthDate: '1960-02-29', birthTime: '23:59', birthCountry: 'NP' },
];

const serializeModule = (module) => ({
  status: module.status,
  a: module.evidence.a,
  c: module.evidence.c,
  coverage: module.evidence.coverage,
});

const corpus = {
  longitudes: INSTANTS.map((iso) => {
    const ms = parseInstant(iso);
    return { iso, ms, values: Object.fromEntries(BODIES.map((b) => [b, longitude(b, ms)])) };
  }),
  sky: INSTANTS.map((iso) => {
    const ms = parseInstant(iso);
    const sky = skyAt(ms);
    return { iso, ms, positions: sky.positions, mercurySpeed: sky.mercurySpeed,
      evaluatedAtUtc: sky.evaluatedAtUtc, cosmic: serializeModule(cosmic(sky)) };
  }),
  aspects: [],
  natal: BIRTHS.map((profile) => {
    const natal = natalSky(birthContext(profile));
    return { profile, positions: natal.positions, ranges: natal.ranges, status: natal.status,
      sampleCount: natal.sampleCount ?? null, method: natal.method };
  }),
  western: [],
};

for (const [transit, natal, body] of [
  [0, 0, 'sun'], [10, 8, 'moon'], [123.456, 3.21, 'mercury'], [359.9, 0.05, 'venus'],
  [180, 0, 'mars'], [90.5, 0, 'jupiter'], [61.2, 0.1, 'saturn'], [271.3, 91.2, 'sun'],
  [45, 0, 'moon'], [118.9, 0, 'mars'],
]) {
  const hit = aspect(transit, natal, body);
  corpus.aspects.push({ transit, natal, body, angle: hit.angle, strength: hit.strength,
    a: hit.a, c: hit.c });
}

for (const profile of BIRTHS) {
  const natal = natalSky(birthContext(profile));
  for (const iso of INSTANTS.slice(-6)) {
    const sky = skyAt(parseInstant(iso));
    for (const category of CATEGORIES) {
      corpus.western.push({ profile, iso, category, ...serializeModule(western(sky, natal, category)) });
    }
  }
}

const target = emitFixture('astronomy_corpus.json', JSON.stringify(corpus, null, 2));
process.stdout.write(`astronomy corpus -> ${target}\n`);
