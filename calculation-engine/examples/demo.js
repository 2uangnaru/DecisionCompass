import {createCalculator} from '../src/index.js';

const engine=createCalculator({birthDate:'1998-06-21',birthTime:'14:30',birthCountry:'VN',traditionalProfile:'male'});
const result=engine.calculate({context:{instantUtc:'2026-09-18T08:30:00Z',deviceTimezone:'Asia/Ho_Chi_Minh',
  location:{latitude:10.7769,longitude:106.7009,accuracyMeters:100,capturedAtUtc:'2026-09-18T08:29:45Z'}},period:'evening',mode:'yes_no'});
console.log(JSON.stringify({engineVersion:result.engineVersion,status:result.status,percentages:result.percentages,
  coverage:result.dataCoverage,timezone:result.context.timezone,timezoneSource:result.context.zoneSource,
  birthData:result.birthData,luckyWindows:result.luckyWindows,modules:result.segments[0].modules},null,2));
