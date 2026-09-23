import test, { after, before } from 'node:test';
import assert from 'node:assert/strict';
import { createApiServer, DEFAULT_HOST, MAX_BODY_BYTES, SERVICE, startApiServer } from '../src/server.js';
import { RULESET, VERSION } from '../src/index.js';

const PROFILE = { birthDate: '1998-06-21', birthTime: '14:30', birthCountry: 'VN', traditionalProfile: 'male' };
const CONTEXT = { instantUtc: '2026-09-18T08:30:00Z', deviceTimezone: 'Asia/Ho_Chi_Minh' };
const request = (overrides = {}) => ({ profile: PROFILE, context: CONTEXT, mode: 'yes_no', period: 'now', ...overrides });

let server, base;

before(async () => {
  server = createApiServer();
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  base = `http://127.0.0.1:${server.address().port}`;
});

after(() => new Promise(resolve => server.close(resolve)));

function post(body, headers = {}) {
  return fetch(`${base}/v1/readings`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...headers },
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });
}

function assertJsonHeaders(response) {
  assert.equal(response.headers.get('content-type'), 'application/json; charset=utf-8');
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
}

async function assertGenericError(response, status, code) {
  assert.equal(response.status, status);
  assertJsonHeaders(response);
  const payload = await response.json();
  assert.deepEqual(Object.keys(payload), ['error']);
  assert.deepEqual(Object.keys(payload.error).sort(), ['code', 'message']);
  assert.equal(payload.error.code, code);
  return JSON.stringify(payload);
}

test('health reports the engine version and ruleset from the engine itself', async () => {
  const response = await fetch(`${base}/health`);
  assert.equal(response.status, 200);
  assertJsonHeaders(response);
  assert.deepEqual(await response.json(), {
    service: SERVICE, status: 'ok', engineVersion: VERSION, rulesetVersion: RULESET,
  });
  // Bumped with the expanded full-day energy tones.
  assert.equal(VERSION, '3.4.0-mvp');
  assert.equal(RULESET, 'civil-midnight-chinese-calendar-symbolic-v7');
});

test('a YES/NO NOW request returns a real engine reading', async () => {
  const response = await post(request());
  assert.equal(response.status, 200);
  assertJsonHeaders(response);
  const reading = await response.json();
  assert.equal(reading.mode, 'yes_no');
  assert.equal(reading.period, 'now');
  assert.equal(reading.status, 'ready');
  assert.equal(reading.engineVersion, VERSION);
  assert.equal(reading.rulesetVersion, RULESET);
  assert.equal(reading.percentages.YES + reading.percentages.NO, 100);
  assert.equal(reading.luckyWindows.length, 0);
  assert.equal(reading.windowStatus, 'not_applicable');
  assert.match(reading.readingKey, /^[0-9a-f]{64}$/);
  assert.equal(reading.context.timezone, 'Asia/Ho_Chi_Minh');
  assert.ok(Array.isArray(reading.warnings));
  assert.ok(reading.dailyBrief.colorInspiration.length > 0);
  assert.ok(reading.inputSnapshot.profile.birthDate === PROFILE.birthDate);
});

test('FORWARD/BACKWARD keeps its own mode and percentages', async () => {
  const response = await post(request({ mode: 'forward_backward', period: 'evening' }));
  assert.equal(response.status, 200);
  const reading = await response.json();
  assert.equal(reading.mode, 'forward_backward');
  assert.equal(reading.modeBasis, 'temporal_momentum');
  assert.equal(reading.percentages.FORWARD + reading.percentages.BACKWARD, 100);
  assert.equal(typeof reading.modeScore, 'number');
  assert.ok(reading.luckyWindows.length > 0);
});

test('LEFT/RIGHT keeps its own mode and percentages', async () => {
  const response = await post(request({ mode: 'left_right', period: 'evening' }));
  assert.equal(response.status, 200);
  const reading = await response.json();
  assert.equal(reading.mode, 'left_right');
  assert.equal(reading.modeBasis, 'symbolic_polarity');
  assert.equal(reading.percentages.LEFT + reading.percentages.RIGHT, 100);
});

test('the same request twice returns the same readingKey and result', async () => {
  const [first, second] = await Promise.all([post(request()), post(request())]);
  const [a, b] = await Promise.all([first.json(), second.json()]);
  assert.equal(a.readingKey, b.readingKey);
  assert.deepEqual(a, b);
});

test('invalid JSON is rejected with 400', async () => {
  await assertGenericError(await post('{"profile": '), 400, 'invalid_json');
});

test('an empty body is rejected with 400', async () => {
  await assertGenericError(await post(''), 400, 'empty_body');
});

test('a non-JSON Content-Type is rejected with 415', async () => {
  const response = await post(request(), { 'content-type': 'text/plain' });
  await assertGenericError(response, 415, 'unsupported_media_type');
});

test('a JSON Content-Type with parameters is still accepted', async () => {
  const response = await post(request(), { 'content-type': 'application/json; charset=utf-8' });
  assert.equal(response.status, 200);
});

test('diagnostics:true is rejected with 422', async () => {
  const response = await post(request({ diagnostics: true }));
  await assertGenericError(response, 422, 'diagnostics_not_available');
});

test('diagnostics:false is accepted and never returns module internals', async () => {
  const response = await post(request({ diagnostics: false, period: 'evening' }));
  assert.equal(response.status, 200);
  const reading = await response.json();
  for (const segment of reading.segments) {
    for (const module of Object.values(segment.modules)) {
      assert.equal(module.diagnostics, undefined);
    }
  }
});

test('invalid engine input returns 422 without leaking engine errors', async () => {
  const cases = [
    request({ profile: { ...PROFILE, birthDate: '1998-13-45' } }),
    request({ profile: undefined }),
    request({ mode: 'up_down' }),
    request({ period: 'tomorrow' }),
    request({ context: { ...CONTEXT, deviceTimezone: 'Not/AZone' } }),
    request({ category: 'medical' }),
  ];
  for (const body of cases) {
    const serialized = await assertGenericError(await post(body), 422, 'invalid_reading_request');
    assert.doesNotMatch(serialized, /INVALID_|PROFILE_REQUIRED|MVP_CATEGORY/);
  }
});

test('every oversized body gets a JSON 413, whatever its size', async () => {
  // Just over the limit, well past the old internal abort threshold, and past
  // 1 MiB: all three must answer identically instead of resetting the socket.
  const sizes = [MAX_BODY_BYTES + 1024, 512 * 1024 + 1024, 1024 * 1024 + 1024];
  for (const size of sizes) {
    const oversized = JSON.stringify(request({ filler: 'x'.repeat(size) }));
    assert.ok(Buffer.byteLength(oversized) > MAX_BODY_BYTES);

    const response = await post(oversized);
    await assertGenericError(response, 413, 'payload_too_large');
    assert.equal(response.headers.get('cache-control'), 'no-store');
    assert.equal(response.headers.get('x-content-type-options'), 'nosniff');

    // The server stays healthy between oversized uploads, not just after them.
    const recovered = await post(request());
    assert.equal(recovered.status, 200, `serving broke after a ${size} byte body`);
    assert.equal((await recovered.json()).status, 'ready');
  }
});

test('an oversized body never leaks request content', async () => {
  const oversized = JSON.stringify(request({ filler: 'x'.repeat(2 * 1024 * 1024) }));
  const body = await (await post(oversized)).text();
  for (const needle of ['1998-06-21', '14:30', 'birthDate', 'xxxx', 'inputSnapshot', '.js:']) {
    assert.ok(!body.includes(needle), `413 body leaked "${needle}"`);
  }
  assert.ok(body.length < 200);
});

test('an unknown path returns 404', async () => {
  await assertGenericError(await fetch(`${base}/v1/unknown`), 404, 'not_found');
  await assertGenericError(await fetch(`${base}/`), 404, 'not_found');
});

test('a wrong method on a known route returns 405 with Allow', async () => {
  const readings = await fetch(`${base}/v1/readings`);
  await assertGenericError(readings, 405, 'method_not_allowed');
  assert.equal(readings.headers.get('allow'), 'POST');

  const health = await fetch(`${base}/health`, { method: 'POST' });
  await assertGenericError(health, 405, 'method_not_allowed');
  assert.equal(health.headers.get('allow'), 'GET');
});

test('the server keeps serving valid requests after malformed ones', async () => {
  await post('{not json');
  await post('');
  await post(request(), { 'content-type': 'text/plain' });
  await fetch(`${base}/nope`);
  await post(request({ mode: 'up_down' }));

  const response = await post(request());
  assert.equal(response.status, 200);
  assert.equal((await response.json()).status, 'ready');

  const health = await fetch(`${base}/health`);
  assert.equal(health.status, 200);
});

test('startApiServer binds the loopback address only', async () => {
  const started = await startApiServer({ port: 0 });
  try {
    const bound = started.address();
    assert.equal(bound.address, DEFAULT_HOST);
    assert.equal(DEFAULT_HOST, '127.0.0.1');
    assert.ok(bound.port > 0);

    const response = await fetch(`http://127.0.0.1:${bound.port}/health`);
    assert.equal(response.status, 200);
  } finally {
    await new Promise(resolve => started.close(resolve));
  }
});

test('a non-loopback host is refused before anything starts listening', async () => {
  for (const host of ['0.0.0.0', '::', '::1', 'localhost', '192.168.1.10', '10.0.0.5', '127.0.0.2', '', null]) {
    await assert.rejects(
      () => startApiServer({ port: 0, host }),
      error => {
        // The exact sentinel proves validation short-circuited: an actual bind
        // attempt would surface an OS error such as EADDRNOTAVAIL instead.
        assert.equal(error.message, 'HOST_MUST_BE_LOOPBACK');
        assert.equal(error.code, undefined);
        return true;
      },
      `host ${JSON.stringify(host)} must be refused`,
    );
  }
});

test('an out-of-range port is refused before anything starts listening', async () => {
  for (const port of [-1, 65536, 1.5, Number.NaN, '8787']) {
    await assert.rejects(
      () => startApiServer({ port, host: DEFAULT_HOST }),
      error => {
        assert.equal(error.message, 'INVALID_PORT');
        return true;
      },
      `port ${JSON.stringify(port)} must be refused`,
    );
  }
});

test('error responses never contain birth data, coordinates or stack traces', async () => {
  const located = {
    ...request({ mode: 'up_down' }),
    context: { ...CONTEXT, location: { latitude: 10.7769, longitude: 106.7009, accuracyMeters: 100, capturedAtUtc: '2026-09-18T08:29:45Z' } },
  };
  const responses = [
    await post(located),
    await post('{"profile": '),
    await post(''),
    await post(request(), { 'content-type': 'text/plain' }),
    await post(request({ diagnostics: true })),
    await fetch(`${base}/v1/unknown`),
    await fetch(`${base}/v1/readings`),
  ];

  const forbidden = [
    '1998-06-21', '14:30', 'birthDate', 'birthTime', 'birthCountry', 'traditionalProfile',
    '10.7769', '106.7009', 'latitude', 'longitude', 'inputSnapshot', 'readingKey',
    'Asia/Ho_Chi_Minh', 'instantUtc', 'deviceTimezone', 'at Object.', 'at async', '.js:',
  ];
  for (const response of responses) {
    const body = await response.text();
    assert.ok(body.length < 200, `error body should stay small, got ${body.length} bytes`);
    for (const needle of forbidden) {
      assert.ok(!body.includes(needle), `error body leaked "${needle}": ${body}`);
    }
  }
});
