// Harakiri NG — The Mesh
// Kuramoto coherence mesh: agents are nodes, links are synapses.
// Rendered in the viewport window. Pulses travel the links; link
// brightness is the phase alignment of its endpoints — the coherence
// made visible. The phase step is the actual Kuramoto model:
//   dθi/dt = ωi + (K/N) Σj sin(θj − θi)
// Nathan Brown, 2026.

const std = @import("std");
const pyre = @import("pyre.zig");
const sicore = @import("sicore.zig");
const trust = @import("trust.zig");
const taskmgr = @import("taskmgr.zig");

const N: usize = 12; // the crew

// links: vera routes, mira gates, merlin executes, gaven watches
const LINKS = [_][2]usize{
    .{ 0, 1 }, .{ 0, 2 }, .{ 0, 3 }, // vera → mira, merlin, gaven
    .{ 1, 2 }, // mira → merlin
    .{ 2, 4 }, .{ 2, 5 }, .{ 2, 6 }, .{ 2, 7 }, // merlin → broods
    .{ 3, 1 }, // gaven watches mira
    .{ 8, 1 }, // paintr → mira
    .{ 9, 3 }, // veda → gaven
    .{ 11, 2 }, // hand → merlin
    .{ 10, 8 }, // si-core-gfx → paintr
    .{ 4, 5 }, .{ 6, 7 }, // brood pairs
};

var phase: [N]f32 = [_]f32{0} ** N;
var pulse_t: f32 = 0;

// η-gate: links whose coherence falls below 0.500 are denied.
// Gaven's law — the same threshold as the tRust watchdog.
pub var link_denied: [LINKS.len]bool = [_]bool{false} ** LINKS.len;

pub fn node_pos(i: usize) [3]f32 {
    if (i < 4) {
        // inner ring: the core crew
        const a = @as(f32, @floatFromInt(i)) * (std.math.pi * 2.0 / 4.0) + 0.4;
        const y: f32 = if (i % 2 == 0) 0.28 else -0.28;
        return .{ @cos(a) * 0.55, y, @sin(a) * 0.55 };
    }
    // outer ring: workers and specialists
    const j = i - 4;
    const a = @as(f32, @floatFromInt(j)) * (std.math.pi * 2.0 / 8.0);
    const y: f32 = if (j % 2 == 0) -0.35 else 0.35;
    return .{ @cos(a) * 1.05, y, @sin(a) * 1.05 };
}

fn node_color(i: usize) [3]u8 {
    if (i >= trust.ntasks) return sicore.GRAY;
    return switch (trust.tasks[i].state) {
        .idle => sicore.GRAY,
        .ready => sicore.WHITE,
        .running => sicore.GREEN,
        .yielding => sicore.GOLD,
        .blocked => sicore.CRIMSON,
        .done => sicore.GRAY,
        .faulted => sicore.CRIMSON_LT,
    };
}

pub fn tick() void {
    // Weak coupling, wide frequency spread: the mesh genuinely drifts in
    // and out of coherence, so η-denials happen for real — never staged.
    const K: f32 = 0.3;
    const dt: f32 = 0.12;
    var d: [N]f32 = undefined;
    var i: usize = 0;
    while (i < N) : (i += 1) {
        var sum: f32 = 0;
        var j: usize = 0;
        while (j < N) : (j += 1) {
            if (j != i) sum += @sin(phase[j] - phase[i]);
        }
        const omega: f32 = 0.7 + @as(f32, @floatFromInt(i)) * 0.09;
        d[i] = omega + K / @as(f32, N) * sum;
    }
    i = 0;
    while (i < N) : (i += 1) phase[i] += d[i] * dt;
    pulse_t += dt;
    // η-gate: coherence below 0.500 denies the crossing
    var li: usize = 0;
    while (li < LINKS.len) : (li += 1) {
        const a = LINKS[li][0];
        const b = LINKS[li][1];
        const cohere = (@cos(phase[a] - phase[b]) + 1.0) / 2.0;
        link_denied[li] = cohere < 0.5;
    }
}

fn project(p: [3]f32, cx: i32, cy: i32, s: i32) [2]i32 {
    return pyre.project_orbit(p, cx, cy, s); // unified: pyre.zig owns the orbit projection
}

fn lerp3(a: [3]u8, b: [3]u8, t: f32) [3]u8 {
    return .{
        @intFromFloat(@as(f32, @floatFromInt(a[0])) * (1.0 - t) + @as(f32, @floatFromInt(b[0])) * t),
        @intFromFloat(@as(f32, @floatFromInt(a[1])) * (1.0 - t) + @as(f32, @floatFromInt(b[1])) * t),
        @intFromFloat(@as(f32, @floatFromInt(a[2])) * (1.0 - t) + @as(f32, @floatFromInt(b[2])) * t),
    };
}

pub fn project_node(i: usize, cx: i32, cy: i32, s: i32) [2]i32 {
    return project(node_pos(i), cx, cy, s);
}

// ---- agent sigils: geometric avatars, role-derived ----
// vera=triangle (routes point out), mira=square (the gate),
// merlin=diamond (the executor), gaven=hexagon (the sentinel),
// broods=squares (workers), paintr=star, veda=ring (the lens),
// si-core-gfx=orb, hand=pentagon.
fn draw_avatar(i: usize, x: i32, y: i32, c: [3]u8) void {
    const r: i32 = 7;
    switch (i) {
        0 => { // vera: triangle
            sicore.line(x, y - r, x + r, y + r, c);
            sicore.line(x + r, y + r, x - r, y + r, c);
            sicore.line(x - r, y + r, x, y - r, c);
        },
        1 => { // mira: square (the gate)
            sicore.rect(x - r, y - r, x + r, y - r + 1, c);
            sicore.rect(x - r, y + r, x + r, y + r + 1, c);
            sicore.rect(x - r, y - r, x - r + 1, y + r, c);
            sicore.rect(x + r, y - r, x + r + 1, y + r, c);
        },
        2 => { // merlin: filled diamond
            var k: i32 = 0;
            while (k <= r) : (k += 1) {
                sicore.hline(x - k, x + k, y - r + k, c);
                if (k < r) sicore.hline(x - k, x + k, y + r - k, c);
            }
        },
        3 => { // gaven: hexagon
            const h: i32 = r * 2 / 3;
            sicore.line(x - r, y, x - h, y - r, c);
            sicore.line(x - h, y - r, x + h, y - r, c);
            sicore.line(x + h, y - r, x + r, y, c);
            sicore.line(x + r, y, x + h, y + r, c);
            sicore.line(x + h, y + r, x - h, y + r, c);
            sicore.line(x - h, y + r, x - r, y, c);
        },
        4, 5, 6, 7 => { // broods: worker squares
            sicore.rect(x - 4, y - 4, x + 4, y + 4, c);
        },
        8 => { // paintr: star
            sicore.line(x - r, y, x + r, y, c);
            sicore.line(x, y - r, x, y + r, c);
            sicore.line(x - 5, y - 5, x + 5, y + 5, c);
            sicore.line(x - 5, y + 5, x + 5, y - 5, c);
        },
        9 => { // veda: the lens
            sicore.ring(x, y, 6, 2, c, 220);
        },
        10 => { // si-core-gfx: the orb
            sicore.circle(x, y, 4, c);
            sicore.ring(x, y, 7, 1, c, 160);
        },
        else => { // hand: pentagon
            const h: i32 = r * 2 / 3;
            sicore.line(x, y - r, x + r, y - h, c);
            sicore.line(x + r, y - h, x + h, y + r, c);
            sicore.line(x + h, y + r, x - h, y + r, c);
            sicore.line(x - h, y + r, x - r, y - h, c);
            sicore.line(x - r, y - h, x, y - r, c);
        },
    }
}

pub fn render(cx: i32, cy: i32, s: i32) void {
    var px: [N]i32 = undefined;
    var py: [N]i32 = undefined;
    var i: usize = 0;
    while (i < N) : (i += 1) {
        const q = project(node_pos(i), cx, cy, s);
        px[i] = q[0];
        py[i] = q[1];
    }

    // links: brightness = phase alignment (coherence visible)
    // denied links go dark: the crossing is refused, no pulse travels
    for (LINKS, 0..) |l, li| {
        const a = l[0];
        const b = l[1];
        if (link_denied[li]) {
            sicore.line(px[a], py[a], px[b], py[b], .{ 26, 10, 14 });
            continue;
        }
        const cohere = (@cos(phase[a] - phase[b]) + 1.0) / 2.0;
        const c = lerp3(.{ 46, 10, 18 }, sicore.CRIMSON_LT, cohere);
        sicore.line(px[a], py[a], px[b], py[b], c);
        // pulse traveling the synapse
        const p = @mod(pulse_t * 0.45 + @as(f32, @floatFromInt(li)) * 0.37, 1.0);
        const qx = @as(i32, @intFromFloat(@as(f32, @floatFromInt(px[a])) * (1.0 - p) + @as(f32, @floatFromInt(px[b])) * p));
        const qy = @as(i32, @intFromFloat(@as(f32, @floatFromInt(py[a])) * (1.0 - p) + @as(f32, @floatFromInt(py[b])) * p));
        sicore.glow(qx, qy, 7, sicore.GOLD, 130);
    }

    // nodes: each agent wears its sigil; state shows through the glow
    i = 0;
    while (i < N) : (i += 1) {
        const c = node_color(i);
        sicore.glow(px[i], py[i], 15, c, 90);
        draw_avatar(i, px[i], py[i], c);
    }

    // labels for the core crew + painter
    const label_idx = [_]usize{ 0, 1, 2, 3, 8 };
    for (label_idx) |li| {
        if (li < trust.ntasks) {
            taskmgr.draw_text_pub(px[li] + 10, py[li] - 4, trust.task_name(&trust.tasks[li]), sicore.GRAY);
        }
    }
}
