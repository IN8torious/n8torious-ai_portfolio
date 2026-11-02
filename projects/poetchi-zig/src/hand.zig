// Harakiri NG — The Hands
// Desktop assistants. Clippy's successors.
//   hand[0] — the WORKER: right hand, walks the taskbar, takes `hand <task>`.
//   hand[1] — the POINTER: LEFT hand, a cursor-hand. Points, grabs, drags
//             pointer with better actions. Built for 3D modeling (grab and
//             turn meshes) and 2D desktop bezels (grab window edges to move
//             and resize). Wired to merlin (executor). tRust-managed.
// Nathan Brown, 2026.

const sicore = @import("sicore.zig");
const taskmgr = @import("taskmgr.zig");
const mreason = @import("reason.zig");
const std = @import("std");

const WHITE = sicore.WHITE;
const CRIMSON = sicore.CRIMSON;
const CRIMSON_LT = sicore.CRIMSON_LT;
const GOLD = sicore.GOLD;
const GRAY = sicore.GRAY;

pub const Kind = enum { worker, pointer };

const Hand = struct {
    x: i32,
    y: i32,
    tx: i32,
    ty: i32,
    kind: Kind,
    busy: bool,
    grabbing: bool, // pointer pose: open point vs closed fist
    task: [32]u8,
    task_len: usize,
};

var hands: [2]Hand = .{
    .{
        .x = 180, .y = 0, .tx = 180, .ty = 0,
        .kind = .worker, .busy = false, .grabbing = false,
        .task = undefined, .task_len = 0,
    },
    .{
        .x = 950, .y = 320, .tx = 950, .ty = 320,
        .kind = .pointer, .busy = false, .grabbing = false,
        .task = undefined, .task_len = 0,
    },
};

// scaled sprite rect: original 16x16 coords, drawn 2x
fn r2(bx: i32, by: i32, x0: i32, y0: i32, x1: i32, y1: i32, c: [3]u8) void {
    sicore.rect(bx + x0 * 2, by + y0 * 2, bx + x1 * 2, by + y1 * 2, c);
}

// worker sprite: open hand, palm up
fn draw_worker(x: i32, y: i32) void {
    const c = WHITE;
    r2(x, y, 4, 6, 12, 14, c); // palm
    r2(x, y, 4, 1, 6, 7, c); // fingers
    r2(x, y, 6, 0, 8, 7, c);
    r2(x, y, 8, 1, 10, 7, c);
    r2(x, y, 10, 2, 12, 7, c);
    r2(x, y, 1, 8, 5, 10, c); // thumb
    r2(x, y, 3, 14, 13, 16, CRIMSON_LT); // cuff
    r2(x, y, 5, 8, 11, 12, .{ 200, 200, 210 }); // palm shading
}

// ---- Kraken's hand: articulated, animated ----
// Forward-kinematics hand. Palm + 4 fingers x 3 segments + thumb x 2.
// Joint angles = rest pose + idle sway (sine) + grab curl. Drawn as capsules.
// LEFT hand (thumb right), gold cuff — the pointer's mark.

const SKIN = [3]u8{ 228, 224, 214 };
const SKIN_SHADE = [3]u8{ 148, 144, 136 };

var anim_t: u32 = 0;
var grab_blend: f32 = 0.0;

// capsule segment via circle stamps
fn capsule(x0: f32, y0: f32, x1: f32, y1: f32, r: f32, c: [3]u8) void {
    const dx = x1 - x0;
    const dy = y1 - y0;
    const len = std.math.sqrt(dx * dx + dy * dy);
    const n: usize = @as(usize, @intFromFloat(len / 2.0)) + 1;
    var i: usize = 0;
    while (i <= n) : (i += 1) {
        const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(n));
        sicore.circle(@as(i32, @intFromFloat(x0 + dx * t)), @as(i32, @intFromFloat(y0 + dy * t)), @as(i32, @intFromFloat(r)), c);
    }
}

fn segcap(x0: f32, y0: f32, x1: f32, y1: f32, r: f32) void {
    capsule(x0, y0, x1, y1, r + 1.5, SKIN_SHADE);
    capsule(x0, y0, x1, y1, r, SKIN);
}

// one finger: chained segments from anchor, spread a0, curl 0..1, idle phase ph
fn finger(ax: f32, ay: f32, a0: f32, lens: [3]f32, radii: [3]f32, curl: f32, ph: f32, t: f32) void {
    const sway = @sin(t * 0.06 + ph) * 0.07 * (1.0 - curl * 0.7);
    var ang = a0 + sway;
    var x = ax;
    var y = ay;
    var j: usize = 0;
    while (j < 3) : (j += 1) {
        // each joint bends further inward with curl; distal joints bend most
        ang += curl * (0.55 + 0.25 * @as(f32, @floatFromInt(j))) + sway * 0.4;
        const nx = x + @sin(ang) * lens[j];
        const ny = y - @cos(ang) * lens[j];
        segcap(x, y, nx, ny, radii[j]);
        x = nx;
        y = ny;
    }
}

fn draw_pointer_hand(bx: i32, by: i32) void {
    const t = @as(f32, @floatFromInt(anim_t));
    const grip = grab_blend;
    const fx = @as(f32, @floatFromInt(bx));
    const fy = @as(f32, @floatFromInt(by));

    // palm: vertical capsule, wrist at local (0,0)
    segcap(fx, fy + 2, fx, fy - 26, 13.0);
    // thenar (thumb base)
    sicore.circle(@as(i32, @intFromFloat(fx + 9)), @as(i32, @intFromFloat(fy - 12)), 8, SKIN_SHADE);
    sicore.circle(@as(i32, @intFromFloat(fx + 9)), @as(i32, @intFromFloat(fy - 12)), 6, SKIN);

    // fingers: pinky, ring, middle, index — rest curl per finger (index points)
    const rest = [4]f32{ 0.30, 0.34, 0.30, 0.06 };
    const anchors = [4][2]f32{ .{ -11, -24 }, .{ -4, -27 }, .{ 4, -27 }, .{ 11, -24 } };
    const spreads = [4]f32{ -0.16, -0.06, 0.05, 0.15 };
    const lens = [4][3]f32{
        .{ 9, 7, 6 },
        .{ 11, 9, 7 },
        .{ 11, 9, 7 },
        .{ 10, 8, 7 },
    };
    const radii = [3]f32{ 3.2, 2.8, 2.4 };
    var f: usize = 0;
    while (f < 4) : (f += 1) {
        const curl = rest[f] + grip * (1.0 - rest[f]);
        finger(fx + anchors[f][0], fy + anchors[f][1], spreads[f], lens[f], radii, curl, @as(f32, @floatFromInt(f)) * 1.7, t);
    }

    // thumb: right side (left hand), 2 segments, folds across palm when grabbing
    {
        const curl = 0.15 + grip * 0.85;
        const sway = @sin(t * 0.05 + 2.3) * 0.05 * (1.0 - grip * 0.7);
        var ang: f32 = 1.15 + sway;
        var x = fx + 12;
        var y = fy - 12;
        const tlens = [2]f32{ 10, 8 };
        const tradii = [2]f32{ 3.4, 2.9 };
        var j: usize = 0;
        while (j < 2) : (j += 1) {
            ang -= curl * (0.7 + 0.3 * @as(f32, @floatFromInt(j))); // fold left/down across palm
            const nx = x + @sin(ang) * tlens[j];
            const ny = y - @cos(ang) * tlens[j];
            segcap(x, y, nx, ny, tradii[j]);
            x = nx;
            y = ny;
        }
    }

    // gold cuff: the pointer's mark
    sicore.rect(bx - 13, by + 2, bx + 13, by + 12, GOLD);
    sicore.rect(bx - 13, by + 9, bx + 13, by + 12, .{ 140, 105, 40 });
}

pub fn init() void {
    hands[0].x = 180;
    hands[0].tx = 180;
    hands[0].busy = false;
    hands[0].task_len = 0;
    hands[1].x = 950;
    hands[1].y = 320;
    hands[1].tx = 950;
    hands[1].ty = 320;
    hands[1].grabbing = false;
}

// ---- worker API ----
pub fn assign(task: []const u8) void {
    var h = &hands[0];
    const n = @min(task.len, 31);
    @memcpy(h.task[0..n], task[0..n]);
    h.task_len = n;
    h.busy = true;
    var hh: i32 = 0;
    for (task) |ch| hh = @mod(hh * 31 + ch, 900);
    h.tx = 140 + @as(i32, @intCast(@abs(hh) % 900));
}

// ---- pointer API ----
pub fn point(x: i32, y: i32) void {
    hands[1].tx = x;
    hands[1].ty = y;
}

pub fn grab() void {
    hands[1].grabbing = true;
}

pub fn release() void {
    hands[1].grabbing = false;
}

pub fn tick() void {
    // worker walks the taskbar
    var w = &hands[0];
    if (w.x < w.tx) w.x += 6;
    if (w.x > w.tx) w.x -= 6;
    if (w.x == w.tx and w.busy) w.busy = false;

    // pointer glides to its target
    var p = &hands[1];
    if (p.x < p.tx) p.x += 10;
    if (p.x > p.tx) p.x -= 10;
    if (p.y < p.ty) p.y += 10;
    if (p.y > p.ty) p.y -= 10;

    // Kraken's hand animation clock; grab blends open<->fist
    anim_t += 1;
    const target: f32 = if (p.grabbing) 1.0 else 0.0;
    grab_blend += (target - grab_blend) * 0.2;

    // code mode: the worker types, a few characters per tick
    if (coding) {
        code_pos += 3;
        if (code_pos >= code_len) {
            code_pos = code_len;
            coding = false;
            w.busy = false;
        }
    }
}

const TB_H: i32 = 56; // taskbar height (desktop.zig agrees)

pub fn render() void {
    const tb_y = sicore.FB_H - TB_H;

    // worker walks just above the taskbar
    const w = &hands[0];
    const bob: i32 = if (w.x != w.tx) @as(i32, @intCast(@mod(@divTrunc(w.x, 12), 2))) * 2 else 0;
    const wy = tb_y - 36 - bob;
    sicore.glow(w.x + 16, wy + 16, 44, WHITE, 40);
    draw_worker(w.x, wy);
    if (w.busy) {
        sicore.glow(w.x + 16, wy + 16, 60, GOLD, 50);
        taskmgr.draw_text_pub(w.x - 24, wy - 18, "working...", GOLD);
    }

    // pointer floats free — Kraken's articulated hand
    const p = &hands[1];
    const pc = if (p.grabbing) GOLD else WHITE;
    sicore.glow(p.x + 16, p.y + 16, 52, pc, 55);
    draw_pointer_hand(p.x + 16, p.y + 30);
    if (p.grabbing) {
        taskmgr.draw_text_pub(p.x - 8, p.y - 16, "grab", GOLD);
    }
    _ = GRAY;
}

pub fn status() []const u8 {
    if (coding) return "worker: typing Zig / pointer: ready";
    if (hands[0].busy) return "worker: working / pointer: ready";
    return "worker: idle / pointer: ready";
}

pub fn worker_task() []const u8 {
    return hands[0].task[0..hands[0].task_len];
}

pub fn pointer_state() []const u8 {
    if (hands[1].grabbing) return "grabbing";
    return "pointing";
}

pub fn pointer_grabbing_pub() bool {
    return hands[1].grabbing;
}

pub fn worker_state_pub() []const u8 {
    if (hands[0].busy) return "working";
    return "idle";
}

// ---- code mode: the hand reasons a brief, picks a generator by domain,
//      and types real Zig character-by-character as a tRust task ----
var code_buf: [2048]u8 = undefined;
var code_len: usize = 0;
var code_pos: usize = 0;
var coding: bool = false;
var code_domain: u8 = 0;

const TMPL_BOUNCER =
    "// generated by the hand: {b}\n" ++
    "const std = @import(\"std\");\n\n" ++
    "pub fn {n}_admit(trust: f32, eta: f32) bool {\n" ++
    "    // admit(x) = trust(x) >= eta ? enter : absent\n" ++
    "    return trust >= eta;\n" ++
    "}\n\n" ++
    "test \"{n} admits above eta\" {\n" ++
    "    try std.testing.expect({n}_admit(0.9, 0.5));\n" ++
    "    try std.testing.expect(!{n}_admit(0.1, 0.5));\n" ++
    "}\n";

const TMPL_OCEAN =
    "// generated by the hand: {b}\n" ++
    "const std = @import(\"std\");\n\n" ++
    "pub fn {n}_rise(density: f32, volume: f32, medium: f32) f32 {\n" ++
    "    // rise(x) = (density(medium) - density(x)) * volume(x)\n" ++
    "    return (medium - density) * volume;\n" ++
    "}\n\n" ++
    "test \"{n} rises when lighter\" {\n" ++
    "    try std.testing.expect({n}_rise(0.5, 2.0, 1.0) > 0);\n" ++
    "    try std.testing.expect({n}_rise(1.5, 2.0, 1.0) < 0);\n" ++
    "}\n";

const TMPL_TENTAILS =
    "// generated by the hand: {b}\n" ++
    "const std = @import(\"std\");\n\n" ++
    "pub fn {n}_focus(powers: []const f32) f32 {\n" ++
    "    // power(path_k) = sum power(path_i) - cut the rest, pour it in\n" ++
    "    var s: f32 = 0;\n" ++
    "    for (powers) |p| s += p;\n" ++
    "    return s;\n" ++
    "}\n\n" ++
    "test \"{n} focus pours\" {\n" ++
    "    const ps = [_]f32{ 1.0, 2.0, 3.0 };\n" ++
    "    try std.testing.expect({n}_focus(&ps) == 6.0);\n" ++
    "}\n";

const TMPL_KURAMOTO =
    "// generated by the hand: {b}\n" ++
    "const std = @import(\"std\");\n\n" ++
    "pub fn {n}_order(phases: []const f32) f32 {\n" ++
    "    // r = |sum e^{{i0}}| / N - 1 is one voice, 0 is noise\n" ++
    "    var sx: f32 = 0;\n" ++
    "    var sy: f32 = 0;\n" ++
    "    for (phases) |p| {\n" ++
    "        sx += std.math.cos(p);\n" ++
    "        sy += std.math.sin(p);\n" ++
    "    }\n" ++
    "    const n: f32 = @floatFromInt(phases.len);\n" ++
    "    return std.math.hypot(sx, sy) / n;\n" ++
    "}\n\n" ++
    "test \"{n} order of locked phases\" {\n" ++
    "    const ps = [_]f32{ 0.1, 0.1, 0.1 };\n" ++
    "    try std.testing.expect({n}_order(&ps) > 0.99);\n" ++
    "}\n";

const TMPL_FORGE =
    "// generated by the hand: {b}\n" ++
    "const std = @import(\"std\");\n\n" ++
    "pub fn {n}_refine(purity: f32, fire: f32, time: f32) f32 {\n" ++
    "    // alloy = ore + fire*time - slag(impurities)\n" ++
    "    return purity + fire * time * (1.0 - purity);\n" ++
    "}\n\n" ++
    "test \"{n} refines toward 1\" {\n" ++
    "    try std.testing.expect({n}_refine(0.2, 1.0, 1.0) > 0.2);\n" ++
    "}\n";

const TMPL_SPIDERMOUSE =
    "// generated by the hand: {b}\n" ++
    "const std = @import(\"std\");\n\n" ++
    "pub fn {n}_plan(x: f32) f32 {\n" ++
    "    // the spider plans: slow mind\n" ++
    "    return x * 2.0;\n" ++
    "}\n\n" ++
    "pub fn {n}_react(x: f32) f32 {\n" ++
    "    // the mouse strikes: fast hands\n" ++
    "    return x + 1.0;\n" ++
    "}\n\n" ++
    "pub fn {n}_strike(x: f32) f32 {\n" ++
    "    // strike = plan(spider) then react(mouse)\n" ++
    "    return {n}_react({n}_plan(x));\n" ++
    "}\n\n" ++
    "test \"{n} strike composes\" {\n" ++
    "    try std.testing.expect({n}_strike(1.0) == 3.0);\n" ++
    "}\n";

fn code_template(di: u8) []const u8 {
    return switch (di) {
        0 => TMPL_BOUNCER,
        1 => TMPL_OCEAN,
        2 => TMPL_TENTAILS,
        3 => TMPL_KURAMOTO,
        4 => TMPL_FORGE,
        5 => TMPL_SPIDERMOUSE,
        else => TMPL_FORGE,
    };
}

fn sanitize_name(src: []const u8, out: []u8) usize {
    var o: usize = 0;
    for (src) |c| {
        if (o >= out.len) break;
        const lc = if (c >= 'A' and c <= 'Z') c + 32 else c;
        if ((lc >= 'a' and lc <= 'z') or (lc >= '0' and lc <= '9') or lc == '_') {
            if (o == 0 and lc >= '0' and lc <= '9') {
                out[o] = '_';
                o += 1;
                if (o >= out.len) break;
            }
            out[o] = lc;
            o += 1;
        }
    }
    if (o == 0) {
        @memcpy(out[0..4], "work");
        o = 4;
    }
    return o;
}

fn sanitize_brief(src: []const u8, out: []u8) usize {
    var o: usize = 0;
    for (src) |c| {
        if (o >= out.len) break;
        out[o] = if ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == ' ' or c == '_' or c == '-') c else '?';
        o += 1;
    }
    return o;
}

fn fill_template(di: u8, name: []const u8, brief: []const u8, out: []u8) usize {
    const tmpl = code_template(di);
    var o: usize = 0;
    var i: usize = 0;
    while (i < tmpl.len and o < out.len) {
        if (tmpl[i] == '{' and i + 2 < tmpl.len) {
            if (tmpl[i + 1] == 'n' and tmpl[i + 2] == '}') {
                const c = @min(name.len, out.len - o);
                @memcpy(out[o .. o + c], name[0..c]);
                o += c;
                i += 3;
                continue;
            } else if (tmpl[i + 1] == 'b' and tmpl[i + 2] == '}') {
                const c = @min(brief.len, out.len - o);
                @memcpy(out[o .. o + c], brief[0..c]);
                o += c;
                i += 3;
                continue;
            }
        }
        out[o] = tmpl[i];
        o += 1;
        i += 1;
    }
    return o;
}

// reason the brief, pick the generator by winning domain, start typing.
// returns false when there is no resonance — nothing to type.
pub fn code(brief: []const u8) bool {
    var p = mreason.Problem{};
    mreason.setName(&p, "brief");
    mreason.sketch(brief, &p);
    const d = mreason.reason(&p);
    if (mreason.abstains(d)) {
        coding = false;
        code_len = 0;
        return false;
    }
    var name: [24]u8 = undefined;
    var brief_s: [64]u8 = undefined;
    var nl: usize = 4;
    if (p.nent > 0) {
        nl = sanitize_name(mreason.entityName(&p, 0), &name);
    } else {
        @memcpy(name[0..4], "work");
    }
    const bl = sanitize_brief(brief, &brief_s);
    code_domain = d.domain;
    code_len = fill_template(d.domain, name[0..nl], brief_s[0..bl], &code_buf);
    code_pos = 0;
    coding = true;
    hands[0].busy = true;
    hands[0].tx = 640; // the worker walks to the code bench
    return true;
}

pub fn code_domain_name() []const u8 {
    return mreason.domainName(code_domain);
}

pub fn code_text() []const u8 {
    return code_buf[0..code_len];
}

pub fn code_typed() []const u8 {
    return code_buf[0..code_pos];
}

pub fn coding_active() bool {
    return coding;
}

pub fn code_progress() u8 {
    if (code_len == 0) return 0;
    return @intCast(code_pos * 100 / code_len);
}
