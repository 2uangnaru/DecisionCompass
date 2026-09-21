import { find } from 'geo-tz/all';
import moment from 'moment-timezone';
import { parseInstant, validZone, localAt, TZDB_VERSION } from './time.js';

// Mobile shell owns permissions. No network, background tracking or OS prompt here.
export function resolveCurrentContext(context) {
  const ms = parseInstant(context.instantUtc);
  const deviceZone = context.deviceTimezone;
  let zone = validZone(deviceZone) ? deviceZone : null;
  let source = 'device', locationStatus = 'not_provided', candidates = [];
  const fix = context.location;
  if (fix) {
    const coordsValid = Number.isFinite(fix.latitude) && Math.abs(fix.latitude) <= 90 && Number.isFinite(fix.longitude) && Math.abs(fix.longitude) <= 180;
    const accuracyValid = Number.isFinite(fix.accuracyMeters) && fix.accuracyMeters >= 0 && fix.accuracyMeters <= 25000;
    let timestamp = NaN;
    try { timestamp = parseInstant(fix.capturedAtUtc); } catch { /* invalid fix falls back */ }
    if (!coordsValid || !accuracyValid || !Number.isFinite(timestamp)) locationStatus = 'invalid_fix';
    else if (timestamp > ms + 60000 || ms - timestamp > 15 * 60000) locationStatus = 'stale_fix';
    else {
      // Border check is a conservative sampling heuristic, not a geometric proof.
      // At least a 1 km buffer is checked even for a nominally precise fix.
      const zones = new Set(find(fix.latitude, fix.longitude));
      const radius = Math.max(1000, fix.accuracyMeters) / 6371008.8;
      const lat = fix.latitude * Math.PI / 180, lon = fix.longitude * Math.PI / 180;
      for (let i = 0; i < 16; i++) {
        const bearing = i * 2 * Math.PI / 16;
        const lat2 = Math.asin(Math.sin(lat) * Math.cos(radius) + Math.cos(lat) * Math.sin(radius) * Math.cos(bearing));
        const lon2 = lon + Math.atan2(Math.sin(bearing) * Math.sin(radius) * Math.cos(lat), Math.cos(radius) - Math.sin(lat) * Math.sin(lat2));
        const longitude = ((lon2 * 180 / Math.PI + 540) % 360) - 180;
        for (const id of find(lat2 * 180 / Math.PI, longitude)) zones.add(id);
      }
      candidates = [...zones].sort();
      if (candidates.length === 1 && validZone(candidates[0])) { zone = candidates[0]; source = 'location'; locationStatus = 'resolved'; }
      else locationStatus = 'ambiguous_zone';
    }
  }
  if (!zone) throw new Error('CURRENT_TIMEZONE_UNAVAILABLE');
  const countries = moment.tz.countries().filter(c => moment.tz.zonesForCountry(c)?.includes(zone));
  return { instantMs: ms, instantUtc: new Date(ms).toISOString(), timezone: zone, zoneSource: source,
    offsetSeconds: localAt(ms, zone).offsetSeconds, localDate: localAt(ms, zone).date,
    region: zone.split('/')[0], countryCandidates: countries, locationStatus,
    locationZoneCandidates: candidates, tzdbVersion: TZDB_VERSION };
}
