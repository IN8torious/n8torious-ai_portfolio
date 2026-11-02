// Host-side numeric check of the Zig neural BRDF port.
// Prints shade() for fixed inputs; compare against the C reference output.
const neural = @import("neural.zig");
const std = @import("std");

pub fn main() !void {
    const n = neural.Vec3{ .x = 0.0, .y = 0.0, .z = 1.0 };
    const lraw = neural.Vec3{ .x = 0.3, .y = 0.3, .z = 0.9 };
    const l = lraw.norm();
    const v = neural.Vec3{ .x = 0.0, .y = 0.0, .z = 1.0 };
    const c1 = neural.shade(n, l, v, 0.65);
    std.debug.print("front: {d} {d} {d}\n", .{ c1[0], c1[1], c1[2] });

    const n2raw = neural.Vec3{ .x = 0.9, .y = 0.1, .z = 0.2 };
    const n2 = n2raw.norm();
    const c2 = neural.shade(n2, l, v, 0.65);
    std.debug.print("side: {d} {d} {d}\n", .{ c2[0], c2[1], c2[2] });

    const c3 = neural.shade(n, l, v, 0.05);
    std.debug.print("d120-low: {d} {d} {d}\n", .{ c3[0], c3[1], c3[2] });
}
