// Harakiri NG — PainTr Desktop (Zig)
// Graphical shell. Windows, taskbar with live tRust task states.
// Cinematic render: 1280x720, ember glow, soft shadows, vignette.
// Renders through SI Core.
// Nathan Brown, 2026.

const trust = @import("trust.zig");
const sicore = @import("sicore.zig");
const hand = @import("hand.zig");
const mesh = @import("mesh.zig");
const wells = @import("wells.zig");
const gates = @import("gates.zig");
const kraken = @import("kraken.zig");
const bellview = @import("bellview.zig");

const OBSIDIAN = sicore.OBSIDIAN;
const CRIMSON = sicore.CRIMSON;
const CRIMSON_LT = sicore.CRIMSON_LT;
const GOLD = sicore.GOLD;
const WHITE = sicore.WHITE;
const GRAY = sicore.GRAY;
const DARK = sicore.DARK;
const GREEN = sicore.GREEN;

const FB_W = sicore.FB_W;
const FB_H = sicore.FB_H;
const TB_H: i32 = 56;

// We need text — import from taskmgr's font
const taskmgr = @import("taskmgr.zig");
const icons = @import("icons.zig");

// ---- window: machined 3D bezel frame, icon in the title bar ----
fn draw_window(x: i32, y: i32, w: i32, h: i32, title: []const u8, glyph: usize) void {
    // soft drop shadow
    sicore.shadow(x, y, x + w, y + h, 14, 150);
    // body
    sicore.rect(x, y, x + w, y + h, DARK);
    // glassy title bar
    sicore.vgrad(x + 1, y + 1, x + w - 1, y + 32, .{ 34, 18, 30 }, .{ 16, 10, 17 });
    sicore.hline(x + 1, x + w - 1, y + 32, CRIMSON);
    // 3D bezel: light from the top-left, weight on the bottom-right
    sicore.hline(x + 1, x + w - 1, y + 1, .{ 120, 40, 55 });
    sicore.vline(x + 1, y + 1, y + h - 1, .{ 120, 40, 55 });
    sicore.hline(x + 1, x + w - 1, y + h - 2, .{ 30, 8, 14 });
    sicore.vline(x + w - 2, y + 1, y + h - 1, .{ 30, 8, 14 });
    // title icon + title
    icons.beveled_icon(x + 10, y + 7, 18, .{ 24, 12, 18 }, glyph, CRIMSON_LT);
    taskmgr.draw_text_pub(x + 36, y + 10, title, WHITE);
    // close dot, lit
    sicore.glow(x + w - 22, y + 16, 12, CRIMSON_LT, 110);
    sicore.circle(x + w - 22, y + 16, 5, CRIMSON_LT);
}

// resize bezel: diagonal grip lines at a window's bottom-right corner
fn draw_bezel(x: i32, y: i32, lit: bool) void {
    const c = if (lit) GOLD else GRAY;
    sicore.line(x - 18, y, x, y - 18, c);
    sicore.line(x - 12, y, x, y - 12, c);
    sicore.line(x - 6, y, x, y - 6, c);
    if (lit) sicore.glow(x - 9, y - 9, 14, GOLD, 90);
}

fn state_color(s: trust.TaskState) [3]u8 {
    return switch (s) {
        .idle => GRAY,
        .ready => WHITE,
        .running => GREEN,
        .yielding => GOLD,
        .blocked => CRIMSON,
        .done => GRAY,
        .faulted => CRIMSON_LT,
    };
}

pub fn render() void {
    // desktop background: obsidian, faint ember glow rising from below, vignette
    sicore.clear(OBSIDIAN);
    sicore.glow(FB_W / 2, FB_H + 120, 620, .{ 70, 12, 24 }, 42);
    sicore.glow(FB_W / 2, FB_H / 3, 420, .{ 24, 8, 18 }, 28);

    // title
    taskmgr.draw_text_2x_pub(32, 26, "POETCHI", WHITE);
    taskmgr.draw_text_pub(34, 60, "desktop - two hands online", GRAY);

    // agent window
    draw_window(32, 110, 560, 380, "agents", 0);
    taskmgr.draw_text_pub(48, 148, "task", GRAY);
    taskmgr.draw_text_pub(220, 148, "state", GRAY);
    taskmgr.draw_text_pub(360, 148, "vruntime", GRAY);
    var y: i32 = 172;
    for (trust.tasks[0..trust.ntasks]) |*t| {
        if (y > 460) break;
        taskmgr.draw_text_pub(48, y, trust.task_name(t), WHITE);
        taskmgr.draw_text_pub(220, y, @tagName(t.state), state_color(t.state));
        taskmgr.draw_ulong_pub(360, y, t.vruntime, GRAY);
        y += 22;
    }

    // 3D viewport window: the mesh + the wells + the gates live here now
    draw_window(624, 110, 624, 380, "viewport - mesh + wells", 4);
    wells.render(936, 295, 125);
    mesh.render(936, 295, 125);
    bellview.render_vp(936, 295, 125); // the Bell beams, if any are live
    gates.render(936, 295, 125);
    kraken.render_vp(); // the Outer Path at the center, tentacles to the paths
    taskmgr.draw_text_pub(640, 450, "kuramoto coherence - brightness = alignment", GRAY);
    const grabbed = hand.pointer_grabbing_pub();
    draw_bezel(1248, 490, grabbed);

    // GPU window
    draw_window(32, 510, 400, 120, "pyre gpu", 2);
    taskmgr.draw_text_pub(48, 556, "software raster", WHITE);
    taskmgr.draw_text_pub(48, 578, "1280x720", GRAY);
    taskmgr.draw_text_pub(48, 600, "sicore: online", GREEN);

    // hands window
    draw_window(452, 510, 380, 120, "hands", 7);
    taskmgr.draw_text_pub(468, 556, "worker: ", GRAY);
    taskmgr.draw_text_pub(540, 556, hand.worker_state_pub(), WHITE);
    taskmgr.draw_text_pub(468, 578, "pointer: ", GRAY);
    taskmgr.draw_text_pub(540, 578, hand.pointer_state(), GOLD);

    // taskbar
    const tb_y = FB_H - TB_H;
    sicore.vgrad(0, tb_y, FB_W, FB_H, DARK, .{ 8, 5, 10 });
    sicore.hline(0, FB_W, tb_y, CRIMSON);
    sicore.glow(FB_W / 2, tb_y, 200, CRIMSON, 50);
    taskmgr.draw_text_pub(16, tb_y + 20, "harakiri", CRIMSON_LT);

    // live agent icons on the taskbar — beveled, state in the glyph color
    var tx: i32 = 140;
    var gi: usize = 0;
    for (trust.tasks[0..trust.ntasks]) |*t| {
        if (tx > FB_W - 40) break;
        icons.beveled_icon(tx, tb_y + 14, 26, .{ 22, 11, 16 }, icons.agent_glyph(gi), state_color(t.state));
        gi += 1;
        tx += 36;
    }

    // the Hands
    hand.render();

    // cinematic finish: tight vignette pulls focus to the work
    sicore.vignette(84);
}
