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

test('an unchanged wheel remains pending until the full bounded change deadline', async (t) => {
  const fake = browser(t);
  const initial = helpers.waitForSemanticsSettled(fake.page);
  for (let frame = 0; frame < 3; frame += 1) fake.frame();
  const token = await initial;
  const result = await outcome(helpers.waitForSemanticsSettled(fake.page, token));
  for (let frame = 0; frame < 3; frame += 1) fake.frame();
  t.mock.timers.tick(1000);
  await setImmediate();
  assert.equal(result.error, undefined);
  assert.equal(result.value, undefined);
  t.mock.timers.tick(14_000);
  await setImmediate();
  assert.match(result.error?.message ?? '', /semantics.*change.*15000/i);
  assert.equal(fake.pendingTimers(), 0);
  assert.equal(fake.pendingFrames(), 0);
});

test('geometry arriving after an early stationary interval still settles', async (t) => {
  let top = 100;
  const fake = browser(t, { document: { querySelectorAll: () => [{ getBoundingClientRect: () => ({ top }) }] } });
  const initial = helpers.waitForSemanticsSettled(fake.page);
  for (let frame = 0; frame < 3; frame += 1) fake.frame();
  const token = await initial;
  const result = await outcome(helpers.waitForSemanticsSettled(fake.page, token));
  for (let frame = 0; frame < 3; frame += 1) fake.frame();
  t.mock.timers.tick(1000);
  await setImmediate();
  assert.equal(result.value, undefined);
  assert.equal(result.error, undefined);
  top = 300;
  for (let frame = 0; frame < 3; frame += 1) fake.frame();
  await setImmediate();
  assert.notEqual(result.value, token);
  assert.equal(result.error, undefined);
  assert.equal(fake.pendingTimers(), 0);
});

// The saved mobile traces show both one and two DPR divisions, depending on the AX path.
function scrollingDocument({ startY, discover = false, fraction = 1, revealAtWheel = 0,
  pixelRatio = 3, viewportHeight = 800, wheelDivisor = pixelRatio ** 2,
  maxOffset = Infinity, anchorGeneration = () => 'content' }) {
  let offset = 0;
  const y = () => startY - offset;
  const wheels = [];
  const moves = [];
  const target = {
    count: async () => wheels.length < revealAtWheel || (discover && (y() < -40 || y() >= viewportHeight)) ? 0 : 1,
    first: () => target,
    boundingBox: async () => ({ x: 0, y: y(), width: 100, height: 40 }),
    toString: () => 'chapter heading',
  };
  const wheel = async (_, distance) => {
    wheels.push(distance);
    const divisor = typeof wheelDivisor === 'function' ? wheelDivisor(wheels.length) : wheelDivisor;
    const next = Math.min(maxOffset, offset + fraction * distance / divisor);
    moves.push(next - offset);
    offset = next;
  };
  const document = { querySelectorAll: () => {
    const generation = anchorGeneration(wheels.length);
    if (generation === null) return [];
    return Array.from({ length: Math.ceil(viewportHeight / 200) + 1 }, (_, index) => {
      const row = Math.floor(offset / 200) + index;
      return {
        id: `${generation}-${row}`,
        textContent: `Content row ${row}`,
        getAttribute: () => null,
        getBoundingClientRect: () => ({ top: row * 200 - offset, width: 100, height: 200 }),
      };
    });
  } };
  const evaluate = async (callback, arg) => {
    if (arg && 'stableFrames' in arg) {
      const current = String(offset);
      if (arg.changedFrom && arg.changedFrom === current) {
        throw new Error(`The semantics tree did not change within 15000ms; last geometry: ${current}.`);
      }
      return current;
    }
    return vm.runInNewContext(`(${callback})`, {
      document, window: { innerHeight: viewportHeight, devicePixelRatio: pixelRatio },
    })(arg);
  };
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

test('a simulated stalled wheel propagates the target and geometry diagnostics', async () => {
  const { page, target, wheels } = scrollingDocument({ startY: 20_000, discover: true, fraction: 0 });
  await assert.rejects(helpers.scrollToLocator(page, target),
    /Wheel 1 failed.*chapter heading.*last geometry.*viewportHeight.*did not change within 15000ms/);
  assert.equal(wheels.length, 1);
});

test('a target arriving after advancing discovery wheels is found', async () => {
  const { page, target, wheels } = scrollingDocument({ startY: 700, fraction: 0.5, revealAtWheel: 2 });
  await helpers.scrollToLocator(page, target);
  assert.equal(wheels.length, 2);
});

test('discovery continues while geometry advances even without an attached target', async () => {
  const { page, target, wheels, position } = scrollingDocument({ startY: 20_000, discover: true });
  await helpers.scrollToLocator(page, target);
  assert(position() > -40 && position() < 800);
  assert(wheels.length > 2);
});

test('semantic link helper requests a tappable anchor with its full text', async () => {
  const { page, target } = scrollingDocument({ startY: 700 });
  const label = 'View project: Case, Source';
  let selected = false;
  const textLink = { ...target, first: () => textLink, waitFor: async () => undefined };
  page.locator = (selector) => {
    assert.equal(selector, 'flt-semantics-host a[flt-tappable]');
    return { filter: ({ hasText }) => {
      assert.equal(hasText, label);
      selected = true;
      return textLink;
    } };
  };
  await helpers.scrollToSemanticLink(page, label);
  assert.equal(selected, true);
});

test('aria-label-only narrative groups use the exact accessible name, not text nodes', async () => {
  const { page, target } = scrollingDocument({ startY: 700 });
  const sentence = 'Owned the client and releases.';
  const name = `More work\nWhat I owned\n${sentence}`;
  let matched = false;
  page.locator = (selector) => {
    assert.equal(selector, 'flt-semantics-host');
    return {
      getByText: () => { throw new Error('The group has an aria-label but no text node.'); },
      getByRole: (role, options) => {
        assert.equal(role, 'group');
        assert.equal(options.name, name);
        assert.equal(options.exact, true);
        matched = true;
        return target;
      },
    };
  };
  assert.equal(await helpers.scrollToSemanticGroup(page, name), target);
  assert.equal(matched, true);
});

function selectedEvidenceDocument(options) {
  const state = scrollingDocument(options);
  const label = 'View project: Selected case, Release';
  const link = { ...state.target, first: () => link, waitFor: async () => undefined };
  const from = {
    count: async () => 1,
    first: () => from,
    boundingBox: async () => ({ x: 0, y: 407 + state.position() - options.startY, width: 306, height: 371 }),
    toString: () => 'selected compact artifact',
  };
  state.page.locator = (selector) => {
    assert.equal(selector, 'flt-semantics-host a[flt-tappable]');
    return { filter: ({ hasText }) => { assert.equal(hasText, label); return link; } };
  };
  return { ...state, label, from };
}

test('mobile discovery cannot leap over a virtualized selected evidence link', async () => {
  const { page, label, from, moves, position } = selectedEvidenceDocument({
    startY: 1250, discover: true, pixelRatio: 2.625, viewportHeight: 839,
    wheelDivisor: 2.625, maxOffset: 5000,
  });
  await helpers.scrollToSemanticLink(page, label, { from });
  assert(position() > -40 && position() < 839, `Selected evidence ended at y=${position()}.`);
  assert(moves.every((move) => move <= 839), `Observed discovery movement: ${moves}.`);
});

test('nearby discovery bounds wheel progress across device ratios and division modes', async () => {
  for (const pixelRatio of [0.75, 1, 2.625, 3]) {
    for (const divisions of [0, 1, 2]) {
      const { page, label, from, moves } = selectedEvidenceDocument({
        startY: 1250, discover: true, pixelRatio, wheelDivisor: pixelRatio ** divisions,
      });
      await helpers.scrollToSemanticLink(page, label, { from });
      assert(moves.every((move) => move <= 800), `DPR=${pixelRatio}, divisions=${divisions}: ${moves}.`);
    }
  }
});

test('nearby discovery stays bounded when anchors disappear and wheel gain changes', async () => {
  const { page, label, from, moves, wheels } = selectedEvidenceDocument({
    startY: 2000, discover: true, anchorGeneration: (count) => count < 2 ? 'content' : null,
    wheelDivisor: (count) => count === 1 ? 9 : 3, maxOffset: 5000,
  });
  await helpers.scrollToSemanticLink(page, label, { from });
  assert(wheels.length > 1);
  assert(wheels.every((delta) => delta <= 640), `Unobserved wheel amplified input: ${wheels}.`);
  assert(moves.every((move) => move <= 800));
});

test('nearby discovery requires the selected artifact to be in the viewport', async () => {
  const { page, label, from, wheels } = selectedEvidenceDocument({ startY: 1250, discover: true });
  from.boundingBox = async () => ({ x: 0, y: 1200, width: 306, height: 371 });
  await assert.rejects(helpers.scrollToSemanticLink(page, label, { from }), /Starting artifact.*viewport/);
  assert.equal(wheels.length, 0);
});

test('boundary correction converges despite partial wheel movement', async () => {
  const { page, target, wheels, position } = scrollingDocument({ startY: 700, fraction: 0.8 });
  await helpers.scrollToPosition(page, target, { targetY: 560 });
  assert(Math.abs(position() - 560) <= 1);
  assert(wheels.length <= 4, `Used ${wheels.length} corrections.`);
});

test('an unachievable boundary fails with the last rectangle', async () => {
  const { page, target, wheels } = scrollingDocument({ startY: 700, fraction: 0 });
  await assert.rejects(helpers.scrollToPosition(page, target, { targetY: 560 }),
    /Correction 1 failed.*last geometry.*700/);
  assert.equal(wheels.length, 1);
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
