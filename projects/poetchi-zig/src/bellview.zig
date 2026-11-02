// Harakiri NG — Bell viewport (entanglement made visible)
// Phase 6c of the entanglement roadmap. Drawn inside the mesh viewport,
// over mesh.render, in the same (cx, cy, s) projection.
//
// The honest shape of entanglement:
//   - the BEAM burns: brightness, thickness and pulse rate are the live
//     concurrence C of the pair (bell.zig).
//   - the Bloch spheres stay DARK: while a pair is entangled each node's
//     reduced state is maximally mixed (Bloch vector = 0), so each sphere
//     renders as a dark core with an arrow of length zero. Nothing local;
//     everything in the correlation.
//   - the eta-gate snap: C < 0.500 downgrades the beam to the mesh's
//     ordinary classical link rendering, in place. One threshold, two regimes.
// Nathan Brown, 2026.

const std = @import("std");
const sicore = @import("sicore.zig");
const mesh = @import("mesh.zig");
const taskmgr = @import("taskmgr.zig");
const bell = @import("bell.zig");

var pulse_t: f32 = 0;

fn lerp3(a: [3]u8, b: [3]u8, t: f32) [3]u8 {
    return .{
        @intFromFloat(@as(f32, @floatFromInt(a[0])) * (1.0 - t) + @as(f32, @floatFromInt(b[0])) * t),
        @intFromFloat(@as(f32, @floatFromInt(a[1])) * (1.0 - t) + @as(f32, @floatFromInt(b[1])) * t),
        @intFromFloat(@as(f32, @floatFromInt(a[2])) * (1.0 - t) + @as(f32, @floatFromInt(b[2])) * t),
    };
}

fn drawBloch(c: [2]i32, v: [3]f32) void {
    sicore.ring(c[0], c[1], 13, 1, sicore.GRAY, 200);
    const len = @sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    if (len < 0.05) {
        // maximally mixed: a dark core, an arrow of length zero
        sicore.circle(c[0], c[1], 3, .{ 34, 34, 42 });
    } else {
        const ex = c[0] + @as(i32, @intFromFloat(v[0] * 12.0));
        const ey = c[1] - @as(i32, @intFromFloat(v[1] * 12.0));
        sicore.line(c[0], c[1], ex, ey, sicore.GOLD);
        sicore.circle(ex, ey, 2, sicore.WHITE);
    }
}

// format a signed milli value ("-2.879") into buf; returns the slice
fn fmtMilli(buf: []u8, milli: i32) []const u8 {
    var n: usize = 0;
    var v = milli;
    if (v < 0) {
        buf[n] = '-';
        n += 1;
        v = -v;
    }
    const whole: u32 = @intCast(@divTrunc(v, 1000));
    const frac: u32 = @intCast(@mod(v, 1000));
    var digits: [8]u8 = undefined;
    var dn: usize = 0;
    var w = whole;
    if (w == 0) {
        digits[dn] = '0';
        dn += 1;
    }
    while (w > 0) {
        digits[dn] = @intCast('0' + w % 10);
        dn += 1;
        w /= 10;
    }
    while (dn > 0) {
        dn -= 1;
        buf[n] = digits[dn];
        n += 1;
    }
    buf[n] = '.';
    n += 1;
    buf[n] = @intCast('0' + (frac / 100) % 10);
    n += 1;
    buf[n] = @intCast('0' + (frac / 10) % 10);
    n += 1;
    buf[n] = @intCast('0' + frac % 10);
    n += 1;
    return buf[0..n];
}

pub fn render_vp(cx: i32, cy: i32, s: i32) void {
    pulse_t += 0.016;
    for (bell.pairs, 0..) |p, pi| {
        if (!p.active) continue;
        const pa = mesh.project_node(p.a, cx, cy, s);
        const pb = mesh.project_node(p.b, cx, cy, s);

        if (p.broken) {
            // the X-form guard fired: alarm magenta, never a fake beam
            sicore.line(pa[0], pa[1], pb[0], pb[1], .{ 255, 0, 255 });
        } else if (p.c >= 0.5) {
            const thick: i32 = 1 + @as(i32, @intFromFloat(p.c * 3.0));
            const col = lerp3(sicore.GOLD, sicore.WHITE, p.c);
            var o: i32 = -thick;
            while (o <= thick) : (o += 1) {
                sicore.line(pa[0] + o, pa[1], pb[0] + o, pb[1], col);
            }
            // midpoint aura, radius from C
            const mx = @divTrunc(pa[0] + pb[0], 2);
            const my = @divTrunc(pa[1] + pb[1], 2);
            const rad: i32 = 10 + @as(i32, @intFromFloat(p.c * 14.0));
            sicore.glow(mx, my, rad, sicore.GOLD, 60);
            // pulse traveling the beam; its rate is C
            const ph = @mod(pulse_t * (0.4 + p.c) + @as(f32, @floatFromInt(pi)) * 0.31, 1.0);
            const qx = @as(i32, @intFromFloat(@as(f32, @floatFromInt(pa[0])) * (1.0 - ph) + @as(f32, @floatFromInt(pb[0])) * ph));
            const qy = @as(i32, @intFromFloat(@as(f32, @floatFromInt(pa[1])) * (1.0 - ph) + @as(f32, @floatFromInt(pb[1])) * ph));
            sicore.glow(qx, qy, 9, sicore.GOLD, 160);
        } else {
            // decayed below the eta-gate floor: a classical link, in place
            sicore.line(pa[0], pa[1], pb[0], pb[1], .{ 46, 10, 18 });
        }

        // the spheres: dark while entangled, honest vectors when not
        drawBloch(pa, bell.bloch(p.rho, 0));
        drawBloch(pb, bell.bloch(p.rho, 1));
    }

    drawHud(cx, cy, s);
}

// HUD: one line per pair + the CHSH verdict, bottom-left of the viewport
fn drawHud(cx: i32, cy: i32, s: i32) void {
    _ = s;
    const x0 = cx - 300;
    var y = cy + 168;
    var buf: [16]u8 = undefined;
    for (bell.pairs) |p| {
        if (!p.active) continue;
        taskmgr.draw_text_pub(x0, y, "BELL", sicore.GOLD);
        taskmgr.draw_ulong_pub(x0 + 40, y, p.a, sicore.GOLD);
        taskmgr.draw_text_pub(x0 + 56, y, "-", sicore.GOLD);
        taskmgr.draw_ulong_pub(x0 + 64, y, p.b, sicore.GOLD);
        if (p.broken) {
            taskmgr.draw_text_pub(x0 + 88, y, "X-FORM BROKEN", .{ 255, 0, 255 });
        } else {
            taskmgr.draw_text_pub(x0 + 88, y, "C", sicore.GOLD);
            taskmgr.draw_text_pub(x0 + 104, y, fmtMilli(&buf, @intFromFloat(p.c * 1000.0)), sicore.WHITE);
            if (p.c < 0.5) taskmgr.draw_text_pub(x0 + 160, y, "CLASSICAL", sicore.GRAY);
        }
        y += 16;
    }
    if (bell.s_valid) {
        taskmgr.draw_text_pub(x0, y, "CHSH S", sicore.GOLD);
        taskmgr.draw_text_pub(x0 + 56, y, fmtMilli(&buf, bell.last_s_milli), sicore.WHITE);
        const quant = (bell.last_s_milli < -2000) or (bell.last_s_milli > 2000);
        taskmgr.draw_text_pub(x0 + 120, y, if (quant) "QUANTUM" else "CLASSICAL", if (quant) sicore.GOLD else sicore.GRAY);
    }
}
