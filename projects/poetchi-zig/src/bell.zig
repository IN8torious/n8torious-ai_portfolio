// Harakiri NG — Bell links (entanglement)
// Phase 6a of the entanglement roadmap: pairwise two-qubit states on the mesh.
//
// One representation: rho, a 4x4 complex density matrix (fixed arrays, no
// allocator). Equations (roadmap Phase 0):
//   normalization: Tr(rho) = 1
//   concurrence:   C = 2|ad - bg| on the pure state; on rho (X-form only)
//                  C = 2*max(0, |z|-sqrt(a*d), |w|-sqrt(b*c))
//   measurement:   Born rule from rho's diagonal; collapse to the projector
//   dephasing:     off-diagonals across the chosen qubit decay e^(-gamma t)
// The X-form guard is LOUD: concurrence returns -1.0 off X-form instead of
// inventing a number. Callers surface it; nobody hides it.
// Nathan Brown, 2026.

const std = @import("std");

pub const Cplx = [2]f32;
pub const Mat2 = [2][2]Cplx;
pub const Rho = [4][4]Cplx;

const Z: Cplx = .{ 0, 0 };
const ONE: Cplx = .{ 1, 0 };
const SQRT1_2: f32 = 0.70710678;

// ---- complex arithmetic ----
pub fn cadd(a: Cplx, b: Cplx) Cplx {
    return .{ a[0] + b[0], a[1] + b[1] };
}
pub fn csub(a: Cplx, b: Cplx) Cplx {
    return .{ a[0] - b[0], a[1] - b[1] };
}
pub fn cmul(a: Cplx, b: Cplx) Cplx {
    return .{ a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0] };
}
pub fn csc(a: Cplx, s: f32) Cplx {
    return .{ a[0] * s, a[1] * s };
}
pub fn cconj(a: Cplx) Cplx {
    return .{ a[0], -a[1] };
}
pub fn cmod(a: Cplx) f32 {
    return @sqrt(a[0] * a[0] + a[1] * a[1]);
}

pub fn rhoZero() Rho {
    var r: Rho = undefined;
    for (0..4) |i| {
        for (0..4) |j| {
            r[i][j] = Z;
        }
    }
    return r;
}

// rho = |psi><psi| from amplitudes over |00>,|01>,|10>,|11>
pub fn rhoFromAmps(a: [4]Cplx) Rho {
    var r = rhoZero();
    for (0..4) |i| {
        for (0..4) |j| {
            r[i][j] = cmul(a[i], cconj(a[j]));
        }
    }
    return r;
}

// ---- the four Bell states ----
pub const BellKind = enum { phi_p, phi_m, psi_p, psi_m };

pub fn bellAmps(kind: BellKind) [4]Cplx {
    return switch (kind) {
        .phi_p => .{ .{ SQRT1_2, 0 }, Z, Z, .{ SQRT1_2, 0 } },
        .phi_m => .{ .{ SQRT1_2, 0 }, Z, Z, .{ -SQRT1_2, 0 } },
        .psi_p => .{ Z, .{ SQRT1_2, 0 }, .{ SQRT1_2, 0 }, Z },
        .psi_m => .{ Z, .{ SQRT1_2, 0 }, .{ -SQRT1_2, 0 }, Z },
    };
}

pub fn bellRho(kind: BellKind) Rho {
    return rhoFromAmps(bellAmps(kind));
}

// ---- single-qubit unitaries ----
pub fn rotY(theta: f32) Mat2 {
    const c = @cos(theta / 2);
    const s = @sin(theta / 2);
    return .{ .{ .{ c, 0 }, .{ -s, 0 } }, .{ .{ s, 0 }, .{ c, 0 } } };
}
pub fn rotZ(phi: f32) Mat2 {
    const c = @cos(phi / 2);
    const s = @sin(phi / 2);
    return .{ .{ .{ c, -s }, Z }, .{ Z, .{ c, s } } };
}
pub fn hadamard() Mat2 {
    return .{ .{ .{ SQRT1_2, 0 }, .{ SQRT1_2, 0 } }, .{ .{ SQRT1_2, 0 }, .{ -SQRT1_2, 0 } } };
}

fn singleU4(U: Mat2, q: usize) [4][4]Cplx {
    // index = 2*b1 + b0: the FIRST tensor factor (i,k) is qubit 1 (high bit),
    // the SECOND (j,l) is qubit 0 (low bit).
    var m: [4][4]Cplx = undefined;
    for (0..4) |r| {
        for (0..4) |c| {
            m[r][c] = Z;
        }
    }
    for (0..2) |i| {
        for (0..2) |j| {
            for (0..2) |k| {
                for (0..2) |l| {
                    // row = 2i+j, col = 2k+l
                    if (q == 0) {
                        if (i == k) m[2 * i + j][2 * k + l] = U[j][l];
                    } else {
                        if (j == l) m[2 * i + j][2 * k + l] = U[i][k];
                    }
                }
            }
        }
    }
    return m;
}

fn matMul4(A: [4][4]Cplx, B: [4][4]Cplx) [4][4]Cplx {
    var out: [4][4]Cplx = undefined;
    for (0..4) |i| {
        for (0..4) |j| {
            var acc: Cplx = Z;
            for (0..4) |k| {
                acc = cadd(acc, cmul(A[i][k], B[k][j]));
            }
            out[i][j] = acc;
        }
    }
    return out;
}

fn conjT4(A: [4][4]Cplx) [4][4]Cplx {
    var out: [4][4]Cplx = undefined;
    for (0..4) |i| {
        for (0..4) |j| {
            out[i][j] = cconj(A[j][i]);
        }
    }
    return out;
}

// rho' = U rho U-dagger, U acting on qubit q
pub fn applySingleU(rho: Rho, U: Mat2, q: usize) Rho {
    const u4m = singleU4(U, q);
    return matMul4(u4m, matMul4(rho, conjT4(u4m)));
}

// CNOT by conjugation: permute rows and columns with the same index map
pub fn applyCNOT(rho: Rho, control: usize, target: usize) Rho {
    var perm: [4]usize = undefined;
    for (0..4) |i| {
        const cb = if (control == 0) i & 1 else (i >> 1) & 1;
        perm[i] = if (cb == 1) (if (target == 0) i ^ 1 else i ^ 2) else i;
    }
    var out = rhoZero();
    for (0..4) |i| {
        for (0..4) |j| {
            out[perm[i]][perm[j]] = rho[i][j];
        }
    }
    return out;
}

// ---- concurrence ----
fn isXForm(rho: Rho) bool {
    for (0..4) |i| {
        for (0..4) |j| {
            const x = (i == j) or (i == 0 and j == 3) or (i == 3 and j == 0) or
                (i == 1 and j == 2) or (i == 2 and j == 1);
            if (!x and cmod(rho[i][j]) > 0.000001) return false;
        }
    }
    return true;
}

pub fn concurrence(rho: Rho) f32 {
    if (!isXForm(rho)) return -1.0; // LOUD sentinel — never a fake number
    const a = cmod(rho[0][0]);
    const b = cmod(rho[1][1]);
    const c = cmod(rho[2][2]);
    const d = cmod(rho[3][3]);
    const w = cmod(rho[0][3]);
    const z = cmod(rho[1][2]);
    return 2 * @max(0.0, @max(z - @sqrt(a * d), w - @sqrt(b * c)));
}

// ---- seeded RNG: mulberry32, bit-matched to the JS engine ----
pub const Rng = struct {
    a: u32,
    pub fn init(seed: u32) Rng {
        return .{ .a = seed };
    }
    pub fn next(self: *Rng) f32 {
        self.a +%= 0x6D2B79F5;
        var t: u32 = (self.a ^ (self.a >> 15)) *% (@as(u32, 1) | self.a);
        t = (t +% ((t ^ (t >> 7)) *% (@as(u32, 61) | t))) ^ t;
        return @as(f32, @floatFromInt(t ^ (t >> 14))) / 4294967296.0;
    }
};

// ---- measurement: Born rule from rho's diagonal ----
pub const MeasResult = struct { outcome: u8, rho: Rho };

fn diagProb(rho: Rho, i: usize) f32 {
    return rho[i][i][0]; // diagonal of a density matrix is real
}

pub fn measure(rho: Rho, rng: *Rng) MeasResult {
    const r = rng.next();
    var acc: f32 = 0;
    var out: u8 = 3;
    for (0..4) |i| {
        acc += diagProb(rho, i);
        if (r < acc) {
            out = @intCast(i);
            break;
        }
    }
    var t = rhoZero();
    t[out][out] = ONE;
    return .{ .outcome = out, .rho = t };
}

pub fn measureQubit(rho: Rho, q: usize, rng: *Rng) MeasResult {
    var p0: f32 = 0;
    for (0..4) |i| {
        const bit = if (q == 0) i & 1 else (i >> 1) & 1;
        if (bit == 0) p0 += diagProb(rho, i);
    }
    const outb: usize = if (rng.next() < p0) 0 else 1;
    var t = rhoZero();
    var tr: f32 = 0;
    for (0..4) |i| {
        for (0..4) |j| {
            const bi = if (q == 0) i & 1 else (i >> 1) & 1;
            const bj = if (q == 0) j & 1 else (j >> 1) & 1;
            if (bi == outb and bj == outb) {
                t[i][j] = rho[i][j];
                if (i == j) tr += diagProb(rho, i);
            }
        }
    }
    const sc = 1.0 / tr; // rho' = P rho P / Tr(P rho P)
    for (0..4) |i| {
        for (0..4) |j| {
            t[i][j] = csc(t[i][j], sc);
        }
    }
    return .{ .outcome = @intCast(outb), .rho = t };
}

// ---- dephasing channel: elements differing in qubit q's bit decay ----
pub fn dephase(rho: Rho, q: usize, gamma: f32, t: f32) Rho {
    const f = @exp(-gamma * t);
    var out = rho;
    for (0..4) |i| {
        for (0..4) |j| {
            const bi = if (q == 0) i & 1 else (i >> 1) & 1;
            const bj = if (q == 0) j & 1 else (j >> 1) & 1;
            if (bi != bj) out[i][j] = csc(rho[i][j], f);
        }
    }
    return out;
}

// ---- Bloch vector of one qubit's reduced state (partial trace) ----
pub fn bloch(rho: Rho, q: usize) [3]f32 {
    var a00: Cplx = undefined;
    var a01: Cplx = undefined;
    var a10: Cplx = undefined;
    var a11: Cplx = undefined;
    if (q == 0) {
        a00 = cadd(rho[0][0], rho[2][2]);
        a01 = cadd(rho[0][1], rho[2][3]);
        a10 = cadd(rho[1][0], rho[3][2]);
        a11 = cadd(rho[1][1], rho[3][3]);
    } else {
        a00 = cadd(rho[0][0], rho[1][1]);
        a01 = cadd(rho[0][2], rho[1][3]);
        a10 = cadd(rho[2][0], rho[3][1]);
        a11 = cadd(rho[2][2], rho[3][3]);
    }
    return .{ 2 * a01[0], 2 * a10[1], a00[0] - a11[0] };
}

// ---- CHSH on the singlet (kernel-side; the HUD carries this verdict) ----
fn chshE(rng: *Rng, a: f32, b: f32, n: u32) f32 {
    var sum: i32 = 0;
    for (0..n) |_| {
        var rho = bellRho(.psi_m);
        rho = applySingleU(rho, rotY(-a), 0);
        rho = applySingleU(rho, rotY(-b), 1);
        const m = measure(rho, rng);
        const b0 = m.outcome & 1;
        const b1 = (m.outcome >> 1) & 1;
        sum += if (b0 == b1) @as(i32, 1) else @as(i32, -1);
    }
    return @as(f32, @floatFromInt(sum)) / @as(f32, @floatFromInt(n));
}

pub fn chsh() f32 {
    var rng = Rng.init(1337);
    const pi = std.math.pi;
    const n: u32 = 4096;
    return chshE(&rng, 0, pi * 0.25, n) - chshE(&rng, 0, pi * 0.75, n) +
        chshE(&rng, pi * 0.5, pi * 0.25, n) + chshE(&rng, pi * 0.5, pi * 0.75, n);
}

// ---- the pairs table (mesh nodes 0..11) ----
pub const MAX_PAIRS = 4;
pub const Pair = struct {
    a: usize = 0,
    b: usize = 0,
    active: bool = false,
    rho: Rho = undefined,
    c: f32 = 0,
    broken: bool = false,
};

pub var pairs: [MAX_PAIRS]Pair = undefined;
// PROVISIONAL default decay 0.020/tick — the value is Nathan's call
// (roadmap open call #3); `bell decay <milli>` sets it live.
pub var gamma_milli: u32 = 20;
pub var last_s_milli: i32 = 0;
pub var s_valid: bool = false;

pub fn init() void {
    for (&pairs) |*p| {
        p.* = .{};
    }
    last_s_milli = 0;
    s_valid = false;
}

pub fn makePair(a: usize, b: usize) bool {
    if (a == b or a >= 12 or b >= 12) return false;
    for (&pairs) |*p| {
        if (!p.active) {
            p.* = .{ .a = a, .b = b, .active = true, .rho = bellRho(.phi_p), .c = 1.0 };
            return true;
        }
    }
    return false;
}

pub fn refresh(i: usize) void {
    if (i < MAX_PAIRS and pairs[i].active) {
        pairs[i].rho = bellRho(.phi_p);
        pairs[i].c = 1.0;
        pairs[i].broken = false;
    }
}

// one mesh-clock tick of decoherence: dephase qubit A, dt = 1 tick
pub fn tick() void {
    const g: f32 = @as(f32, @floatFromInt(gamma_milli)) / 1000.0;
    if (g <= 0) return;
    for (&pairs) |*p| {
        if (!p.active) continue;
        p.rho = dephase(p.rho, 0, g, 1.0);
        const cc = concurrence(p.rho);
        if (cc < 0) {
            p.broken = true; // X-form guard fired — surfaced, never hidden
        } else {
            p.c = cc;
        }
    }
}
