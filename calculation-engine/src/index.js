import { createHash } from 'node:crypto';
import { VERSION, RULESET, WEIGHTS, MODES, combine, decision, percent, scoreForMode, weightedTimeAverage, round, boundedCache } from './core.js';
import { birthContext, segmentsForDay, periodSegments, localAt, parseBirthDate, parseBirthTime } from './time.js';
import { resolveCurrentContext } from './location.js';
import { calendarAt, nearbyBoundaries } from './calendar.js';
import { numerology } from './numerology.js';
import { buildBaZi, scoreBaZi } from './bazi.js';
import { buildZiWei, scoreZiWei, inspectZiWei } from './ziwei.js';
import { natalSky, skyAt, western, cosmic } from './astronomy.js';
import { almanac } from './calendar.js';

export { resolveCurrentContext, VERSION, RULESET };
export const PROVIDERS=Object.freeze({lunarJavascript:'1.7.7',iztro:'2.6.1',astronomyEngine:'2.1.19',geoTz:'8.1.9',momentTimezone:'0.6.4'});
const COLORS=['sage','coral','sand','pearl','ocean_blue'];
function normalizeProfile(p) {
  if(!p||typeof p!=='object')throw new Error('PROFILE_REQUIRED');
  const birthDate=parseBirthDate(p.birthDate),birthTime=parseBirthTime(p.birthTime);
  const conventions={male:'male',female:'female',male_convention:'male',female_convention:'female',unspecified:null};
  if(p.traditionalProfile!=null&&!Object.hasOwn(conventions,p.traditionalProfile))throw new Error('INVALID_TRADITIONAL_PROFILE');
  if(p.birthCountry!=null&&typeof p.birthCountry!=='string')throw new Error('INVALID_BIRTH_COUNTRY');
  if(p.revision!=null&&(!Number.isSafeInteger(p.revision)||p.revision<1))throw new Error('INVALID_PROFILE_REVISION');
  return {birthDate,birthTime,birthCountry:p.birthCountry?.toUpperCase()??null,birthTimezone:p.birthTimezone??null,
    traditionalProfile:conventions[p.traditionalProfile]??null,revision:p.revision??1};
}
function hash(value){return createHash('sha256').update(JSON.stringify(value)).digest('hex');}
function moduleSummary(modules,diagnostics) {
  return Object.fromEntries(Object.entries(modules).map(([name,m])=>[name,{
    status:m.status,coverage:round(m.evidence.coverage),a:round(m.evidence.a),c:round(m.evidence.c),
    contribution:{a:round(WEIGHTS[name]*m.evidence.coverage*m.evidence.a),c:round(WEIGHTS[name]*m.evidence.coverage*m.evidence.c)},
    ...(diagnostics?{diagnostics:m.diagnostics}:{})
  }]));
}
/** Compile birth-dependent data once per profile. All subsequent readings run offline. */
export function createCalculator(inputProfile) {
  const profile=normalizeProfile(inputProfile),birth=birthContext(profile);
  const baZi=buildBaZi(birth,profile.traditionalProfile),ziWei=buildZiWei(birth,profile.traditionalProfile),natal=natalSky(birth);
  const cache=boundedCache(256);
  function evaluate(ms,zone) {
    const key=`${ms}|${zone}`;
    if(cache.get(key))return cache.get(key);
    const calendar=calendarAt(ms,zone),sky=skyAt(ms);
    const modules={B:scoreBaZi(baZi,calendar,ms),Z:scoreZiWei(ziWei,calendar),T:almanac(calendar),
      W:western(sky,natal),N:numerology(profile.birthDate,calendar.local.date),U:cosmic(sky)};
    const fusion=combine(modules);
    return cache.set(key,{calendar,modules,evidence:fusion});
  }
  function calculateInternal(input) {
    const period=input.period??'now',mode=input.mode??'yes_no';
    if(!Object.hasOwn(MODES,mode))throw new Error('INVALID_DECISION_MODE');
    if(input.category!=null&&input.category!=='general')throw new Error('MVP_CATEGORY_IS_GENERAL');
    if(input.space!=null)throw new Error('SPATIAL_FENG_SHUI_OUT_OF_SCOPE');
    const context=resolveCurrentContext(input.context??{}),now=context.instantMs,zone=context.timezone;
    if(profile.birthDate>context.localDate)throw new Error('BIRTH_DATE_IN_FUTURE');
    if(birth.exact&&birth.intervals[0].start>now)throw new Error('BIRTH_INSTANT_IN_FUTURE');
    // Luck-cycle boundaries can occur inside an earthly-branch hour.
    const extra=nearbyBoundaries(now);
    if(baZi.decade) {
      for(const t of decadeBoundaries(baZi))if(Math.abs(t-now)<3*86400000)extra.push(t);
    }
    const segments=segmentsForDay(now,zone,extra),selected=periodSegments(segments,now,period);
    const warnings=[];
    if(birth.status!=='exact')warnings.push(birth.status);
    if(!profile.birthTime)warnings.push('unknown_birth_time');
    if(!profile.traditionalProfile)warnings.push('unspecified_traditional_convention');
    if(context.locationStatus==='ambiguous_zone')warnings.push('location_timezone_ambiguous_using_device');
    const base={engineVersion:VERSION,rulesetVersion:RULESET,providers:{...PROVIDERS,tzdb:context.tzdbVersion},
      mode,period,category:'general',context,birthData:{status:birth.status,timeKnown:!!birth.clock,
        timezoneSource:birth.zoneSource,timezoneCandidates:birth.zones},warnings,
      inputSnapshot:{profile,context:{instantUtc:context.instantUtc,timezone:zone,zoneSource:context.zoneSource},period,mode}};
    if(!selected.length)return {...base,status:'period_elapsed',winner:null,percentages:null,luckyWindows:[],consumeUnlock:false};
    const evaluated=selected.map(s=>({...s,value:evaluate(s.start,zone)}));
    const duration=s=>(s.end-(s.candidateStart??s.start))/1000;
    const e=period==='now'?evaluated[0].value.evidence:weightedTimeAverage(evaluated.map(s=>({duration:duration(s),evidence:s.value.evidence})));
    const windows=period==='now'?[]:evaluated.filter(s=>duration(s)>=900).map(s=>({
      startUtc:new Date(s.candidateStart??s.start).toISOString(),endUtc:new Date(s.end).toISOString(),
      startLocal:localAt(s.candidateStart??s.start,zone).iso,endLocal:localAt(s.end,zone).iso,
      score:percent(scoreForMode(s.value.evidence,mode)),dataCoverage:round(s.value.evidence.coverage),hourBranch:s.hourBranch,
      meaning:'symbolic_timing_score_not_probability',
    })).sort((a,b)=>b.score-a.score||a.startUtc.localeCompare(b.startUtc)).slice(0,2);
    const first=evaluated[0].value,briefNumber=first.modules.N.diagnostics.personalDay;
    const readingKey=hash({profile,rules:RULESET,providers:base.providers,zone,period,
      segments:evaluated.map(s=>[s.start,s.end,period==='now'?null:s.candidateStart])});
    return {...base,...decision(e,mode),readingKey,axisScores:{action:round(e.a),change:round(e.c),selected:round(scoreForMode(e,mode))},
      evaluatedAtUtc:new Date(evaluated[0].start).toISOString(),luckyWindows:windows,
      windowStatus:period==='now'?'not_applicable':windows.length===2?'two_available':windows.length===1?'one_remaining':'no_15_minute_window',
      dailyBrief:{luckyNumber:briefNumber,colorInspiration:COLORS[Math.floor(first.calendar.day.stem/2)]},
      segments:evaluated.map(s=>({startUtc:new Date(s.start).toISOString(),endUtc:new Date(s.end).toISOString(),
        includedFromUtc:new Date(s.candidateStart??s.start).toISOString(),durationSeconds:duration(s),
        modules:moduleSummary(s.value.modules,!!input.diagnostics)})),
      monetizationHandledByApp:true};
  }
  return {calculate:input=>structuredClone(calculateInternal(input)),
    inspectBirthCharts:()=>structuredClone({profile,birth,baZi,ziWei:inspectZiWei(ziWei),western:natal})};
}
import { addCivil } from './time.js';
function decadeBoundaries(chart) {
  if(!chart.decade)return [];
  const d=chart.decade;return Array.from({length:20},(_,i)=>addCivil(d.startUtc,d.birthZone,i*10));
}
export function calculate(input) {
  return createCalculator(input.profile).calculate(input);
}
