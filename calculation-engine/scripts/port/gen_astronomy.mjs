// Emits the Astronomy Engine tables the calculation engine needs, as Dart.
//
// Only the bodies the engine actually asks for are exported: the VSOP87
// truncated series for Mercury, Venus, Earth, Mars, Jupiter and Saturn, and the
// Montenbruck/Pfleger lunar series. Uranus, Neptune, Pluto and the star catalog
// are left out, because `src/astronomy.js` never reaches them and the APK
// should not carry tables it cannot use.
//
// The table text is read out of the pinned `astronomy-engine` source and
// re-emitted, so the numeric literals — and therefore the double-precision
// results — are identical. The `AddSol` / `ADDN` rows keep their original
// order, because floating-point summation is not associative.

import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { emit, header, dartDouble, dartInt, ENGINE_ROOT } from './lib.mjs';

const SOURCE = resolve(ENGINE_ROOT, 'node_modules/astronomy-engine/astronomy.js');
const source = readFileSync(SOURCE, 'utf8');

const BODIES = ['Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter', 'Saturn'];

/** Extracts a balanced `{...}` or `[...]` literal beginning at `start`. */
function balanced(text, start, open, close) {
  let depth = 0;
  for (let i = start; i < text.length; i++) {
    if (text[i] === open) depth++;
    else if (text[i] === close) {
      depth--;
      if (depth === 0) return text.slice(start, i + 1);
    }
  }
  throw new Error('UNBALANCED_LITERAL');
}

const vsopStart = source.indexOf('const vsop = {');
if (vsopStart < 0) throw new Error('VSOP_TABLE_NOT_FOUND');
const vsopLiteral = balanced(source, source.indexOf('{', vsopStart), '{', '}');
// eslint-disable-next-line no-eval
const vsop = (0, eval)(`(${vsopLiteral})`);

for (const body of BODIES) {
  if (!Array.isArray(vsop[body]) || vsop[body].length !== 3) {
    throw new Error(`VSOP_BODY_SHAPE:${body}`);
  }
}

function seriesToDart(series) {
  const terms = series
    .map((term) => {
      if (term.length !== 3) throw new Error('VSOP_TERM_SHAPE');
      return `      [${term.map(dartDouble).join(', ')}],`;
    })
    .join('\n');
  return `    <List<double>>[\n${terms}\n    ],`;
}

function modelToDart(model) {
  const formulas = model
    .map((formula) => `  <List<List<double>>>[\n${formula.map(seriesToDart).join('\n')}\n  ],`)
    .join('\n');
  return `<List<List<List<double>>>>[\n${formulas}\n]`;
}

let termCount = 0;
const vsopEntries = BODIES.map((body) => {
  for (const formula of vsop[body]) for (const series of formula) termCount += series.length;
  return `  '${body}': ${modelToDart(vsop[body])},`;
}).join('\n');

// --- Lunar series -----------------------------------------------------------

function extractCalls(name, arity) {
  const pattern = new RegExp(`${name}\\(([^)]*)\\)`, 'g');
  const calls = [];
  const body = source.slice(source.indexOf('function CalcMoon(time)'), source.indexOf('class LibrationInfo'));
  let match;
  while ((match = pattern.exec(body)) !== null) {
    const args = match[1].split(',').map((part) => part.trim());
    if (args.length !== arity) continue; // the declaration itself, not a call
    if (args.some((part) => !/^[+-]?(\d+\.?\d*(E-?\d+)?|\.\d+)$/i.test(part))) continue;
    calls.push(args.map(Number));
  }
  return calls;
}

const addSol = extractCalls('AddSol', 8);
const addN = extractCalls('ADDN', 5);
if (addSol.length !== 104) throw new Error(`ADDSOL_COUNT:${addSol.length}`);
if (addN.length !== 10) throw new Error(`ADDN_COUNT:${addN.length}`);

const addSolRows = addSol
  .map((row) => `  [${row.slice(0, 4).map(dartDouble).join(', ')}, ` +
    `${row.slice(4).map(dartInt).join(', ')}],`)
  .join('\n');

const addNRows = addN
  .map((row) => `  [${dartDouble(row[0])}, ${row.slice(1).map(dartInt).join(', ')}],`)
  .join('\n');

const body = `${header('gen_astronomy.mjs')}
/// VSOP87 truncated series for the six bodies the engine needs, indexed
/// `+ '`[longitude, latitude, radius][power][term] = [amplitude, phase, frequency]`.' + `
///
/// Copied verbatim from Astronomy Engine 2.1.19 (MIT). Uranus, Neptune and
/// Pluto are intentionally absent: nothing in the reading path uses them.
const Map<String, List<List<List<List<double>>>>> vsopModels =
    <String, List<List<List<List<double>>>>>{
${vsopEntries}
};

/// \`AddSol(coeffl, coeffs, coeffg, coeffp, p, q, r, s)\` rows, in source order.
/// Summation order is preserved because it changes the last bits of the result.
const List<List<num>> moonAddSol = <List<num>>[
${addSolRows}
];

/// \`ADDN(coeffn, p, q, r, s)\` rows, in source order.
const List<List<num>> moonAddN = <List<num>>[
${addNRows}
];
`;

const target = emit('astronomy/astronomy_data.dart', body);
process.stdout.write(
  `astronomy: ${BODIES.length} VSOP bodies, ${termCount} terms, ` +
    `${addSol.length} AddSol rows, ${addN.length} ADDN rows -> ${target}\n`,
);
