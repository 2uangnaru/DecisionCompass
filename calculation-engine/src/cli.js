import {readFile} from 'node:fs/promises';
import {calculate,createCalculator} from './index.js';

// Offline JSON interface; no port is opened and no profile is stored.
try {
  const args=process.argv.slice(2),inspect=args.includes('--inspect');
  const path=args.find(a=>a!=='--inspect');
  let text;
  if(path)text=await readFile(path,'utf8');
  else {
    const chunks=[];let length=0;
    for await(const chunk of process.stdin){length+=chunk.length;if(length>65536)throw new Error('INPUT_EXCEEDS_64_KIB');chunks.push(chunk);}
    text=Buffer.concat(chunks).toString('utf8');
  }
  if(Buffer.byteLength(text)>65536)throw new Error('INPUT_EXCEEDS_64_KIB');
  const input=JSON.parse(text.replace(/^\uFEFF/,''));
  const result=inspect?createCalculator(input.profile).inspectBirthCharts():calculate(input);
  process.stdout.write(JSON.stringify(result,null,2)+'\n');
}catch(error){
  process.stderr.write(JSON.stringify({status:'error',error:error.message})+'\n');
  process.exitCode=1;
}
