import test from 'node:test';
import assert from 'node:assert/strict';
import {solarTerms,calendarAt,civilCalendar,natalPillars,almanac} from '../src/calendar.js';
import {birthContext,localCandidates} from '../src/time.js';
import lunar from 'lunar-javascript';

test('published HKO lunar conversion fixtures',()=>{
  // https://www.hko.gov.hk/en/gts/time/calendar/pdf/files/2024e.pdf
  // https://www.hko.gov.hk/en/publica/calendar/files/Cal_2025.pdf
  const fixtures=[['2024-02-10',2024,1,1],['2024-03-10',2024,2,1],['2024-04-09',2024,3,1],['2024-05-08',2024,4,1],['2025-01-29',2025,1,1],['2025-01-30',2025,1,2]];
  for(const [date,year,month,day]of fixtures)assert.deepEqual(civilCalendar(date).lunar,{year,month,day,leap:false});
});
test('24 solar terms per year and chronological instants',()=>{
  for(const y of [1900,1950,1986,2000,2024,2026,2099]){
    const terms=solarTerms(y);assert.equal(terms.length,24);assert.equal(terms.filter(t=>t.monthIndex>=0).length,12);
    for(let i=1;i<terms.length;i++)assert.ok(terms[i].instant>terms[i-1].instant);
  }
});
test('HKO 2024 Li Chun 4 February 16:27 HKT: correct UTC, not local-machine parse',()=>{
  // https://my.weather.gov.hk/en/gts/astron2024/files/HKO_almanac_2024.pdf
  const spring=solarTerms(2024).find(t=>t.name==='立春');
  assert.ok(Math.abs(spring.instant-Date.parse('2024-02-04T08:27:00Z'))<120000);
  for(const zone of ['Asia/Hong_Kong','America/New_York','Asia/Kathmandu']){
    assert.equal(calendarAt(spring.instant-1000,zone).year.text,'癸卯');
    assert.equal(calendarAt(spring.instant,zone).year.text,'甲辰');
    assert.equal(calendarAt(spring.instant,zone).month.text,'丙寅');
  }
});
test('Bazi published example: 2000-08-16 03:00 China civil time',()=>{
  // https://iztro.com/en_US/quick-start : 庚辰 甲申 丙午 庚寅
  const c=calendarAt(Date.parse('2000-08-15T19:00:00Z'),'Asia/Shanghai');
  assert.deepEqual([c.year.text,c.month.text,c.day.text,c.hour.text],['庚辰','甲申','丙午','庚寅']);
});
test('day switches at midnight, not 23:00; hour stem is based on chosen day',()=>{
  const a=calendarAt(Date.parse('2026-09-18T14:59:00Z'),'Asia/Ho_Chi_Minh');
  const b=calendarAt(Date.parse('2026-09-18T16:59:00Z'),'Asia/Ho_Chi_Minh');
  const c=calendarAt(Date.parse('2026-09-18T17:00:00Z'),'Asia/Ho_Chi_Minh');
  assert.equal(a.day.text,b.day.text);assert.notEqual(b.day.text,c.day.text);
  assert.equal(b.hour.branch,0);assert.equal(c.hour.branch,0);assert.notEqual(b.hour.stem,c.hour.stem);
});
test('unknown birth hour omits hour pillar and solar-term ambiguity omits year/month',()=>{
  const birth=birthContext({birthDate:'2024-02-04',birthTime:null,birthTimezone:'Asia/Shanghai'});
  const p=natalPillars(birth);assert.equal(p[0],null);assert.equal(p[1],null);assert.ok(p[2]);assert.equal(p[3],null);
});
test('month is solar-month, lunar leap date is preserved',()=>{
  assert.equal(civilCalendar('2023-03-22').lunar.leap,true);
  const first=calendarAt(Date.parse('2023-03-21T12:00:00Z'),'Asia/Shanghai');
  const next=calendarAt(Date.parse('2023-03-22T12:00:00Z'),'Asia/Shanghai');
  assert.equal(first.month.text,next.month.text);
});
test('almanac agrees with provider away from intentionally changed boundary conventions',()=>{
  for(const date of ['1986-05-29','2000-08-16','2026-09-18']){
    const [y,m,d]=date.split('-').map(Number),provider=lunar.Solar.fromYmdHms(y,m,d,12,0,0).getLunar();
    // China observed DST in 1986: noon local is not always 04:00 UTC.
    const c=calendarAt(localCandidates(date,'12:00','Asia/Shanghai')[0],'Asia/Shanghai'),a=almanac(c).diagnostics;
    assert.equal(a.dayGod.name,provider.getDayTianShen());assert.equal(a.hourGod.name,provider.getTimeTianShen());
  }
});
