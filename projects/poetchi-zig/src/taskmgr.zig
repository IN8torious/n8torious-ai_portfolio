// Harakiri NG — Visual Task Manager
// Windows-style: process list, graphs, descriptors. Fully transparent agents.
// Renders through SI Core (internal graphics engine). Dumps as PPM.
// Nathan Brown, 2026.

const trust = @import("trust.zig");
const sicore = @import("sicore.zig");
const profont = @import("profont.zig");

// Re-export for convenience
const OBSIDIAN = sicore.OBSIDIAN;
const CRIMSON = sicore.CRIMSON;
const CRIMSON_LT = sicore.CRIMSON_LT;
const GOLD = sicore.GOLD;
const WHITE = sicore.WHITE;
const GRAY = sicore.GRAY;
const DARK = sicore.DARK;
const GREEN = sicore.GREEN;

const FB_W = sicore.FB_W;
const FB_H = sicore.FB_H;

// ---- profont text: 8x12 professional sans, 2x supersampled, upright ----
// Each glyph is rasterized into a 16x24 coverage buffer, then box-downsampled
// 2x2. Edge pixels land as 4-level grayscale blends. No slant — professional
// means upright.
fn draw_char(x: i32, y: i32, ch: u8, c: [3]u8) void {
    const g = profont.glyph(ch);
    var buf: [24][16]bool = [_][16]bool{[_]bool{false} ** 16} ** 24;
    var row: usize = 0;
    while (row < 12) : (row += 1) {
        var col: usize = 0;
        while (col < 8) : (col += 1) {
            if ((g[row] >> @intCast(7 - col)) & 1 != 0) {
                const bx = col * 2;
                const by = row * 2;
                buf[by][bx] = true;
                buf[by][bx + 1] = true;
                buf[by + 1][bx] = true;
                buf[by + 1][bx + 1] = true;
            }
        }
    }
    var oy: i32 = 0;
    while (oy < 12) : (oy += 1) {
        var ox: i32 = 0;
        while (ox < 8) : (ox += 1) {
            const ux: usize = @intCast(ox);
            const uy: usize = @intCast(oy);
            var cov: u8 = 0;
            if (buf[uy * 2][ux * 2]) cov += 1;
            if (buf[uy * 2][ux * 2 + 1]) cov += 1;
            if (buf[uy * 2 + 1][ux * 2]) cov += 1;
            if (buf[uy * 2 + 1][ux * 2 + 1]) cov += 1;
            if (cov == 0) continue;
            const a: u8 = if (cov >= 4) 255 else cov * 64;
            sicore.blend(x + ox + 1, y + oy + 1, .{ 4, 2, 5 }, a); // shadow
            sicore.blend(x + ox, y + oy, c, a);
        }
    }
}


pub fn draw_text_pub(x: i32, y: i32, s: []const u8, c: [3]u8) void {
    draw_text(x, y, s, c);
}

// 2x headline text: each glyph pixel becomes a 2x2 block
pub fn draw_text_2x_pub(x: i32, y: i32, s: []const u8, c: [3]u8) void {
    var cx = x;
    for (s) |ch| {
        draw_char_2x(cx, y, ch, c);
        cx += 18;
    }
}

// decimal u64 for the framebuffer (scheduler vruntime readout)
pub fn draw_ulong_pub(x: i32, y: i32, v: u64, c: [3]u8) void {
    var buf: [20]u8 = undefined;
    var len: usize = 0;
    var n = v;
    if (n == 0) {
        buf[0] = '0';
        len = 1;
    } else {
        var tmp: [20]u8 = undefined;
        var tl: usize = 0;
        while (n > 0) : (tl += 1) {
            tmp[tl] = @intCast(n % 10 + '0');
            n /= 10;
        }
        while (tl > 0) : (tl -= 1) {
            buf[len] = tmp[tl - 1];
            len += 1;
        }
    }
    draw_text(x, y, buf[0..len], c);
}

fn draw_char_2x(x: i32, y: i32, ch: u8, c: [3]u8) void {
    const g = profont.glyph(ch);
    var row: u8 = 0;
    while (row < 12) : (row += 1) {
        var col: u8 = 0;
        while (col < 8) : (col += 1) {
            if ((g[row] >> @intCast(7 - col)) & 1 != 0) {
                const bx = x + @as(i32, col) * 2;
                const by = y + @as(i32, row) * 2;
                sicore.rect(bx + 2, by + 2, bx + 4, by + 4, .{ 4, 2, 5 });
                sicore.rect(bx, by, bx + 2, by + 2, c);
            }
        }
    }
}

fn draw_text(x: i32, y: i32, s: []const u8, c: [3]u8) void {
    var cx = x;
    for (s) |ch| {
        draw_char(cx, y, ch, c);
        cx += profont.ADV;
    }
}

// ---- agent descriptors ----
fn descriptor(name: []const u8) []const u8 {
    if (eql(name, "vera")) return "intent router";
    if (eql(name, "mira")) return "gate keeper";
    if (eql(name, "merlin")) return "executor";
    if (eql(name, "gaven")) return "sentinel";
    if (startsWith(name, "brood")) return "worker";
    if (eql(name, "paintr")) return "painter";
    if (eql(name, "veda")) return "auditor";
    return "unknown";
}

fn eql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |x, y| if (x != y) return false;
    return true;
}

fn startsWith(s: []const u8, prefix: []const u8) bool {
    if (s.len < prefix.len) return false;
    for (prefix, 0..) |c, i| if (s[i] != c) return false;
    return true;
}

// ---- history for graphs ----
const HIST_LEN = 64;
var hist: [16][HIST_LEN]u8 = undefined; // quanta per tick, per task
var hist_pos: usize = 0;

pub fn sample() void {
    for (trust.tasks[0..trust.ntasks], 0..) |*t, i| {
        if (i < 16) hist[i][hist_pos] = @truncate(@min(t.quanta_used, 255));
    }
    hist_pos = (hist_pos + 1) % HIST_LEN;
}

// ---- render the task manager ----
pub fn render() void {
    // background
    sicore.rect(0, 0, FB_W, FB_H, OBSIDIAN);

    // title bar
    sicore.rect(0, 0, FB_W, 36, DARK);
    sicore.hline(0, FB_W, 36, CRIMSON);
    draw_text(16, 12, "HARAKIRI TASK MANAGER", WHITE);
    draw_text(FB_W - 140, 12, "tRust watchdog", GRAY);

    // column headers
    draw_text(16, 48, "AGENT", GRAY);
    draw_text(140, 48, "STATE", GRAY);
    draw_text(230, 48, "QUANTA", GRAY);
    draw_text(320, 48, "ETA", GRAY);
    sicore.hline(16, FB_W - 16, 62, DARK);

    // process list
    var y: i32 = 70;
    for (trust.tasks[0..trust.ntasks], 0..) |*t, i| {
        if (i >= 10) break; // show first 10
        const name = trust.task_name(t);
        draw_text(16, y, name, WHITE);
        draw_text(140, y, @tagName(t.state), state_color(t.state));
        // quanta bar
        const qbar_w: i32 = @intCast(@min(t.quanta_used * 60 / @max(t.contract.max_quanta, 1), 60));
        sicore.rect(230, y + 1, 230 + 60, y + 6, DARK);
        sicore.rect(230, y + 1, 230 + qbar_w, y + 6, CRIMSON);
        // eta
        var eta_buf: [8]u8 = undefined;
        const eta_s = fmt_int(t.eta_x1000, &eta_buf);
        draw_text(320, y, eta_s, if (t.eta_x1000 >= 500) GREEN else CRIMSON_LT);
        // descriptor
        draw_text(380, y, descriptor(name), GRAY);
        y += 20;
    }

    // graphs section
    const gy: i32 = 300;
    draw_text(16, gy - 20, "QUANTA HISTORY", GRAY);
    sicore.hline(16, FB_W - 16, gy - 8, DARK);

    // draw one graph per task (first 5, side by side)
    const gw: i32 = 110;
    const gh: i32 = 80;
    for (0..@min(trust.ntasks, 5)) |i| {
        const gx: i32 = 16 + @as(i32, @intCast(i)) * (gw + 12);
        // frame
        sicore.rect(gx, gy, gx + gw, gy + gh, DARK);
        const name = trust.task_name(&trust.tasks[i]);
        draw_text(gx + 4, gy + gh + 4, name, GRAY);
        // line graph
        var hx: usize = 0;
        while (hx < HIST_LEN - 1) : (hx += 1) {
            const p1 = (hist_pos + hx) % HIST_LEN;
            const p2 = (hist_pos + hx + 1) % HIST_LEN;
            const v1: i32 = hist[i][p1];
            const v2: i32 = hist[i][p2];
            const x1 = gx + 4 + @as(i32, @intCast(hx * (@as(usize, @intCast(gw - 8)) / HIST_LEN)));
            const x2 = gx + 4 + @as(i32, @intCast((hx + 1) * (@as(usize, @intCast(gw - 8)) / HIST_LEN)));
            const y1 = gy + gh - 4 - @divTrunc(v1 * (gh - 8), 255);
            const y2 = gy + gh - 4 - @divTrunc(v2 * (gh - 8), 255);
            sicore.line(x1, y1, x2, y2, CRIMSON_LT);
        }
    }

    // footer
    sicore.rect(0, FB_H - 28, FB_W, FB_H, DARK);
    draw_text(16, FB_H - 20, "tRust: no contract, no execution", CRIMSON_LT);
}

fn state_color(s: trust.TaskState) [3]u8 {
    return switch (s) {
        .idle => GRAY,
        .ready => WHITE,
        .running => GREEN,
        .yielding => GOLD,
        .blocked => CRIMSON,
        .done => GRAY,
        .faulted => CRIMSON_LT,
    };

}

fn fmt_int(v: u32, buf: []u8) []u8 {
    var i = buf.len;
    var n = v;
    if (n == 0) {
        i -= 1;
        buf[i] = '0';
        return buf[i..];
    }
    while (n > 0 and i > 0) {
        i -= 1;
        buf[i] = '0' + @as(u8, @truncate(n % 10));
        n /= 10;
    }
    return buf[i..];
}


