import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { createRequire, stripTypeScriptTypes } from 'node:module';
import test from 'node:test';
import { setImmediate } from 'node:timers/promises';
import vm from 'node:vm';

const context = vm.createContext({ URL });
const modules = new Map();

async function loadHelper(name, overrides = {}) {
  const filename = new URL(`../e2e/helpers/${name}.ts`, import.meta.url);
  const module = new vm.SourceTextModule(stripTypeScriptTypes(readFileSync(filename, 'utf8')), { context });
  modules.set(name, module);
  await module.link(async (path) => {
    if (path.startsWith('./')) {
      const dependency = path.slice(2);
      if (!modules.has(dependency)) await loadHelper(dependency);
      return modules.get(dependency);
    }
    const dependency = overrides[path] ?? createRequire(filename)(path);
    const keys = Object.keys(dependency);
    return new vm.SyntheticModule(keys, function () {
      for (const key of keys) this.setExport(key, dependency[key]);
    }, { context });
  });
  await module.evaluate();
  return module.namespace;
}

const helpers = await loadHelper('semantics_scroll');

function browser(t, options = {}) {
  t.mock.timers.enable({ apis: ['setTimeout'] });
  let frameId = 0;
  const frames = new Map();
  const timers = new Set();
  const node = { getBoundingClientRect: () => ({ top: 100 }) };
  const globals = {
    document: { querySelectorAll: () => [node] },
    window: { innerHeight: 800, devicePixelRatio: 3 },
    performance: { now: () => 0 },
    requestAnimationFrame: (callback) => { frames.set(++frameId, callback); return frameId; },
    cancelAnimationFrame: (id) => frames.delete(id),
    setTimeout: (callback, delay) => {
      const id = setTimeout(() => { timers.delete(id); callback(); }, delay);
      timers.add(id);
      return id;
    },
    clearTimeout: (id) => { timers.delete(id); clearTimeout(id); },
    ...options,
  };
  return {
    page: { evaluate: (callback, arg) => vm.runInNewContext(`(${callback})`, globals)(arg) },
    frame() {
      const callbacks = [...frames.values()];
      frames.clear();
      for (const callback of callbacks) callback(0);
    },
    pendingFrames: () => frames.size,
    pendingTimers: () => timers.size,
  };
}

async function outcome(promise) {
  const result = {};
  promise.then((value) => { result.value = value; }, (error) => { result.error = error; });
  await setImmediate();
  return result;
}

test('frame waits reject at their deadline even when no frame arrives', async (t) => {
  const fake = browser(t);
  const result = await outcome(helpers.waitForFrames(fake.page, 2));
  t.mock.timers.tick(15_000);
  await setImmediate();
  assert.match(result.error?.message ?? '', /frame.*15000/i);
  assert.equal(fake.pendingFrames(), 0);
});

test('semantics waits reject at their deadline even when no frame arrives', async (t) => {
  const fake = browser(t);
  const result = await outcome(helpers.waitForSemanticsSettled(fake.page));
  t.mock.timers.tick(15_000);
  await setImmediate();
  assert.match(result.error?.message ?? '', /semantics.*15000/i);
  assert.equal(fake.pendingFrames(), 0);
});

test('row geometry waits reject when the frame stream stops', async (t) => {
  const fake = browser(t);
  const element = { getBoundingClientRect: () => ({ x: 0, y: 100, width: 100, height: 40 }) };
  const locator = { evaluate: (callback) => fake.page.evaluate(callback, element) };
  const waits = modules.get('frame_waits').namespace;
  const result = await outcome(waits.waitForStableBounds(locator));
  fake.frame();
  t.mock.timers.tick(15_000);
  await setImmediate();
  assert.match(result.error?.message ?? '', /row geometry.*15000/i);
  assert.equal(fake.pendingFrames(), 0);
});

test('an unchanged tree cannot masquerade as a completed wheel', async (t) => {
  const fake = browser(t);
  const initial = helpers.waitForSemanticsSettled(fake.page);
  for (let frame = 0; frame < 10; frame += 1) fake.frame();
  const token = await initial;
  const result = await outcome(helpers.waitForSemanticsSettled(fake.page, token));
  for (let frame = 0; frame < 100; frame += 1) fake.frame();
  t.mock.timers.tick(15_000);
  await setImmediate();
  assert.match(result.error?.message ?? '', /semantics.*change/i);
});

// Emulated Chromium divides wheel deltas by the pixel ratio (3) and Flutter divides them again.
function scrollingDocument({ startY, discover = false, fraction = 1 }) {
  let offset = 0;
  const y = () => startY - offset;
  const wheels = [];
  const moves = [];
  const target = {
    count: async () => discover && (y() < -40 || y() >= 800) ? 0 : 1,
    first: () => target,
    boundingBox: async () => ({ x: 0, y: y(), width: 100, height: 40 }),
    toString: () => 'chapter heading',
  };
  const wheel = async (_, distance) => {
    wheels.push(distance);
    moves.push(fraction * distance / 9);
    offset += moves.at(-1);
  };
  const evaluate = async (callback) => callback.toString().includes('querySelectorAll')
    ? String(offset) : vm.runInNewContext(`(${callback})`, {
      window: { innerHeight: 800, devicePixelRatio: 3 },
    })();
  return { page: { mouse: { wheel }, evaluate }, target, wheels, moves, position: y };
}

test('geometric scrolling reaches a distant target using scaled wheel deltas', async () => {
  const { page, target, wheels, position } = scrollingDocument({ startY: 20_000 });
  await helpers.scrollToLocator(page, target);
  assert(position() > 0 && position() < 800);
  assert(wheels.length <= 2, `Used ${wheels.length} wheels for a known target.`);
});

test('discovery traverses clipped headings without skipping the viewport', async () => {
  const { page, target, wheels, moves, position } = scrollingDocument({ startY: 20_000, discover: true });
  await helpers.scrollToLocator(page, target);
  assert(position() > -40 && position() < 800);
  assert(wheels.length <= 33, `Used ${wheels.length} wheels to discover the target.`);
  assert(moves.every((move) => move <= 800));
});

test('missing target discovery has a finite ceiling and reports geometry', async () => {
  const { page, target, wheels } = scrollingDocument({ startY: 100_000, discover: true });
  await assert.rejects(helpers.scrollToLocator(page, target), /48 wheels.*chapter heading.*last geometry/);
  assert.equal(wheels.length, 48);
});

test('boundary correction converges despite partial wheel movement', async () => {
  const { page, target, wheels, position } = scrollingDocument({ startY: 700, fraction: 0.8 });
  await helpers.scrollToPosition(page, target, { targetY: 560 });
  assert(Math.abs(position() - 560) <= 1);
  assert(wheels.length <= 4, `Used ${wheels.length} corrections.`);
});

test('an unachievable boundary fails with the last rectangle', async () => {
  const { page, target, wheels } = scrollingDocument({ startY: 700, fraction: 0 });
  await assert.rejects(helpers.scrollToPosition(page, target, { targetY: 560 }), /8 corrections.*last geometry.*700/);
  assert.equal(wheels.length, 8);
});

test('settled waits release their deadline and frame callbacks', async (t) => {
  const fake = browser(t);
  const frames = helpers.waitForFrames(fake.page, 2);
  fake.frame();
  fake.frame();
  await frames;
  assert.equal(fake.pendingTimers(), 0);
  const semantics = helpers.waitForSemanticsSettled(fake.page);
  for (let frame = 0; frame < 3; frame += 1) fake.frame();
  await semantics;
  assert.equal(fake.pendingTimers(), 0);
  assert.equal(fake.pendingFrames(), 0);
});

test('a changed semantics tree must remain stable before resolving', async (t) => {
  let top = 100;
  const document = { querySelectorAll: () => [{ getBoundingClientRect: () => ({ top }) }] };
  const fake = browser(t, { document });
  const before = helpers.waitForSemanticsSettled(fake.page);
  for (let frame = 0; frame < 3; frame += 1) fake.frame();
  const token = await before;
  const result = await outcome(helpers.waitForSemanticsSettled(fake.page, token));
  top = 200;
  fake.frame();
  top = 300;
  fake.frame();
  await setImmediate();
  assert.equal(result.value, undefined);
  fake.frame();
  fake.frame();
  await setImmediate();
  assert.notEqual(result.value, token);
  assert.equal(fake.pendingTimers(), 0);
});

test('the shared context answers analytics locally before handing the context to tests', async () => {
  const setup = await loadHelper('test_setup', { '@playwright/test': { test: { extend: (fixtures) => fixtures } } });
  const { site } = JSON.parse(readFileSync('assets/content/portfolio.json', 'utf8'));
  const routes = [];
  const context = { route: async (matches, handler) => routes.push({ matches, handler }) };
  await setup.test.context({ context }, async (used) => {
    assert.equal(used, context);
    assert.equal(routes.length, site.analytics ? 1 : 0);
  });
  if (!site.analytics) return;
  const { matches, handler } = routes[0];
  assert(matches(new URL(site.analytics.script_url)));
  assert.equal(matches(new URL('https://example.com/js/script.js')), false);
  let answer;
  await handler({ fulfill: async (response) => { answer = response; } });
  assert.equal(answer.body, '');
  assert.equal(answer.contentType, 'application/javascript');
});

test('every CI spec uses the hermetic test context', () => {
  const directory = new URL('../e2e/', import.meta.url);
  for (const file of readdirSync(directory).filter((name) => name.endsWith('.spec.ts'))) {
    const source = readFileSync(new URL(file, directory), 'utf8');
    assert.match(source, /import \{[^}]*\btest\b[^}]*\} from ['"]\.\/helpers\/test_setup['"];/, file);
    assert.doesNotMatch(source, /import \{[^}]*\btest\b[^}]*\} from ['"]@playwright\/test['"];/, file);
  }
  const production = readFileSync(new URL('../e2e-prod/portfolio.spec.ts', import.meta.url), 'utf8');
  assert.match(production, /import \{[^}]*\btest\b[^}]*\} from ['"]\.\.\/e2e\/helpers\/test_setup['"];/);
});
