import { createHash } from 'node:crypto';
import { dailyColors } from './colors.js';
import { VERSION, RULESET, WEIGHTS, LUCK_BASELINE, CATEGORIES, MODES, LEGACY_MODES, requireCurrentMode, combine, decision, weightedTimeAverage, round, weightsFor, boundedCache, clamp, evidence } from './core.js';
import { SCORING_VERSION, SCALE_VERSION, SCALES, SIGNALS, MODE_SIGNALS, signalsNeededBy, momentSignals, timing, momentum, grounding, horizon, median, normalizeAll, modeScore, adjustAgainstHistory, displayTenths, displayPercent } from './scoring.js';
import { birthContext, segmentsForDay, periodSegments, localAt, localCandidates, civilDateShift, parseBirthDate, parseBirthTime, PERIODS, periodBoundaryHours } from './time.js';
import { resolveCurrentContext } from './location.js';
import { calendarAt, nearbyBoundaries } from './calendar.js';
import { numerology } from './numerology.js';
import { buildBaZi, scoreBaZi } from './bazi.js';
import { buildZiWei, scoreZiWei, inspectZiWei } from './ziwei.js';
import { natalSky, skyAt, western, cosmic } from './astronomy.js';
import { almanac } from './calendar.js';
import { dailyEnergy } from './daily-energy.js';
import { scoreVedic } from './vedic.js';

export { resolveCurrentContext, VERSION, RULESET, CATEGORIES, MODES, LEGACY_MODES, SCORING_VERSION, SCALE_VERSION };
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
function moduleSummary(modules,diagnostics,category) {
  const weights=weightsFor(category);
  return Object.fromEntries(Object.entries(modules).map(([name,m])=>[name,{
    status:m.status,coverage:round(m.evidence.coverage),a:round(m.evidence.a),c:round(m.evidence.c),
    weight:round(weights[name]),
    contribution:{a:round(weights[name]*m.evidence.coverage*m.evidence.a),c:round(weights[name]*m.evidence.coverage*m.evidence.c)},
    ...(diagnostics?{diagnostics:m.diagnostics}:{})
  }]));
}
/** Compile birth-dependent data once per profile. All subsequent readings run offline. */
export function createCalculator(inputProfile) {
  const profile=normalizeProfile(inputProfile),birth=birthContext(profile);
  const baZi=buildBaZi(birth,profile.traditionalProfile),ziWei=buildZiWei(birth,profile.traditionalProfile),natal=natalSky(birth);
  // Sized for a v9.1 reading: the selected segments, the whole local day for
  // the brief, and every cross-day anchor the chosen mode reaches for.
  const cache=boundedCache(512),signalCache=boundedCache(512),scoreCache=boundedCache(256);
  const UNAVAILABLE=Object.freeze({unavailable:true});
  function evaluate(ms,zone,category) {
    // Category changes Zi Wei targets, Western body emphasis and fusion
    // weights, so it must be part of the cache identity.
    const key=`${ms}|${zone}|${category}`;
    if(cache.get(key))return cache.get(key);
    const calendar=calendarAt(ms,zone),sky=skyAt(ms);
    const modules={B:scoreBaZi(baZi,calendar,ms),Z:scoreZiWei(ziWei,calendar,category),T:almanac(calendar),
      W:western(sky,natal,category),V:scoreVedic(ms,birth,natal),N:numerology(profile.birthDate,calendar.local.date),U:cosmic(sky)};
    const raw=combine(modules,category);
    const a = raw.coverage > 0 ? clamp(raw.a - LUCK_BASELINE * raw.coverage) : 0;
    const c = raw.coverage > 0 ? clamp(raw.c - LUCK_BASELINE * raw.coverage) : 0;
    const fusion = evidence(a, c, raw.coverage);
    return cache.set(key,{calendar,modules,evidence:fusion});
  }
  function moments(ms,zone,category) {
    const key=`${ms}|${zone}|${category}`;
    const hit=signalCache.get(key);
    if(hit)return hit;
    const {calendar,modules}=evaluate(ms,zone,category);
    return signalCache.set(key,momentSignals(modules,weightsFor(category),calendar));
  }
  // An anchor is one local wall-clock time on one local civil date. A date
  // where that wall time does not exist — the hour a spring-forward skips —
  // has no anchor, and every caller drops it rather than sliding to a
  // neighbouring hour and pretending it was the same time of day.
  function anchorAt(date,clock,zone) {
    const candidates=localCandidates(date,clock,zone);
    return candidates.length?candidates[0]:null;
  }
  // A later window is read at the first hour of its period that exists on
  // that date, so a transition inside the period still leaves it comparable.
  function periodAnchor(date,period,zone) {
    const [lo,hi]=PERIODS[period];
    for(let h=lo;h<hi;h++) {
      const ms=anchorAt(date,`${String(h).padStart(2,'0')}:00`,zone);
      if(ms!=null)return ms;
    }
    return null;
  }
  /**
   * Every moment later than [anchorHour] on [date] that the timing signal is
   * compared against.
   *
   * Two groups, in order: the rest of the selected period hour by hour, then
   * the periods that have not started yet. Without the first group an evening
   * reading had nothing later to compare against at all — no period starts
   * after 18:00 — so every evening slot scored a timing of exactly zero.
   *
   * NOW contributes no first group: it is a single instant rather than a span,
   * so it is compared only against the periods still ahead of it.
   */
  function laterAlignments(date,anchorHour,period,zone,category) {
    const later=[];
    if(period!=='now') {
      for(const h of periodBoundaryHours(period)) {
        if(h<=anchorHour)continue;
        const ms=anchorAt(date,`${String(h).padStart(2,'0')}:00`,zone);
        if(ms!=null)later.push(moments(ms,zone,category).q);
      }
    }
    for(const other of Object.keys(PERIODS)) {
      if(PERIODS[other][0]<=anchorHour)continue;
      const ms=periodAnchor(date,other,zone);
      if(ms!=null)later.push(moments(ms,zone,category).q);
    }
    return later;
  }
  function rawSignals(date,clock,period,zone,category,needed,base) {
    const raw={};
    for(const name of needed) {
      if(name==='P')raw.P=base.p;
      else if(name==='C')raw.C=base.c;
      else if(name==='L')raw.L=base.l;
      else if(name==='R')raw.R=base.r;
      else if(name==='Y')raw.Y=base.y;
      else if(name==='T') {
        raw.T=timing(base.q,laterAlignments(date,Number(clock.slice(0,2)),period,zone,category));
      }
      else if(name==='M') {
        const priors=[];
        for(let k=1;k<=3;k++) {
          const ms=anchorAt(civilDateShift(date,-k),clock,zone);
          if(ms!=null)priors.push(moments(ms,zone,category).c);
        }
        raw.M=momentum(base.c,priors);
      }
      else if(name==='G') {
        const ms=anchorAt(civilDateShift(date,7),clock,zone);
        raw.G=grounding(base.p,base.c,ms==null?null:moments(ms,zone,category).p);
      }
      else if(name==='H') {
        const series=[base];
        for(let k=1;k<=7;k++) {
          const ms=anchorAt(civilDateShift(date,k),clock,zone);
          if(ms!=null)series.push(moments(ms,zone,category));
        }
        raw.H=horizon(series);
      }
    }
    return raw;
  }
  /**
   * One date's unadjusted mode score, or null when that date has no anchor.
   *
   * The requested signal set is part of the cache identity. Without it, a
   * reading taken after a `probeAllSignals` call on the same calculator would
   * be handed the probe's nine signals, and a probe taken after a normal
   * reading would be handed only the three that mode mixes. The selected
   * period is part of the identity too, because the timing signal compares
   * against the rest of that period.
   */
  function rawScoreOn(date,clock,period,zone,category,mode,needed) {
    const key=`${date}|${clock}|${period}|${zone}|${category}|${mode}|${needed.join('')}`;
    const hit=scoreCache.get(key);
    if(hit)return hit===UNAVAILABLE?null:hit;
    const ms=anchorAt(date,clock,zone);
    if(ms==null) { scoreCache.set(key,UNAVAILABLE); return null; }
    const base=moments(ms,zone,category);
    const raw=rawSignals(date,clock,period,zone,category,needed,base);
    const normalized=normalizeAll(raw);
    return scoreCache.set(key,{raw,normalized,score:modeScore(mode,normalized),base});
  }
  function calculateInternal(input) {
    const period=input.period??'now',mode=input.mode??'yes_no';
    const category=input.category??'general';
    // A retired mode fails with its own code: the caller is asking for a
    // question this ruleset no longer scores, not passing a typo.
    requireCurrentMode(mode);
    if(!CATEGORIES.includes(category))throw new Error('INVALID_CATEGORY');
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
      mode,period,category,context,birthData:{status:birth.status,timeKnown:!!birth.clock,
        timezoneSource:birth.zoneSource,timezoneCandidates:birth.zones},warnings,
      inputSnapshot:{profile,context:{instantUtc:context.instantUtc,timezone:zone,zoneSource:context.zoneSource},period,mode,category}};
    if(!selected.length)return {...base,status:'period_elapsed',winner:null,percentages:null,luckyWindows:[],consumeUnlock:false};
    const evaluated=selected.map(s=>({...s,value:evaluate(s.start,zone,category)}));
    const duration=s=>(s.end-(s.candidateStart??s.start))/1000;
    // The fused pair no longer decides anything. It still describes the
    // window the reader picked — coverage, the two axes, the daily brief —
    // so it is calculated exactly as before and reported unchanged.
    const e=period==='now'?evaluated[0].value.evidence:weightedTimeAverage(evaluated.map(s=>({duration:duration(s),evidence:s.value.evidence})));

    // The anchor: one wall-clock time on one local date, the instant whose
    // modules the mode is scored from. Every other date this reading reads —
    // the previous fortnight, the three days behind it, the week ahead — is
    // that same wall time on that date.
    const anchorMs=evaluated[0].start,anchorLocal=localAt(anchorMs,zone);
    const anchorDate=anchorLocal.date;
    const anchorClock=`${String(anchorLocal.hour).padStart(2,'0')}:${String(anchorLocal.minute).padStart(2,'0')}`;
    // Calibration and simulation scripts ask for every signal so they can
    // measure the raw distributions. It cannot change the result: a mode
    // score only ever reads the signals its own mixture names.
    const mixture=signalsNeededBy(mode);
    const needed=input.probeAllSignals?[...SIGNALS]:mixture;
    const today=rawScoreOn(anchorDate,anchorClock,period,zone,category,mode,needed);
    // The fortnight only ever contributes mode scores, so each prior date
    // costs exactly the signals this mode mixes — never the probe's nine.
    const priorScores=[];
    for(let k=1;k<=14;k++) {
      const prior=rawScoreOn(civilDateShift(anchorDate,-k),anchorClock,period,zone,category,mode,mixture);
      if(prior)priorScores.push(prior.score);
    }
    const adjusted=adjustAgainstHistory(today.score,priorScores);
    const tenths=displayTenths(adjusted);

    /**
     * A window's score: this mode's own mixture, recomputed from scratch at
     * that window's instant.
     *
     * Every signal is recalculated there, the timing signal included. Under
     * v9.1 a window reused the headline's `T`, so all of an ACT / WAIT
     * reading's windows carried the same timing value and the ranking could
     * not see the one thing that mode is about.
     *
     * The fortnight contrast is deliberately not applied: a fifteen-minute
     * slot has no fortnight of its own, and the number's job is to rank the
     * slots of one day against each other. So the figure reads as "this mode's
     * score for this slot, on the same display curve as the headline, before
     * the headline's comparison against the reader's own fortnight".
     */
    const windowScore=start=>{
      const local=localAt(start,zone);
      const clock=`${String(local.hour).padStart(2,'0')}:${String(local.minute).padStart(2,'0')}`;
      const raw=rawSignals(local.date,clock,period,zone,category,mixture,moments(start,zone,category));
      return displayPercent(modeScore(mode,normalizeAll(raw)));
    };
    const windows=period==='now'?[]:evaluated.filter(s=>duration(s)>=900).map(s=>({
      startUtc:new Date(s.candidateStart??s.start).toISOString(),endUtc:new Date(s.end).toISOString(),
      startLocal:localAt(s.candidateStart??s.start,zone).iso,endLocal:localAt(s.end,zone).iso,
      score:windowScore(s.start),dataCoverage:round(s.value.evidence.coverage),hourBranch:s.hourBranch,
      meaning:'symbolic_timing_score_not_probability',
    })).sort((a,b)=>b.score-a.score||a.startUtc.localeCompare(b.startUtc)).slice(0,2);
    const first=evaluated[0].value,briefNumber=first.modules.N.diagnostics.personalDay;
    // The whole local day, read once with the general profile: the brief must
    // not move with the decision mode, the category, the chosen period or the
    // moment the app was opened.
    const daySegments=segments.map(s=>({start:s.start,end:s.end,duration:(s.end-s.start)/1000,
      ...evaluate(s.start,zone,'general')}));
    const energy=dailyEnergy(daySegments.map(s=>({start:s.start,end:s.end,evidence:s.evidence})));
    const dayStart=daySegments[0];
    const colors=dailyColors(daySegments.map(s=>({duration:s.duration,modules:s.modules})),
      dayStart.calendar.day.stem,dayStart.modules.N.diagnostics.personalDay);
    const readingKey=hash({profile,rules:RULESET,providers:base.providers,zone,period,category,
      segments:evaluated.map(s=>[s.start,s.end,period==='now'?null:s.candidateStart])});
    return {...base,...decision(mode,adjusted,e.coverage,tenths),readingKey,
      axisScores:{action:round(e.a),change:round(e.c),selected:round(adjusted)},
      scoring:{system:SCORING_VERSION,scaleVersion:SCALE_VERSION,
        anchorLocal:`${anchorDate}T${anchorClock}`,
        signals:Object.fromEntries(Object.entries(today.raw).map(([k,v])=>[k,round(v)])),
        normalized:Object.fromEntries(Object.entries(today.normalized).map(([k,v])=>[k,round(v)])),
        rawModeScore:round(today.score),
        priorDatesUsed:priorScores.length,
        priorMedian:priorScores.length?round(median(priorScores)):null,
        adjustedModeScore:round(adjusted),
        meaning:'symbolic_alignment_not_success_probability'},
      evaluatedAtUtc:new Date(evaluated[0].start).toISOString(),luckyWindows:windows,
      windowStatus:period==='now'?'not_applicable':windows.length===2?'two_available':windows.length===1?'one_remaining':'no_15_minute_window',
      dailyBrief:{luckyNumber:briefNumber,colors,energy},
      segments:evaluated.map(s=>({startUtc:new Date(s.start).toISOString(),endUtc:new Date(s.end).toISOString(),
        includedFromUtc:new Date(s.candidateStart??s.start).toISOString(),durationSeconds:duration(s),
        modules:moduleSummary(s.value.modules,!!input.diagnostics,category)})),
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
