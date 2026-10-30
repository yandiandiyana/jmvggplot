// Run: node tests/js/test-layerops.js   (from project root)
'use strict';
const assert = require('assert');
const mod = require('../../jamovi/js/layerplot.js');
const { ops, N_SLOTS, FIELDS, emptySlot } = mod.layerOps;

const slot = (type, extra) => Object.assign(emptySlot(type), extra || {});
const pad = a => { const o = a.slice(); while (o.length < N_SLOTS) o.push(emptySlot()); return o; };
const types = s => s.map(x => x.type);
let passed = 0;
const queue = [];
function test(name, fn) { queue.push([name, fn]); }
const tick = () => new Promise(r => setTimeout(r, 5));

test('add puts the layer in the first free position', () => {
  const r = ops.add(pad([slot('point')]), 'smooth');
  assert.deepStrictEqual(types(r).slice(0, 3), ['point', 'smooth', 'none']);
});
test('add fails when full or type none', () => {
  const full = Array.from({ length: N_SLOTS }, () => slot('point'));
  assert.strictEqual(ops.add(full, 'line'), null);
  assert.strictEqual(ops.add(pad([]), 'none'), null);
});
test('delete removes and shifts later layers up', () => {
  const r = ops.remove(pad([slot('point'), slot('line'), slot('smooth')]), 1);
  assert.deepStrictEqual(types(r).slice(0, 3), ['point', 'smooth', 'none']);
});
test('delete on an empty slot is a no-op', () => {
  assert.strictEqual(ops.remove(pad([slot('point')]), 3), null);
});
test('duplicate inserts a copy right after the source, keeping settings', () => {
  const src = slot('point', { alpha: 0.4, size: 3 });
  const r = ops.duplicate(pad([src, slot('smooth')]), 0);
  assert.deepStrictEqual(types(r).slice(0, 4), ['point', 'point', 'smooth', 'none']);
  assert.strictEqual(r[1].alpha, 0.4);
  assert.notStrictEqual(r[1], r[0]);
});
test('duplicate fails when full', () => {
  const full = Array.from({ length: N_SLOTS }, () => slot('point'));
  assert.strictEqual(ops.duplicate(full, 0), null);
});
test('move up / down swap neighbours and carry settings', () => {
  const s = pad([slot('point', { alpha: 0.2 }), slot('line'), slot('text')]);
  const up = ops.moveUp(s, 1);
  assert.deepStrictEqual(types(up).slice(0, 3), ['line', 'point', 'text']);
  assert.strictEqual(up[1].alpha, 0.2);
  const dn = ops.moveDown(s, 0);
  assert.deepStrictEqual(types(dn).slice(0, 3), ['line', 'point', 'text']);
});
test('move up on first / move down on last are no-ops', () => {
  const s = pad([slot('point'), slot('line')]);
  assert.strictEqual(ops.moveUp(s, 0), null);
  assert.strictEqual(ops.moveDown(s, 1), null);
});
test('gaps are compacted by actions', () => {
  const s = pad([slot('point'), slot('none'), slot('line')]);
  const r = ops.moveUp(s, 2);               // line is 2nd used layer
  assert.deepStrictEqual(types(r).slice(0, 3), ['line', 'point', 'none']);
});
test('new fields are part of the slot', () => {
  ['bins', 'intercept', 'slope', 'width', 'position', 'stat'].forEach(f => assert.ok(FIELDS.includes(f)));
  const d = ops.duplicate(pad([slot('abline', { intercept: 3, slope: 2 })]), 0);
  assert.strictEqual(d[1].intercept, 3); assert.strictEqual(d[1].slope, 2);
});
test('reset restores defaults but keeps the layer type and position', () => {
  const s = pad([slot('smooth', { alpha: 0.3, size: 5, method: 'loess', se: false, enabled: false, bins: 5, intercept: 9, slope: 4 })]);
  const r = ops.reset(s, 0);
  assert.deepStrictEqual(r[0], emptySlot('smooth'));
});

// --- handler behaviour with a mock jamovi `ui` (incl. re-entrant 'changed' on reset) ---
function mockUi(initial) {
  const calls = { begin: 0, end: 0 };
  const ui = { view: { model: { options: {
    beginEdit() { calls.begin++; }, endEdit() { calls.end++; } } } } };
  const mk = (name, v) => { ui[name] = { _v: v, value() { return this._v; },
    setValue(x) { this._v = x; if (this.onChange) this.onChange(); } }; };
  for (let i = 1; i <= N_SLOTS; i++) {
    const s = initial[i - 1] || emptySlot();
    FIELDS.forEach(f => mk('l' + i + '_' + f, s[f]));
    mk('act' + i, 'none');
    ui['act' + i].onChange = () => mod['act' + i + '_changed'](ui, {});
  }
  mk('addLayer', 'none');
  ui.addLayer.onChange = () => mod.addLayer_changed(ui, {});
  return { ui, calls };
}
const uiTypes = ui => Array.from({ length: N_SLOTS }, (_, i) => ui['l' + (i + 1) + '_type'].value());

test('handler: add layer; one batched edit; dropdown resets AFTER the batch', async () => {
  const { ui, calls } = mockUi([slot('point')]);
  ui.addLayer.setValue('smooth');
  assert.strictEqual(calls.begin, 1); assert.strictEqual(calls.end, 1);
  assert.strictEqual(ui.addLayer.value(), 'smooth');   // not yet reset: deferred
  await tick();
  assert.deepStrictEqual(uiTypes(ui).slice(0, 3), ['point', 'smooth', 'none']);
  assert.strictEqual(ui.addLayer.value(), 'none');
  assert.strictEqual(calls.begin, 1);                  // reset did not start another batch
});
test('handler: can add the same type twice in a row', async () => {
  const { ui } = mockUi([slot('point')]);
  ui.addLayer.setValue('smooth'); await tick();
  ui.addLayer.setValue('smooth'); await tick();
  assert.deepStrictEqual(uiTypes(ui).slice(0, 4), ['point', 'smooth', 'smooth', 'none']);
});
test('handler: delete / duplicate / move via per-layer dropdown', async () => {
  const { ui } = mockUi([slot('point'), slot('line'), slot('smooth')]);
  ui.act2.setValue('up'); await tick();
  assert.deepStrictEqual(uiTypes(ui).slice(0, 3), ['line', 'point', 'smooth']);
  ui.act1.setValue('duplicate'); await tick();
  assert.deepStrictEqual(uiTypes(ui).slice(0, 4), ['line', 'line', 'point', 'smooth']);
  ui.act4.setValue('delete'); await tick();
  assert.deepStrictEqual(uiTypes(ui).slice(0, 4), ['line', 'line', 'point', 'none']);
  assert.ok(['act1', 'act2', 'act3', 'act4'].every(n => ui[n].value() === 'none'));
});
test('handler: endEdit still runs and dropdown resets when action cannot apply', async () => {
  const { ui, calls } = mockUi([slot('point')]);
  ui.act1.setValue('up'); await tick();
  assert.strictEqual(calls.begin, calls.end);
  assert.strictEqual(ui.act1.value(), 'none');
});

(async () => {
  for (const [name, fn] of queue) { await fn(); passed++; console.log('ok  -', name); }
  console.log(passed + ' tests passed');
})().catch(e => { console.error('FAILED:', e.message); process.exit(1); });
