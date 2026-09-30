/** The seven questions a reader can ask. */
export type Mode = 'yes_no' | 'act_wait' | 'advance_retreat' | 'stay_go' | 'keep_let_go' | 'commit_withdraw' | 'left_right';

/**
 * Modes retired by an earlier ruleset that a saved reading may still carry.
 *
 * `forward_backward` was replaced by `commit_withdraw` in ruleset v9.1. They
 * ask different questions and are scored from different signals, so an old
 * reading is never relabelled: `calculate` rejects this value with
 * `LEGACY_DECISION_MODE:forward_backward`, and a client parses it only to
 * render history.
 */
export type LegacyMode = 'forward_backward';

/** The nine v9.1 signals. See `src/scoring.js` for what each one measures. */
export type Signal = 'P' | 'C' | 'L' | 'T' | 'M' | 'R' | 'G' | 'H' | 'Y';
export type Period = 'now' | 'morning' | 'midday' | 'afternoon' | 'evening';
export type Category = 'general' | 'love' | 'career' | 'money' | 'study' | 'friends' | 'other';
export type ModuleId = 'B' | 'Z' | 'T' | 'W' | 'N' | 'U';
export interface Profile {
  birthDate: string;
  birthTime?: string | null;
  birthCountry?: string | null;
  /** Optional exact birth IANA zone; never supplied from current location implicitly. */
  birthTimezone?: string | null;
  traditionalProfile?: 'male' | 'female' | 'male_convention' | 'female_convention' | 'unspecified' | null;
  revision?: number;
}
export interface CurrentContext {
  instantUtc: string;
  deviceTimezone: string;
  location?: {latitude:number; longitude:number; accuracyMeters:number; capturedAtUtc:string} | null;
}
export interface ReadingInput {
  profile: Profile;
  context: CurrentContext;
  period?: Period;
  mode?: Mode;
  category?: Category;
  diagnostics?: boolean;
  /**
   * Calibration and simulation scripts only: report every signal, not just the
   * ones this mode mixes. It cannot change the result.
   */
  probeAllSignals?: boolean;
}

/**
 * How the reported percentage was arrived at.
 *
 * `signals` are the raw values this mode reads; `normalized` is each of them
 * through `tanh(raw / scale)` against the fixed, versioned scales. Mixing
 * `normalized` by the mode's own weights and dividing by that mixture's
 * `sqrt(sum of w squared)` reproduces `rawModeScore`, and pushing that away
 * from `priorMedian` reproduces `adjustedModeScore`, which is what `modeScore`
 * and `percentages` are built from.
 *
 * A percentage is symbolic alignment. It is not a probability of success.
 */
export interface Scoring {
  system: string;
  scaleVersion: string;
  /** The local date and wall clock every other date in this reading was read at. */
  anchorLocal: string;
  signals: Partial<Record<Signal, number>>;
  normalized: Partial<Record<Signal, number>>;
  rawModeScore: number;
  /** How many of the previous fourteen local dates had a usable anchor. */
  priorDatesUsed: number;
  priorMedian: number | null;
  adjustedModeScore: number;
  meaning: 'symbolic_alignment_not_success_probability';
}
export interface ModuleResult {
  status:'calculated' | 'partial' | 'unavailable' | 'scenario_analysis';
  coverage:number;
  a:number;
  c:number;
  contribution:{a:number;c:number};
  diagnostics?: Record<string,unknown>;
}
export interface LuckyWindow {
  startUtc:string; endUtc:string; startLocal:string; endLocal:string;
  score:number; dataCoverage:number; hourBranch:number;
  meaning:'symbolic_timing_score_not_probability';
}
export interface ResolvedContext {
  instantMs:number; instantUtc:string; timezone:string; zoneSource:'device' | 'location';
  offsetSeconds:number; localDate:string; region:string; countryCandidates:string[];
  locationStatus:string; locationZoneCandidates:string[]; tzdbVersion:string;
}
/** One of the twenty palette entries, with the stem and element it came from. */
export interface DailyColor {
  key:string; name:string; hex:string;
  element:'wood'|'fire'|'earth'|'metal'|'water'; stem:number;
}

/**
 * Two colours for the local civil day. `lead` comes from the day stem's own
 * pair; `supporting` from the family that element generates, so the two are
 * always different families. Editorial symbolism, not Yong Shen.
 */
export interface DailyColors {
  lead:DailyColor; supporting:DailyColor;
  meaning:'symbolic_colour_pairing_not_yong_shen';
}

export interface ReadingResult {
  engineVersion:string; rulesetVersion:string; providers:Record<string,string>;
  status:'ready' | 'balanced' | 'insufficient_data' | 'period_elapsed';
  percentages:Record<string,number> | null; winner:string | null;
  dataCoverage?:number; readingKey?:string;
  axisScores?:{action:number;change:number;selected:number};
  modeScore?:number;
  modeBasis?:'overall_acceptance' | 'action_timing' | 'tactical_momentum' | 'change_alignment' | 'release_alignment' | 'durability_horizon' | 'symbolic_polarity' | 'temporal_momentum';
  scoring?:Scoring;
  period:Period; mode:Mode | LegacyMode; category:Category; context:ResolvedContext;
  birthData:{status:string;timeKnown:boolean;timezoneSource:string;timezoneCandidates:string[]};
  warnings:string[]; inputSnapshot:Record<string,unknown>;
  evaluatedAtUtc?:string; luckyWindows:LuckyWindow[];
  windowStatus?:'not_applicable' | 'two_available' | 'one_remaining' | 'no_15_minute_window';
  /** One decimal, as tenths of a percent: the two sides always sum to 100.0. */
  percentagesArePercentNotProbability?:true;
  dailyBrief?:{luckyNumber:number;colors:DailyColors;energy:{
    level:'quiet'|'soft'|'steady'|'lively'|'bright'|'radiant'|'focused'|'flowing'|'unavailable';index:number|null;dataCoverage:number;
  }};
  segments?:Array<{startUtc:string;endUtc:string;includedFromUtc:string;durationSeconds:number;modules:Record<ModuleId,ModuleResult>}>;
  consumeUnlock?:false; monetizationHandledByApp?:true;
}
export function calculate(input:ReadingInput):ReadingResult;
export function createCalculator(profile:Profile):{
  calculate(input:Omit<ReadingInput,'profile'>):ReadingResult;
  inspectBirthCharts():Record<string,unknown>;
};
export function resolveCurrentContext(context:CurrentContext):ResolvedContext;
export const VERSION:string;
export const RULESET:string;
export const PROVIDERS:Readonly<Record<string,string>>;
export const CATEGORIES:ReadonlyArray<Category>;
export const SCORING_VERSION:string;
export const SCALE_VERSION:string;
export const MODES:Readonly<Record<Mode,{labels:[string,string];basis:string}>>;
export const LEGACY_MODES:Readonly<Record<LegacyMode,{labels:[string,string];basis:string;replacedBy:Mode}>>;
