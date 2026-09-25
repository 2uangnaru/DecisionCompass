import test from 'node:test';
import assert from 'node:assert/strict';
import { ayanamsaLahiri, toSidereal, NAKSHATRA_NAMES, NAKSHATRA_VECTORS, tithiVector, gocharaVector, scoreVedic } from '../src/vedic.js';
import { birthContext } from '../src/time.js';
import { natalSky } from '../src/astronomy.js';

test('Lahiri Ayanamsa computes valid astronomical offset', () => {
  const j2000 = 946728000000.0;
  assert.ok(Math.abs(ayanamsaLahiri(j2000) - 23.8617) < 0.001);
  const ms2026 = Date.parse('2026-09-18T08:30:00Z');
  const a2026 = ayanamsaLahiri(ms2026);
  assert.ok(a2026 > 24.2 && a2026 < 24.3);
});

test('sidereal conversion maps tropical degrees within 0..360', () => {
  assert.equal(toSidereal(30, 24), 6);
  assert.equal(toSidereal(10, 24), 346);
});

test('all 27 Nakshatras have valid normalized vectors', () => {
  assert.equal(NAKSHATRA_NAMES.length, 27);
  assert.equal(NAKSHATRA_VECTORS.length, 27);
  for (let i = 0; i < 27; i++) {
    const [a, c] = NAKSHATRA_VECTORS[i];
    assert.ok(Number.isFinite(a) && a >= -1 && a <= 1);
    assert.ok(Number.isFinite(c) && c >= -1 && c <= 1);
  }
});

test('tithi vectors reward waxing purna and penalize rikta/amavasya', () => {
  const purna = tithiVector(15);
  const rikta = tithiVector(4);
  const amavasya = tithiVector(30);
  assert.ok(purna[0] > rikta[0]);
  assert.ok(purna[0] > amavasya[0]);
  assert.ok(rikta[0] < 0);
  assert.ok(amavasya[0] < 0);
});

test('gochara Upachaya houses are positive and house 8 is cautionary', () => {
  for (const h of [3, 6, 10, 11]) {
    assert.ok(gocharaVector(h)[0] > 0);
  }
  assert.ok(gocharaVector(8)[0] < 0);
  assert.ok(gocharaVector(12)[0] < 0);
});

test('scoreVedic produces valid evidence and diagnostics', () => {
  const profile = { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN' };
  const birth = birthContext(profile);
  const natal = natalSky(birth);
  const now = Date.parse('2026-09-18T08:30:00Z');
  const res = scoreVedic(now, birth, natal);

  assert.equal(res.status, 'calculated');
  assert.ok(res.evidence.coverage > 0 && res.evidence.coverage <= 1);
  assert.ok(res.evidence.a >= -1 && res.evidence.a <= 1);
  assert.ok(res.evidence.c >= -1 && res.evidence.c <= 1);
  assert.ok(res.diagnostics.nakshatra);
  assert.ok(res.diagnostics.tithi >= 1 && res.diagnostics.tithi <= 30);
  assert.ok(res.diagnostics.karana >= 1 && res.diagnostics.karana <= 60);
  assert.ok(res.diagnostics.gocharaHouse >= 1 && res.diagnostics.gocharaHouse <= 12);
});
