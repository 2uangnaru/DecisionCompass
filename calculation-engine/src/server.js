/**
 * Local HTTP API around the calculation engine.
 *
 *   GET  /health        service + engine/ruleset versions
 *   POST /v1/readings   ReadingInput (see src/index.d.ts) -> raw ReadingResult
 *
 * Local development only: binds to 127.0.0.1 and nothing else, has no auth, no
 * rate limiting, no persistence and no TLS. Any other host is rejected before a
 * socket exists — see assertLoopbackHost. Read the "API cục bộ" section of
 * README.md before this is exposed anywhere beyond the developer machine.
 *
 * Privacy: request bodies carry birth data, so nothing from a request is ever
 * logged, echoed back, or included in an error response. Engine exception
 * messages stay inside this process; clients only ever see the generic codes in
 * ERRORS below.
 */
import { createServer } from 'node:http';
import { pathToFileURL } from 'node:url';
import { calculate, RULESET, VERSION } from './index.js';

export const SERVICE = 'decision-compass-calculation-api';
export const MAX_BODY_BYTES = 64 * 1024;
export const DEFAULT_PORT = 8787;
export const DEFAULT_HOST = '127.0.0.1';

const EMPTY_BODY = Buffer.alloc(0);

const JSON_HEADERS = Object.freeze({
  'content-type': 'application/json; charset=utf-8',
  'cache-control': 'no-store',
  'x-content-type-options': 'nosniff',
});

/** Stable, generic client-facing errors. No engine text is ever substituted in. */
const ERRORS = Object.freeze({
  invalid_json: { status: 400, message: 'The request body is not valid JSON.' },
  empty_body: { status: 400, message: 'A JSON request body is required.' },
  not_found: { status: 404, message: 'The requested resource does not exist.' },
  method_not_allowed: { status: 405, message: 'The requested method is not supported for this resource.' },
  unsupported_media_type: { status: 415, message: 'Content-Type must be application/json.' },
  payload_too_large: { status: 413, message: 'The request body exceeds the 64 KiB limit.' },
  diagnostics_not_available: { status: 422, message: 'Diagnostics output is not available from this API.' },
  invalid_reading_request: { status: 422, message: 'The reading request could not be processed.' },
  internal_error: { status: 500, message: 'The request could not be completed.' },
});

/** Engine invariants — these mean the engine failed, not the caller. */
const ENGINE_INTERNAL_CODES = new Set([
  'INVALID_EVIDENCE', 'INVALID_PILLAR', 'INVALID_SEGMENTS', 'SOLAR_TERM_RANGE',
  'ZIWEI_MAJOR_BRIGHTNESS_MISSING', 'ZIWEI_STAR_CATALOG_MISMATCH', 'ZIWEI_TRANSFORM_CATALOG_MISMATCH',
]);

/** Input rejections the engine raises before computing anything. */
const ENGINE_INPUT_CODES = new Set([
  'PROFILE_REQUIRED', 'MVP_CATEGORY_IS_GENERAL', 'SPATIAL_FENG_SHUI_OUT_OF_SCOPE',
  'CURRENT_TIMEZONE_UNAVAILABLE', 'BIRTH_DATE_IN_FUTURE', 'BIRTH_INSTANT_IN_FUTURE',
  'UTC_OR_OFFSET_REQUIRED', 'SUPPORTED_BIRTH_YEARS_1900_2099', 'SUPPORTED_READING_YEARS_1900_2099',
]);

function isInputError(error) {
  const code = typeof error?.message === 'string' ? error.message : '';
  if (ENGINE_INTERNAL_CODES.has(code) || code.startsWith('UNKNOWN_MODULE')) return false;
  return ENGINE_INPUT_CODES.has(code) || code.startsWith('INVALID_');
}

function sendJson(res, status, payload, extraHeaders) {
  if (res.writableEnded || res.headersSent) return;
  res.writeHead(status, { ...JSON_HEADERS, ...extraHeaders });
  res.end(JSON.stringify(payload));
}

function sendError(res, code, extraHeaders) {
  const { status, message } = ERRORS[code];
  sendJson(res, status, { error: { code, message } }, extraHeaders);
}

function isJsonContentType(value) {
  return typeof value === 'string' && value.split(';')[0].trim().toLowerCase() === 'application/json';
}

/**
 * Buffers the body up to MAX_BODY_BYTES. Past the limit it stops buffering and
 * discards what it already held, but keeps draining to the end of the stream so
 * that every oversized request — 65 KiB or 10 MiB — still receives the JSON 413
 * rather than a connection reset. The socket is never destroyed for size alone.
 *
 * Draining costs time on an abusive upload but never memory. A request/idle
 * timeout is the right control for that and is deliberately left to the
 * production hardening step (see README).
 */
function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let buffered = 0, tooLarge = false;
    req.on('data', chunk => {
      if (tooLarge) return; // Already over the limit: discard, but keep draining.
      if (buffered + chunk.length > MAX_BODY_BYTES) {
        // Release everything held so far; nothing above the limit is ever kept,
        // and the socket is left open so the 413 can actually be delivered.
        tooLarge = true;
        chunks.length = 0;
        buffered = 0;
        return;
      }
      buffered += chunk.length;
      chunks.push(chunk);
    });
    req.on('end', () => resolve({ tooLarge, body: tooLarge ? EMPTY_BODY : Buffer.concat(chunks) }));
    req.on('error', reject);
  });
}

async function handleReading(req, res) {
  if (!isJsonContentType(req.headers['content-type'])) return sendError(res, 'unsupported_media_type');

  let received;
  try {
    received = await readBody(req);
  } catch {
    return; // Client went away mid-upload; there is nobody left to answer.
  }
  if (received.tooLarge) return sendError(res, 'payload_too_large');
  if (received.body.length === 0) return sendError(res, 'empty_body');

  let input;
  try {
    input = JSON.parse(received.body.toString('utf8'));
  } catch {
    return sendError(res, 'invalid_json');
  }
  if (input === null || typeof input !== 'object' || Array.isArray(input)) {
    return sendError(res, 'invalid_reading_request');
  }
  if (input.diagnostics) return sendError(res, 'diagnostics_not_available');

  let reading;
  try {
    // Diagnostics stay off whatever arrives: per-module internals must not leave
    // this process even if the check above is ever relaxed.
    reading = calculate({ ...input, diagnostics: false });
  } catch (error) {
    return sendError(res, isInputError(error) ? 'invalid_reading_request' : 'internal_error');
  }
  sendJson(res, 200, reading);
}

function handleRequest(req, res) {
  const path = (req.url ?? '/').split('?')[0];
  if (path === '/health') {
    if (req.method !== 'GET') return sendError(res, 'method_not_allowed', { allow: 'GET' });
    return sendJson(res, 200, {
      service: SERVICE, status: 'ok', engineVersion: VERSION, rulesetVersion: RULESET,
    });
  }
  if (path === '/v1/readings') {
    if (req.method !== 'POST') return sendError(res, 'method_not_allowed', { allow: 'POST' });
    return handleReading(req, res);
  }
  return sendError(res, 'not_found');
}

/** Builds the server without binding it, so tests can pick an ephemeral port. */
export function createApiServer() {
  return createServer((req, res) => {
    try {
      const pending = handleRequest(req, res);
      if (pending && typeof pending.catch === 'function') {
        pending.catch(() => sendError(res, 'internal_error'));
      }
    } catch {
      sendError(res, 'internal_error');
    }
  });
}

export function resolvePort(raw = process.env.PORT) {
  if (raw === undefined || raw === null || raw === '') return DEFAULT_PORT;
  const port = Number(raw);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('INVALID_PORT');
  return port;
}

/**
 * Only the loopback address is ever bound. `0.0.0.0`, `::`, `localhost` (which
 * can resolve to a non-loopback record) and every LAN address are refused —
 * this API has no auth, so reachability off-box is the whole risk.
 */
export function assertLoopbackHost(host) {
  if (host !== DEFAULT_HOST) throw new Error('HOST_MUST_BE_LOOPBACK');
  return host;
}

/** Programmatic port: 0 means "ephemeral", which the env var deliberately refuses. */
function assertListenPort(port) {
  if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error('INVALID_PORT');
  return port;
}

export function startApiServer({ port = resolvePort(), host = DEFAULT_HOST } = {}) {
  return new Promise((resolve, reject) => {
    // Validate first: a rejected host must never reach createServer or listen.
    try {
      assertLoopbackHost(host);
      assertListenPort(port);
    } catch (error) {
      reject(error);
      return;
    }
    const server = createApiServer();
    server.once('error', reject);
    server.listen(port, DEFAULT_HOST, () => resolve(server));
  });
}

const entryPoint = process.argv[1] ? pathToFileURL(process.argv[1]).href : null;
if (import.meta.url === entryPoint) {
  let port;
  try {
    port = resolvePort();
  } catch {
    process.stderr.write('PORT must be an integer between 1 and 65535\n');
    process.exit(1);
  }
  // CLI never takes a host from anywhere: loopback is hard-coded.
  startApiServer({ port, host: DEFAULT_HOST }).then(server => {
    const bound = server.address();
    process.stdout.write(`${SERVICE} ${VERSION} on http://${bound.address}:${bound.port} (local development only)\n`);
  }).catch(() => {
    process.stderr.write(`Failed to bind ${DEFAULT_HOST}:${port}\n`);
    process.exit(1);
  });
}
