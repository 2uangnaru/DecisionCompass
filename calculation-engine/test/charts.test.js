import test from 'node:test';
import assert from 'node:assert/strict';
import {birthContext} from '../src/time.js';
import {buildBaZi,scoreBaZi,tenGod,decadeAt} from '../src/bazi.js';
import {buildZiWei,scoreZiWei,inspectZiWei} from '../src/ziwei.js';
import {calendarAt} from '../src/calendar.js';
import {natalSky,skyAt,longitude,cosmic,western} from '../src/astronomy.js';
import lunar from 'lunar-javascript';

const exact=birthContext({birthDate:'2000-08-16',birthTime:'03:00',birthTimezone:'Asia/Shanghai'});
const now=Date.parse('2026-09-18T08:00:00Z'),cal=calendarAt(now,'Asia/Shanghai');
test('all ten Day Masters map to all ten gods',()=>{
  for(let dm=0;dm<10;dm++)assert.equal(new Set(Array.from({length:10},(_,s)=>tenGod(dm,s))).size,10);
});
test('Bazi chart includes hidden stems, roots, structure and an automatic decade schedule',()=>{
  const b=buildBaZi(exact,'male');
  assert.equal(b.pillars.length,4);assert.ok(b.tenGods.every(Boolean));assert.ok(b.decade);
  assert.ok(Math.abs(b.elementDistribution.reduce((a,v)=>a+v,0)-1)<1e-12);
  assert.equal(b.decade.forward,true);assert.ok(decadeAt(b,now));
  assert.equal(decadeAt(b,b.decade.startUtc-1),null);
  assert.equal(decadeAt(b,b.decade.startUtc).index,1);
});
test('BaZi start-age offsets agree with upstream minute-resolution Yun on a non-DST fixture',()=>{
  const b=buildBaZi(exact,'male');
  const provider=lunar.Solar.fromYmdHms(2000,8,16,3,0,0).getLunar().getEightChar().getYun(1,2);
  assert.deepEqual(b.decade.startAge,{years:provider.getStartYear(),months:provider.getStartMonth(),days:provider.getStartDay(),hours:provider.getStartHour()});
});
test('missing hour removes hour pillar and exact luck-start claim',()=>{
  const b=buildBaZi(birthContext({birthDate:'2000-08-16',birthCountry:'CN'}),'male');
  assert.equal(b.pillars[3],null);assert.equal(b.decade,null);assert.ok(b.pillars.slice(0,3).every(Boolean));
  assert.ok(scoreBaZi(b,cal,now).evidence.coverage<scoreBaZi(buildBaZi(exact,'male'),cal,now).evidence.coverage);
});
test('unreviewed Yong Shen is explicitly absent, not invented from missing elements',()=>{
  const b=buildBaZi(exact,'male');assert.equal(b.traditionalYongShen,null);assert.equal(b.traditionalXiShen,null);
  assert.ok(scoreBaZi(b,cal,now).evidence.coverage<1);
});
test('Zi Wei provider reference example: life at Wu, body at Xu, 14 majors',()=>{
  const z=buildZiWei(exact,'male'),chart=inspectZiWei(z)[0].chart;
  // https://iztro.com/en_US/quick-start : 2000-8-16, timeIndex 2, male
  assert.equal(chart.earthlyBranchOfSoulPalace,'午');assert.equal(chart.earthlyBranchOfBodyPalace,'戌');
  assert.equal(chart.palaces.length,12);
  assert.equal(chart.palaces.flatMap(p=>p.majorStars).filter(s=>s.type==='major').length,14);
  const score=scoreZiWei(z,cal);assert.equal(score.evidence.coverage,1);
  assert.deepEqual(Object.keys(score.diagnostics.layers),['natal','decadal','yearly','monthly','daily','hourly']);
});
test('unknown hour uses 12 explicit charts; inconsistent directions are neutralized',()=>{
  const birth=birthContext({birthDate:'2000-08-16',birthCountry:'CN'}),z=buildZiWei(birth,'male'),score=scoreZiWei(z,cal);
  assert.equal(score.diagnostics.scenarioCount,12);assert.equal(score.status,'scenario_analysis');
  for(const axis of ['a','c']){
    const r=score.diagnostics.ranges[axis];
    if(r.min<=0&&r.max>=0)assert.equal(score.evidence[axis],0);
  }
  assert.equal(score.evidence.coverage,.75);
});
test('missing convention is a separate scenario dimension',()=>{
  const score=scoreZiWei(buildZiWei(exact,null),cal);assert.equal(score.diagnostics.scenarioCount,2);
});
test('Zi Wei current-day rule treats late Zi and early Zi on the same civil date consistently',()=>{
  const early=buildZiWei(birthContext({birthDate:'2000-08-16',birthTime:'00:30',birthCountry:'CN'}),'male');
  const late=buildZiWei(birthContext({birthDate:'2000-08-16',birthTime:'23:30',birthCountry:'CN'}),'male');
  assert.deepEqual(scoreZiWei(early,cal).evidence,scoreZiWei(late,cal).evidence);
});
test('Western natal chart uses correct geocentric equinox frame',()=>{
  // USNO: March equinox 2024-03-20 03:06 UTC, apparent Sun longitude ~0.
  // https://aa.usno.navy.mil/calculated/seasons?year=2024&tz=0&submit=Get+Data
  const lon=longitude('sun',Date.parse('2024-03-20T03:06:00Z'));
  assert.ok(Math.min(lon,360-lon)<.01);
  const natal=natalSky(exact);assert.equal(Object.keys(natal.positions).length,7);
  assert.ok(western(skyAt(now),natal).evidence.coverage>.999999);
});
test('HKO published new Moon 2025-01-29 20:36 HKT gives near-zero elongation',()=>{
  // https://www.hko.gov.hk/tc/gts/astron2025/files/HKO_almanac_2025.pdf
  const u=cosmic(skyAt(Date.parse('2025-01-29T12:36:00Z'))).diagnostics;
  assert.ok(Math.min(u.elongationDegrees,360-u.elongationDegrees)<.05);
  assert.ok(u.illuminationApprox<.000001);
});
test('unknown birth hour excludes moving Moon; no default noon',()=>{
  const natal=natalSky(birthContext({birthDate:'2000-08-16',birthTime:null,birthTimezone:'Asia/Shanghai'}));
  assert.equal(natal.positions.moon,undefined);assert.ok(natal.ranges.moon.spanDegrees>10);
  assert.equal(natal.method,'uncertain_birth_interval_sampled_3h');
});
test('unresolved birth timezone does not become current timezone for Western natal chart',()=>{
  const natal=natalSky(birthContext({birthDate:'2000-08-16',birthTime:'03:00'}));
  assert.deepEqual(natal.positions,{});assert.equal(western(skyAt(now),natal).evidence.coverage,0);
});
