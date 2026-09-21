import iztro from 'iztro';
import { evidence, blend, moduleResult, clamp, mod, boundedCache } from './core.js';
import { hourBranch } from './time.js';

const CONFIG={yearDivide:'normal',horoscopeDivide:'normal',ageDivide:'normal',dayDivide:'current',algorithm:'default'};
const MAJOR={'紫微':[.2,-.2],'天机':[.1,.5],'太阳':[.3,.2],'武曲':[.25,-.2],'天同':[-.1,-.35],'廉贞':[.1,.25],'天府':[.2,-.5],'太阴':[-.1,-.25],'贪狼':[.15,.5],'巨门':[-.15,.2],'天相':[.15,-.4],'天梁':[.1,-.45],'七杀':[.1,.55],'破军':[-.1,.65]};
const AUX={'左辅':[.2,-.1],'右弼':[.2,-.1],'文昌':[.2,0],'文曲':[.2,0],'天魁':[.2,-.1],'天钺':[.2,-.1],'擎羊':[-.25,.2],'陀罗':[-.25,-.1],'火星':[-.25,.2],'铃星':[-.25,.15],'地空':[-.25,.3],'地劫':[-.25,.3]};
const BRIGHTNESS={'庙':1,'旺':.95,'得':.85,'利':.8,'平':.7,'不':.6,'陷':.5};
const TRANSFORMS={'禄':[.35,-.1],'权':[.2,.2],'科':[.25,-.2],'忌':[-.45,.15]};
const LAYERS={natal:.15,decadal:.15,yearly:.15,monthly:.10,daily:.20,hourly:.25};
const proximity=(p,t)=>({0:1,4:.6,8:.6,6:.5}[mod(p-t,12)]??0);
const charts=boundedCache(256);
function configure(){iztro.astro.config(CONFIG);iztro.i18n?.setLanguage?.('zh-CN');}
function chartFor(date,index,gender) {
  const key=`${date}|${index}|${gender}`;
  if(charts.get(key))return charts.get(key);
  configure();
  return charts.set(key,iztro.astro.bySolar(date,index,gender==='male'?'男':'女',true,'zh-CN'));
}
export function buildZiWei(birth,traditionalProfile) {
  const indexes=birth.clock?[hourBranch(Number(birth.clock.slice(0,2)))]:Array.from({length:12},(_,i)=>i);
  if(birth.status==='birth_time_nonexistent')return {charts:[],reason:birth.status,unknownHour:!birth.clock};
  // Unknown convention is modeled as alternatives, never inferred from a name.
  const genders=['male','female'].includes(traditionalProfile)?[traditionalProfile]:['male','female'];
  const entries=indexes.flatMap(index=>genders.map(gender=>({index,gender,chart:chartFor(birth.date,index,gender)})));
  return {charts:entries,unknownHour:!birth.clock,unknownConvention:genders.length>1,rules:CONFIG};
}
function scoreChart(chart,date,timeIndex) {
  configure();
  const target=chart.palaces.findIndex(p=>p.name==='命宫');
  const stars=chart.palaces.flatMap((p,index)=>[...p.majorStars,...p.minorStars,...p.adjectiveStars].map(s=>({...s,palace:index})));
  const parts=[];
  for(const [weight,catalog,divisor]of [[.45,MAJOR,4],[.20,AUX,3]]) {
    const selected=stars.filter(s=>s.name in catalog);
    if(selected.length!==Object.keys(catalog).length||new Set(selected.map(s=>s.name)).size!==selected.length)throw new Error('ZIWEI_STAR_CATALOG_MISMATCH');
    const values=[0,1].map(k=>selected.reduce((sum,s)=>{
      if(catalog===MAJOR&&!(s.brightness in BRIGHTNESS))throw new Error('ZIWEI_MAJOR_BRIGHTNESS_MISSING');
      return sum+catalog[s.name][k]*(BRIGHTNESS[s.brightness]??1)*proximity(s.palace,target)/divisor;
    },0));
    parts.push([weight,evidence(...values.map(clamp),1)]);
  }
  const transformed=[],layerDetails={};
  const natalEvents=stars.filter(s=>s.mutagen in TRANSFORMS).map(s=>({name:s.name,kind:s.mutagen,palace:s.palace}));
  const horoscope=chart.horoscope(date,timeIndex);
  for(const [layer,weight]of Object.entries(LAYERS)) {
    const data=horoscope[layer], index=layer==='natal'?target:data.index;
    if(index<0)continue;
    const events=layer==='natal'?natalEvents:data.mutagen.map((name,i)=>({name,kind:['禄','权','科','忌'][i],palace:stars.find(s=>s.name===name)?.palace}));
    if(events.length!==4||events.some(e=>e.palace==null)||new Set(events.map(e=>e.kind)).size!==4)throw new Error('ZIWEI_TRANSFORM_CATALOG_MISMATCH');
    const v=[0,1].map(k=>clamp(events.reduce((sum,e)=>sum+proximity(e.palace,index)*TRANSFORMS[e.kind][k]/2,0)));
    transformed.push([weight,evidence(...v,1)]);layerDetails[layer]={target:index,events};
  }
  parts.push([.35,blend(transformed)]);
  return {evidence:blend(parts),layers:layerDetails,lifePalace:target,bodyPalace:chart.palaces.findIndex(p=>p.isBodyPalace),
    majorCount:14,auxiliaryCount:12};
}
export function scoreZiWei(built,cal) {
  if(!built.charts.length)return moduleResult(evidence(),{reason:built.reason});
  const results=built.charts.map(entry=>({...scoreChart(entry.chart,cal.local.date,cal.hour.branch),birthHourIndex:entry.index,convention:entry.gender}));
  if(results.length===1)return moduleResult(results[0].evidence,{...results[0],rules:CONFIG,scenarioCount:1,method:'single_chart'});
  const ranges=Object.fromEntries(['a','c'].map(k=>[k,{min:Math.min(...results.map(r=>r.evidence[k])),max:Math.max(...results.map(r=>r.evidence[k]))}]));
  const conservative=k=>ranges[k].min>0?ranges[k].min:ranges[k].max<0?ranges[k].max:0;
  // Missing birth inputs and cross-scenario agreement are separate quantities.
  // The cap is explicit product policy, NOT a likelihood of any birth hour.
  const inputFactor=(built.unknownHour?.75:1)*(built.unknownConvention?.75:1);
  const q=Math.min(...results.map(r=>r.evidence.coverage))*inputFactor;
  return moduleResult(evidence(conservative('a'),conservative('c'),q),{method:'conservative_across_possible_charts',scenarioCount:results.length,
    unknownBirthHour:built.unknownHour,unknownConvention:built.unknownConvention,inputCoverageFactor:inputFactor,
    ranges,scenarioScores:results.map(({birthHourIndex,convention,evidence:e})=>({birthHourIndex,convention,...e})),rules:CONFIG},'scenario_analysis');
}
export function inspectZiWei(built) {
  return built.charts.map(({index,gender,chart})=>({birthHourIndex:index,convention:gender,
    // Provider chart is available for audit, but not needed by the app result.
    chart:JSON.parse(JSON.stringify(chart))}));
}
