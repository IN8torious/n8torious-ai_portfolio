// Host-side parity check: the Zig BELL port must agree with the JS pair engine
// (~/workspace/si-core-entanglement/pair.js, test_pair.js, chsh.js).
// Same battery, same analytic expectations. A test that cannot fail is a painting.
const bell = @import("bell.zig");
const std = @import("std");

var pass: u32 = 0;
var fail: u32 = 0;

fn t(name: []const u8, cond: bool) void {
    if (cond) {
        pass += 1;
    } else {
        fail += 1;
        std.debug.print("FAIL: {s}\n", .{name});
    }
}

fn approx(a: f32, b: f32, tol: f32) bool {
    return @abs(a - b) <= tol;
}

fn trace(rho: bell.Rho) f32 {
    var s: f32 = 0;
    for (0..4) |i| s += rho[i][i][0];
    return s;
}

const Z: bell.Cplx = .{ 0, 0 };
const ONE: bell.Cplx = .{ 1, 0 };

pub fn main() !void {
    // 1. trace preserved through 1000 random op sequences on rho
    {
        var rng = bell.Rng.init(42);
        var worst: f32 = 0;
        for (0..1000) |_| {
            const amps = [4]bell.Cplx{
                .{ rng.next(), rng.next() },
                .{ rng.next(), rng.next() },
                .{ rng.next(), rng.next() },
                .{ rng.next(), rng.next() },
            };
            var n: f32 = 0;
            for (amps) |a| n += a[0] * a[0] + a[1] * a[1];
            const inv = 1.0 / @sqrt(n);
            var na: [4]bell.Cplx = undefined;
            for (0..4) |i| na[i] = bell.csc(amps[i], inv);
            var rho = bell.rhoFromAmps(na);
            rho = bell.applySingleU(rho, bell.rotY(rng.next() * 6.28), 0);
            rho = bell.applySingleU(rho, bell.rotZ(rng.next() * 6.28), 1);
            rho = bell.applyCNOT(rho, 0, 1);
            worst = @max(worst, @abs(trace(rho) - 1));
        }
        t("trace preserved through 1000 random op sequences", worst < 0.0001);
    }

    // 2. product states give C = 0
    {
        var worst: f32 = 0;
        const bases = [4][4]bell.Cplx{
            .{ ONE, Z, Z, Z },
            .{ Z, ONE, Z, Z },
            .{ Z, Z, ONE, Z },
            .{ Z, Z, Z, ONE },
        };
        for (bases) |amps| {
            worst = @max(worst, bell.concurrence(bell.rhoFromAmps(amps)));
        }
        var rng = bell.Rng.init(7);
        for (0..50) |_| {
            var rho = bell.rhoFromAmps(bases[0]);
            rho = bell.applySingleU(rho, bell.rotY(rng.next() * 6.28), 0);
            rho = bell.applySingleU(rho, bell.rotZ(rng.next() * 6.28), 0);
            rho = bell.applySingleU(rho, bell.rotY(rng.next() * 6.28), 1);
            worst = @max(worst, bell.concurrence(rho));
        }
        t("product states give C = 0", worst < 0.001);
    }

    // 3. Bell states give C = 1
    {
        var worst: f32 = 0;
        for ([_]bell.BellKind{ .phi_p, .phi_m, .psi_p, .psi_m }) |k| {
            worst = @max(worst, @abs(bell.concurrence(bell.bellRho(k)) - 1));
        }
        t("all four Bell states give C = 1", worst < 0.0001);
    }

    // 4. H on A then CNOT(A->B) builds phi+ exactly (compare density matrices)
    {
        const amps = [4]bell.Cplx{ ONE, Z, Z, Z };
        var rho = bell.rhoFromAmps(amps);
        rho = bell.applySingleU(rho, bell.hadamard(), 0);
        rho = bell.applyCNOT(rho, 0, 1);
        const ref = bell.bellRho(.phi_p);
        var worst: f32 = 0;
        for (0..4) |i| {
            for (0..4) |j| {
                worst = @max(worst, bell.cmod(bell.csub(rho[i][j], ref[i][j])));
            }
        }
        t("H + CNOT builds phi+ exactly", worst < 0.0001 and approx(bell.concurrence(rho), 1, 0.0001));
    }

    // 5. Born statistics on (|00>+|01>)/sqrt(2)
    {
        const h: f32 = 0.70710678;
        const amps = [4]bell.Cplx{ .{ h, 0 }, .{ h, 0 }, Z, Z };
        const rho = bell.rhoFromAmps(amps);
        var rng = bell.Rng.init(2026);
        var n0: u32 = 0;
        var n1: u32 = 0;
        var nbad: u32 = 0;
        const N: u32 = 4096;
        for (0..N) |_| {
            const m = bell.measure(rho, &rng);
            if (m.outcome == 0) {
                n0 += 1;
            } else if (m.outcome == 1) {
                n1 += 1;
            } else {
                nbad += 1;
            }
        }
        const p0 = @as(f32, @floatFromInt(n0)) / N;
        const p1 = @as(f32, @floatFromInt(n1)) / N;
        t("Born statistics converge", nbad == 0 and approx(p0, 0.5, 0.03) and approx(p1, 0.5, 0.03));
    }

    // 6. the seed is the source
    {
        const amps = [4]bell.Cplx{ ONE, Z, Z, Z };
        var rho = bell.rhoFromAmps(amps);
        rho = bell.applySingleU(rho, bell.hadamard(), 0);
        const seq = struct {
            fn run(r: bell.Rho, seed: u32) [64]u8 {
                var rng = bell.Rng.init(seed);
                var out: [64]u8 = undefined;
                for (0..64) |i| out[i] = bell.measure(r, &rng).outcome;
                return out;
            }
        }.run;
        t("same seed reproduces the outcome sequence", std.mem.eql(u8, &seq(rho, 99), &seq(rho, 99)));
        t("different seed changes the outcome sequence", !std.mem.eql(u8, &seq(rho, 99), &seq(rho, 100)));
    }

    // 7. measuring one half of phi+ breaks it: C -> 0, partner definite
    {
        const trials: u32 = 2048;
        var n0: u32 = 0;
        var worst_c: f32 = 0;
        var mismatch: u32 = 0;
        for (0..trials) |i| {
            var rng = bell.Rng.init(5000 + @as(u32, @intCast(i)));
            const m = bell.measureQubit(bell.bellRho(.phi_p), 0, &rng);
            if (m.outcome == 0) n0 += 1;
            worst_c = @max(worst_c, bell.concurrence(m.rho));
            const expect: usize = if (m.outcome == 0) 0 else 3;
            if (m.rho[expect][expect][0] < 0.999) mismatch += 1;
        }
        const p0 = @as(f32, @floatFromInt(n0)) / trials;
        t("partial measurement: definite partner, entanglement broken", approx(p0, 0.5, 0.03) and worst_c < 0.001 and mismatch == 0);
    }

    // 8. dephasing drives C along e^(-gamma t)
    {
        const rho = bell.bellRho(.phi_p);
        var worst: f32 = 0;
        for ([_]f32{ 0, 0.25, 0.5, 1, 2 }) |tt| {
            const d = bell.dephase(rho, 0, 1, tt);
            worst = @max(worst, @abs(bell.concurrence(d) - @exp(-tt)));
        }
        const dead = bell.dephase(rho, 0, 1, 20);
        t("dephasing drives C along e^(-gamma t)", worst < 0.0001 and bell.concurrence(dead) < 0.000001);
    }

    // 9. concurrence is loud off X-form: sentinel -1, never a fake number
    {
        const h: f32 = 0.70710678;
        const amps = [4]bell.Cplx{ .{ h, 0 }, .{ h, 0 }, Z, Z };
        const rho = bell.rhoFromAmps(amps);
        t("concurrence refuses non-X-form rho", bell.concurrence(rho) == -1.0);
    }

    // 10. CNOT twice is the identity
    {
        var rng = bell.Rng.init(11);
        const amps = [4]bell.Cplx{
            .{ rng.next(), rng.next() },
            .{ rng.next(), rng.next() },
            .{ rng.next(), rng.next() },
            .{ rng.next(), rng.next() },
        };
        var n: f32 = 0;
        for (amps) |a| n += a[0] * a[0] + a[1] * a[1];
        const inv = 1.0 / @sqrt(n);
        var na: [4]bell.Cplx = undefined;
        for (0..4) |i| na[i] = bell.csc(amps[i], inv);
        const rho = bell.rhoFromAmps(na);
        const back = bell.applyCNOT(bell.applyCNOT(rho, 0, 1), 0, 1);
        var worst: f32 = 0;
        for (0..4) |i| {
            for (0..4) |j| {
                worst = @max(worst, bell.cmod(bell.csub(back[i][j], rho[i][j])));
            }
        }
        t("CNOT applied twice is the identity", worst < 0.0001);
    }

    // 11. CHSH parity: the Zig engine must also break the classical ceiling,
    //     and land near the JS engine's S (-2.8789) within sampling noise
    {
        const s = bell.chsh();
        std.debug.print("CHSH (zig) S = {d:.4}  (js: -2.8789, analytic: -2.8284)\n", .{s});
        t("CHSH singlet violates the classical bound", s < -2.6);
        t("CHSH lands near the analytic 2*sqrt(2)", approx(s, -2.8284, 0.15));
    }

    std.debug.print("check_bell: {d}/{d} green\n", .{ pass, pass + fail });
    if (fail > 0) std.process.exit(1);
}
