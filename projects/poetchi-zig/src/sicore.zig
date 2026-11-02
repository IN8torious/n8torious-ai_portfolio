// Harakiri NG — SI Core (graphics variant)
// The internal graphics engine. Owns the framebuffer, serves draw requests.
// A variant of Nathan's SI Core, scoped to graphics.
// Nathan Brown, 2026.

// SI Core identity
pub const SI_NAME = "si-core-gfx";
pub const SI_VERSION = "0.1";
pub const SI_ROLE = "internal graphics engine";

pub const FB_W = 1280;
pub const FB_H = 720;

// The framebuffer — SI Core owns this. Nobody else touches it directly.
var fb: [FB_W * FB_H * 3]u8 = undefined;

// Harakiri palette
pub const OBSIDIAN = [3]u8{ 12, 8, 14 };
pub const CRIMSON = [3]u8{ 220, 20, 60 };
pub const CRIMSON_LT = [3]u8{ 255, 45, 85 };
pub const GOLD = [3]u8{ 212, 175, 55 };
pub const WHITE = [3]u8{ 240, 240, 245 };
pub const GRAY = [3]u8{ 80, 80, 90 };
pub const DARK = [3]u8{ 25, 18, 28 };
pub const GREEN = [3]u8{ 45, 200, 100 };

// ---- core pixel op (private — only SI Core writes pixels) ----
fn px(x: i32, y: i32, c: [3]u8) void {
    if (x < 0 or y < 0 or x >= FB_W or y >= FB_H) return;
    const i: usize = @intCast((y * FB_W + x) * 3);
    fb[i] = c[0];
    fb[i + 1] = c[1];
    fb[i + 2] = c[2];
}

// ---- public draw API (what agents call through tRust contracts) ----
pub fn plot(x: i32, y: i32, c: [3]u8) void {
    px(x, y, c);
}

pub fn clear(c: [3]u8) void {
    var i: usize = 0;
    while (i < fb.len) : (i += 3) {
        fb[i] = c[0];
        fb[i + 1] = c[1];
        fb[i + 2] = c[2];
    }
}

pub fn rect(x0: i32, y0: i32, x1: i32, y1: i32, c: [3]u8) void {
    var y = y0;
    while (y < y1) : (y += 1) {
        var x = x0;
        while (x < x1) : (x += 1) px(x, y, c);
    }
}

pub fn hline(x0: i32, x1: i32, y: i32, c: [3]u8) void {
    var x = x0;
    while (x < x1) : (x += 1) px(x, y, c);
}

pub fn vline(x: i32, y0: i32, y1: i32, c: [3]u8) void {
    var y = y0;
    while (y < y1) : (y += 1) px(x, y, c);
}

pub fn line(x0: i32, y0: i32, x1: i32, y1: i32, c: [3]u8) void {    var x = x0;
    var y = y0;
    const dx: i32 = if (x1 > x0) x1 - x0 else x0 - x1;
    const dy: i32 = if (y1 > y0) y1 - y0 else y0 - y1;
    const sx: i32 = if (x0 < x1) 1 else -1;
    const sy: i32 = if (y0 < y1) 1 else -1;
    var err = dx - dy;
    while (true) {
        px(x, y, c);
        if (x == x1 and y == y1) break;
        const e2 = 2 * err;
        if (e2 > -dy) { err -= dy; x += sx; }
        if (e2 < dx) { err += dx; y += sy; }
    }
}

// ---- framebuffer access (for PPM dump) ----
pub fn fb_ptr() [*]u8 {
    return &fb;
}

pub fn fb_len() usize {
    return fb.len;
}

// ---- cinematic kit: the Unreal treatment ----

// alpha-blend one pixel (alpha 0..255)
pub fn blend(x: i32, y: i32, c: [3]u8, alpha: u8) void {
    if (x < 0 or y < 0 or x >= FB_W or y >= FB_H) return;
    const i: usize = @intCast((y * FB_W + x) * 3);
    const a: u16 = alpha;
    const ia: u16 = 255 - a;
    fb[i] = @intCast((@as(u16, c[0]) * a + @as(u16, fb[i]) * ia) / 255);
    fb[i + 1] = @intCast((@as(u16, c[1]) * a + @as(u16, fb[i + 1]) * ia) / 255);
    fb[i + 2] = @intCast((@as(u16, c[2]) * a + @as(u16, fb[i + 2]) * ia) / 255);
}

pub fn rect_blend(x0: i32, y0: i32, x1: i32, y1: i32, c: [3]u8, alpha: u8) void {
    var y = y0;
    while (y < y1) : (y += 1) {
        var x = x0;
        while (x < x1) : (x += 1) blend(x, y, c, alpha);
    }
}

// vertical gradient fill
pub fn vgrad(x0: i32, y0: i32, x1: i32, y1: i32, c0: [3]u8, c1: [3]u8) void {
    const h = y1 - y0;
    if (h <= 0) return;
    var y = y0;
    while (y < y1) : (y += 1) {
        const t: f32 = @as(f32, @floatFromInt(y - y0)) / @as(f32, @floatFromInt(h));
        const u: f32 = 1.0 - t;
        const r: u8 = @intFromFloat(@as(f32, @floatFromInt(c0[0])) * u + @as(f32, @floatFromInt(c1[0])) * t);
        const g: u8 = @intFromFloat(@as(f32, @floatFromInt(c0[1])) * u + @as(f32, @floatFromInt(c1[1])) * t);
        const b: u8 = @intFromFloat(@as(f32, @floatFromInt(c0[2])) * u + @as(f32, @floatFromInt(c1[2])) * t);
        hline(x0, x1, y, .{ r, g, b });
    }
}

// radial glow: soft falloff light around (cx,cy)
pub fn glow(cx: i32, cy: i32, radius: i32, c: [3]u8, peak: u8) void {
    var y = cy - radius;
    while (y <= cy + radius) : (y += 1) {
        var x = cx - radius;
        while (x <= cx + radius) : (x += 1) {
            const dx = x - cx;
            const dy = y - cy;
            const d2 = dx * dx + dy * dy;
            if (d2 > radius * radius) continue;
            const d: f32 = @sqrt(@as(f32, @floatFromInt(d2)));
            const t = 1.0 - d / @as(f32, @floatFromInt(radius));
            const a: u8 = @intFromFloat(t * t * @as(f32, @floatFromInt(peak)));
            if (a > 0) blend(x, y, c, a);
        }
    }
}

// soft drop shadow under a rect: layered expanding blends
pub fn shadow(x0: i32, y0: i32, x1: i32, y1: i32, layers: i32, alpha: u8) void {
    var r = layers;
    while (r > 0) : (r -= 1) {
        const a: u8 = @intCast(@divTrunc(@as(i32, alpha) * (layers - r + 1), layers * 3));
        rect_blend(x0 - r, y0 - r, x1 + r, y1 + r, .{ 0, 0, 0 }, a);
    }
}

// filled circle
pub fn circle(cx: i32, cy: i32, r: i32, c: [3]u8) void {
    var y = cy - r;
    while (y <= cy + r) : (y += 1) {
        var x = cx - r;
        while (x <= cx + r) : (x += 1) {
            const dx = x - cx;
            const dy = y - cy;
            if (dx * dx + dy * dy <= r * r) px(x, y, c);
        }
    }
}

// ring outline with alpha: the well's pulse bands
pub fn ring(cx: i32, cy: i32, r: i32, thick: i32, c: [3]u8, alpha: u8) void {
    var y = cy - r - thick;
    while (y <= cy + r + thick) : (y += 1) {
        var x = cx - r - thick;
        while (x <= cx + r + thick) : (x += 1) {
            const dx = x - cx;
            const dy = y - cy;
            const d2 = dx * dx + dy * dy;
            const ro = r + @divTrunc(thick, 2);
            const ri = r - @divTrunc(thick, 2);
            if (d2 <= ro * ro and d2 >= ri * ri) blend(x, y, c, alpha);
        }
    }
}

// vignette: darken toward the corners (amount 0..255)
pub fn vignette(amount: u8) void {
    const cx: f32 = @as(f32, FB_W) / 2.0;
    const cy: f32 = @as(f32, FB_H) / 2.0;
    const maxd: f32 = @sqrt(cx * cx + cy * cy);
    const amt: f32 = @as(f32, @floatFromInt(amount)) / 255.0;
    var y: i32 = 0;
    while (y < FB_H) : (y += 1) {
        var x: i32 = 0;
        while (x < FB_W) : (x += 1) {
            const dx = @as(f32, @floatFromInt(x)) - cx;
            const dy = @as(f32, @floatFromInt(y)) - cy;
            const d = @sqrt(dx * dx + dy * dy) / maxd;
            const f = 1.0 - amt * d * d * 1.8;
            if (f < 0.999) {
                const i: usize = @intCast((y * FB_W + x) * 3);
                fb[i] = @intFromFloat(@as(f32, @floatFromInt(fb[i])) * f);
                fb[i + 1] = @intFromFloat(@as(f32, @floatFromInt(fb[i + 1])) * f);
                fb[i + 2] = @intFromFloat(@as(f32, @floatFromInt(fb[i + 2])) * f);
            }
        }
    }
}

// ---- SI Core status ----
pub fn about() []const u8 {
    return "si-core-gfx v0.1 — internal graphics engine";
}
