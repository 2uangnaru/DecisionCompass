import assert from 'node:assert/strict';
import {createCalculator} from '../src/index.js';
import {calendarAt,solarTerms} from '../src/calendar.js';
import {localAt,segmentsForDay,HOUR} from '../src/time.js';
import {mod} from '../src/core.js';

// Seeded only for test inputs; the product engine has no random outcome path.
let seed=0xdecafbad;
function rand(){seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;}
const zones=['Asia/Ho_Chi_Minh','Asia/Tokyo','America/New_York','Europe/London','Australia/Lord_Howe','Asia/Kathmandu','Pacific/Kiritimati','Pacific/Honolulu'];
const start=performance.now();
let calendars=0,readings=0,uncertain=0;
const origin=Date.parse('1901-01-01T00:00:00Z'),span=Date.parse('2098-01-01T00:00:00Z')-origin;
for(let i=0;i<10000;i++){
  const ms=origin+Math.floor(rand()*span),zone=zones[i%zones.length],c=calendarAt(ms,zone);
  for(const p of [c.year,c.month,c.day,c.hour]){assert.ok(p.stem>=0&&p.stem<10);assert.ok(p.branch>=0&&p.branch<12);assert.equal(p.stem%2,p.branch%2);}
  assert.equal(c.local.date,localAt(ms,zone).date);
  if(i%100===0){
    const segs=segmentsForDay(ms,zone);assert.equal(segs.filter(s=>s.start<=ms&&ms<s.end).length,1);
    for(let j=1;j<segs.length;j++)assert.equal(segs[j-1].end,segs[j].start);
  }
  calendars++;
}
console.log(JSON.stringify({phase:'calendar',cases:calendars,elapsedSeconds:(performance.now()-start)/1000}));
for(let p=0;p<20;p++){
  const profile={birthDate:`${1970+p}-${String(1+mod(p*7,12)).padStart(2,'0')}-${String(1+mod(p*11,27)).padStart(2,'0')}`,
    birthTime:p%5===0?null:`${String(mod(p*3,24)).padStart(2,'0')}:30`,birthTimezone:zones[p%zones.length],traditionalProfile:p%2?'male':'female'};
  const engine=createCalculator(profile);
  for(let i=0;i<50;i++){
    const now=Date.parse('2024-01-01T00:00:00Z')+Math.floor(rand()*3*365*24)*HOUR;
    const input={context:{instantUtc:new Date(now).toISOString(),deviceTimezone:zones[i%zones.length]},period:i%5===0?'evening':'now',mode:['yes_no','stay_go','keep_let_go'][i%3]};
    const r=engine.calculate(input);
    if(r.status!=='period_elapsed'){
      assert.equal(Object.values(r.percentages).reduce((a,b)=>a+b,0),100);
      assert.ok(r.dataCoverage>0&&r.dataCoverage<=1);
      for(const segment of r.segments)for(const m of Object.values(segment.modules)){
        assert.ok(Number.isFinite(m.a)&&Math.abs(m.a)<=1);assert.ok(Number.isFinite(m.c)&&Math.abs(m.c)<=1);assert.ok(m.coverage>=0&&m.coverage<=1);
      }
      assert.ok(r.luckyWindows.length<=2);
      if(i===0)assert.deepEqual(r,engine.calculate(input));
    }
    readings++;if(profile.birthTime===null)uncertain++;
  }
  if(p%5===4)console.log(JSON.stringify({phase:'readings',cases:readings,elapsedSeconds:(performance.now()-start)/1000}));
}
// Every term across a 20-year interval: exact year/month transition consistency.
let termChecks=0;
for(let y=2016;y<=2035;y++)for(const t of solarTerms(y).filter(t=>t.monthIndex>=0)){
  const before=calendarAt(t.instant-1000,'Pacific/Honolulu'),after=calendarAt(t.instant,'Pacific/Kiritimati');
  assert.notEqual(before.month.text,after.month.text);termChecks++;
}
console.log(JSON.stringify({status:'passed',calendarCases:calendars,endToEndReadings:readings,unknownHourReadings:uncertain,solarTermTransitions:termChecks,elapsedSeconds:(performance.now()-start)/1000}));
