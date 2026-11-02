// Harakiri NG — parity proof for the transforms unification (v1.1).
// The pre-unification project() from mesh.zig/wells.zig (hand-rolled,
// 4-decimal trig literals) against pyre.project_orbit (Mat4 composition,
// real trig) over a grid of points and scales. The only sanctioned
// difference is the literals' rounding: rotated coords must agree to
// < 2e-4, and integer screen coords must never differ by more than 1 px.
const std = @import("std");
const pyre = @import("pyre.zig");

fn old_project(p: [3]f32, cx: i32, cy: i32, s: i32) [2]i32 {
    const ca: f32 = 0.8776;
    const sa: f32 = 0.4794;
    const cb: f32 = 0.9394;
    const sb: f32 = 0.3429;
    const x1 = p[0] * ca + p[2] * sa;
    const z1 = -p[0] * sa + p[2] * ca;
    const y1 = p[1] * cb - z1 * sb;
    return .{
        cx + @as(i32, @intFromFloat(x1 * @as(f32, @floatFromInt(s)))),
        cy - @as(i32, @intFromFloat(y1 * @as(f32, @floatFromInt(s)))),
    };
}

pub fn main() void {
    var pass: u32 = 0;
    var fail: u32 = 0;
    var max_dev: f32 = 0;
    var max_px: u32 = 0;
    const scales = [_]i32{ 40, 90, 160 };
    var xi: i32 = -8;
    while (xi <= 8) : (xi += 1) {
        var yi: i32 = -8;
        while (yi <= 8) : (yi += 1) {
            var zi: i32 = -8;
            while (zi <= 8) : (zi += 1) {
                const p = [3]f32{ @as(f32, @floatFromInt(xi)) * 0.25, @as(f32, @floatFromInt(yi)) * 0.25, @as(f32, @floatFromInt(zi)) * 0.25 };
                const q = pyre.ORBIT_VIEW.transform_point(.{ .x = p[0], .y = p[1], .z = p[2] });
                const ca: f32 = 0.8776;
                const sa: f32 = 0.4794;
                const cb: f32 = 0.9394;
                const sb: f32 = 0.3429;
                const x1 = p[0] * ca + p[2] * sa;
                const z1 = -p[0] * sa + p[2] * ca;
                const y1 = p[1] * cb - z1 * sb;
                const dev = @max(@abs(q.x - x1), @abs(q.y - y1));
                if (dev > max_dev) max_dev = dev;
                if (dev < 2e-4) {
                    pass += 1;
                } else {
                    fail += 1;
                }
                for (scales) |s| {
                    const a = old_project(p, 320, 240, s);
                    const b = pyre.project_orbit(p, 320, 240, s);
                    const d = @max(@abs(a[0] - b[0]), @abs(a[1] - b[1]));
                    if (d > max_px) max_px = d;
                    if (d <= 1) {
                        pass += 1;
                    } else {
                        fail += 1;
                    }
                }
            }
        }
    }
    std.debug.print("check_project: max coord deviation {d:.6}, max screen deviation {} px\n", .{ max_dev, max_px });
    std.debug.print("{} pass, {} fail\n", .{ pass, fail });
    if (fail > 0) std.process.exit(1);
}
