import lunar from 'lunar-javascript';
import { localAt, hourBranch, HOUR, DAY } from './time.js';
import { mod, boundedCache, evidence, moduleResult } from './core.js';

const { Solar, LunarUtil } = lunar;
export const STEMS = [...'甲乙丙丁戊己庚辛壬癸'];
export const BRANCHES = [...'子丑寅卯辰巳午未申酉戌亥'];
const JIE = ['立春', '惊蛰', '清明', '立夏', '芒种', '小暑', '立秋', '白露', '寒露', '立冬', '大雪', '小寒'];
const termCache = boundedCache(210), civilCache = boundedCache(512);
export function solarTerms(year) {
  if (termCache.get(year)) return termCache.get(year);
  const table = Solar.fromYmd(year, 6, 1).getLunar().getJieQiTable();
  // Provider tables use the fixed UTC+08 Chinese calendar reference meridian.
  // Do not parse these strings in the machine's timezone or historical Shanghai DST.
  const result = Object.entries(table).filter(([name, s]) => !/[A-Z_]/.test(name) && s.getYear() === year)
    .map(([name, s]) => ({ name, instant: Date.UTC(s.getYear(), s.getMonth() - 1, s.getDay(), s.getHour(), s.getMinute(), s.getSecond()) - 8 * HOUR,
      monthIndex: JIE.indexOf(name) })).sort((a, b) => a.instant - b.instant);
  // Dong Zhi is exported as DONG_ZHI for the current calendar year in this provider.
  if (!result.some(t => t.name === '冬至' && new Date(t.instant).getUTCFullYear() === year)) {
    const s = table.DONG_ZHI;
    if (s?.getYear() === year) result.push({ name: '冬至', instant: Date.UTC(year, s.getMonth() - 1, s.getDay(), s.getHour(), s.getMinute(), s.getSecond()) - 8 * HOUR, monthIndex: -1 });
  }
  return termCache.set(year, result.sort((a, b) => a.instant - b.instant));
}
export function termsAround(ms) {
  const year = new Date(ms).getUTCFullYear();
  return [year - 1, year, year + 1].flatMap(solarTerms).sort((a, b) => a.instant - b.instant);
}
export function pillar(stem, branch) {
  if (!Number.isInteger(stem) || stem < 0 || stem > 9 || !Number.isInteger(branch) || branch < 0 || branch > 11 || stem % 2 !== branch % 2) throw new Error('INVALID_PILLAR');
  return { stem, branch, text: STEMS[stem] + BRANCHES[branch] };
}
export function civilCalendar(date) {
  if (civilCache.get(date)) return civilCache.get(date);
  const [y, m, d] = date.split('-').map(Number);
  const l = Solar.fromYmd(y, m, d).getLunar();
  return civilCache.set(date, { lunar: { year: l.getYear(), month: Math.abs(l.getMonth()), day: l.getDay(), leap: l.getMonth() < 0 },
    day: pillar(l.getDayGanIndexExact2(), l.getDayZhiIndexExact2()) });
}
export function solarPillars(ms) {
  const terms = termsAround(ms);
  const spring = terms.filter(t => t.name === '立春' && t.instant <= ms).at(-1);
  const jie = terms.filter(t => t.monthIndex >= 0 && t.instant <= ms).at(-1);
  if (!spring || !jie) throw new Error('SOLAR_TERM_RANGE');
  const year = new Date(spring.instant).getUTCFullYear();
  const stem = mod(year - 4, 10), branch = mod(year - 4, 12), n = jie.monthIndex;
  return { year: pillar(stem, branch), month: pillar(mod((stem % 5) * 2 + 2 + n, 10), mod(2 + n, 12)),
    latestJie: jie, solarYear: year };
}
export function calendarAt(ms, zone) {
  const local = localAt(ms, zone), civil = civilCalendar(local.date), solar = solarPillars(ms);
  const branch = hourBranch(local.hour), hour = pillar(mod(2 * (civil.day.stem % 5) + branch, 10), branch);
  return { local, lunar: civil.lunar, year: solar.year, month: solar.month, day: civil.day, hour,
    solarYear: solar.solarYear, latestJie: solar.latestJie };
}
export function natalPillars(birth) {
  const day = civilCalendar(birth.date).day;
  let year = null, month = null;
  if (birth.intervals.length) {
    const candidates = birth.intervals.flatMap(i => {
      const breaks = termsAround(i.start).filter(t => t.monthIndex >= 0 && t.instant > i.start && t.instant <= i.end);
      return [i.start, i.end, ...breaks.map(t => t.instant)].map(solarPillars);
    });
    if (candidates.every(c => c.year.text === candidates[0].year.text)) year = candidates[0].year;
    if (candidates.every(c => c.month.text === candidates[0].month.text)) month = candidates[0].month;
  }
  let hour = null;
  if (birth.clock && birth.status !== 'birth_time_nonexistent') {
    const branch = hourBranch(Number(birth.clock.slice(0, 2)));
    hour = pillar(mod(2 * (day.stem % 5) + branch, 10), branch);
  }
  return [year, month, day, hour];
}
const OFFICER_VECTORS = [[.3,.3],[.1,.7],[.1,-.3],[0,0],[.2,-.7],[.1,-.6],[-.5,.7],[-.5,0],[.5,.2],[.3,-.3],[.4,.6],[-.3,-.5]];
const OFFICER_IDS = ['establish','remove','full','balance','stable','hold','break','danger','success','receive','open','close'];
export function almanac(cal) {
  const god = (baseBranch, selectedBranch) => {
    const name = LunarUtil.TIAN_SHEN[mod(selectedBranch + LunarUtil.ZHI_TIAN_SHEN_OFFSET[BRANCHES[baseBranch]], 12) + 1];
    return { name, auspicious: LunarUtil.TIAN_SHEN_TYPE[name] === '黄道' };
  };
  const dayGod = god(cal.month.branch, cal.day.branch), hourGod = god(cal.day.branch, cal.hour.branch);
  const officer = mod(cal.day.branch - cal.month.branch, 12), v = OFFICER_VECTORS[officer];
  return moduleResult(evidence(.25 * (dayGod.auspicious ? .5 : -.5) + .40 * (hourGod.auspicious ? .5 : -.5) + .35 * v[0], v[1], 1),
    { dayGod, hourGod, officer: OFFICER_IDS[officer], rules: 'solar-month-exact/civil-day-midnight', calendar: cal });
}
export function nearbyBoundaries(ms) {
  return termsAround(ms).filter(t => Math.abs(t.instant - ms) < 3 * DAY).map(t => t.instant);
}
