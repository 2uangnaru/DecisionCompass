import { evidence, blend, moduleResult, mod, clamp } from './core.js';
import { natalPillars, pillar, termsAround } from './calendar.js';
import { cyclical, addCivil } from './time.js';

export const HIDDEN = [[9],[5,9,7],[0,2,4],[1],[4,1,9],[2,6,4],[3,5],[5,3,1],[6,8,4],[7],[4,7,3],[8,0]];
const GOD_IDS = [['peer','competitor'],['expression','challenge'],['opportunity','stewardship'],['pressure','responsibility'],['reflection','support']];
const GODS = {peer:[.1,-.25],competitor:[.05,.25],expression:[.3,.25],challenge:[.1,.4],opportunity:[.2,.35],stewardship:[.15,-.2],pressure:[-.25,.2],responsibility:[.1,-.15],reflection:[-.2,-.1],support:[.2,-.2]};
const LAYERS={decade:.10,yearly:.15,monthly:.15,daily:.30,hourly:.30};
const COMBINATIONS=[[0,1],[2,11],[3,10],[4,9],[5,8],[6,7]];
const HARMS=[[0,7],[1,6],[2,5],[3,4],[8,11],[9,10]];
const BREAKS=[[0,9],[1,4],[2,11],[3,6],[5,8],[7,10]];
const inPairs=(a,b,rows)=>rows.some(([x,y])=>(a===x&&b===y)||(a===y&&b===x));
export function tenGod(day,other) {return GOD_IDS[mod(Math.floor(other/2)-Math.floor(day/2),5)][day%2===other%2?0:1];}
export function relations(a,b) {
  const result=[];
  if(a===b) result.push('same');
  if(mod(a-b,12)===6) result.push('clash');
  if(inPairs(a,b,COMBINATIONS)) result.push('combination');
  if(inPairs(a,b,HARMS)) result.push('harm');
  if(inPairs(a,b,BREAKS)) result.push('break');
  if(inPairs(a,b,[[0,3]])) result.push('punishment');
  if(a===b&&[4,6,9,11].includes(a)) result.push('self_punishment');
  return result;
}
function branchVector(a,b) {
  // v2 scoring preserved. Additional relations are diagnostics until separately
  // weighted; overlapping relations must not accidentally be counted twice.
  if(a===b)return [.1,-.2];
  if(mod(a-b,12)===6)return [-.5,.5];
  if(inPairs(a,b,COMBINATIONS))return [.5,-.4];
  return [0,0];
}
export function buildBaZi(birth,traditionalProfile) {
  const pillars=natalPillars(birth), dm=pillars[2].stem, dmElement=Math.floor(dm/2);
  const mass=[0,0,0,0,0], weights=[1,1.5,1,1];let present=0;
  const gods=pillars.map((p,i)=>{
    if(!p)return null;
    present+=weights[i];mass[Math.floor(p.stem/2)]+=.4*weights[i];
    for(const s of HIDDEN[p.branch])mass[Math.floor(s/2)]+=.6*weights[i]/HIDDEN[p.branch].length;
    return {visible:tenGod(dm,p.stem),hidden:HIDDEN[p.branch].map(s=>({stem:s,god:tenGod(dm,s)}))};
  });
  const distribution=mass.map(v=>v/present);
  const branches=pillars.filter(Boolean).map(p=>p.branch), structures=[];
  for(const set of [[8,0,4],[11,3,7],[2,6,10],[5,9,1]])if(set.every(b=>branches.includes(b)))structures.push({type:'three_harmony',branches:set,transformationConfirmed:false});
  for(const set of [[2,5,8],[1,10,7]])if(set.every(b=>branches.includes(b)))structures.push({type:'three_punishment',branches:set});
  const pairs=[];
  for(let i=0;i<4;i++)for(let j=i+1;j<4;j++)if(pillars[i]&&pillars[j]) {
    pairs.push({positions:[i,j],branches:relations(pillars[i].branch,pillars[j].branch),
      stemCombination:mod(pillars[i].stem-pillars[j].stem,10)===5,transformationConfirmed:false});
  }
  // A season-adjusted descriptive index. Do not equate it to a certified Yong Shen.
  const month=pillars[1], seasonal=distribution.slice();
  if(month) {
    const seasonElement=Math.floor(HIDDEN[month.branch][0]/2);
    const factors=[1,.8,.5,.4,.6];
    for(let e=0;e<5;e++)seasonal[e]*=factors[mod(e-seasonElement,5)];
    const total=seasonal.reduce((a,b)=>a+b,0);for(let e=0;e<5;e++)seasonal[e]/=total;
  }
  const support=seasonal[dmElement]+seasonal[mod(dmElement-1,5)];
  const chart={pillars,tenGods:gods,elementDistribution:distribution,seasonalDistribution:seasonal,
    supportIndex:support,strengthMethod:'descriptive_seasonal_index_not_yong_shen',
    rootPositions:pillars.flatMap((p,i)=>p&&HIDDEN[p.branch].some(s=>Math.floor(s/2)===dmElement)?[i]:[]),
    structures,pairs,traditionalYongShen:null,traditionalXiShen:null,coverage:present/4.5,
    missing:pillars.flatMap((p,i)=>p?[]:[['year','month','day','hour'][i]]),decade:null};
  if(birth.exact&&pillars[0]&&pillars[1]&&['male','female'].includes(traditionalProfile)) {
    const instant=birth.intervals[0].start, zone=birth.intervals[0].zone;
    const forward=(pillars[0].stem%2===0)===(traditionalProfile==='male');
    const terms=termsAround(instant).filter(t=>t.monthIndex>=0);
    const term=forward?terms.find(t=>t.instant>instant):terms.filter(t=>t.instant<=instant).at(-1);
    let minutes=Math.floor(Math.abs(term.instant-instant)/60000);
    const years=Math.floor(minutes/4320);minutes%=4320;
    const months=Math.floor(minutes/360);minutes%=360;
    const days=Math.floor(minutes/12),hours=(minutes%12)*2;
    chart.decade={forward,startUtc:addCivil(instant,zone,years,months,days,hours),birthZone:zone,
      startAge:{years,months,days,hours},method:'three_days_one_year_minute_resolution',referenceTerm:term};
  }
  return chart;
}
export function decadeAt(chart,ms) {
  const d=chart.decade;
  if(!d||ms<d.startUtc)return null;
  let n=1;
  while(n<20&&ms>=addCivil(d.startUtc,d.birthZone,n*10))n++;
  const cycle=mod(cyclical(chart.pillars[1].stem,chart.pillars[1].branch)+(d.forward?n:-n),60);
  return {pillar:pillar(cycle%10,cycle%12),index:n,startUtc:addCivil(d.startUtc,d.birthZone,(n-1)*10),endUtc:addCivil(d.startUtc,d.birthZone,n*10)};
}
export function scoreBaZi(chart,cal,ms) {
  const dm=chart.pillars[2].stem, known=chart.pillars.map((p,i)=>({p,w:[.1,.2,.5,.2][i]})).filter(x=>x.p);
  const total=known.reduce((s,x)=>s+x.w,0), decade=decadeAt(chart,ms);
  const timing={yearly:cal.year,monthly:cal.month,daily:cal.day,hourly:cal.hour};
  if(decade)timing.decade=decade.pillar;
  const parts=[],layerDiagnostics={};
  for(const [name,p]of Object.entries(timing)) {
    const stems=[[.4,p.stem],...HIDDEN[p.branch].map(s=>[.6/HIDDEN[p.branch].length,s])];
    const gv=[0,1].map(k=>stems.reduce((sum,[w,s])=>sum+w*GODS[tenGod(dm,s)][k],0));
    const bv=[0,1].map(k=>known.reduce((sum,{w,p:n})=>sum+w/total*branchVector(p.branch,n.branch)[k],0));
    // The 15% favorable-element component stays absent: no manufactured Yong Shen.
    const e=blend([[.55,evidence(...gv,1)],[.30,evidence(...bv,1)]]);
    e.coverage*=chart.coverage;
    parts.push([LAYERS[name],e]);
    layerDiagnostics[name]={pillar:p,relations:known.map(({p:n})=>relations(p.branch,n.branch))};
  }
  return moduleResult(blend(parts),{chart,activeDecade:decade,layers:layerDiagnostics,
    excludedRules:['automatic_yong_shen','special_chart_transformations'],method:'bazi_expanded_v2_generated_inputs'});
}
