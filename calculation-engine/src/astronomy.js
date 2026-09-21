import * as Astronomy from 'astronomy-engine';
import { clamp, evidence, moduleResult, mod, boundedCache } from './core.js';
import { HOUR } from './time.js';

const BODIES = { sun:'Sun', moon:'Moon', mercury:'Mercury', venus:'Venus', mars:'Mars', jupiter:'Jupiter', saturn:'Saturn' };
const TRANSIT = {moon:.35,sun:.15,mercury:.1,venus:.1,mars:.1,jupiter:.1,saturn:.1};
const NATAL = {sun:.3,moon:.3,mercury:.1,venus:.1,mars:.1,jupiter:.05,saturn:.05};
const CONJ = {moon:0,sun:.1,mercury:.2,venus:-.1,mars:.4,jupiter:.3,saturn:-.4};
const ASPECTS = {60:[.5,.2],90:[-.5,.3],120:[.6,-.3],180:[-.6,.3]};
const skyCache = boundedCache(512);
const signedAngle = x => mod(x+180,360)-180;
export function longitude(body, ms) {
  // EclipticLongitude() in the provider is HELIOCENTRIC. We need geocentric ECT.
  return Astronomy.Ecliptic(Astronomy.GeoVector(BODIES[body] ?? body, new Date(ms), true)).elon;
}
export function skyAt(ms) {
  if (skyCache.get(ms)) return skyCache.get(ms);
  const positions = Object.fromEntries(Object.keys(BODIES).map(b => [b, longitude(b,ms)]));
  const mercurySpeed = signedAngle(longitude('mercury',ms+HOUR)-longitude('mercury',ms-HOUR))*12;
  return skyCache.set(ms, { positions, mercurySpeed, evaluatedAtUtc: new Date(ms).toISOString() });
}
export function natalSky(birth) {
  if (!birth.intervals.length) return { positions: {}, ranges: {}, status: birth.status, method: 'no_birth_instant_available' };
  const points = new Set();
  for (const {start,end} of birth.intervals) {
    points.add(start); points.add(end);
    for (let t=start+3*HOUR;t<end;t+=3*HOUR) points.add(t);
  }
  const sorted = [...points].sort((a,b)=>a-b), positions = {}, ranges = {};
  for (const body of Object.keys(BODIES)) {
    const values = sorted.map(t=>longitude(body,t)), base = values[0];
    const delta = values.map(v=>signedAngle(v-base));
    const lo = Math.min(...delta), hi = Math.max(...delta), span = hi-lo;
    // 0.02 deg guard for interpolation between 3h samples; a model tolerance,
    // not a prediction confidence. Unknown-time Moon is normally excluded.
    const stable = birth.exact || span + .02 <= .5;
    ranges[body] = { minLongitude:mod(base+lo,360), maxLongitude:mod(base+hi,360), spanDegrees:span, stable };
    if (stable) positions[body] = mod(base+(lo+hi)/2,360);
  }
  return { positions, ranges, status:birth.exact?'exact':'stable_features_only', sampleCount:sorted.length,
    method:birth.exact?'birth_utc':'uncertain_birth_interval_sampled_3h', maxAcceptedSpanDegrees:.5 };
}
export function aspect(transit, natal, body) {
  const distance = Math.abs(signedAngle(transit-natal));
  const angles=[0,60,90,120,180];
  const angle=angles.reduce((a,b)=>Math.abs(distance-b)<Math.abs(distance-a)?b:a);
  const strength=Math.max(0,1-Math.abs(distance-angle)/3), v=angle===0?[0,CONJ[body]]:ASPECTS[angle];
  return { angle,strength,a:strength*v[0],c:strength*v[1] };
}
export function western(sky,natal) {
  let a=0,c=0,q=0; const aspects=[];
  for (const [p,pw] of Object.entries(TRANSIT)) for (const [n,nw] of Object.entries(NATAL)) {
    if (natal.positions[n]==null) continue;
    const w=pw*nw, hit=aspect(sky.positions[p],natal.positions[n],p);
    q+=w; a+=w*hit.a; c+=w*hit.c;
    if(hit.strength>0) aspects.push({transit:p,natal:n,angle:hit.angle,strength:hit.strength});
  }
  return moduleResult(q?evidence(clamp(3*a/q),clamp(3*c/q),Math.min(1,q)):evidence(), {aspects,natal,houseSystem:null});
}
export function cosmic(sky) {
  const phi=mod(sky.positions.moon-sky.positions.sun,360), rad=phi*Math.PI/180, motion=clamp(sky.mercurySpeed/.10);
  return moduleResult(evidence(.8*.35*Math.sin(rad)+.2*.15*motion,.8*.25*Math.cos(rad)+.2*.10*motion,1),
    {elongationDegrees:phi,illuminationApprox:(1-Math.cos(rad))/2,mercurySpeed:sky.mercurySpeed,
      mercuryMotion:Math.abs(sky.mercurySpeed)<=.01?'stationary':sky.mercurySpeed<0?'retrograde':'direct'});
}
