// Dumps whole readings for the awkward cases, straight out of the Node engine.
//
// These are the scenarios where an engine is easiest to get quietly wrong: a
// DST fold and a DST gap, a date-line timezone, an unknown birth hour, a birth
// country with several candidate zones, an elapsed period, and periods that
// leave two, one or zero fifteen-minute windows.
//
// The Dart port must reproduce each one exactly, so the expectations are engine
// output rather than anybody's idea of the right answer.

import { emitFixture } from './lib.mjs';
import { calculate } from '../../src/index.js';

const PROFILE_KNOWN = {
  birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN',
  traditionalProfile: 'male', revision: 1,
};
const PROFILE_UNKNOWN_HOUR = {
  birthDate: '1998-06-21', birthTime: null, birthCountry: 'VN',
  traditionalProfile: 'unspecified', revision: 1,
};
const PROFILE_FOLD = {
  birthDate: '1974-11-03', birthTime: '01:30', birthCountry: 'US',
  traditionalProfile: 'female', revision: 1,
};
const PROFILE_GAP = {
  // 01:30 on this date never happened in the UK: the clocks jumped from 01:00
  // to 02:00. The engine must report `birth_time_nonexistent` rather than
  // sliding the birth an hour to make it exist.
  birthDate: '1999-03-28', birthTime: '01:30', birthCountry: 'GB',
  traditionalProfile: 'male', revision: 1,
};
const PROFILE_GAP_PARTIAL = {
  // 02:15 exists in some Australian zones on this date and not in others.
  birthDate: '2015-10-04', birthTime: '02:15', birthCountry: 'AU',
  traditionalProfile: 'male', revision: 1,
};
const PROFILE_DATELINE = {
  birthDate: '2011-12-30', birthTime: '12:00', birthCountry: 'WS',
  traditionalProfile: 'female', revision: 1,
};

const SCENARIOS = [
  { name: 'dst_fold_birth', profile: PROFILE_FOLD,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'America/New_York' },
    period: 'now', mode: 'yes_no', category: 'general' },
  { name: 'dst_fold_reading_day', profile: PROFILE_KNOWN,
    context: { instantUtc: '2026-11-01T04:30:00Z', deviceTimezone: 'America/New_York' },
    period: 'morning', mode: 'act_wait', category: 'general' },
  { name: 'dst_gap_reading_day', profile: PROFILE_KNOWN,
    context: { instantUtc: '2026-03-08T06:30:00Z', deviceTimezone: 'America/New_York' },
    period: 'morning', mode: 'advance_retreat', category: 'career' },
  { name: 'dst_gap_birth_nonexistent', profile: PROFILE_GAP,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Europe/London' },
    period: 'now', mode: 'yes_no', category: 'general' },
  { name: 'dst_gap_birth_partial_zones', profile: PROFILE_GAP_PARTIAL,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Australia/Lord_Howe' },
    period: 'now', mode: 'yes_no', category: 'general' },
  { name: 'date_line_reading', profile: PROFILE_DATELINE,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Pacific/Kiritimati' },
    period: 'evening', mode: 'stay_go', category: 'general' },
  { name: 'unknown_birth_hour', profile: PROFILE_UNKNOWN_HOUR,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
    period: 'now', mode: 'keep_let_go', category: 'love' },
  { name: 'quarter_hour_zone', profile: PROFILE_KNOWN,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Kathmandu' },
    period: 'afternoon', mode: 'left_right', category: 'money' },
  { name: 'period_elapsed_morning', profile: PROFILE_KNOWN,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
    period: 'morning', mode: 'yes_no', category: 'general' },
  { name: 'two_windows_evening', profile: PROFILE_KNOWN,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
    period: 'evening', mode: 'forward_backward', category: 'study' },
  { name: 'one_window_evening_late', profile: PROFILE_KNOWN,
    context: { instantUtc: '2026-09-18T15:50:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
    period: 'evening', mode: 'keep_let_go', category: 'friends' },
  { name: 'no_window_evening_latest', profile: PROFILE_KNOWN,
    context: { instantUtc: '2026-09-18T16:52:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
    period: 'evening', mode: 'keep_let_go', category: 'other' },
  { name: 'explicit_birth_timezone', profile: {
      birthDate: '1998-06-21', birthTime: '14:30', birthTimezone: 'Asia/Ho_Chi_Minh',
      traditionalProfile: 'male', revision: 1 },
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
    period: 'now', mode: 'yes_no', category: 'general' },
  { name: 'unresolved_birth_timezone', profile: {
      birthDate: '1998-06-21', birthTime: '14:30', traditionalProfile: 'male', revision: 1 },
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' },
    period: 'now', mode: 'yes_no', category: 'general' },
  { name: 'invalid_location_fix', profile: PROFILE_KNOWN,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh',
      location: { latitude: 200, longitude: 2, accuracyMeters: 10,
        capturedAtUtc: '2026-09-18T08:29:00Z' } },
    period: 'now', mode: 'yes_no', category: 'general' },
  { name: 'stale_location_fix', profile: PROFILE_KNOWN,
    context: { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh',
      location: { latitude: 10.77, longitude: 106.7, accuracyMeters: 40,
        capturedAtUtc: '2026-09-18T08:00:00Z' } },
    period: 'now', mode: 'yes_no', category: 'general' },
];

const readings = SCENARIOS.map((scenario) => ({
  ...scenario,
  result: calculate({
    profile: scenario.profile,
    context: scenario.context,
    period: scenario.period,
    mode: scenario.mode,
    category: scenario.category,
  }),
}));

const target = emitFixture('edge_readings.json', JSON.stringify({ readings }, null, 2));
process.stdout.write(`edge readings: ${readings.length} scenarios -> ${target}\n`);
