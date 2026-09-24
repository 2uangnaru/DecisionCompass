import { clamp } from './core.js';

/**
 * Two personalised colours for a local civil day.
 *
 * Editorial symbolism, not a validated prediction and not an automatic Yong
 * Shen / Xi Shen: the engine does not claim a favourable element for a person,
 * only a colour pairing derived from the day's own stem and that day's
 * module signals. Nothing here invents birth-hour information — a module with
 * no coverage simply drops out of its weighted signal.
 *
 * Ten Heavenly Stems, two shades each. The previous rule folded the ten stems
 * into five colours (`COLORS[stem/2]`), so the day stem advancing by one each
 * day repeated the colour every second day. Giving each stem its own pair
 * makes the lead colour distinct across any ten consecutive local dates.
 */
export const PALETTE = Object.freeze([
  // 甲 wood
  [{ key: 'cedar', name: 'Cedar', hex: '#4EAE83' }, { key: 'jade', name: 'Jade', hex: '#56C6A5' }],
  // 乙 wood
  [{ key: 'sage', name: 'Sage', hex: '#9BBF8A' }, { key: 'mint', name: 'Mint', hex: '#AADBB2' }],
  // 丙 fire
  [{ key: 'ember', name: 'Ember', hex: '#D97566' }, { key: 'solar_coral', name: 'Solar Coral', hex: '#E88862' }],
  // 丁 fire
  [{ key: 'rose', name: 'Rose', hex: '#C9758F' }, { key: 'blossom', name: 'Blossom', hex: '#DC8DA0' }],
  // 戊 earth
  [{ key: 'ochre', name: 'Ochre', hex: '#C59E61' }, { key: 'amber', name: 'Amber', hex: '#D4AA68' }],
  // 己 earth
  [{ key: 'sand', name: 'Sand', hex: '#D8BF92' }, { key: 'clay', name: 'Clay', hex: '#C9A77A' }],
  // 庚 metal
  [{ key: 'silver', name: 'Silver', hex: '#AAB9CB' }, { key: 'steel', name: 'Steel', hex: '#95AAC1' }],
  // 辛 metal
  [{ key: 'pearl', name: 'Pearl', hex: '#E8DED0' }, { key: 'champagne', name: 'Champagne', hex: '#E4D5B5' }],
  // 壬 water
  [{ key: 'ocean_blue', name: 'Ocean Blue', hex: '#66A9D2' }, { key: 'azure', name: 'Azure', hex: '#4F9CCB' }],
  // 癸 water
  [{ key: 'indigo', name: 'Indigo', hex: '#899AD5' }, { key: 'mist_blue', name: 'Mist Blue', hex: '#9FBCE1' }],
]);

/** The Five Element each Heavenly Stem belongs to, in stem order. */
export const STEM_ELEMENTS = Object.freeze([
  'wood', 'wood', 'fire', 'fire', 'earth', 'earth', 'metal', 'metal', 'water', 'water',
]);

/** The stems of each element: the yang stem first, then the yin stem. */
export const ELEMENT_STEMS = Object.freeze({
  wood: [0, 1], fire: [2, 3], earth: [4, 5], metal: [6, 7], water: [8, 9],
});

/**
 * The generating cycle (相生). The supporting colour is drawn from the family
 * the lead's element generates, so the two are always from different families
 * — visually distinct by construction — and read as flowing rather than
 * clashing.
 */
export const GENERATES = Object.freeze({
  wood: 'fire', fire: 'earth', earth: 'metal', metal: 'water', water: 'wood',
});

/**
 * Module weights for the lead shade: the full-day general reading, Ba Zi and
 * Zi Wei leading, Western natal/transit and numerology supporting.
 */
export const LEAD_WEIGHTS = Object.freeze({ B: .30, Z: .30, W: .20, N: .20 });

/**
 * Module weights for the supporting family. Deliberately excludes Ba Zi, so
 * the second colour is not a restatement of the first: it reads the day
 * through Zi Wei, the sky and numerology instead.
 */
export const SUPPORT_WEIGHTS = Object.freeze({ Z: .40, W: .30, N: .30 });

/**
 * Duration-weighted average of each module over the whole local day, so the
 * result cannot depend on when the app was opened. Segments carry their own
 * elapsed seconds, which handles 23- and 25-hour DST days naturally.
 */
export function dailyModules(segments) {
  if (!segments.length) throw new Error('INVALID_SEGMENTS');
  const seconds = segments.reduce((s, x) => s + x.duration, 0);
  if (!seconds || segments.some(x => !Number.isFinite(x.duration) || x.duration <= 0)) {
    throw new Error('INVALID_SEGMENTS');
  }
  const out = {};
  for (const segment of segments) {
    for (const [name, module] of Object.entries(segment.modules)) {
      // Modules arrive either as evidence or wrapped alongside diagnostics,
      // exactly as `combine` in core.js has to allow for. Reading `module.a`
      // directly would silently see `undefined` and drop every module.
      const e = module.evidence ?? module;
      const slot = out[name] ??= { a: 0, c: 0, coverage: 0 };
      slot.a += segment.duration * e.a;
      slot.c += segment.duration * e.c;
      slot.coverage += segment.duration * e.coverage;
    }
  }
  for (const slot of Object.values(out)) {
    slot.a /= seconds; slot.c /= seconds; slot.coverage /= seconds;
  }
  return out;
}

/**
 * One signal in [-1, 1] from the named modules' action axis, each weighted by
 * its own data coverage and then normalised by the weight actually present.
 * A module the profile cannot support does not drag the signal toward zero;
 * it simply does not vote.
 */
export function colorSignal(modules, weights) {
  let sum = 0, total = 0;
  for (const [name, weight] of Object.entries(weights)) {
    const module = modules[name];
    if (!module || !module.coverage) continue;
    const applied = weight * module.coverage;
    sum += applied * module.a;
    total += applied;
  }
  return total ? clamp(sum / total) : 0;
}

/**
 * The day's two colours.
 *
 * - **Lead**: the local civil day's own stem fixes the family; its two shades
 *   are separated by the sign of the full-day [LEAD_WEIGHTS] signal. The stem
 *   advances one per day, so the lead colour is distinct across any ten
 *   consecutive local dates.
 * - **Supporting**: the family the lead's element generates. Which of that
 *   family's two stems is chosen by the sign of the [SUPPORT_WEIGHTS] signal
 *   (yang stem when non-negative, yin stem otherwise), and the shade within
 *   it by the parity of the numerology personal day.
 *
 * Both are fixed for the whole local day: nothing here reads the decision
 * mode, the category, the chosen period or the instant of the request.
 */
export function dailyColors(segments, dayStem, personalDay) {
  if (!Number.isInteger(dayStem) || dayStem < 0 || dayStem > 9) {
    throw new Error('INVALID_DAY_STEM');
  }
  const modules = dailyModules(segments);
  const leadElement = STEM_ELEMENTS[dayStem];
  const lead = PALETTE[dayStem][colorSignal(modules, LEAD_WEIGHTS) >= 0 ? 1 : 0];

  const supportElement = GENERATES[leadElement];
  const supportStem = ELEMENT_STEMS[supportElement][
    colorSignal(modules, SUPPORT_WEIGHTS) >= 0 ? 0 : 1
  ];
  const shade = Number.isInteger(personalDay) ? Math.abs(personalDay) % 2 : 0;
  const supporting = PALETTE[supportStem][shade];

  return {
    lead: { ...lead, element: leadElement, stem: dayStem },
    supporting: { ...supporting, element: supportElement, stem: supportStem },
    meaning: 'symbolic_colour_pairing_not_yong_shen',
  };
}
