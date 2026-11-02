// Harakiri NG — Pyre GPU (Zig port)
// Software 3D rasterizer. Bare metal, no libc, no FPU dependency beyond basics.
// Renders through SI Core.
// Nathan Brown, 2026.

const sicore = @import("sicore.zig");
const neural = @import("neural.zig");
const std = @import("std"); // for math only — not used at runtime

// ---- vec3 ----
pub const Vec3 = struct {
    x: f32, y: f32, z: f32,

    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return .{ .x = a.x - b.x, .y = a.y - b.y, .z = a.z - b.z };
    }
    pub fn cross(a: Vec3, b: Vec3) Vec3 {
        return .{
            .x = a.y * b.z - a.z * b.y,
            .y = a.z * b.x - a.x * b.z,
            .z = a.x * b.y - a.y * b.x,
        };
    }
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

// ---- mat4 (column-major) ----
pub const Mat4 = struct {
    m: [16]f32,

    pub fn identity() Mat4 {
        return .{ .m = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1,
        } };
    }

    pub fn perspective(fov: f32, aspect: f32, near: f32, far: f32) Mat4 {
        const t = 1.0 / @tan(fov * 0.5);
        return .{ .m = .{
            t / aspect, 0, 0, 0,
            0, t, 0, 0,
            0, 0, (far + near) / (near - far), -1,
            0, 0, (2 * far * near) / (near - far), 0,
        } };
    }

    pub fn rot_y(angle: f32) Mat4 {
        const c = @cos(angle);
        const s = @sin(angle);
        return .{ .m = .{
            c, 0, -s, 0,
            0, 1, 0, 0,
            s, 0, c, 0,
            0, 0, 0, 1,
        } };
    }

    pub fn rot_x(angle: f32) Mat4 {
        const c = @cos(angle);
        const s = @sin(angle);
        return .{ .m = .{
            1, 0, 0, 0,
            0, c, s, 0,
            0, -s, c, 0,
            0, 0, 0, 1,
        } };
    }

    pub fn translate(x: f32, y: f32, z: f32) Mat4 {
        return .{ .m = .{
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            x, y, z, 1,
        } };
    }

    pub fn mul(a: Mat4, b: Mat4) Mat4 {
        var r = Mat4.identity();
        for (0..4) |col| {
            for (0..4) |row| {
                var sum: f32 = 0;
                for (0..4) |k| {
                    sum += a.m[k * 4 + row] * b.m[col * 4 + k];
                }
                r.m[col * 4 + row] = sum;
            }
        }
        return r;
    }

    pub fn transform_point(m: Mat4, v: Vec3) Vec3 {
        const x = m.m[0] * v.x + m.m[4] * v.y + m.m[8] * v.z + m.m[12];
        const y = m.m[1] * v.x + m.m[5] * v.y + m.m[9] * v.z + m.m[13];
        const z = m.m[2] * v.x + m.m[6] * v.y + m.m[10] * v.z + m.m[14];
        const w = m.m[3] * v.x + m.m[7] * v.y + m.m[11] * v.z + m.m[15];
        if (w != 0) {
            return .{ .x = x / w, .y = y / w, .z = z / w };
        }
        return .{ .x = x, .y = y, .z = z };
    }
};

// ---- the shared orbit projection ----
// One projection for every viewport layer. Before the unification,
// mesh.zig and wells.zig each hand-rolled this same rotation with
// 4-decimal trig literals (0.8776, 0.4794, 0.9394, 0.3429); the matrix
// form computes the real values and there is exactly one place to fix.
// rotY(0.5) then rotX(0.35), orthographic, scaled to pixels — the same
// numbers the hand-rolled code produced, proven by check_project.zig.
pub const ORBIT_VIEW = Mat4.mul(Mat4.rot_x(0.35), Mat4.rot_y(0.5));

pub fn project_orbit(p: [3]f32, cx: i32, cy: i32, s: i32) [2]i32 {
    const q = ORBIT_VIEW.transform_point(.{ .x = p[0], .y = p[1], .z = p[2] });
    const sf: f32 = @floatFromInt(s);
    return .{
        cx + @as(i32, @intFromFloat(q.x * sf)),
        cy - @as(i32, @intFromFloat(q.y * sf)),
    };
}

// ---- cube ----
const cube_verts = [8]Vec3{
    .{ .x = -1, .y = -1, .z = -1 },
    .{ .x = 1, .y = -1, .z = -1 },
    .{ .x = 1, .y = 1, .z = -1 },
    .{ .x = -1, .y = 1, .z = -1 },
    .{ .x = -1, .y = -1, .z = 1 },
    .{ .x = 1, .y = -1, .z = 1 },
    .{ .x = 1, .y = 1, .z = 1 },
    .{ .x = -1, .y = 1, .z = 1 },
};

const cube_tris = [12][3]u8{
    .{ 0, 2, 1 }, .{ 0, 3, 2 }, // front (winding corrected 2026-10-17: was inside-out)
    .{ 5, 7, 4 }, .{ 5, 6, 7 }, // back (winding corrected 2026-10-17: was inside-out)
    .{ 4, 0, 3 }, .{ 4, 3, 7 }, // left
    .{ 1, 5, 6 }, .{ 1, 6, 2 }, // right
    .{ 3, 2, 6 }, .{ 3, 6, 7 }, // top
    .{ 4, 5, 1 }, .{ 4, 1, 0 }, // bottom
};

// Harakiri palette for faces
const face_colors = [6][3]u8{
    .{ 220, 20, 60 },   // crimson
    .{ 140, 10, 30 },   // dark crimson
    .{ 180, 30, 50 },   // mid crimson
    .{ 100, 8, 20 },    // deep
    .{ 200, 40, 70 },   // bright
    .{ 80, 5, 15 },     // darkest
};

// Depth buffer
var depth: [sicore.FB_W * sicore.FB_H]f32 = undefined;

fn clear_depth() void {
    for (&depth) |*d| d.* = 1e30;
}

// Barycentric triangle rasterizer
fn draw_tri(p0: Vec3, p1: Vec3, p2: Vec3, color: [3]u8) void {
    const W: f32 = @floatFromInt(sicore.FB_W);
    const H: f32 = @floatFromInt(sicore.FB_H);

    // NDC to screen
    const sx0: i32 = @intFromFloat((p0.x * 0.5 + 0.5) * W);
    const sy0: i32 = @intFromFloat((0.5 - p0.y * 0.5) * H);
    const sx1: i32 = @intFromFloat((p1.x * 0.5 + 0.5) * W);
    const sy1: i32 = @intFromFloat((0.5 - p1.y * 0.5) * H);
    const sx2: i32 = @intFromFloat((p2.x * 0.5 + 0.5) * W);
    const sy2: i32 = @intFromFloat((0.5 - p2.y * 0.5) * H);

    // Backface cull (signed area)
    const area = (sx1 - sx0) * (sy2 - sy0) - (sx2 - sx0) * (sy1 - sy0);
    if (area <= 0) return;

    // Bounding box
    const minx = @max(0, @min(sx0, @min(sx1, sx2)));
    const maxx = @min(sicore.FB_W - 1, @max(sx0, @max(sx1, sx2)));
    const miny = @max(0, @min(sy0, @min(sy1, sy2)));
    const maxy = @min(sicore.FB_H - 1, @max(sy0, @max(sy1, sy2)));

    const farea: f32 = @floatFromInt(area);

    var y = miny;
    while (y <= maxy) : (y += 1) {
        var x = minx;
        while (x <= maxx) : (x += 1) {
            // Barycentric
            const w0: f32 = @floatFromInt((sx1 - x) * (sy2 - y) - (sx2 - x) * (sy1 - y));
            const w1: f32 = @floatFromInt((sx2 - x) * (sy0 - y) - (sx0 - x) * (sy2 - y));
            const w2: f32 = @floatFromInt((sx0 - x) * (sy1 - y) - (sx1 - x) * (sy0 - y));
            if (w0 >= 0 and w1 >= 0 and w2 >= 0) {
                const b0 = w0 / farea;
                const b1 = w1 / farea;
                const b2 = w2 / farea;
                const z = b0 * p0.z + b1 * p1.z + b2 * p2.z;
                const idx: usize = @intCast(y * sicore.FB_W + x);
                if (z < depth[idx]) {
                    depth[idx] = z;
                    sicore.plot(x, y, color);
                }
            }
        }
    }
}

pub fn render_cube(angle_deg: u32) u32 {
    const angle: f32 = @as(f32, @floatFromInt(angle_deg)) * 0.0174533;
    const aspect: f32 = @as(f32, @floatFromInt(sicore.FB_W)) / @as(f32, @floatFromInt(sicore.FB_H));

    sicore.clear(sicore.OBSIDIAN);
    clear_depth();

    const proj = Mat4.perspective(1.047, aspect, 0.1, 100.0); // 60 deg
    const rot = Mat4.rot_y(angle);
    const trans = Mat4.translate(0, 0, -5);
    const mvp = Mat4.mul(proj, Mat4.mul(trans, rot));

    var tris_drawn: u32 = 0;
    for (cube_tris, 0..) |tri, i| {
        const v0 = Mat4.transform_point(mvp, cube_verts[tri[0]]);
        const v1 = Mat4.transform_point(mvp, cube_verts[tri[1]]);
        const v2 = Mat4.transform_point(mvp, cube_verts[tri[2]]);
        draw_tri(v0, v1, v2, face_colors[i / 2]);
        tris_drawn += 1;
    }
    return tris_drawn;
}

// ---- Neural BRDF path (opt-in demo; flat-shaded render_cube above is untouched) ----

// Cube face normals (±x, ±y, ±z per cube_tris face order)
const face_normals = [6]Vec3{
    .{ .x = 0, .y = 0, .z = 1 },  // front
    .{ .x = 0, .y = 0, .z = -1 }, // back
    .{ .x = -1, .y = 0, .z = 0 }, // left
    .{ .x = 1, .y = 0, .z = 0 },  // right
    .{ .x = 0, .y = 1, .z = 0 },  // top
    .{ .x = 0, .y = -1, .z = 0 }, // bottom
};

// d120 material-family roll per face (1..120 normalized). Each face wears a
// different family, so the cube shows the BRDF's material variation.
const face_d120 = [6]f32{ 7.0 / 120.0, 27.0 / 120.0, 47.0 / 120.0, 67.0 / 120.0, 87.0 / 120.0, 107.0 / 120.0 };

// Fixed key light for the neural demo: normalize(0.3, 0.3, 0.9),
// the same light the v2 BRDF was trained and demoed against.
const demo_light = Vec3{ .x = 0.30151, .y = 0.30151, .z = 0.90453 };

// Triangle rasterizer with per-pixel interpolated normals + neural BRDF shade.
// p*: NDC clip positions (for raster); q*: world-space positions (for view dir);
// n*: world-space vertex normals (interpolated + renormalized per pixel).
fn draw_tri_neural(p0: Vec3, p1: Vec3, p2: Vec3, q0: Vec3, q1: Vec3, q2: Vec3, n0: Vec3, n1: Vec3, n2: Vec3, d120_norm: f32) void {
    const W: f32 = @floatFromInt(sicore.FB_W);
    const H: f32 = @floatFromInt(sicore.FB_H);

    const sx0: i32 = @intFromFloat((p0.x * 0.5 + 0.5) * W);
    const sy0: i32 = @intFromFloat((0.5 - p0.y * 0.5) * H);
    const sx1: i32 = @intFromFloat((p1.x * 0.5 + 0.5) * W);
    const sy1: i32 = @intFromFloat((0.5 - p1.y * 0.5) * H);
    const sx2: i32 = @intFromFloat((p2.x * 0.5 + 0.5) * W);
    const sy2: i32 = @intFromFloat((0.5 - p2.y * 0.5) * H);

    // Backface cull (signed area)
    const area = (sx1 - sx0) * (sy2 - sy0) - (sx2 - sx0) * (sy1 - sy0);
    if (area <= 0) return;

    const minx = @max(0, @min(sx0, @min(sx1, sx2)));
    const maxx = @min(sicore.FB_W - 1, @max(sx0, @max(sx1, sx2)));
    const miny = @max(0, @min(sy0, @min(sy1, sy2)));
    const maxy = @min(sicore.FB_H - 1, @max(sy0, @max(sy1, sy2)));

    const farea: f32 = @floatFromInt(area);

    var y = miny;
    while (y <= maxy) : (y += 1) {
        var x = minx;
        while (x <= maxx) : (x += 1) {
            const w0: f32 = @floatFromInt((sx1 - x) * (sy2 - y) - (sx2 - x) * (sy1 - y));
            const w1: f32 = @floatFromInt((sx2 - x) * (sy0 - y) - (sx0 - x) * (sy2 - y));
            const w2: f32 = @floatFromInt((sx0 - x) * (sy1 - y) - (sx1 - x) * (sy0 - y));
            if (w0 >= 0 and w1 >= 0 and w2 >= 0) {
                const b0 = w0 / farea;
                const b1 = w1 / farea;
                const b2 = w2 / farea;
                const z = b0 * p0.z + b1 * p1.z + b2 * p2.z;
                const idx: usize = @intCast(y * sicore.FB_W + x);
                if (z < depth[idx]) {
                    depth[idx] = z;
                    // Interpolated normal (renormalized), world position for view dir
                    const n = (Vec3{
                        .x = b0 * n0.x + b1 * n1.x + b2 * n2.x,
                        .y = b0 * n0.y + b1 * n1.y + b2 * n2.y,
                        .z = b0 * n0.z + b1 * n1.z + b2 * n2.z,
                    }).norm();
                    const qw = Vec3{
                        .x = b0 * q0.x + b1 * q1.x + b2 * q2.x,
                        .y = b0 * q0.y + b1 * q1.y + b2 * q2.y,
                        .z = b0 * q0.z + b1 * q1.z + b2 * q2.z,
                    };
                    const view_dir = (Vec3{ .x = -qw.x, .y = -qw.y, .z = -qw.z }).norm();
                    const c = neural.shade(
                        .{ .x = n.x, .y = n.y, .z = n.z },
                        .{ .x = demo_light.x, .y = demo_light.y, .z = demo_light.z },
                        .{ .x = view_dir.x, .y = view_dir.y, .z = view_dir.z },
                        d120_norm,
                    );
                    sicore.plot(x, y, c);
                }
            }
        }
    }
}

// Neural-lit cube demo: every fragment runs the v2 MLP (12->32->32->16->3).
pub fn render_cube_neural(angle_deg: u32) u32 {
    const angle: f32 = @as(f32, @floatFromInt(angle_deg)) * 0.0174533;
    const aspect: f32 = @as(f32, @floatFromInt(sicore.FB_W)) / @as(f32, @floatFromInt(sicore.FB_H));

    sicore.clear(sicore.OBSIDIAN);
    clear_depth();

    const proj = Mat4.perspective(1.047, aspect, 0.1, 100.0); // 60 deg
    const rot = Mat4.rot_y(angle);
    const trans = Mat4.translate(0, 0, -5);
    const model = Mat4.mul(trans, rot);
    const mvp = Mat4.mul(proj, model);

    var tris_drawn: u32 = 0;
    for (cube_tris, 0..) |tri, i| {
        const face = i / 2;
        const v0 = Mat4.transform_point(mvp, cube_verts[tri[0]]);
        const v1 = Mat4.transform_point(mvp, cube_verts[tri[1]]);
        const v2 = Mat4.transform_point(mvp, cube_verts[tri[2]]);
        const q0 = Mat4.transform_point(model, cube_verts[tri[0]]);
        const q1 = Mat4.transform_point(model, cube_verts[tri[1]]);
        const q2 = Mat4.transform_point(model, cube_verts[tri[2]]);
        // Rotate the face normal (direction only, w=0 math: drop translation)
        const fn0 = face_normals[face];
        const rn = Vec3{
            .x = rot.m[0] * fn0.x + rot.m[4] * fn0.y + rot.m[8] * fn0.z,
            .y = rot.m[1] * fn0.x + rot.m[5] * fn0.y + rot.m[9] * fn0.z,
            .z = rot.m[2] * fn0.x + rot.m[6] * fn0.y + rot.m[10] * fn0.z,
        };
        draw_tri_neural(v0, v1, v2, q0, q1, q2, rn, rn, rn, face_d120[face]);
        tris_drawn += 1;
    }
    return tris_drawn;
}

// ---- Neural sphere: the geometry the BRDF was trained on ----
// Lat/long sphere, per-vertex normals. Shows the highlight sweep.

const SPH_LAT: usize = 20;
const SPH_LON: usize = 28;
const SPH_R: f32 = 1.4;
const SPH_NVERT: usize = (SPH_LAT + 1) * (SPH_LON + 1);

var sph_verts: [SPH_NVERT]Vec3 = undefined;
var sph_built: bool = false;

// Transformed verts live in .bss (module scope) — the kernel stack is only
// 16KB and three 609-vert arrays would smash it.
var sph_wv: [SPH_NVERT]Vec3 = undefined;
var sph_cv: [SPH_NVERT]Vec3 = undefined;
var sph_wn: [SPH_NVERT]Vec3 = undefined;

fn build_sphere() void {
    if (sph_built) return;
    var vi: usize = 0;
    var lat: usize = 0;
    while (lat <= SPH_LAT) : (lat += 1) {
        const theta: f32 = @as(f32, @floatFromInt(lat)) / @as(f32, @floatFromInt(SPH_LAT)) * 3.14159265;
        const st = @sin(theta);
        const ct = @cos(theta);
        var lon: usize = 0;
        while (lon <= SPH_LON) : (lon += 1) {
            const phi: f32 = @as(f32, @floatFromInt(lon)) / @as(f32, @floatFromInt(SPH_LON)) * 6.2831853;
            sph_verts[vi] = .{
                .x = SPH_R * st * @cos(phi),
                .y = SPH_R * ct,
                .z = SPH_R * st * @sin(phi),
            };
            vi += 1;
        }
    }
    sph_built = true;
}

// Neural-lit sphere demo: d120 = 0.65 (roll 78, same as the C training demo).
pub fn render_sphere_neural(angle_deg: u32) u32 {
    build_sphere();
    const angle: f32 = @as(f32, @floatFromInt(angle_deg)) * 0.0174533;
    const aspect: f32 = @as(f32, @floatFromInt(sicore.FB_W)) / @as(f32, @floatFromInt(sicore.FB_H));

    sicore.clear(sicore.OBSIDIAN);
    clear_depth();

    const proj = Mat4.perspective(1.047, aspect, 0.1, 100.0); // 60 deg
    const rot = Mat4.rot_y(angle);
    const trans = Mat4.translate(0, 0, -5);
    const model = Mat4.mul(trans, rot);
    const mvp = Mat4.mul(proj, model);

    // Transform verts to world + clip once (module-scope arrays: the 16KB
    // kernel stack can't hold three 609-vert arrays)
    for (sph_verts, 0..) |sv, i| {
        sph_wv[i] = Mat4.transform_point(model, sv);
        sph_cv[i] = Mat4.transform_point(mvp, sv);
        // normal = normalized local pos, rotated (direction only)
        const il = 1.0 / SPH_R;
        const lx = sv.x * il;
        const ly = sv.y * il;
        const lz = sv.z * il;
        sph_wn[i] = .{
            .x = rot.m[0] * lx + rot.m[4] * ly + rot.m[8] * lz,
            .y = rot.m[1] * lx + rot.m[5] * ly + rot.m[9] * lz,
            .z = rot.m[2] * lx + rot.m[6] * ly + rot.m[10] * lz,
        };
    }

    var tris_drawn: u32 = 0;
    var lat: usize = 0;
    while (lat < SPH_LAT) : (lat += 1) {
        var lon: usize = 0;
        while (lon < SPH_LON) : (lon += 1) {
            const a = lat * (SPH_LON + 1) + lon;
            const b = a + 1;
            const c = a + SPH_LON + 1;
            const d = c + 1;
            draw_tri_neural(sph_cv[a], sph_cv[b], sph_cv[d], sph_wv[a], sph_wv[b], sph_wv[d], sph_wn[a], sph_wn[b], sph_wn[d], 0.65);
            draw_tri_neural(sph_cv[a], sph_cv[d], sph_cv[c], sph_wv[a], sph_wv[d], sph_wv[c], sph_wn[a], sph_wn[d], sph_wn[c], 0.65);
            tris_drawn += 2;
        }
    }
    return tris_drawn;
}
