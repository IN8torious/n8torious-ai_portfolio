// Harakiri NG — Web Browser
// Minimal HTML parser + layout + renderer. Local pages first, network later.
// Renders through SI Core.
// Nathan Brown, 2026.

const sicore = @import("sicore.zig");
const taskmgr = @import("taskmgr.zig");

const WHITE = sicore.WHITE;
const GRAY = sicore.GRAY;
const CRIMSON = sicore.CRIMSON;
const CRIMSON_LT = sicore.CRIMSON_LT;
const OBSIDIAN = sicore.OBSIDIAN;
const DARK = sicore.DARK;

// ---- built-in pages ----
const PAGE_HOME =
    "<h1>Harakiri Browser</h1>" ++
    "<p>Bare metal. No chromium. No webkit.</p>" ++
    "<p>Pages: <a>about</a> <a>agents</a> <a>gpu</a></p>" ++
    "<p>tRust watchdog: online. SI Core: online.</p>";

const PAGE_ABOUT =
    "<h1>About</h1>" ++
    "<p>Harakiri NG v0.1</p>" ++
    "<p>Zig kernel. TempleOS guts.</p>" ++
    "<p>(c) 2026 Nathan Brown</p>";

const PAGE_AGENTS =
    "<h1>Agents</h1>" ++
    "<p>vera: intent router</p>" ++
    "<p>mira: gate keeper</p>" ++
    "<p>merlin: executor</p>" ++
    "<p>gaven: sentinel</p>" ++
    "<p>brood: workers x4</p>";

const PAGE_GPU =
    "<h1>Pyre GPU</h1>" ++
    "<p>Software rasterizer.</p>" ++
    "<p>1280x720 via SI Core.</p>";

// ---- simple HTML tokenizer/parser ----
// Supports: <h1>, <p>, <a>. Everything else is text.
const Token = union(enum) {
    h1_start, h1_end,
    p_start, p_end,
    a_start, a_end,
    text: []const u8,
};

fn next_token(html: []const u8, pos: *usize) ?Token {
    if (pos.* >= html.len) return null;
    if (html[pos.*] == '<') {
        const end = index_of(html[pos.*..], '>') orelse return null;
        const tag = html[pos.* + 1 .. pos.* + end];
        pos.* += end + 1;
        if (eql(tag, "h1")) return .h1_start;
        if (eql(tag, "/h1")) return .h1_end;
        if (eql(tag, "p")) return .p_start;
        if (eql(tag, "/p")) return .p_end;
        if (eql(tag, "a")) return .a_start;
        if (eql(tag, "/a")) return .a_end;
        return next_token(html, pos); // skip unknown tags
    } else {
        const start = pos.*;
        while (pos.* < html.len and html[pos.*] != '<') : (pos.* += 1) {}
        return Token{ .text = html[start..pos.*] };
    }
}

fn index_of(s: []const u8, c: u8) ?usize {
    for (s, 0..) |ch, i| if (ch == c) return i;
    return null;
}

fn eql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |x, y| if (x != y) return false;
    return true;
}

// ---- renderer ----
pub fn render_page(name: []const u8) void {
    const html = if (eql(name, "about"))
        PAGE_ABOUT
    else if (eql(name, "agents"))
        PAGE_AGENTS
    else if (eql(name, "gpu"))
        PAGE_GPU
    else
        PAGE_HOME;

    sicore.clear(OBSIDIAN);

    // browser chrome
    sicore.rect(0, 0, sicore.FB_W, 40, DARK);
    sicore.hline(0, sicore.FB_W, 40, CRIMSON);
    taskmgr.draw_text_pub(12, 14, "harakiri://", CRIMSON_LT);
    taskmgr.draw_text_pub(110, 14, name, WHITE);

    // page content
    var y: i32 = 60;
    var pos: usize = 0;
    var in_h1 = false;
    var in_a = false;

    while (next_token(html, &pos)) |tok| {
        switch (tok) {
            .h1_start => in_h1 = true,
            .h1_end => { in_h1 = false; y += 24; },
            .p_start => {},
            .p_end => y += 20,
            .a_start => in_a = true,
            .a_end => in_a = false,
            .text => |t| {
                const color = if (in_h1) CRIMSON_LT else if (in_a) WHITE else GRAY;
                // word wrap: simple, split on spaces
                var wp: usize = 0;
                var x: i32 = 24;
                while (wp < t.len) {
                    const ws = index_of(t[wp..], ' ') orelse t.len - wp;
                    const word = t[wp .. wp + ws];
                    const ww: i32 = @intCast(word.len * 9);
                    if (x + ww > sicore.FB_W - 24) {
                        x = 24;
                        y += 20;
                    }
                    // draw word (skip leading space)
                    const wstart: usize = if (word.len > 0 and word[0] == ' ') 1 else 0;
                    if (in_h1) {
                        // h1: bigger spacing
                        taskmgr.draw_text_pub(x, y, word[wstart..], color);
                    } else {
                        taskmgr.draw_text_pub(x, y, word[wstart..], color);
                    }
                    x += ww;
                    wp += ws;
                    if (wp < t.len and t[wp] == ' ') {
                        x += 9;
                        wp += 1;
                    }
                }
                if (in_h1) y += 8;
            },
        }
        if (y > sicore.FB_H - 40) break;
    }

    // status bar
    sicore.rect(0, sicore.FB_H - 24, sicore.FB_W, sicore.FB_H, DARK);
    taskmgr.draw_text_pub(12, sicore.FB_H - 18, "local page. network: soon.", GRAY);
}
