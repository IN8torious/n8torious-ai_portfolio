// PoeTchi — REASON subsystem
// Freestanding Zig port of ~/workspace/metaphorical-reasoning/.
// problem → resonance → binding → laws → NCAG gate.
//
// The crew's decision layer. tRust (trust.zig) stays the hard floor —
// the watchdog supervises; REASON decides. A run with no resonance
// ABSTAINS: refusal is absence, never hallucination.
// Every law carries its equation (MEDUSA). No allocator; fixed buffers.
// Nathan Brown, 2026.

const std = @import("std");

pub const MAX_ENT: usize = 8;
pub const MAX_REL: usize = 8;

// ---- the engine's verb set (sketch matches these; relations reference them) ----
pub const VERBS = [_][]const u8{
    "queues_for", "judged_by", "held_by", "passes", "refused",
    "floats_on", "sinks_through", "stratified_by", "carried_by", "surfaces",
    "driven_by", "shares_with", "splits_from", "rejoins", "sees_through",
    "couples_with", "locks_to", "drifts_from", "entrains",
    "heated_by", "struck_by", "melts_into", "quenched_in", "alloyed_with",
    "senses_through", "waits_on", "strikes_at", "planned_by", "reacted_by",
};

fn verbIndex(comptime name: []const u8) u8 {
    for (VERBS, 0..) |v, i| {
        if (std.mem.eql(u8, v, name)) return @intCast(i);
    }
    @compileError("unknown verb: " ++ name);
}

pub fn verbName(v: u8) []const u8 {
    if (v < VERBS.len) return VERBS[v];
    return "?";
}

// ---- laws: runnable functions, each carrying its equation ----
pub const LawCtx = struct {
    args: [8]f32 = [_]f32{0} ** 8,
    nargs: u8 = 0,
    out: [8]f32 = [_]f32{0} ** 8,
    nout: u8 = 0,
    param: f32 = 0, // extra scalar (K for phase_lock, …)
    plan: ?*const fn (f32) f32 = null, // strike: the spider's plan
    react: ?*const fn (f32) f32 = null, // strike: the mouse's reflex
    result: f32 = 0,
    flag: bool = false, // admission: enter? strike: applied?
};

pub const LawFn = *const fn (*LawCtx) void;

pub const Law = struct {
    name: []const u8,
    eq: []const u8,
    run: LawFn,
};

// bouncer
fn law_admission(ctx: *LawCtx) void {
    ctx.flag = ctx.args[0] >= ctx.args[1];
    ctx.result = if (ctx.flag) 1.0 else 0.0;
}
fn law_the_rope(ctx: *LawCtx) void {
    ctx.result = ctx.args[0] * ctx.args[1];
}
// ocean
fn law_buoyancy(ctx: *LawCtx) void {
    ctx.result = (ctx.args[2] - ctx.args[0]) * ctx.args[1];
}
fn law_stratify(ctx: *LawCtx) void {
    var idx: [8]u8 = undefined;
    var i: u8 = 0;
    while (i < ctx.nargs) : (i += 1) idx[i] = i;
    var j: u8 = 1; // insertion sort of indices by density — like seeks like
    while (j < ctx.nargs) : (j += 1) {
        const key = idx[j];
        var k: u8 = j;
        while (k > 0 and ctx.args[idx[k - 1]] > ctx.args[key]) : (k -= 1) {
            idx[k] = idx[k - 1];
        }
        idx[k] = key;
    }
    i = 0;
    while (i < ctx.nargs) : (i += 1) ctx.out[i] = @floatFromInt(idx[i]);
    ctx.nout = ctx.nargs;
}
// ten-tails
fn law_shared_vision(ctx: *LawCtx) void {
    // each arg's bit pattern is a path's sight-set; union is the shared vision
    var acc: u32 = 0;
    var i: u8 = 0;
    while (i < ctx.nargs) : (i += 1) acc |= @as(u32, @bitCast(ctx.args[i]));
    ctx.result = @as(f32, @bitCast(acc));
}
fn law_focus(ctx: *LawCtx) void {
    var s: f32 = 0;
    var i: u8 = 0;
    while (i < ctx.nargs) : (i += 1) s += ctx.args[i];
    ctx.result = s;
}
// kuramoto
fn law_phase_lock(ctx: *LawCtx) void {
    const n = ctx.nargs;
    if (n == 0) return;
    var m: f32 = 0;
    var i: u8 = 0;
    while (i < n) : (i += 1) m += ctx.args[i];
    m /= @as(f32, @floatFromInt(n));
    const nf: f32 = @floatFromInt(n);
    i = 0;
    while (i < n) : (i += 1) {
        ctx.out[i] = ctx.args[i] + ctx.param * std.math.sin(m - ctx.args[i]) / nf;
    }
    ctx.nout = n;
}
fn law_order(ctx: *LawCtx) void {
    const n = ctx.nargs;
    if (n == 0) {
        ctx.result = 0;
        return;
    }
    var sx: f32 = 0;
    var sy: f32 = 0;
    var i: u8 = 0;
    while (i < n) : (i += 1) {
        sx += std.math.cos(ctx.args[i]);
        sy += std.math.sin(ctx.args[i]);
    }
    ctx.result = std.math.hypot(sx, sy) / @as(f32, @floatFromInt(n));
}
// forge
fn law_transform(ctx: *LawCtx) void {
    const purity = ctx.args[0];
    ctx.result = purity + ctx.args[1] * ctx.args[2] * (1.0 - purity);
}
fn law_quench(ctx: *LawCtx) void {
    ctx.result = ctx.args[0] / @max(ctx.args[1], 1e-6);
}
// spider-mouse
fn law_web_tension(ctx: *LawCtx) void {
    var s: f32 = 0; // args as (vibration, weight) pairs — the web feels before it sees
    var i: u8 = 0;
    while (i + 1 < ctx.nargs) : (i += 2) s += ctx.args[i] * ctx.args[i + 1];
    ctx.result = s;
}
fn law_strike(ctx: *LawCtx) void {
    // strike = plan(spider) then react(mouse). Needs both functions;
    // without them the law cannot run — it says so instead of faking it.
    if (ctx.plan) |pl| {
        if (ctx.react) |re| {
            ctx.result = re(pl(ctx.args[0]));
            ctx.flag = true;
            return;
        }
    }
    ctx.result = 0;
    ctx.flag = false;
}

// ---- domains: Nathan's own framings. No new domains without his say-so. ----
pub const Domain = struct {
    name: []const u8,
    roles: []const []const u8,
    rel_verbs: []const u8,
    laws: []const Law,
    speak_tmpl: []const u8, // {t} = topic, {b} = first bound entity
};

pub const DOMAINS = [_]Domain{
    .{
        .name = "bouncer",
        .roles = &[_][]const u8{ "crowd", "rope", "list", "door" },
        .rel_verbs = &[_]u8{ verbIndex("queues_for"), verbIndex("judged_by"), verbIndex("held_by"), verbIndex("passes"), verbIndex("refused") },
        .laws = &[_]Law{
            .{ .name = "admission", .eq = "admit(x) = trust(x) >= eta ? enter : absent", .run = law_admission },
            .{ .name = "the_rope", .eq = "wait(x) = position(x) * patience", .run = law_the_rope },
        },
        .speak_tmpl = "this {t} is a bouncer - {b} queues at the rope, the list decides, refusal is absence.",
    },
    .{
        .name = "ocean",
        .roles = &[_][]const u8{ "surface", "depths", "current", "floor" },
        .rel_verbs = &[_]u8{ verbIndex("floats_on"), verbIndex("sinks_through"), verbIndex("stratified_by"), verbIndex("carried_by"), verbIndex("surfaces") },
        .laws = &[_]Law{
            .{ .name = "buoyancy", .eq = "rise(x) = (density(medium) - density(x)) * volume(x)", .run = law_buoyancy },
            .{ .name = "stratify", .eq = "layer(x) = rank(density(x)) - like seeks like", .run = law_stratify },
        },
        .speak_tmpl = "this {t} is an ocean - {b} is the system state, things rise or sink by density, like seeks like.",
    },
    .{
        .name = "ten-tails",
        .roles = &[_][]const u8{ "paths", "outer", "receivers", "will" },
        .rel_verbs = &[_]u8{ verbIndex("driven_by"), verbIndex("shares_with"), verbIndex("splits_from"), verbIndex("rejoins"), verbIndex("sees_through") },
        .laws = &[_]Law{
            .{ .name = "shared_vision", .eq = "sight = union sight(path_i) - every eye sees every eye's field", .run = law_shared_vision },
            .{ .name = "focus", .eq = "power(path_k) = sum power(path_i) - cut the rest, pour it in", .run = law_focus },
        },
        .speak_tmpl = "this {t} is the ten-tails - {b} were always one whole; drive them through one will, pour everything into the focused path.",
    },
    .{
        .name = "kuramoto",
        .roles = &[_][]const u8{ "oscillators", "medium", "mean_phase" },
        .rel_verbs = &[_]u8{ verbIndex("couples_with"), verbIndex("locks_to"), verbIndex("drifts_from"), verbIndex("entrains") },
        .laws = &[_]Law{
            .{ .name = "phase_lock", .eq = "d0i = wi + (K/N)*sum sin(0j - 0i) - K above critical locks", .run = law_phase_lock },
            .{ .name = "order", .eq = "r = |sum e^{i0}| / N - 1 is one voice, 0 is noise", .run = law_order },
        },
        .speak_tmpl = "this {t} is kuramoto - no one commands coherence; the oscillators listen to their neighbors until they breathe as one.",
    },
    .{
        .name = "forge",
        .roles = &[_][]const u8{ "ore", "fire", "hammer", "alloy" },
        .rel_verbs = &[_]u8{ verbIndex("heated_by"), verbIndex("struck_by"), verbIndex("melts_into"), verbIndex("quenched_in"), verbIndex("alloyed_with") },
        .laws = &[_]Law{
            .{ .name = "transform", .eq = "alloy = ore + fire*time - slag(impurities)", .run = law_transform },
            .{ .name = "quench", .eq = "hardness = dT / dt - faster quench, harder edge", .run = law_quench },
        },
        .speak_tmpl = "this {t} is a forge - feed the ore through fire, strike it while it glows, quench fast for a hard edge.",
    },
    .{
        .name = "spider-mouse",
        .roles = &[_][]const u8{ "web", "spider", "mouse", "signal" },
        .rel_verbs = &[_]u8{ verbIndex("senses_through"), verbIndex("waits_on"), verbIndex("strikes_at"), verbIndex("planned_by"), verbIndex("reacted_by") },
        .laws = &[_]Law{
            .{ .name = "web_tension", .eq = "alert = sum vibration(signal_i) * weight_i - the web feels before it sees", .run = law_web_tension },
            .{ .name = "strike", .eq = "strike = plan(spider) then react(mouse) - deliberation then reflex", .run = law_strike },
        },
        .speak_tmpl = "this {t} is spider-mouse - the spider plans on the web, the mouse strikes on the signal. Slow mind, fast hands.",
    },
};

pub fn domainName(di: u8) []const u8 {
    if (di < DOMAINS.len) return DOMAINS[di].name;
    return "none";
}

pub fn domainIndex(name: []const u8) ?u8 {
    for (DOMAINS, 0..) |d, i| {
        if (std.mem.eql(u8, d.name, name)) return @intCast(i);
    }
    return null;
}

// ---- problems: entities + relations, fixed buffers ----
pub const Entity = struct {
    name: [24]u8 = [_]u8{0} ** 24,
    len: u8 = 0,
};

pub const Relation = struct {
    s: u8, // entity index
    v: u8, // verb index
    o: u8, // entity index
};

pub const Problem = struct {
    name: [32]u8 = [_]u8{0} ** 32,
    name_len: u8 = 0,
    entities: [MAX_ENT]Entity = [_]Entity{.{}} ** MAX_ENT,
    nent: u8 = 0,
    rels: [MAX_REL]Relation = [_]Relation{.{ .s = 0, .v = 0, .o = 0 }} ** MAX_REL,
    nrel: u8 = 0,
};

pub fn setName(p: *Problem, name: []const u8) void {
    const n = @min(name.len, 31);
    @memcpy(p.name[0..n], name[0..n]);
    p.name_len = @intCast(n);
}

pub fn addEntity(p: *Problem, name: []const u8) ?u8 {
    if (p.nent >= MAX_ENT) return null;
    const e = &p.entities[p.nent];
    const n = @min(name.len, 23);
    @memcpy(e.name[0..n], name[0..n]);
    e.len = @intCast(n);
    p.nent += 1;
    return p.nent - 1;
}

pub fn addRelation(p: *Problem, s: u8, v: u8, o: u8) bool {
    if (p.nrel >= MAX_REL) return false;
    p.rels[p.nrel] = .{ .s = s, .v = v, .o = o };
    p.nrel += 1;
    return true;
}

pub fn entityName(p: *const Problem, i: u8) []const u8 {
    const e = &p.entities[i];
    return e.name[0..e.len];
}

fn isWordChar(c: u8) bool {
    return (c >= 'a' and c <= 'z') or c == '_';
}

fn isVerb(w: []const u8) bool {
    for (VERBS) |v| {
        if (std.mem.eql(u8, v, w)) return true;
    }
    return false;
}

fn hasEntity(p: *const Problem, w: []const u8) bool {
    var i: u8 = 0;
    while (i < p.nent) : (i += 1) {
        if (std.mem.eql(u8, entityName(p, i), w)) return true;
    }
    return false;
}

fn containsVerb(hay: []const u8, verb: []const u8) bool {
    if (std.mem.indexOf(u8, hay, verb) != null) return true;
    var spaced: [32]u8 = undefined; // 'queues_for' also matches 'queues for'
    if (verb.len > spaced.len) return false;
    var i: usize = 0;
    while (i < verb.len) : (i += 1) spaced[i] = if (verb[i] == '_') ' ' else verb[i];
    return std.mem.indexOf(u8, hay, spaced[0..verb.len]) != null;
}

// sketch: keyword-level text → problem. Honest, not NLP —
// the caller owns the semantics; hand-write relations for real runs.
pub fn sketch(text: []const u8, p: *Problem) void {
    var lower: [256]u8 = undefined;
    const n = @min(text.len, 256);
    var i: usize = 0;
    while (i < n) : (i += 1) {
        const c = text[i];
        lower[i] = if (c >= 'A' and c <= 'Z') c + 32 else c;
    }
    const lt = lower[0..n];

    p.nent = 0;
    var pos: usize = 0;
    while (pos < n) {
        while (pos < n and !isWordChar(lt[pos])) : (pos += 1) {}
        const start = pos;
        while (pos < n and isWordChar(lt[pos])) : (pos += 1) {}
        if (pos > start) {
            const w = lt[start..pos];
            if (w.len > 3 and !isVerb(w) and !hasEntity(p, w)) {
                _ = addEntity(p, w);
            }
        }
    }

    p.nrel = 0;
    var hi: u8 = 0; // hit index — relations chain entities in hit order
    for (VERBS, 0..) |v, vi| {
        if (p.nrel >= MAX_REL) break;
        if (p.nent == 0) break;
        if (containsVerb(lt, v)) {
            const a: u8 = hi % p.nent;
            const b: u8 = (hi + 1) % p.nent;
            if (addRelation(p, a, @intCast(vi), b)) hi += 1;
        }
    }
}

// ---- 1. resonance: shared relation SHAPES, not words (x1000) ----
pub fn resonance(p: *const Problem, d: *const Domain) u32 {
    var hit: u32 = 0;
    for (d.rel_verbs) |rv| {
        var i: u8 = 0;
        while (i < p.nrel) : (i += 1) {
            if (p.rels[i].v == rv) {
                hit += 1;
                break;
            }
        }
    }
    return hit * 1000 / @as(u32, @intCast(d.rel_verbs.len));
}

// ---- 2. binding: entities onto roles, greedy by relation participation ----
pub const Binding = struct {
    role: u8,
    ent: u8,
};

pub fn bind(p: *const Problem, d: *const Domain, out: []Binding) u8 {
    var used: [MAX_ENT]bool = [_]bool{false} ** MAX_ENT;
    var n: u8 = 0;
    for (d.roles, 0..) |_, ri| {
        if (n >= out.len) break;
        var best: i16 = -1;
        var bs: i32 = -1;
        var ei: u8 = 0;
        while (ei < p.nent) : (ei += 1) {
            if (used[ei]) continue;
            var s: i32 = 0;
            var rj: u8 = 0;
            while (rj < p.nrel) : (rj += 1) {
                const r = p.rels[rj];
                if (r.s == ei or r.o == ei) {
                    for (d.rel_verbs) |rv| {
                        if (r.v == rv) {
                            s += 1;
                            break;
                        }
                    }
                }
            }
            if (s > bs) {
                bs = s;
                best = ei;
            }
        }
        if (best >= 0) {
            out[n] = .{ .role = @intCast(ri), .ent = @intCast(best) };
            used[@intCast(best)] = true;
            n += 1;
        }
    }
    return n;
}

// ---- 3+4. reason: rank, bind, paradox, NCAG gate ----
pub const NONE: u8 = 0xFF;

pub const Decision = struct {
    domain: u8 = NONE, // index into DOMAINS; NONE = abstain
    score_x1000: u32 = 0,
    runner_up: u8 = NONE,
    runner_score: u32 = 0,
};

pub fn reason(p: *const Problem) Decision {
    var d = Decision{};
    for (DOMAINS, 0..) |dom, i| {
        const s = resonance(p, &dom);
        const ii: u8 = @intCast(i);
        if (s > d.score_x1000) {
            d.runner_up = d.domain;
            d.runner_score = d.score_x1000;
            d.domain = ii;
            d.score_x1000 = s;
        } else if (s > d.runner_score and ii != d.domain) {
            d.runner_up = ii;
            d.runner_score = s;
        }
    }
    if (d.domain == NONE or d.score_x1000 == 0) {
        d.domain = NONE; // NCAG: no resonance → ABSTAIN, never hallucinate
        d.score_x1000 = 0;
    }
    return d;
}

pub fn abstains(d: Decision) bool {
    return d.domain == NONE;
}

pub fn firstLaw(di: u8) []const u8 {
    if (di >= DOMAINS.len) return "";
    return DOMAINS[di].laws[0].name;
}

// run a named law of a domain on a context. false = no such law.
pub fn runLaw(di: u8, name: []const u8, ctx: *LawCtx) bool {
    if (di >= DOMAINS.len) return false;
    for (DOMAINS[di].laws) |*l| {
        if (std.mem.eql(u8, l.name, name)) {
            l.run(ctx);
            return true;
        }
    }
    return false;
}

// the winning domain speaks: topic + first binding into its template.
pub fn speak(di: u8, p: *const Problem, bindings: []const Binding, out: []u8) usize {
    if (di >= DOMAINS.len or out.len == 0) return 0;
    const tmpl = DOMAINS[di].speak_tmpl;
    var o: usize = 0;
    var i: usize = 0;
    while (i < tmpl.len and o < out.len) {
        if (tmpl[i] == '{' and i + 2 < tmpl.len) {
            if (tmpl[i + 1] == 't' and tmpl[i + 2] == '}') {
                const nm = p.name[0..p.name_len];
                const c = @min(nm.len, out.len - o);
                @memcpy(out[o .. o + c], nm[0..c]);
                o += c;
                i += 3;
                continue;
            } else if (tmpl[i + 1] == 'b' and tmpl[i + 2] == '}') {
                if (bindings.len > 0) {
                    const en = entityName(p, bindings[0].ent);
                    const c = @min(en.len, out.len - o);
                    @memcpy(out[o .. o + c], en[0..c]);
                    o += c;
                } else {
                    const c = @min(@as(usize, 7), out.len - o);
                    @memcpy(out[o .. o + c], "nothing"[0..c]);
                    o += c;
                }
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

// ---- vera's routing table: winning domain → the agent who owns that work ----
const AFFINITY = [_][]const u8{
    "gaven", // bouncer: admission is the gate's work
    "mira", // ocean: the surface-reader
    "kraken", // ten-tails: the consolidator
    "brood-00", // kuramoto: coherence of the workers
    "paintr", // forge: transformation is the painter's work
    "merlin", // spider-mouse: plan then strike is the executor's work
};

pub fn affinity(di: u8) []const u8 {
    if (di < AFFINITY.len) return AFFINITY[di];
    return "none";
}
