// Harakiri NG — Neural BRDF v2 (Zig port)
// Bare-metal port of pyre-gpu/ml/pyre_neural_v2.h.
// MLP: 12 -> 32 -> 32 -> 16 -> 3. Weights in neural_weights.zig,
// values character-identical to neural_brdf_v2_weights.h.
// Nathan Brown, 2026.

const w = @import("neural_weights.zig");

// ---- vec3 (local copy so this module needs no other imports) ----
pub const Vec3 = struct {
    x: f32, y: f32, z: f32,

    pub fn dot(a: Vec3, b: Vec3) f32 {
        return a.x * b.x + a.y * b.y + a.z * b.z;
    }
    pub fn len(a: Vec3) f32 {
        return @sqrt(a.dot(a));
    }
    pub fn norm(a: Vec3) Vec3 {
        const l = a.len();
        if (l == 0) return a;
        return .{ .x = a.x / l, .y = a.y / l, .z = a.z / l };
    }
};

// ---- sigmoid: 256-entry lookup, Taylor-series exp, ported op-for-op from the C ----
var sigmoid_table: [256]f32 = undefined;
var sigmoid_ready: bool = false;

fn taylor_e_h(h: f32) f32 {
    const h2 = h * h;
    const h3 = h2 * h;
    const h4 = h3 * h;
    const h5 = h4 * h;
    const h6 = h5 * h;
    return 1.0 + h + h2 / 2.0 + h3 / 6.0 + h4 / 24.0 + h5 / 120.0 + h6 / 720.0;
}

fn sigmoid_init() void {
    if (sigmoid_ready) return;
    var i: usize = 0;
    while (i < 256) : (i += 1) {
        const x: f32 = -8.0 + (16.0 * @as(f32, @floatFromInt(i))) / 255.0;
        var ex: f32 = undefined;
        if (x >= 0) {
            const e_h = taylor_e_h(-x / 8.0);
            ex = e_h * e_h;
            ex *= ex;
            ex *= ex;
        } else {
            const e_h = taylor_e_h(-x / 8.0);
            ex = e_h * e_h;
            ex *= ex;
            ex *= ex;
        }
        sigmoid_table[i] = 1.0 / (1.0 + ex);
    }
    sigmoid_ready = true;
}

fn sigmoid(x: f32) f32 {
    if (!sigmoid_ready) sigmoid_init();
    if (x <= -8.0) return 0.0;
    if (x >= 8.0) return 1.0;
    const t: f32 = (x + 8.0) * (255.0 / 16.0);
    const i: usize = @intFromFloat(t);
    if (i >= 255) return 1.0;
    const f: f32 = t - @as(f32, @floatFromInt(i));
    return sigmoid_table[i] * (1.0 - f) + sigmoid_table[i + 1] * f;
}

fn relu(x: f32) f32 {
    return if (x > 0.0) x else 0.0;
}

// ---- neural shade ----
// n, light_dir, view_dir: unit vectors. d120_norm: material family 1..120 / 120.
// Returns 0..255 RGB. Ported op-for-op from pyre2_neural_shade.
pub fn shade(n: Vec3, light_dir: Vec3, view_dir: Vec3, d120_norm: f32) [3]u8 {
    var ndotl = n.dot(light_dir);
    if (ndotl < 0.0) ndotl = 0.0;
    var ndotv = n.dot(view_dir);
    if (ndotv < 0.0) ndotv = 0.0;

    const in = [12]f32{
        n.x, n.y, n.z,
        light_dir.x, light_dir.y, light_dir.z,
        view_dir.x, view_dir.y, view_dir.z,
        d120_norm, ndotl, ndotv,
    };

    var h1: [32]f32 = undefined;
    for (0..32) |i| {
        var s: f32 = w.brdf2_b1[i];
        for (0..12) |j| s += w.brdf2_w1[i * 12 + j] * in[j];
        h1[i] = relu(s);
    }
    var h2: [32]f32 = undefined;
    for (0..32) |i| {
        var s: f32 = w.brdf2_b2[i];
        for (0..32) |j| s += w.brdf2_w2[i * 32 + j] * h1[j];
        h2[i] = relu(s);
    }
    var h3: [16]f32 = undefined;
    for (0..16) |i| {
        var s: f32 = w.brdf2_b3[i];
        for (0..32) |j| s += w.brdf2_w3[i * 32 + j] * h2[j];
        h3[i] = relu(s);
    }

    var r: f32 = w.brdf2_b4[0];
    var g: f32 = w.brdf2_b4[1];
    var b: f32 = w.brdf2_b4[2];
    for (0..16) |j| {
        r += w.brdf2_w4[0 * 16 + j] * h3[j];
        g += w.brdf2_w4[1 * 16 + j] * h3[j];
        b += w.brdf2_w4[2 * 16 + j] * h3[j];
    }

    return .{
        @intFromFloat(sigmoid(r) * 255.0),
        @intFromFloat(sigmoid(g) * 255.0),
        @intFromFloat(sigmoid(b) * 255.0),
    };
}
