'use strict';

// Layer manager for jmvggplot.
//
// Layers live in ordinary options (l1_type ... l6_slope), so jamovi saves/restores
// them. This file only REARRANGES those option values when the user picks an
// action in a "Layer actions" dropdown (act1..act6) or "Add layer" (addLayer).
// Uses only documented API: {option}_changed handlers, ui.<opt>.value()/setValue(),
// and ui.view.model.options.beginEdit()/endEdit().
//
// Pure list logic is in `ops` (no jamovi objects) so it can be tested with node.
// Note: actions compact the list (empty slots move to the end).

const N_SLOTS = 6;
const FIELDS = ['type', 'enabled', 'inherit', 'alpha', 'size', 'method', 'se', 'bins', 'intercept', 'slope', 'width', 'position', 'stat'];
const DEFAULT_SLOT = { type: 'none', enabled: true, inherit: true, alpha: 1, size: 0, method: 'lm', se: true,
                       bins: 30, intercept: 0, slope: 1, width: 0, position: 'default', stat: 'mean_se' };

function emptySlot(type) {
    return Object.assign({}, DEFAULT_SLOT, type ? { type: type } : {});
}
function isUsed(s) { return s.type !== 'none'; }
function compact(slots) { return slots.filter(isUsed).map(s => Object.assign({}, s)); }
function pad(list) {
    const out = list.slice(0, N_SLOTS);
    while (out.length < N_SLOTS) out.push(emptySlot());
    return out;
}
// position of slot i (0-based) among the used slots, or -1 if slot i is empty
function usedIndex(slots, i) {
    if (!slots[i] || !isUsed(slots[i])) return -1;
    let k = 0;
    for (let j = 0; j < i; j++) if (isUsed(slots[j])) k++;
    return k;
}

// Each op returns a new slot array of length N_SLOTS, or null if it cannot apply.
const ops = {
    add(slots, type) {
        const c = compact(slots);
        if (!type || type === 'none' || c.length >= N_SLOTS) return null;
        c.push(emptySlot(type));
        return pad(c);
    },
    remove(slots, i) {
        const k = usedIndex(slots, i);
        if (k < 0) return null;
        const c = compact(slots);
        c.splice(k, 1);
        return pad(c);
    },
    duplicate(slots, i) {
        const k = usedIndex(slots, i);
        const c = compact(slots);
        if (k < 0 || c.length >= N_SLOTS) return null;
        c.splice(k + 1, 0, Object.assign({}, c[k]));
        return pad(c);
    },
    moveUp(slots, i) {
        const k = usedIndex(slots, i);
        if (k <= 0) return null;
        const c = compact(slots);
        const t = c[k - 1]; c[k - 1] = c[k]; c[k] = t;
        return pad(c);
    },
    moveDown(slots, i) {
        const k = usedIndex(slots, i);
        const c = compact(slots);
        if (k < 0 || k >= c.length - 1) return null;
        const t = c[k + 1]; c[k + 1] = c[k]; c[k] = t;
        return pad(c);
    },
    reset(slots, i) {
        if (usedIndex(slots, i) < 0) return null;
        const out = slots.map(s => Object.assign({}, s));
        out[i] = emptySlot(slots[i].type);
        return out;
    }
};

function readSlots(ui) {
    const slots = [];
    for (let i = 1; i <= N_SLOTS; i++) {
        const s = {};
        FIELDS.forEach(f => { s[f] = ui['l' + i + '_' + f].value(); });
        slots.push(s);
    }
    return slots;
}

function writeSlots(ui, slots) {
    slots.forEach((s, idx) => {
        FIELDS.forEach(f => {
            const ctl = ui['l' + (idx + 1) + '_' + f];
            if (ctl.value() !== s[f]) ctl.setValue(s[f]);
        });
    });
}

// Run one action as a single batched edit. The selector dropdown is put back to
// 'none' AFTER the batch has finished (deferred), so the reset is a separate,
// real option change rather than being swallowed by the batch.
function perform(ui, selectorName, compute) {
    const options = ui.view.model.options;
    options.beginEdit();
    try {
        const next = compute(readSlots(ui));
        if (next) writeSlots(ui, next);
    } finally {
        options.endEdit();
    }
    setTimeout(function () {
        if (ui[selectorName].value() !== 'none') ui[selectorName].setValue('none');
    }, 0);
}

const handlers = {};

for (let n = 1; n <= N_SLOTS; n++) {
    const selector = 'act' + n;
    handlers[selector + '_changed'] = function (ui, event) {
        const action = ui[selector].value();
        if (action === 'none') return;          // our own reset: ignore
        const i = n - 1;
        perform(ui, selector, slots => {
            switch (action) {
                case 'up':        return ops.moveUp(slots, i);
                case 'down':      return ops.moveDown(slots, i);
                case 'duplicate': return ops.duplicate(slots, i);
                case 'reset':     return ops.reset(slots, i);
                case 'delete':    return ops.remove(slots, i);
                default:          return null;
            }
        });
    };
}

handlers.addLayer_changed = function (ui, event) {
    const type = ui.addLayer.value();
    if (type === 'none') return;                // our own reset: ignore
    perform(ui, 'addLayer', slots => ops.add(slots, type));
};

// Auxiliary (non-event) member, exposed for unit tests.
handlers.layerOps = { ops: ops, N_SLOTS: N_SLOTS, FIELDS: FIELDS, emptySlot: emptySlot };

module.exports = handlers;
