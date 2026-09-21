import test from 'node:test';
import assert from 'node:assert/strict';
import {birthContext,localAt,localCandidates,segmentsForDay,parseInstant,parseBirthDate,parseBirthTime,HOUR} from '../src/time.js';
import {resolveCurrentContext} from '../src/location.js';

test('UTC instant requires explicit offset; invalid leap dates rejected',()=>{
  for(const s of ['2024-01-01T12:00:00','not-a-date','2024-02-30T00:00:00Z'])assert.throws(()=>parseInstant(s));
  assert.throws(()=>parseBirthDate('2023-02-29'));assert.equal(parseBirthDate('2024-02-29'),'2024-02-29');
  for(const t of ['24:00','12:60','9:00'])assert.throws(()=>parseBirthTime(t));
});
test('one UTC instant has different local dates across the date line',()=>{
  const t=Date.parse('2026-09-18T12:30:00Z');
  assert.equal(localAt(t,'Pacific/Kiritimati').date,'2026-09-19');
  assert.equal(localAt(t,'Pacific/Honolulu').date,'2026-09-18');
});
test('half-hour and quarter-hour timezone offsets',()=>{
  const t=Date.parse('2026-01-01T00:00:00Z');
  assert.equal(localAt(t,'Asia/Kolkata').clock,'05:30:00');
  assert.equal(localAt(t,'Asia/Kathmandu').clock,'05:45:00');
  assert.equal(localAt(t,'Australia/Eucla').clock,'08:45:00');
});
test('DST gap is absent and fold produces two distinct instants',()=>{
  assert.deepEqual(localCandidates('2024-03-10','02:30','America/New_York'),[]);
  const candidates=localCandidates('2024-11-03','01:30','America/New_York');
  assert.deepEqual(candidates.map(t=>new Date(t).toISOString()),['2024-11-03T05:30:00.000Z','2024-11-03T06:30:00.000Z']);
});
test('segmentation covers 23h and 25h dates without overlaps or holes',()=>{
  for(const [date,hours]of [['2024-03-10',23],['2024-11-03',25]]){
    const segments=segmentsForDay(Date.parse(`${date}T12:00:00Z`),'America/New_York');
    assert.equal(segments.reduce((s,x)=>s+x.end-x.start,0),hours*HOUR);
    for(let i=1;i<segments.length;i++)assert.equal(segments[i-1].end,segments[i].start);
  }
});
test('Lord Howe half-hour DST shift does not lose a segment',()=>{
  const rows=segmentsForDay(Date.parse('2024-10-06T01:00:00Z'),'Australia/Lord_Howe');
  assert.equal(rows.reduce((s,r)=>s+r.end-r.start,0),23.5*HOUR);
});
test('unknown hour preserves the complete day, including DST and skipped dates',()=>{
  const b=birthContext({birthDate:'2024-11-03',birthTime:null,birthTimezone:'America/New_York'});
  assert.equal(b.intervals.reduce((s,i)=>s+i.end-i.start+1,0),25*HOUR);
  assert.equal(birthContext({birthDate:'2011-12-30',birthTime:null,birthTimezone:'Pacific/Apia'}).status,'birth_time_nonexistent');
});
test('birth country is a candidate set; no country majority or current-zone substitution',()=>{
  const b=birthContext({birthDate:'1998-06-21',birthTime:'14:30',birthCountry:'US'});
  assert.ok(b.zones.length>1);assert.equal(b.exact,false);
  const unknown=birthContext({birthDate:'1998-06-21',birthTime:'14:30'});
  assert.equal(unknown.status,'birth_timezone_unresolved');assert.equal(unknown.intervals.length,0);
  const same=birthContext({birthDate:'1998-06-21',birthTime:'14:30',birthCountry:'VN'});
  assert.equal(same.exact,true);
});
test('location fix resolves to a timezone and never overwrites birth information',()=>{
  const c=resolveCurrentContext({instantUtc:'2026-09-18T08:30:00Z',deviceTimezone:'America/New_York',
    location:{latitude:10.7769,longitude:106.7009,accuracyMeters:100,capturedAtUtc:'2026-09-18T08:29:59Z'}});
  assert.equal(c.timezone,'Asia/Ho_Chi_Minh');assert.equal(c.zoneSource,'location');
  assert.ok(!('birthTimezone'in c));assert.ok(!('latitude'in c));
});
test('denied, stale, inaccurate or malformed location falls back to device timezone',()=>{
  const context={instantUtc:'2026-09-18T08:30:00Z',deviceTimezone:'Asia/Tokyo'};
  const fix={latitude:10.77,longitude:106.7,accuracyMeters:50,capturedAtUtc:'2026-09-18T08:29:00Z'};
  for(const location of [null,{...fix,latitude:NaN},{...fix,accuracyMeters:50000},{...fix,capturedAtUtc:'2026-09-17T08:29:00Z'}]){
    const c=resolveCurrentContext({...context,location});assert.equal(c.timezone,'Asia/Tokyo');assert.equal(c.zoneSource,'device');
  }
  assert.throws(()=>resolveCurrentContext({instantUtc:context.instantUtc,deviceTimezone:'wrong'}),/TIMEZONE_UNAVAILABLE/);
});
