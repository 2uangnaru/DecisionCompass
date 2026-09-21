export const VERSION = '3.1.0-mvp';
export const RULESET = 'civil-midnight-chinese-calendar-symbolic-v4';
export const WEIGHTS = Object.freeze({ B: 2 / 9, Z: 2 / 9, T: 1 / 9, W: 2 / 9, N: 1 / 6, U: 1 / 18 });
export const MODES = Object.freeze({
  yes_no: Object.freeze({ labels: ['YES', 'NO'], a: 1, c: 0, sign: 1, basis: 'overall_acceptance' }),
  act_wait: Object.freeze({ labels: ['ACT', 'WAIT'], a: .85, c: .15, sign: 1, basis: 'action_timing' }),
  advance_retreat: Object.freeze({ labels: ['ADVANCE', 'RETREAT'], a: .55, c: .45, sign: 1, basis: 'tactical_momentum' }),
  stay_go: Object.freeze({ labels: ['STAY', 'GO'], a: 0, c: 1, sign: -1, basis: 'change_alignment' }),
  keep_let_go: Object.freeze({ labels: ['KEEP', 'LET GO'], a: -.3, c: .7, sign: -1, basis: 'release_alignment' }),
  forward_backward: Object.freeze({ labels: ['FORWARD', 'BACKWARD'], a: .25, c: .75, sign: 1, basis: 'temporal_momentum' }),
  left_right: Object.freeze({ labels: ['LEFT', 'RIGHT'], a: .7, c: -.3, sign: -1, basis: 'symbolic_polarity' }),
});
export const mod = (x, n) => ((x % n) + n) % n;
export const clamp = x => Math.max(-1, Math.min(1, x));
export const round = x => Math.round(x * 1e10) / 1e10;
export function evidence(a = 0, c = 0, coverage = 0) {
  if (![a, c, coverage].every(Number.isFinite) || Math.abs(a) > 1.00000001 || Math.abs(c) > 1.00000001 || coverage < 0 || coverage > 1.00000001) throw new Error('INVALID_EVIDENCE');
  return { a: clamp(a), c: clamp(c), coverage: Math.min(1, coverage) };
}
// Within a module, normalize the available components and return coverage separately.
export function blend(parts) {
  const q = parts.reduce((s, [w, e]) => s + w * e.coverage, 0);
  if (!q) return evidence();
  return evidence(...['a', 'c'].map(k => clamp(parts.reduce((s, [w, e]) => s + w * e.coverage * e[k], 0) / q)), q);
}
// At the final boundary, coverage is applied exactly once; no missing-module redistribution.
export function combine(modules) {
  const out = { a: 0, c: 0, coverage: 0 };
  for (const [name, entry] of Object.entries(modules)) {
    if (!Object.hasOwn(WEIGHTS, name)) throw new Error(`UNKNOWN_MODULE:${name}`);
    const e = entry.evidence ?? entry;
    evidence(e.a, e.c, e.coverage);
    const w = WEIGHTS[name] * e.coverage;
    out.a += w * e.a; out.c += w * e.c; out.coverage += w;
  }
  return evidence(clamp(out.a), clamp(out.c), Math.min(1, out.coverage));
}
export function percent(score) { return Math.floor(50 + 40 * clamp(score) + .5); }
export function scoreForMode(e, mode) {
  if (!Object.hasOwn(MODES, mode)) throw new Error('INVALID_DECISION_MODE');
  const definition = MODES[mode];
  return clamp(definition.sign * (definition.a * e.a + definition.c * e.c));
}
export function decision(e, mode) {
  if (!Object.hasOwn(MODES, mode)) throw new Error('INVALID_DECISION_MODE');
  if (!e.coverage) return { status: 'insufficient_data', percentages: null, winner: null };
  const definition = MODES[mode], [first, second] = definition.labels;
  const selectedScore = scoreForMode(e, mode), p = percent(selectedScore);
  return { status: p === 50 ? 'balanced' : 'ready', winner: p === 50 ? null : p > 50 ? first : second,
    percentages: { [first]: p, [second]: 100 - p }, dataCoverage: round(e.coverage),
    modeScore: round(selectedScore), modeBasis: definition.basis,
    meaning: 'symbolic_alignment_not_success_probability' };
}
export function weightedTimeAverage(items) {
  const seconds = items.reduce((s, x) => s + x.duration, 0);
  if (!seconds || items.some(x => !Number.isFinite(x.duration) || x.duration <= 0)) throw new Error('INVALID_SEGMENTS');
  // Values here have already had module coverage applied.
  return evidence(...['a', 'c', 'coverage'].map(k => items.reduce((s, x) => s + x.duration * x.evidence[k], 0) / seconds));
}
export function moduleResult(e, diagnostics = {}, status) {
  return { status: status ?? (e.coverage === 0 ? 'unavailable' : e.coverage < .999999 ? 'partial' : 'calculated'), evidence: e, diagnostics };
}
export function boundedCache(max = 256) {
  const map = new Map();
  return { get: key => map.get(key), set(key, value) { if (map.size >= max && !map.has(key)) map.delete(map.keys().next().value); map.set(key, value); return value; } };
}
