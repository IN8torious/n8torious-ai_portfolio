// Harakiri NG — The Wells
// Rhyme-fuel wells: harmonic fountains in the viewport. Agents tune to a
// well and burn rhyme families to cross the mesh — the courier's run made
// visible. Each well pulses concentric rings in its rhyme family's color;
// when a courier arrives, the well flares and the trail ignites.
// Doctrine: The Courier's Rhyme Run.
// Nathan Brown, 2026.

const std = @import("std");
const pyre = @import("pyre.zig");
const sicore = @import("sicore.zig");
const mesh = @import("mesh.zig");
const taskmgr = @import("taskmgr.zig");

const NW: usize = 3;
const NC: usize = 2;

// rhyme families: ember, tide, veil
const WELL_POS = [_][3]f32{
    .{ -1.6, 0.5, 0.4 },
    .{ 1.6, -0.5, -0.4 },
    .{ 0.3, 0.9, 1.3 },
};
const WELL_COL = [_][3]u8{
    .{ 220, 20, 60 }, // ember — crimson
    .{ 212, 175, 55 }, // tide — gold
    .{ 150, 90, 230 }, // veil — violet
};
const WELL_NAMES = [_][]const u8{ "ember", "tide", "veil" };

var well_phase: [NW]f32 = [_]f32{ 0.0, 2.1, 4.2 };
var well_flare: [NW]f32 = [_]f32{0} ** NW;

// couriers: agent-node index, target well, progress along the run
var courier_node: [NC]usize = .{ 4, 6 }; // brood-00, brood-02
var courier_well: [NC]usize = .{ 0, 1 };
var courier_p: [NC]f32 = .{ 0.3, 0.65 };

fn project(p: [3]f32, cx: i32, cy: i32, s: i32) [2]i32 {
    return pyre.project_orbit(p, cx, cy, s); // unified: pyre.zig owns the orbit projection
}

fn lerp3f(a: [3]f32, b: [3]f32, t: f32) [3]f32 {
    return .{
        a[0] * (1.0 - t) + b[0] * t,
        a[1] * (1.0 - t) + b[1] * t,
        a[2] * (1.0 - t) + b[2] * t,
    };
}

pub fn tick() void {
    var w: usize = 0;
    while (w < NW) : (w += 1) {
        well_phase[w] += 0.12;
        well_flare[w] *= 0.93;
        if (well_flare[w] < 0.01) well_flare[w] = 0;
    }
    var c: usize = 0;
    while (c < NC) : (c += 1) {
        courier_p[c] += 0.025;
        if (courier_p[c] >= 1.0) {
            // the burn lands — the well flares, the courier retunes
            well_flare[courier_well[c]] = 1.0;
            courier_well[c] = (courier_well[c] + 1) % NW;
            courier_p[c] = 0.0;
        }
    }
}

pub fn render(cx: i32, cy: i32, s: i32) void {
    // wells first (they sit behind the mesh)
    var w: usize = 0;
    while (w < NW) : (w += 1) {
        const q = project(WELL_POS[w], cx, cy, s);
        const col = WELL_COL[w];
        const fl = well_flare[w];
        // heart glow, brighter while flaring
        const ga: u8 = @intFromFloat(50.0 + fl * 150.0);
        sicore.glow(q[0], q[1], @as(i32, @intFromFloat(26.0 + fl * 46.0)), col, ga);
        // three pulse rings, breathing
        var k: i32 = 0;
        while (k < 3) : (k += 1) {
            const base: f32 = 16.0 + @as(f32, @floatFromInt(k)) * 13.0;
            const r: i32 = @as(i32, @intFromFloat(base + @sin(well_phase[w] + @as(f32, @floatFromInt(k)) * 1.7) * 5.0));
            const a: u8 = @intFromFloat(110.0 - @as(f32, @floatFromInt(k)) * 28.0 + fl * 90.0);
            sicore.ring(q[0], q[1], r, 2, col, a);
        }
        // heart
        sicore.circle(q[0], q[1], 4, col);
        // name
        taskmgr.draw_text_pub(q[0] - 14, q[1] + 52, WELL_NAMES[w], col);
    }

    // couriers on their runs: bright head, fading trail
    var c: usize = 0;
    while (c < NC) : (c += 1) {
        const n3 = mesh.node_pos(courier_node[c]);
        const w3 = WELL_POS[courier_well[c]];
        const col = WELL_COL[courier_well[c]];
        var k: i32 = 0;
        while (k < 5) : (k += 1) {
            const pk = courier_p[c] - @as(f32, @floatFromInt(k)) * 0.035;
            if (pk < 0) continue;
            const p3 = lerp3f(n3, w3, pk);
            const q = project(p3, cx, cy, s);
            const a: u8 = @intFromFloat(200.0 - @as(f32, @floatFromInt(k)) * 38.0);
            sicore.glow(q[0], q[1], 8 - k, col, a);
        }
        const head3 = lerp3f(n3, w3, courier_p[c]);
        const hq = project(head3, cx, cy, s);
        sicore.glow(hq[0], hq[1], 10, sicore.WHITE, 160);
        sicore.circle(hq[0], hq[1], 3, sicore.WHITE);
    }
}
