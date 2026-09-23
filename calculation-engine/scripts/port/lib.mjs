// Shared helpers for the Dart-port code generators.
//
// These scripts read the pinned upstream provider packages in `node_modules`
// and emit Dart source under `mobile_app/lib/local_engine/`. Nothing here
// invents data: every table is copied verbatim from the provider that the Node
// engine already uses, so the Dart engine and the Node engine share one source
// of truth. Re-run them after bumping a provider version.

import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

export const ENGINE_ROOT = resolve(fileURLToPath(new URL('../../', import.meta.url)));
export const DART_ROOT = resolve(ENGINE_ROOT, '../mobile_app/lib/local_engine');
export const FIXTURE_ROOT = resolve(ENGINE_ROOT, '../mobile_app/test/local_engine');

/** Writes a generated Dart file, creating parent directories as needed. */
export function emit(relativePath, body) {
  const target = resolve(DART_ROOT, relativePath);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, body, 'utf8');
  return target;
}

export function emitFixture(relativePath, body) {
  const target = resolve(FIXTURE_ROOT, relativePath);
  mkdirSync(dirname(target), { recursive: true });
  writeFileSync(target, body, 'utf8');
  return target;
}

export function header(source) {
  return `// GENERATED FILE — DO NOT EDIT BY HAND.
//
// Produced by \`calculation-engine/scripts/port/${source}\` from the pinned
// upstream provider package. See \`calculation-engine/THIRD_PARTY.md\` and
// \`mobile_app/lib/local_engine/LICENSES.md\` for attribution and licensing.
`;
}

/** Formats a JS number as a Dart double literal without losing precision. */
export function dartDouble(value) {
  if (!Number.isFinite(value)) throw new Error(`NON_FINITE_LITERAL:${value}`);
  if (Object.is(value, -0)) return '-0.0';
  // Round-trip through the shortest representation JS prints, then make sure
  // Dart reads it as a double rather than an int.
  const text = String(value);
  if (/[.eE]/.test(text)) return text;
  return `${text}.0`;
}

export function dartInt(value) {
  if (!Number.isSafeInteger(value)) throw new Error(`NON_INTEGER_LITERAL:${value}`);
  return String(value);
}

export function dartString(value) {
  return JSON.stringify(value);
}

/** Wraps a long flat list of literals so the analyzer stays fast. */
export function wrapList(literals, perLine = 8, indent = '  ') {
  const lines = [];
  for (let i = 0; i < literals.length; i += perLine) {
    lines.push(indent + literals.slice(i, i + perLine).join(', ') + ',');
  }
  return lines.join('\n');
}
