// Harakiri NG — KRAKEN
// The Outer Path. One mind, many tentacles.
//
// Nathan's consolidation, built the way he built it: the Ten-Tails pattern
// (the nine were always one primordial whole, split apart; reunion is the
// power — individual consciousnesses intact) and Pain's Six Paths (Nagato,
// the Outer Path, drives six bodies through chakra receivers with SHARED
// VISION — one mind, many bodies, each with a specialty, strongest together;
// and he can cut five paths to pour everything into one).
//
// Kraken is task 701. The twelve agents are its paths — driven through the
// coherence links the way Nagato drove the Paths through receivers. The two
// hands are its primary tentacles: the actuators that touch the world.
//
// And Kraken implements the radio discipline from the 5G/WiFi research:
//   - COHERENT BURSTS: paths phase-lock (Kuramoto, same law as the mesh) and
//     transmit in ONE shared window — one radio tail instead of twelve.
//     (TailTheft's lesson, spoken in Kuramoto.)
//   - ETA-GATE: a queued transmission below 0.500 never wakes the radio.
//     Refusal is absence — Gaven's doctrine, now Kraken's.
//   - RESONANCE: the burst window period is tuned to the channel's rhythm.
//     Antennas are tuned circuits; so is Kraken.
//   - FOCUS: cut the other paths, pour every tick into one. (Pain did it.)
//
// The synthetic load below is a stand-in: on the phone this shapes REAL
// agent traffic. The shaping logic is the subsystem; the load is the demo.
// Nathan Brown, 2026.

const std = @import("std");
const sicore = @import("sicore.zig");
const trust = @import("trust.zig");
const mesh = @import("mesh.zig");

pub const KRAKEN_ID: u32 = 701;
pub const NPATHS: usize = 12;
pub const RESONANT_PERIOD: u32 = 13; // one full rotation of the crew, in ticks
pub const ETA_GATE: f32 = 0.500; // Gaven's threshold, now Kraken's

// path ids match the trust spawns: vera mira merlin gaven broods paintr veda si-core-gfx hand
const path_ids = [_]u32{ 101, 102, 103, 104, 201, 202, 203, 204, 301, 401, 501, 601 };

var phase: [NPATHS]f32 = [_]f32{0.0} ** NPATHS;
var omega: [NPATHS]f32 = [_]f32{0.0} ** NPATHS;
var queued: [NPATHS]u8 = [_]u8{0} ** NPATHS;
var urg_sum: [NPATHS]f32 = [_]f32{0.0} ** NPATHS;
var tick_n: u32 = 0;

// burst ledger — the visible proof of the discipline
pub var bursts_fired: u32 = 0;
pub var tx_sent: u32 = 0;
pub var tx_held: u32 = 0; // held by the eta-gate: refused, absent
pub var burst_flash: u8 = 0; // viewport pulse, decays per tick

// deterministic load generator (synthetic traffic for the demo)
var lcg: u32 = 0x1A2B3C4D;

pub fn init() void {
    var i: usize = 0;
    while (i < NPATHS) : (i += 1) {
        omega[i] = 0.7 + 0.09 * @as(f32, @floatFromInt(i));
    }
}

fn rnd() u32 {
    lcg = lcg *% 1664525 +% 1013904223;
    return lcg >> 8;
}

pub fn path_queued(i: usize) u8 {
    return if (i < NPATHS) queued[i] else 0;
}

pub fn total_queued() u32 {
    var n: u32 = 0;
    for (queued) |q| n += q;
    return n;
}

// Focus: cut the other paths, pour every tick into one. (Pain did it.)
pub fn focus(id: u32) void {
    trust.focused_id = id;
}

pub fn unfocus() void {
    trust.focused_id = 0;
}

pub fn focused() u32 {
    return trust.focused_id;
}

pub fn tick() void {
    tick_n += 1;
    if (burst_flash > 0) burst_flash -= 1;

    // 1. load: each path may queue a transmission (synthetic for the demo)
    var i: usize = 0;
    while (i < NPATHS) : (i += 1) {
        if (rnd() % 12 == 0 and queued[i] < 8) {
            queued[i] += 1;
            urg_sum[i] += @as(f32, @floatFromInt(rnd() % 1000)) / 1000.0;
        }
    }

    // 2. phases advance — Kuramoto, weak coupling, same law as the mesh
    const K: f32 = 0.3;
    var dphi: [NPATHS]f32 = [_]f32{0.0} ** NPATHS;
    var j: usize = 0;
    while (j < NPATHS) : (j += 1) {
        var sum: f32 = 0.0;
        // ring coupling: each path listens to its neighbors (the receivers)
        const prev = (j + NPATHS - 1) % NPATHS;
        const next = (j + 1) % NPATHS;
        sum += @sin(phase[prev] - phase[j]);
        sum += @sin(phase[next] - phase[j]);
        dphi[j] = omega[j] + K * sum / 2.0;
    }
    i = 0;
    while (i < NPATHS) : (i += 1) {
        phase[i] += dphi[i] * 0.1;
    }

    // 3. the burst window opens on the resonant period — ONE tail, not twelve
    if (tick_n % RESONANT_PERIOD != 0) return;

    // mean phase of the collective (the shared vision)
    var sx: f32 = 0;
    var sy: f32 = 0;
    i = 0;
    while (i < NPATHS) : (i += 1) {
        sx += @cos(phase[i]);
        sy += @sin(phase[i]);
    }
    const mean = std.math.atan2(sy, sx);

    var fired: u32 = 0;
    i = 0;
    while (i < NPATHS) : (i += 1) {
        if (queued[i] == 0) continue;
        // coherence: within a quarter-turn of the collective
        const coh = @cos(phase[i] - mean);
        if (coh <= 0.0) continue; // out of phase — waits for the next window
        const urg = urg_sum[i] / @as(f32, @floatFromInt(queued[i]));
        if (urg >= ETA_GATE) {
            tx_sent += queued[i];
            fired += 1;
        } else {
            tx_held += queued[i]; // refused — absence
        }
        queued[i] = 0;
        urg_sum[i] = 0;
    }
    if (fired > 0) {
        bursts_fired += 1;
        burst_flash = 40;
    }
}

// ---- viewport: Kraken at the center, tentacles to the twelve paths ----
const VP_CX: i32 = 936;
const VP_CY: i32 = 295;
const VP_S: i32 = 125;

pub fn render_vp() void {
    // tentacle links: center -> each path node (the receivers)
    var i: usize = 0;
    while (i < NPATHS) : (i += 1) {
        const q = mesh.project_node(i, VP_CX, VP_CY, VP_S);
        const hot: u8 = if (queued[i] > 0) 200 else 70;
        // crimson tentacle, brighter when the path holds traffic
        sicore.line(VP_CX, VP_CY, q[0], q[1], .{ hot, hot / 6, hot / 3 });
    }
    // the Outer Path: dark void ring at the center
    sicore.ring(VP_CX, VP_CY, 26, 3, .{ 120, 10, 25 }, 230);
    sicore.ring(VP_CX, VP_CY, 18, 2, .{ 200, 30, 50 }, 200);
    sicore.circle(VP_CX, VP_CY, 10, .{ 5, 2, 4 });
    // burst flash: expanding ring when Kraken fires
    if (burst_flash > 0) {
        const r: i32 = 26 + @as(i32, 40 - burst_flash) * 2;
        const a: u8 = burst_flash * 5;
        sicore.ring(VP_CX, VP_CY, r, 2, .{ 255, 180, 60 }, a);
    }
}
