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

// Category selects which palace(s) the reading is measured against, replacing a
// single hard-coded 命宫 target. Provider alias sets are listed together.
// Symbolic editorial emphases, not a claim about another person.
const target=(palaces,weight)=>Object.freeze({palaces:Object.freeze(palaces),weight});
export const ZIWEI_CATEGORY_TARGETS=Object.freeze({
  general:Object.freeze([target(['命宫'],1)]),
  other:Object.freeze([target(['命宫'],1)]),
  love:Object.freeze([target(['夫妻'],.75),target(['福德'],.25)]),
  career:Object.freeze([target(['官禄'],.80),target(['迁移'],.20)]),
  money:Object.freeze([target(['财帛'],.75),target(['田宅'],.25)]),
  study:Object.freeze([target(['官禄'],.45),target(['父母'],.30),target(['福德'],.25)]),
  friends:Object.freeze([target(['仆役','交友'],.65),target(['兄弟'],.35)]),
});

for (const [category,spec] of Object.entries(ZIWEI_CATEGORY_TARGETS)) {
  if(!spec.length)throw new Error(`ZIWEI_TARGETS_EMPTY:${category}`);
  if(!spec.every(t=>t.palaces.length&&Number.isFinite(t.weight)&&t.weight>0))throw new Error(`ZIWEI_TARGET_VALUE:${category}`);
  if(Math.abs(spec.reduce((s,t)=>s+t.weight,0)-1)>1e-9)throw new Error(`ZIWEI_TARGETS_NOT_NORMALIZED:${category}`);
}

/** Resolves each target to a palace index, failing loudly when a palace is absent. */
function resolveTargets(chart,category) {
  if(!Object.hasOwn(ZIWEI_CATEGORY_TARGETS,category))throw new Error('INVALID_CATEGORY');
  return ZIWEI_CATEGORY_TARGETS[category].map(({palaces,weight})=>{
    const index=chart.palaces.findIndex(p=>palaces.includes(p.name));
    if(index<0)throw new Error(`ZIWEI_PALACE_UNRESOLVED:${palaces.join('/')}`);
    return {palace:chart.palaces[index].name,aliases:palaces,index,weight};
  });
}

const weightedProximity=(palaceIndex,targets)=>targets.reduce((sum,t)=>sum+t.weight*proximity(palaceIndex,t.index),0);
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
function scoreChart(chart,date,timeIndex,category) {
  configure();
  const targets=resolveTargets(chart,category);
  const stars=chart.palaces.flatMap((p,index)=>[...p.majorStars,...p.minorStars,...p.adjectiveStars].map(s=>({...s,palace:index})));
  const parts=[];
  for(const [weight,catalog,divisor]of [[.45,MAJOR,4],[.20,AUX,3]]) {
    const selected=stars.filter(s=>s.name in catalog);
    if(selected.length!==Object.keys(catalog).length||new Set(selected.map(s=>s.name)).size!==selected.length)throw new Error('ZIWEI_STAR_CATALOG_MISMATCH');
    const values=[0,1].map(k=>selected.reduce((sum,s)=>{
      if(catalog===MAJOR&&!(s.brightness in BRIGHTNESS))throw new Error('ZIWEI_MAJOR_BRIGHTNESS_MISSING');
      return sum+catalog[s.name][k]*(BRIGHTNESS[s.brightness]??1)*weightedProximity(s.palace,targets)/divisor;
    },0));
    parts.push([weight,evidence(...values.map(clamp),1)]);
  }
  const transformed=[],layerDetails={};
  const natalEvents=stars.filter(s=>s.mutagen in TRANSFORMS).map(s=>({name:s.name,kind:s.mutagen,palace:s.palace}));
  const horoscope=chart.horoscope(date,timeIndex);
  for(const [layer,weight]of Object.entries(LAYERS)) {
    const data=horoscope[layer], index=layer==='natal'?null:data.index;
    if(index!==null&&index<0)continue;
    const events=layer==='natal'?natalEvents:data.mutagen.map((name,i)=>({name,kind:['禄','权','科','忌'][i],palace:stars.find(s=>s.name===name)?.palace}));
    if(events.length!==4||events.some(e=>e.palace==null)||new Set(events.map(e=>e.kind)).size!==4)throw new Error('ZIWEI_TRANSFORM_CATALOG_MISMATCH');
    // The natal layer is measured against the category's target palaces; the
    // time layers keep their own horoscope palace.
    const reach=e=>index===null?weightedProximity(e.palace,targets):proximity(e.palace,index);
    const v=[0,1].map(k=>clamp(events.reduce((sum,e)=>sum+reach(e)*TRANSFORMS[e.kind][k]/2,0)));
    transformed.push([weight,evidence(...v,1)]);
    layerDetails[layer]={target:index===null?targets.map(t=>({palace:t.palace,index:t.index,weight:t.weight})):index,events};
  }
  parts.push([.35,blend(transformed)]);
  return {evidence:blend(parts),layers:layerDetails,category,
    targetPalaces:targets.map(t=>({palace:t.palace,aliases:t.aliases,index:t.index,weight:t.weight})),
    lifePalace:chart.palaces.findIndex(p=>p.name==='命宫'),bodyPalace:chart.palaces.findIndex(p=>p.isBodyPalace),
    majorCount:14,auxiliaryCount:12};
}
export function scoreZiWei(built,cal,category='general') {
  if(!built.charts.length)return moduleResult(evidence(),{reason:built.reason,category});
  const results=built.charts.map(entry=>({...scoreChart(entry.chart,cal.local.date,cal.hour.branch,category),birthHourIndex:entry.index,convention:entry.gender}));
  if(results.length===1)return moduleResult(results[0].evidence,{...results[0],rules:CONFIG,scenarioCount:1,method:'single_chart'});
  const ranges=Object.fromEntries(['a','c'].map(k=>[k,{min:Math.min(...results.map(r=>r.evidence[k])),max:Math.max(...results.map(r=>r.evidence[k]))}]));
  const conservative=k=>ranges[k].min>0?ranges[k].min:ranges[k].max<0?ranges[k].max:0;
  // Missing birth inputs and cross-scenario agreement are separate quantities.
  // The cap is explicit product policy, NOT a likelihood of any birth hour.
  const inputFactor=(built.unknownHour?.75:1)*(built.unknownConvention?.75:1);
  const q=Math.min(...results.map(r=>r.evidence.coverage))*inputFactor;
  return moduleResult(evidence(conservative('a'),conservative('c'),q),{method:'conservative_across_possible_charts',scenarioCount:results.length,
    unknownBirthHour:built.unknownHour,unknownConvention:built.unknownConvention,inputCoverageFactor:inputFactor,
    category,targetPalaces:results[0].targetPalaces,
    ranges,scenarioScores:results.map(({birthHourIndex,convention,evidence:e})=>({birthHourIndex,convention,...e})),rules:CONFIG},'scenario_analysis');
}
export function inspectZiWei(built) {
  return built.charts.map(({index,gender,chart})=>({birthHourIndex:index,convention:gender,
    // Provider chart is available for audit, but not needed by the app result.
    chart:JSON.parse(JSON.stringify(chart))}));
}
