import test from 'node:test';
import assert from 'node:assert/strict';
import {createCalculator,calculate} from '../src/index.js';
import {combine,decision,evidence,WEIGHTS} from '../src/core.js';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const profile={birthDate:'1998-06-21',birthTime:'14:30',birthCountry:'VN',traditionalProfile:'male'};
const engine=createCalculator(profile);
const context={instantUtc:'2026-09-18T08:30:00Z',deviceTimezone:'Asia/Ho_Chi_Minh'};
test('end-to-end raw profile produces all seven modules, not a supplied chart',()=>{
  const r=engine.calculate({context});
  assert.deepEqual(Object.keys(r.segments[0].modules),['B','Z','T','W','V','N','U']);
  assert.equal(r.percentages.YES+r.percentages.NO,100);
  assert.ok(r.dataCoverage>0&&r.dataCoverage<=1);assert.equal(r.luckyWindows.length,0);
});
test('same inputs deterministic and same segment does not reroll',()=>{
  const first=engine.calculate({context}),again=engine.calculate({context});assert.deepEqual(first,again);
  const later=engine.calculate({context:{...context,instantUtc:'2026-09-18T08:45:00Z'}});
  assert.deepEqual(first.percentages,later.percentages);assert.equal(first.readingKey,later.readingKey);
});
test('each decision mode has its own semantic projection without altering the calculation key',()=>{
  const modes=['yes_no','act_wait','advance_retreat','stay_go','keep_let_go','forward_backward','left_right'];
  const readings=modes.map(mode=>engine.calculate({context,mode}));
  assert.ok(readings.every(r=>Object.values(r.percentages).reduce((a,b)=>a+b,0)===100));
  assert.ok(readings.every(r=>r.readingKey===readings[0].readingKey));
  assert.deepEqual(readings.map(r=>r.modeBasis),[
    'overall_acceptance','action_timing','tactical_momentum','change_alignment',
    'release_alignment','temporal_momentum','symbolic_polarity'
  ]);
  const sample=evidence(.8,-.4,1);
  const yes=decision(sample,'yes_no'),forward=decision(sample,'forward_backward'),left=decision(sample,'left_right');
  assert.notEqual(yes.percentages.YES,forward.percentages.FORWARD);
  assert.notEqual(yes.percentages.YES,left.percentages.LEFT);
  assert.throws(()=>engine.calculate({context,mode:'up_down'}),/INVALID_DECISION_MODE/);
});
test('period returns two valid ranked nonoverlapping windows with absolute instants',()=>{
  const r=engine.calculate({context,period:'evening'});assert.equal(r.luckyWindows.length,2);
  assert.ok(r.luckyWindows[0].score>=r.luckyWindows[1].score);
  const sorted=[...r.luckyWindows].sort((a,b)=>a.startUtc.localeCompare(b.startUtc));
  assert.ok(sorted[0].endUtc<=sorted[1].startUtc);
  for(const w of r.luckyWindows){assert.ok(Date.parse(w.startUtc)>=Date.parse(context.instantUtc));assert.ok(Date.parse(w.endUtc)-Date.parse(w.startUtc)>=900000);}
});
test('elapsed period returns an explicit state, never tomorrow without asking',()=>{
  const r=engine.calculate({context,period:'morning'});assert.equal(r.status,'period_elapsed');assert.deepEqual(r.luckyWindows,[]);assert.equal(r.consumeUnlock,false);
});
test('one remaining window and less than 15 minutes do not fabricate two windows',()=>{
  const late={...context,instantUtc:'2026-09-18T16:30:00Z'};
  assert.equal(engine.calculate({context:late,period:'evening'}).windowStatus,'one_remaining');
  assert.equal(engine.calculate({context:{...late,instantUtc:'2026-09-18T16:50:00Z'},period:'evening'}).windowStatus,'no_15_minute_window');
});
test('DST repeated local hour creates different calculation snapshots',()=>{
  const a=engine.calculate({context:{instantUtc:'2024-11-03T05:30:00Z',deviceTimezone:'America/New_York'}});
  const b=engine.calculate({context:{instantUtc:'2024-11-03T06:30:00Z',deviceTimezone:'America/New_York'}});
  assert.notEqual(a.readingKey,b.readingKey);assert.notEqual(a.context.offsetSeconds,b.context.offsetSeconds);
});
test('unknown hour and no birthplace timezone still yield a partial reading',()=>{
  const r=calculate({profile:{birthDate:'1998-06-21'},context});
  assert.ok(r.percentages);assert.equal(r.segments[0].modules.W.status,'unavailable');
  assert.equal(r.segments[0].modules.Z.status,'scenario_analysis');assert.ok(r.warnings.includes('unknown_birth_time'));
});
test('spatial module excluded and fixed six-module weights sum to one',()=>{
  assert.ok(Math.abs(Object.values(WEIGHTS).reduce((a,b)=>a+b,0)-1)<1e-12);
  assert.throws(()=>combine({F:evidence(1,1,1)}),/UNKNOWN_MODULE/);
  assert.throws(()=>engine.calculate({context,space:{}}),/OUT_OF_SCOPE/);
});
test('missing module weight is not reassigned and coverage is applied only once',()=>{
  const r=combine({N:evidence(.6,.4,.5)});
  assert.ok(Math.abs(r.a-.045)<1e-12);assert.ok(Math.abs(r.coverage-0.075)<1e-12);
});
test('future or invalid profiles fail before yielding an invented answer',()=>{
  assert.throws(()=>calculate({profile:{birthDate:'2099-01-01'},context}),/FUTURE/);
  assert.throws(()=>createCalculator({birthDate:'1998-13-01'}));
  assert.throws(()=>engine.calculate({context,period:'tomorrow'}),/INVALID_PERIOD/);
});
test('caller mutations cannot poison cached readings or compiled profiles',()=>{
  const a=engine.calculate({context,diagnostics:true});a.inputSnapshot.profile.birthDate='1900-01-01';a.segments[0].modules.B.diagnostics.chart.pillars[0].stem=99;
  const charts=engine.inspectBirthCharts();charts.baZi.pillars[0].stem=99;
  const b=engine.calculate({context,diagnostics:true});assert.equal(b.inputSnapshot.profile.birthDate,'1998-06-21');assert.notEqual(b.segments[0].modules.B.diagnostics.chart.pillars[0].stem,99);
});
test('runtime host timezone does not change results',()=>{
  const code="import {calculate} from './src/index.js'; const r=calculate("+JSON.stringify({profile,context,period:'evening'})+"); console.log(JSON.stringify({p:r.percentages,k:r.readingKey,w:r.luckyWindows}));";
  const results=['UTC','America/Los_Angeles','Asia/Tokyo'].map(TZ=>execFileSync(process.execPath,['--input-type=module','-e',code],{cwd:new URL('..',import.meta.url),env:{...process.env,TZ},encoding:'utf8'}));
  assert.equal(results[0],results[1]);assert.equal(results[0],results[2]);
});
test('prototype-property names and malformed revision are rejected explicitly',()=>{
  assert.throws(()=>engine.calculate({context,mode:'toString'}),/INVALID_DECISION_MODE/);
  assert.throws(()=>engine.calculate({context,period:'constructor'}),/INVALID_PERIOD/);
  assert.throws(()=>createCalculator({...profile,traditionalProfile:'toString'}),/INVALID_TRADITIONAL_PROFILE/);
  assert.throws(()=>createCalculator({...profile,revision:{}}),/INVALID_PROFILE_REVISION/);
});
test('JSON CLI calculates from a request file',()=>{
  const cwd=fileURLToPath(new URL('..',import.meta.url));
  const out=execFileSync(process.execPath,['src/cli.js','examples/request.json'],{cwd,encoding:'utf8'});
  const r=JSON.parse(out);assert.equal(r.percentages.YES+r.percentages.NO,100);assert.equal(r.luckyWindows.length,2);
});
test('JSON CLI rejects malformed input with machine-readable error',()=>{
  const cwd=fileURLToPath(new URL('..',import.meta.url));
  try{execFileSync(process.execPath,['src/cli.js'],{cwd,input:'{bad json',encoding:'utf8',stdio:['pipe','pipe','pipe']});assert.fail('should reject');}
  catch(error){assert.equal(error.status,1);assert.equal(JSON.parse(error.stderr).status,'error');}
});
