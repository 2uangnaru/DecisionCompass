import { evidence, moduleResult } from './core.js';
const digits = n => [...String(n)].reduce((s, c) => s + Number(c), 0);
const r = n => 1 + ((n - 1) % 9);
const vectors = { 1:[.6,.6], 2:[-.2,-.3], 3:[.4,.2], 4:[.1,-.6], 5:[.3,.7], 6:[.1,-.5], 7:[-.6,-.2], 8:[.5,.1], 9:[-.2,.6] };
export function numerology(birthDate, currentDate) {
  const [by,bm,bd] = birthDate.split('-').map(Number), [y,m,d] = currentDate.split('-').map(Number);
  if (birthDate > currentDate) throw new Error('BIRTH_DATE_IN_FUTURE');
  const lifePath = r(digits(by)+digits(bm)+digits(bd)), personalYear = r(bm+bd+digits(y));
  const personalMonth = r(personalYear+m), personalDay = r(personalMonth+d);
  const numbers = [lifePath,personalYear,personalMonth,personalDay], weights = [.1,.15,.25,.5];
  return moduleResult(evidence(...[0,1].map(axis => numbers.reduce((s,n,i) => s+weights[i]*vectors[n][axis],0)),1),
    { lifePath, personalYear, personalMonth, personalDay, masterNumbers: false });
}
