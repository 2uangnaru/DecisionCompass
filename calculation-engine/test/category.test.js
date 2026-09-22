import test from 'node:test';
import assert from 'node:assert/strict';
import { calculate, createCalculator, CATEGORIES } from '../src/index.js';
import { CATEGORY_WEIGHTS, MODES, WEIGHTS, combine, evidence, weightsFor } from '../src/core.js';
import { WESTERN_CATEGORY_PROFILES } from '../src/astronomy.js';
import { ZIWEI_CATEGORY_TARGETS, buildZiWei, scoreZiWei } from '../src/ziwei.js';
import { birthContext } from '../src/time.js';
import { calendarAt } from '../src/calendar.js';

const profile = { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male' };
const context = { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' };
const engine = createCalculator(profile);
const reading = category => engine.calculate({ context, mode: 'yes_no', period: 'now', category });

test('the category enum is exactly the seven documented wire values', () => {
  assert.deepEqual([...CATEGORIES], ['general', 'love', 'career', 'money', 'study', 'friends', 'other']);
});

test('every category is accepted and echoed back in the result and snapshot', () => {
  for (const category of CATEGORIES) {
    const r = reading(category);
    assert.equal(r.category, category);
    assert.equal(r.inputSnapshot.category, category);
    assert.equal(r.percentages.YES + r.percentages.NO, 100);
  }
});

test('an omitted category still defaults to general', () => {
  const omitted = engine.calculate({ context, mode: 'yes_no', period: 'now' });
  assert.equal(omitted.category, 'general');
  assert.deepEqual(omitted.percentages, reading('general').percentages);
  assert.equal(omitted.readingKey, reading('general').readingKey);
});

test('unknown categories are rejected rather than silently downgraded', () => {
  for (const category of ['medical', 'legal', 'General', '', 'toString', 'constructor']) {
    assert.throws(() => engine.calculate({ context, category }), /INVALID_CATEGORY/, `accepted ${category}`);
  }
});

test('readingKey changes with category, and repeats are deterministic', () => {
  const keys = new Map(CATEGORIES.map(category => [category, reading(category).readingKey]));
  assert.equal(new Set(keys.values()).size, CATEGORIES.length, 'each category needs its own snapshot identity');
  for (const category of CATEGORIES) {
    assert.equal(reading(category).readingKey, keys.get(category));
    assert.deepEqual(reading(category), reading(category));
  }
});

test('general and other share the formula but stay distinct readings', () => {
  const general = reading('general'), other = reading('other');
  assert.deepEqual(CATEGORY_WEIGHTS.other, WEIGHTS);
  assert.equal(general.modeScore, other.modeScore);
  assert.deepEqual(general.percentages, other.percentages);
  assert.notEqual(general.readingKey, other.readingKey);
  assert.equal(other.category, 'other');
});

test('category reaches the fused evidence, not just the label', () => {
  const scores = new Map(CATEGORIES.map(category => [category, reading(category).modeScore]));
  // Not every category must differ for every input, but a category-aware engine
  // must produce more than one distinct score for this reference case.
  assert.ok(new Set(scores.values()).size >= 4, `expected varied scores, got ${[...scores.values()]}`);
  assert.notEqual(scores.get('love'), scores.get('general'));
});

test('module weights come from the selected category profile', () => {
  for (const category of CATEGORIES) {
    const modules = reading(category).segments[0].modules;
    for (const [name, weight] of Object.entries(CATEGORY_WEIGHTS[category])) {
      assert.ok(Math.abs(modules[name].weight - weight) < 1e-9, `${category}/${name}`);
      const expected = weight * modules[name].coverage * modules[name].a;
      assert.ok(Math.abs(modules[name].contribution.a - expected) < 1e-9, `${category}/${name} contribution`);
    }
  }
});

test('every module-weight profile is complete, non-negative and sums to 1', () => {
  for (const category of CATEGORIES) {
    const weights = weightsFor(category), names = Object.keys(weights);
    assert.deepEqual(names.sort(), Object.keys(WEIGHTS).sort());
    assert.ok(names.every(name => Number.isFinite(weights[name]) && weights[name] >= 0));
    assert.ok(Math.abs(Object.values(weights).reduce((s, w) => s + w, 0) - 1) < 1e-9, category);
  }
  assert.throws(() => weightsFor('medical'), /INVALID_CATEGORY/);
});

test('every Western body profile covers the supported bodies and sums to 1', () => {
  const bodies = ['sun', 'moon', 'mercury', 'venus', 'mars', 'jupiter', 'saturn'];
  for (const [category, weights] of Object.entries(WESTERN_CATEGORY_PROFILES)) {
    assert.deepEqual(Object.keys(weights).sort(), [...bodies].sort(), category);
    assert.ok(Object.values(weights).every(w => Number.isFinite(w) && w >= 0), category);
    assert.ok(Math.abs(Object.values(weights).reduce((s, w) => s + w, 0) - 1) < 1e-9, category);
  }
  // general/other deliberately keep the verified default transit/natal pair.
  assert.equal(WESTERN_CATEGORY_PROFILES.general, undefined);
  assert.equal(reading('general').segments[0].modules.W.status, 'calculated');
});

test('Zi Wei target palettes resolve, and diagnostics name them', () => {
  for (const category of CATEGORIES) {
    const spec = ZIWEI_CATEGORY_TARGETS[category];
    assert.ok(spec.length >= 1, category);
    assert.ok(Math.abs(spec.reduce((s, t) => s + t.weight, 0) - 1) < 1e-9, category);
  }

  const built = buildZiWei(birthContext({ ...profile, birthCountry: 'VN' }), 'male');
  const cal = calendarAt(Date.parse(context.instantUtc), context.deviceTimezone);
  for (const category of CATEGORIES) {
    const scored = scoreZiWei(built, cal, category);
    const targets = scored.diagnostics.targetPalaces;
    assert.equal(targets.length, ZIWEI_CATEGORY_TARGETS[category].length, category);
    assert.ok(targets.every(t => Number.isInteger(t.index) && t.index >= 0), `${category} unresolved palace`);
    assert.equal(scored.diagnostics.category, category);
  }
  assert.throws(() => scoreZiWei(built, cal, 'medical'), /INVALID_CATEGORY/);
});

test('the friends profile accepts either provider alias for the servant palace', () => {
  assert.deepEqual([...ZIWEI_CATEGORY_TARGETS.friends[0].palaces], ['仆役', '交友']);
  const built = buildZiWei(birthContext({ ...profile, birthCountry: 'VN' }), 'male');
  const cal = calendarAt(Date.parse(context.instantUtc), context.deviceTimezone);
  const resolved = scoreZiWei(built, cal, 'friends').diagnostics.targetPalaces;
  assert.ok(['仆役', '交友'].includes(resolved[0].palace), `resolved to ${resolved[0].palace}`);
});

test('Zi Wei scoring differs by category on the same chart', () => {
  const built = buildZiWei(birthContext({ ...profile, birthCountry: 'VN' }), 'male');
  const cal = calendarAt(Date.parse(context.instantUtc), context.deviceTimezone);
  const values = CATEGORIES.map(category => scoreZiWei(built, cal, category).evidence.a);
  assert.ok(new Set(values).size >= 4, `expected varied Zi Wei scores, got ${values}`);
});

test('unknown hour and unknown convention keep their scenario policy per category', () => {
  const vague = createCalculator({ birthDate: '1998-06-21', birthCountry: 'VN' });
  for (const category of CATEGORIES) {
    const r = vague.calculate({ context, category, diagnostics: true });
    const z = r.segments[0].modules.Z;
    assert.equal(z.status, 'scenario_analysis');
    assert.equal(z.diagnostics.unknownBirthHour, true);
    assert.equal(z.diagnostics.unknownConvention, true);
    assert.ok(Math.abs(z.diagnostics.inputCoverageFactor - .5625) < 1e-9);
    assert.equal(z.diagnostics.category, category);
    assert.ok(r.warnings.includes('unknown_birth_time'));
  }
});

test('decision-mode coefficients are untouched by the category work', () => {
  assert.deepEqual(
    Object.fromEntries(Object.entries(MODES).map(([mode, m]) => [mode, [m.a, m.c, m.sign, m.basis]])),
    {
      yes_no: [1, 0, 1, 'overall_acceptance'],
      act_wait: [.85, .15, 1, 'action_timing'],
      advance_retreat: [.55, .45, 1, 'tactical_momentum'],
      stay_go: [0, 1, -1, 'change_alignment'],
      keep_let_go: [-.3, .7, -1, 'release_alignment'],
      forward_backward: [.25, .75, 1, 'temporal_momentum'],
      left_right: [.7, -.3, -1, 'symbolic_polarity'],
    },
  );
});

test('all seven modes stay distinct under a category', () => {
  const modes = Object.keys(MODES);
  for (const category of ['general', 'love', 'money']) {
    const bases = modes.map(mode => engine.calculate({ context, mode, category }).modeBasis);
    assert.equal(new Set(bases).size, modes.length, category);
  }
});

test('coverage is still applied exactly once and missing weight is not redistributed', () => {
  // Only N present: love weights N at .10, so a=.6*.5*.10 and coverage=.5*.10.
  const single = combine({ N: evidence(.6, .4, .5) }, 'love');
  assert.ok(Math.abs(single.a - .03) < 1e-12);
  assert.ok(Math.abs(single.coverage - .05) < 1e-12);
  assert.throws(() => combine({ F: evidence(1, 1, 1) }, 'love'), /UNKNOWN_MODULE/);
  assert.throws(() => combine({ N: evidence(.6, .4, .5) }, 'medical'), /INVALID_CATEGORY/);
});

test('category is part of the evaluation cache identity, not just the output', () => {
  // Same instant and zone, different category: Z and W must change, which only
  // happens if the cache key includes the category.
  const love = reading('love').segments[0].modules;
  const career = reading('career').segments[0].modules;
  assert.notEqual(love.Z.a, career.Z.a);
  assert.notEqual(love.W.a, career.W.a);
  assert.equal(love.N.a, career.N.a, 'numerology stays category-neutral');
  assert.equal(love.U.a, career.U.a, 'cosmic stays category-neutral');
  assert.equal(love.T.a, career.T.a, 'almanac stays category-neutral in this version');
  assert.equal(love.B.a, career.B.a, 'BaZi evidence stays category-neutral; weight carries the emphasis');
});

test('a one-shot calculate() call honours category the same way', () => {
  const direct = calculate({ profile, context, mode: 'yes_no', period: 'now', category: 'study' });
  assert.equal(direct.category, 'study');
  assert.equal(direct.readingKey, reading('study').readingKey);
});
