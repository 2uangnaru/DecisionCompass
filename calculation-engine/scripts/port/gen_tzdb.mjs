// Emits the moment-timezone packed IANA database as Dart source.
//
// The packed strings are copied verbatim from
// `moment-timezone/data/packed/latest.json`, so the Dart unpacker sees exactly
// the transitions, links and country mappings the Node engine sees, including
// the `version` string that the engine reports as `providers.tzdb`.

import { createRequire } from 'node:module';
import { emit, header, dartString, ENGINE_ROOT } from './lib.mjs';

const require = createRequire(`${ENGINE_ROOT}/`);
const packed = require('moment-timezone/data/packed/latest.json');

function block(name, values) {
  const lines = values.map((value) => `  ${dartString(value)},`).join('\n');
  return `const List<String> ${name} = <String>[\n${lines}\n];\n`;
}

const body = `${header('gen_tzdb.mjs')}
/// Version string of the bundled IANA time zone database, reported verbatim as
/// \`providers.tzdb\` and \`context.tzdbVersion\`.
const String tzdbVersion = ${dartString(packed.version)};

/// Packed zone records, one per IANA zone, in moment-timezone's own format:
/// \`name|abbrs|offsets|indices|untils|population\`.
${block('tzdbPackedZones', packed.zones)}
/// Zone links, \`canonical|alias\`.
${block('tzdbPackedLinks', packed.links)}
/// Country-to-zone mappings, \`CC|zone|zone|...\`.
${block('tzdbPackedCountries', packed.countries)}`;

const target = emit('time/tzdb_data.dart', body);
process.stdout.write(
  `tzdb ${packed.version}: ${packed.zones.length} zones, ${packed.links.length} links, ` +
    `${packed.countries.length} countries -> ${target}\n`,
);
