// Harakiri NG — The Gates
// Mira's gate and Gaven's throat, made visible.
// Every mesh link whose coherence falls below η = 0.500 is denied — the
// same threshold as the tRust watchdog. Denied links go dark and their
// pulses die. Mira's gate ring flashes on every verdict change; Gaven's
// throat is the dark band the mesh must cross. Refusal is absence.
// Nathan Brown, 2026.

const std = @import("std");
const sicore = @import("sicore.zig");
const mesh = @import("mesh.zig");
const taskmgr = @import("taskmgr.zig");

var gate_flash: f32 = 0;
var last_denied: usize = 0;

pub fn tick() void {
    var n: usize = 0;
    for (mesh.link_denied) |d| {
        if (d) n += 1;
    }
    if (n != last_denied) {
        gate_flash = 1.0; // a verdict changed — the gate speaks
        last_denied = n;
    }
    gate_flash *= 0.94;
    if (gate_flash < 0.01) gate_flash = 0;
}

pub fn denied_count() usize {
    return last_denied;
}

// Mira's gate speaks: flash the ring on a verdict.
pub fn verdict_changed() void {
    gate_flash = 1.0;
}

pub fn render(cx: i32, cy: i32, s: i32) void {
    // Gaven's throat: the dark band across the world
    sicore.rect_blend(624, cy - 16, 1248, cy + 16, .{ 0, 0, 0 }, 60);
    sicore.hline(624, 1248, cy - 16, .{ 60, 12, 20 });
    sicore.hline(624, 1248, cy + 16, .{ 60, 12, 20 });
    taskmgr.draw_text_pub(636, cy + 24, "gavens throat - eta 0.500", sicore.GRAY);

    // Mira's gate: a gold ring around her node with epsilon ticks
    const q = mesh.project_node(1, cx, cy, s); // mira
    const gx = q[0];
    const gy = q[1];
    if (gate_flash > 0) {
        const fa: u8 = @intFromFloat(gate_flash * 140.0);
        sicore.glow(gx, gy, 44, sicore.GOLD, fa);
    }
    sicore.ring(gx, gy, 26, 2, sicore.GOLD, 150);
    // eight epsilon checks around the ring
    var k: i32 = 0;
    while (k < 8) : (k += 1) {
        const a = @as(f32, @floatFromInt(k)) * std.math.pi / 4.0;
        const x0 = gx + @as(i32, @intFromFloat(@cos(a) * 30.0));
        const y0 = gy + @as(i32, @intFromFloat(@sin(a) * 30.0));
        const x1 = gx + @as(i32, @intFromFloat(@cos(a) * 36.0));
        const y1 = gy + @as(i32, @intFromFloat(@sin(a) * 36.0));
        sicore.line(x0, y0, x1, y1, sicore.GOLD);
    }
    taskmgr.draw_text_pub(gx - 30, gy + 42, "miras gate", sicore.GOLD);
}
