// Harakiri NG — icons
// 3D-beveled icons: every icon is a little machined object — dark outer
// edge, lit top-left bevel, dark bottom-right bevel, face, glyph.
// Nathan Brown, 2026.

const sicore = @import("sicore.zig");

fn lighten(c: [3]u8, f: f32) [3]u8 {
    const r: i32 = @min(255, @as(i32, @intFromFloat(@as(f32, @floatFromInt(c[0])) * f)));
    const g: i32 = @min(255, @as(i32, @intFromFloat(@as(f32, @floatFromInt(c[1])) * f)));
    const b: i32 = @min(255, @as(i32, @intFromFloat(@as(f32, @floatFromInt(c[2])) * f)));
    return .{ @intCast(r), @intCast(g), @intCast(b) };
}

fn darken(c: [3]u8, f: f32) [3]u8 {
    return .{
        @intFromFloat(@as(f32, @floatFromInt(c[0])) * f),
        @intFromFloat(@as(f32, @floatFromInt(c[1])) * f),
        @intFromFloat(@as(f32, @floatFromInt(c[2])) * f),
    };
}

// agent glyphs: 0=triangle 1=square 2=diamond 3=hexagon 4=star
// 5=ring 6=orb 7=pentagon 8=dot
pub fn draw_glyph(glyph: usize, x: i32, y: i32, r: i32, c: [3]u8) void {
    switch (glyph) {
        0 => {
            sicore.line(x, y - r, x + r, y + r, c);
            sicore.line(x + r, y + r, x - r, y + r, c);
            sicore.line(x - r, y + r, x, y - r, c);
        },
        1 => {
            sicore.rect(x - r, y - r, x + r, y - r + 1, c);
            sicore.rect(x - r, y + r, x + r, y + r + 1, c);
            sicore.rect(x - r, y - r, x - r + 1, y + r, c);
            sicore.rect(x + r, y - r, x + r + 1, y + r, c);
        },
        2 => {
            var k: i32 = 0;
            while (k <= r) : (k += 1) {
                sicore.hline(x - k, x + k, y - r + k, c);
                if (k < r) sicore.hline(x - k, x + k, y + r - k, c);
            }
        },
        3 => {
            const h: i32 = @divTrunc(r * 2, 3);
            sicore.line(x - r, y, x - h, y - r, c);
            sicore.line(x - h, y - r, x + h, y - r, c);
            sicore.line(x + h, y - r, x + r, y, c);
            sicore.line(x + r, y, x + h, y + r, c);
            sicore.line(x + h, y + r, x - h, y + r, c);
            sicore.line(x - h, y + r, x - r, y, c);
        },
        4 => {
            sicore.line(x - r, y, x + r, y, c);
            sicore.line(x, y - r, x, y + r, c);
            sicore.line(x - @divTrunc(r * 2, 3), y - @divTrunc(r * 2, 3), x + @divTrunc(r * 2, 3), y + @divTrunc(r * 2, 3), c);
            sicore.line(x - @divTrunc(r * 2, 3), y + @divTrunc(r * 2, 3), x + @divTrunc(r * 2, 3), y - @divTrunc(r * 2, 3), c);
        },
        5 => sicore.ring(x, y, r, 2, c, 220),
        6 => sicore.circle(x, y, @divTrunc(r * 2, 3), c),
        7 => {
            const h: i32 = @divTrunc(r * 2, 3);
            sicore.line(x, y - r, x + r, y - h, c);
            sicore.line(x + r, y - h, x + h, y + r, c);
            sicore.line(x + h, y + r, x - h, y + r, c);
            sicore.line(x - h, y + r, x - r, y - h, c);
            sicore.line(x - r, y - h, x, y - r, c);
        },
        else => sicore.circle(x, y, @divTrunc(r * 2, 3), c),
    }
}

// a full beveled icon: shadow, bevel, face, centered glyph
pub fn beveled_icon(x: i32, y: i32, s: i32, face: [3]u8, glyph: usize, gc: [3]u8) void {
    const b: i32 = 2;
    // drop shadow
    sicore.rect_blend(x + 2, y + 3, x + s + 2, y + s + 3, .{ 0, 0, 0 }, 90);
    // dark outer edge
    sicore.rect(x, y, x + s, y + s, darken(face, 0.4));
    // bevel: light falls from the top-left
    const lt = lighten(face, 1.6);
    const dk = darken(face, 0.55);
    sicore.rect(x + 1, y + 1, x + s - 1, y + 1 + b, lt);
    sicore.rect(x + 1, y + 1, x + 1 + b, y + s - 1, lt);
    sicore.rect(x + 1, y + s - 1 - b, x + s - 1, y + s - 1, dk);
    sicore.rect(x + s - 1 - b, y + 1, x + s - 1, y + s - 1, dk);
    // face
    sicore.rect(x + 1 + b, y + 1 + b, x + s - 1 - b, y + s - 1 - b, face);
    // face highlight: a soft top sheen
    sicore.rect_blend(x + 1 + b, y + 1 + b, x + s - 1 - b, y + 1 + b + @divTrunc(s, 4), lt, 40);
    // glyph
    draw_glyph(glyph, x + @divTrunc(s, 2), y + @divTrunc(s, 2) + 1, @divTrunc(s, 4), gc);
}

// agent index -> glyph (mirrors the mesh avatars)
pub fn agent_glyph(i: usize) usize {
    return switch (i) {
        0 => 0, // vera: triangle
        1 => 1, // mira: square
        2 => 2, // merlin: diamond
        3 => 3, // gaven: hexagon
        4, 5, 6, 7 => 8, // broods: dots
        8 => 4, // paintr: star
        9 => 5, // veda: ring
        10 => 6, // si-core-gfx: orb
        else => 7, // hand: pentagon
    };
}
