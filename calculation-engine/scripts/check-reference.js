import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {createCalculator} from '../src/index.js';
import {skyAt} from '../src/astronomy.js';

const starIds=Object.fromEntries('紫微:ziwei 天机:tianji 太阳:taiyang 武曲:wuqu 天同:tiantong 廉贞:lianzhen 天府:tianfu 太阴:taiyin 贪狼:tanlang 巨门:jumen 天相:tianxiang 天梁:tianliang 七杀:qisha 破军:pojun 左辅:zuofu 右弼:youbi 文昌:wenchang 文曲:wenqu 天魁:tiankui 天钺:tianyue 擎羊:qingyang 陀罗:tuoluo 火星:huoxing 铃星:lingxing 地空:dikong 地劫:dijie'.split(' ').map(x=>x.split(':')));
const brightness={'庙':'miao','旺':'wang','得':'de','利':'li','平':'ping','不':'bu','陷':'xian'};
const transforms={'禄':'lu','权':'quan','科':'khoa','忌':'ky'};
const cases=[],results=[];
for(const [date,clock,zone,gender] of [['2000-08-16','03:00','Asia/Shanghai','male'],['1986-05-29','11:30','Asia/Ho_Chi_Minh','female'],['1998-06-21','14:30','America/New_York','male']]){
  const engine=createCalculator({birthDate:date,birthTime:clock,birthTimezone:zone,traditionalProfile:gender});
  const inspected=engine.inspectBirthCharts(),chart=inspected.ziWei[0].chart;
  for(const instant of ['2026-09-18T08:30:00Z','2025-01-01T01:00:00Z','2024-02-04T08:28:00Z']){
    const r=engine.calculate({context:{instantUtc:instant,deviceTimezone:zone},diagnostics:true});
    const mods=r.segments[0].modules,cal=mods.T.diagnostics.calendar,z=mods.Z.diagnostics;
    const sky=skyAt(Date.parse(r.evaluatedAtUtc));
    const stars=chart.palaces.flatMap((p,i)=>[...p.majorStars,...p.minorStars,...p.adjectiveStars].filter(s=>s.name in starIds).map(s=>[starIds[s.name],i,brightness[s.brightness]??null]));
    const layers=Object.fromEntries(Object.entries(z.layers).map(([name,l])=>[name==='decadal'?'decade':name,{target:l.target,events:l.events.map(e=>({kind:transforms[e.kind],palace:e.palace}))}]));
    cases.push({birth_date:date,date:cal.local.date,pillars:inspected.baZi.pillars.map(p=>p?[p.stem,p.branch]:null),
      timing:Object.fromEntries(Object.entries(mods.B.diagnostics.layers).map(([name,l])=>[name,[l.pillar.stem,l.pillar.branch]])),
      stars,target:z.lifePalace,layers,almanac:[mods.T.diagnostics.dayGod.auspicious,mods.T.diagnostics.hourGod.auspicious,mods.T.diagnostics.officer],
      transits:sky.positions,natal:inspected.western.positions,cosmic:[sky.positions.sun,sky.positions.moon,sky.mercurySpeed]});
    results.push(r);
  }
}
const expected=JSON.parse(execFileSync('python',['-B',fileURLToPath(new URL('./legacy_reference.py',import.meta.url))],{input:JSON.stringify(cases),encoding:'utf8'}));
let checks=0;
for(let i=0;i<results.length;i++){
  const actual=results[i],reference=expected[i];
  for(const name of Object.keys(reference.modules))for(const k of ['a','c','coverage']){
    assert.ok(Math.abs(actual.segments[0].modules[name][k]-reference.modules[name][k])<1e-8,`${i}:${name}:${k}`);checks++;
  }
  assert.ok(Math.abs(actual.axisScores.action-reference.fusion.a)<1e-8);checks++;
  assert.ok(Math.abs(actual.axisScores.change-reference.fusion.c)<1e-8);checks++;
  assert.ok(Math.abs(actual.dataCoverage-reference.fusion.coverage)<1e-8);checks++;
}
console.log(JSON.stringify({status:'passed',realChartCases:results.length,numericComparisons:checks,reference:'Python v1/v2, F removed and weights divided by 0.9'}));
