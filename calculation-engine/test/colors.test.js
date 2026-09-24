import assert from 'node:assert/strict';
import test from 'node:test';
import { createCalculator } from '../src/index.js';
import {
  ELEMENT_STEMS, GENERATES, LEAD_WEIGHTS, PALETTE, STEM_ELEMENTS,
  SUPPORT_WEIGHTS, colorSignal, dailyColors, dailyModules,
} from '../src/colors.js';

const PROFILE = { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'US', traditionalProfile: 'unspecified' };
const ZONE = 'Asia/Ho_Chi_Minh';
const engine = createCalculator(PROFILE);

/** A reading at 10:00 local on the given UTC-based day offset. */
const readingOn = (year, monthIndex, day, opts = {}) => engine.calculate({
  context: { instantUtc: new Date(Date.UTC(year, monthIndex, day, 3, 0, 0)).toISOString(), deviceTimezone: ZONE },
  mode: opts.mode ?? 'yes_no', period: opts.period ?? 'now', category: opts.category ?? 'general',
});

test('the palette is twenty distinct colours, two per stem', () => {
  assert.equal(PALETTE.length, 10);
  const keys = [], hexes = [], names = [];
  for (const pair of PALETTE) {
    assert.equal(pair.length, 2);
    for (const shade of pair) {
      assert.match(shade.hex, /^#[0-9A-F]{6}$/);
      keys.push(shade.key); hexes.push(shade.hex); names.push(shade.name);
    }
  }
  assert.equal(new Set(keys).size, 20);
  assert.equal(new Set(hexes).size, 20);
  assert.equal(new Set(names).size, 20);
});

test('every stem belongs to an element that holds exactly that stem', () => {
  assert.equal(STEM_ELEMENTS.length, 10);
  for (const [element, stems] of Object.entries(ELEMENT_STEMS)) {
    assert.equal(stems.length, 2);
    for (const stem of stems) assert.equal(STEM_ELEMENTS[stem], element);
  }
  // The generating cycle is a single five-step loop.
  let element = 'wood';
  const walked = new Set();
  for (let i = 0; i < 5; i++) { walked.add(element); element = GENERATES[element]; }
  assert.equal(element, 'wood');
  assert.equal(walked.size, 5);
});

test('the lead colour is distinct across ten consecutive local dates', () => {
  const leads = [];
  for (let day = 0; day < 10; day++) leads.push(readingOn(2026, 8, 18 + day).dailyBrief.colors.lead.key);
  assert.equal(new Set(leads).size, 10, 'ten consecutive days must not reuse a lead colour');
});

test('the lead colour never repeats on adjacent days, across boundaries', () => {
  // A month end, a year end and a leap-year February are all just stem
  // arithmetic, but they are where an off-by-one would surface.
  for (const [year, monthIndex, day] of [[2026, 8, 25], [2026, 11, 27], [2028, 1, 25]]) {
    const leads = [];
    for (let offset = 0; offset < 12; offset++) {
      leads.push(readingOn(year, monthIndex, day + offset).dailyBrief.colors.lead.key);
    }
    for (let i = 1; i < leads.length; i++) {
      assert.notEqual(leads[i], leads[i - 1], `${year}-${monthIndex + 1}-${day}+${i} repeated ${leads[i]}`);
    }
  }
});

test('the two colours are always different families and different colours', () => {
  for (let day = 0; day < 20; day++) {
    const { lead, supporting } = readingOn(2026, 8, 18 + day).dailyBrief.colors;
    assert.notEqual(lead.element, supporting.element);
    assert.notEqual(lead.hex, supporting.hex);
    assert.equal(supporting.element, GENERATES[lead.element], 'supporting must be the generated family');
    assert.equal(STEM_ELEMENTS[lead.stem], lead.element);
    assert.equal(STEM_ELEMENTS[supporting.stem], supporting.element);
  }
});

test('colours hold for the whole day, whatever is asked of the engine', () => {
  const baseline = readingOn(2026, 8, 18).dailyBrief.colors;
  // Every mode, every category, every period, and a different hour of the
  // same local day must all report the same pair.
  for (const mode of ['yes_no', 'act_wait', 'stay_go', 'left_right', 'keep_let_go']) {
    assert.deepEqual(readingOn(2026, 8, 18, { mode }).dailyBrief.colors, baseline, mode);
  }
  for (const category of ['love', 'career', 'money', 'study', 'friends', 'other']) {
    assert.deepEqual(readingOn(2026, 8, 18, { category }).dailyBrief.colors, baseline, category);
  }
  for (const period of ['evening', 'afternoon']) {
    assert.deepEqual(readingOn(2026, 8, 18, { period }).dailyBrief.colors, baseline, period);
  }
  const lateSameDay = engine.calculate({
    context: { instantUtc: '2026-09-18T15:40:00.000Z', deviceTimezone: ZONE }, // 22:40 local
    mode: 'yes_no', period: 'now', category: 'general',
  });
  assert.equal(lateSameDay.context.localDate, '2026-09-18');
  assert.deepEqual(lateSameDay.dailyBrief.colors, baseline);
});

test('a different profile can get a different shade of the same family', () => {
  const other = createCalculator({ ...PROFILE, birthDate: '1972-02-29', birthTime: null });
  const mine = readingOn(2026, 8, 18).dailyBrief.colors.lead;
  const theirs = other.calculate({
    context: { instantUtc: new Date(Date.UTC(2026, 8, 18, 3)).toISOString(), deviceTimezone: ZONE },
    mode: 'yes_no', period: 'now', category: 'general',
  }).dailyBrief.colors.lead;
  // Same day, so the same stem and family; the shade is what personalises it.
  assert.equal(theirs.stem, mine.stem);
  assert.equal(theirs.element, mine.element);
});

test('a module with no coverage does not vote, and does not drag the signal', () => {
  const full = { B: { a: .5, c: 0, coverage: 1 }, Z: { a: .5, c: 0, coverage: 1 }, W: { a: .5, c: 0, coverage: 1 }, N: { a: .5, c: 0, coverage: 1 } };
  assert.ok(Math.abs(colorSignal(full, LEAD_WEIGHTS) - .5) < 1e-12);
  // Dropping two modules entirely leaves the remaining agreement intact,
  // rather than halving it toward zero.
  const partial = { B: { a: .5, c: 0, coverage: 1 }, Z: { a: .5, c: 0, coverage: 0 }, W: { a: .5, c: 0, coverage: 1 }, N: { a: .5, c: 0, coverage: 0 } };
  assert.ok(Math.abs(colorSignal(partial, LEAD_WEIGHTS) - .5) < 1e-12);
  assert.equal(colorSignal({}, SUPPORT_WEIGHTS), 0);
});

test('day modules are weighted by elapsed seconds, not by segment count', () => {
  const modules = dailyModules([
    { duration: 3600, modules: { B: { a: 1, c: 0, coverage: 1 } } },
    { duration: 10800, modules: { B: { a: -1, c: 0, coverage: 1 } } },
  ]);
  // Three hours of -1 against one hour of +1 averages to -0.5.
  assert.ok(Math.abs(modules.B.a + .5) < 1e-12);
  assert.throws(() => dailyModules([]), /INVALID_SEGMENTS/);
  assert.throws(() => dailyModules([{ duration: 0, modules: {} }]), /INVALID_SEGMENTS/);
});

test('an out-of-range stem is refused rather than guessed at', () => {
  const segments = [{ duration: 3600, modules: { B: { a: 0, c: 0, coverage: 1 } } }];
  assert.throws(() => dailyColors(segments, 10, 1), /INVALID_DAY_STEM/);
  assert.throws(() => dailyColors(segments, -1, 1), /INVALID_DAY_STEM/);
  assert.throws(() => dailyColors(segments, 1.5, 1), /INVALID_DAY_STEM/);
});

test('the brief never claims Yong Shen', () => {
  const colors = readingOn(2026, 8, 18).dailyBrief.colors;
  assert.equal(colors.meaning, 'symbolic_colour_pairing_not_yong_shen');
});

test('a module wrapped alongside diagnostics is still read', () => {
  // The engine's own modules arrive wrapped. Reading `module.a` directly saw
  // `undefined`, dropped every module, and left the signal permanently zero —
  // which quietly pinned every lead colour to its second shade.
  const wrapped = dailyModules([
    {
      duration: 3600,
      modules: { B: { evidence: { a: .8, c: 0, coverage: 1 }, diagnostics: {} } },
    },
  ]);
  assert.ok(Math.abs(wrapped.B.a - .8) < 1e-12, 'wrapped evidence was ignored');
  assert.equal(wrapped.B.coverage, 1);
  assert.ok(colorSignal(wrapped, LEAD_WEIGHTS) > 0, 'signal collapsed to zero');
});

test('the lead shade actually responds to the signal', () => {
  const segment = evidence => [{ duration: 3600, modules: { B: { evidence }, Z: { evidence }, W: { evidence }, N: { evidence } } }];
  const positive = dailyColors(segment({ a: .6, c: 0, coverage: 1 }), 0, 1);
  const negative = dailyColors(segment({ a: -.6, c: 0, coverage: 1 }), 0, 1);
  assert.notEqual(positive.lead.key, negative.lead.key,
    'both signs picked the same shade, so the signal is not being used');
  assert.equal(positive.lead.stem, negative.lead.stem, 'the family is the day stem either way');
});
