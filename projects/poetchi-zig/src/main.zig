// PoeTchi — Zig kernel. The kernel Kraken lives in; Nathan gave it hands.
// Bare-metal ARM64. Harakiri agents. tRust watchdog. Pyre GPU. PainTr GUI.
// Nathan Brown, 2026.

const trust = @import("trust.zig");
const taskmgr = @import("taskmgr.zig");
const sicore = @import("sicore.zig");
const pyre = @import("pyre.zig");
const desktop = @import("desktop.zig");
const browser = @import("browser.zig");
const hand = @import("hand.zig");
const mesh = @import("mesh.zig");
const wells = @import("wells.zig");
const gates = @import("gates.zig");
const kraken = @import("kraken.zig");
const mreason = @import("reason.zig");
const net = @import("net.zig");
const bell = @import("bell.zig");
const bellview = @import("bellview.zig");

// ---- UART (PL011, QEMU virt) ----
const UART_BASE: usize = 0x09000000;
const UART_DR: *volatile u32 = @ptrFromInt(UART_BASE + 0x00);
const UART_FR: *volatile u32 = @ptrFromInt(UART_BASE + 0x18);

fn uart_putc(c: u8) void {
    while (UART_FR.* & (1 << 5) != 0) {} // TXFF
    UART_DR.* = c;
}

fn uart_puts(s: []const u8) void {
    for (s) |c| uart_putc(c);
}

fn uart_getc() u8 {
    while (UART_FR.* & (1 << 4) != 0) {} // RXFE
    return @truncate(UART_DR.*);
}

// ---- Agents ----
const Role = enum(u8) {
    vera = 0,
    mira = 1,
    merlin = 2,
    gaven = 3,
    brood = 4,
    hive = 5,
    paintr = 6,
    veda = 7,
};

const State = enum(u8) {
    idle = 0,
    armed = 1,
    running = 2,
    held = 3,
    done = 4,
};

const Agent = struct {
    id: u32,
    role: Role,
    state: State,
    quanta: u32,
    quanta_done: u32,
    eta_x1000: u32,
    name: [16]u8,
};

var agents: [16]Agent = undefined;
var nagents: usize = 0;

fn register_agent(name: []const u8, id: u32, role: Role) void {
    if (nagents >= agents.len) return;
    var a = &agents[nagents];
    a.id = id;
    a.role = role;
    a.state = .idle;
    a.quanta = 0;
    a.quanta_done = 0;
    a.eta_x1000 = 972;
    @memset(&a.name, 0);
    const n = @min(name.len, 15);
    @memcpy(a.name[0..n], name[0..n]);
    nagents += 1;
}

fn init_crew() void {
    nagents = 0;
    register_agent("vera", 101, .vera);
    register_agent("mira", 102, .mira);
    register_agent("merlin", 103, .merlin);
    register_agent("gaven", 104, .gaven);
    register_agent("brood-00", 201, .brood);
    register_agent("brood-01", 202, .brood);
    register_agent("brood-02", 203, .brood);
    register_agent("brood-03", 204, .brood);
    register_agent("paintr", 301, .paintr);
    register_agent("veda", 401, .veda);
}

// ---- printing ----
fn print_ulong(v: u64) void {
    var buf: [24]u8 = undefined;
    var i: usize = 0;
    if (v == 0) {
        uart_putc('0');
        return;
    }
    var n = v;
    while (n > 0 and i < 24) : (i += 1) {
        buf[i] = '0' + @as(u8, @truncate(n % 10));
        n /= 10;
    }
    while (i > 0) {
        i -= 1;
        uart_putc(buf[i]);
    }
}

fn role_name(r: Role) []const u8 {
    return switch (r) {
        .vera => "vera",
        .mira => "mira",
        .merlin => "merlin",
        .gaven => "gaven",
        .brood => "brood",
        .hive => "hive",
        .paintr => "paintr",
        .veda => "veda",
    };
}

fn state_name(s: State) []const u8 {
    return switch (s) {
        .idle => "idle",
        .armed => "armed",
        .running => "running",
        .held => "held",
        .done => "done",
    };
}

fn agent_name(a: *const Agent) []const u8 {
    var len: usize = 0;
    while (len < 16 and a.name[len] != 0) : (len += 1) {}
    return a.name[0..len];
}

// ---- commands ----
fn cmd_about() void {
    uart_puts("Harakiri NG v1.0 (Zig)\n");
    uart_puts("Bare-metal ARM64. Agents + GPU + GUI.\n");
    uart_puts("(c) 2026 Nathan Brown\n");
}

fn cmd_agents() void {
    uart_puts("agent crew:\n");
    for (agents[0..nagents]) |*a| {
        uart_puts("  ");
        uart_puts(agent_name(a));
        uart_puts(" [");
        print_ulong(a.id);
        uart_puts("] ");
        uart_puts(role_name(a.role));
        uart_puts(" / ");
        uart_puts(state_name(a.state));
        uart_puts(" (eta ");
        print_ulong(a.eta_x1000);
        uart_puts(")\n");
    }
}

fn cmd_tasks() void {
    uart_puts("tRust task manager:\n");
    for (trust.tasks[0..trust.ntasks]) |*t| {
        uart_puts("  ");
        uart_puts(trust.task_name(t));
        uart_puts(" [");
        print_ulong(t.id);
        uart_puts("] ");
        uart_puts(@tagName(t.state));
        uart_puts(" quanta ");
        print_ulong(t.quanta_used);
        uart_puts("/");
        print_ulong(t.contract.max_quanta);
        uart_puts(" eta ");
        print_ulong(t.eta_x1000);
        uart_puts("\n");
    }
}

fn cmd_tick() void {
    trust.tick();
    hand.tick();
    mesh.tick();
    wells.tick();
    gates.tick();
    kraken.tick();
    bell.tick();
    uart_puts("tick: scheduler ran one round\n");
}

fn cmd_watchdog() void {
    uart_puts("tRust watchdog denial demo:\n");

    // Spawn a task with η below Gaven's gate (500)
    const bad_contract = trust.agent_contract();
    const t = trust.spawn("intruder", 999, bad_contract, null);
    if (t) |task| {
        task.eta_x1000 = 250; // below threshold
        uart_puts("  spawned 'intruder' with eta 250 (gate: 500)\n");

        const v = trust.inspect(task, .running);
        uart_puts("  watchdog verdict: ");
        uart_puts(trust.verdict_name(v));
        uart_puts("\n");

        if (!trust.transition(task, .running)) {
            uart_puts("  transition denied — task faulted\n");
        }
        uart_puts("  intruder state: ");
        uart_puts(@tagName(task.state));
        uart_puts("\n");
    }
    uart_puts("watchdog holds.\n");
}

fn cmd_kraken(args: []const u8) void {
    var it = split(args, ' ');
    const sub = it.next();
    if (sub == null or sub.?.len == 0) {
        // status: the Outer Path reports
        uart_puts("kraken: one mind, twelve paths\n");
        uart_puts("  queued: ");
        print_ulong(kraken.total_queued());
        uart_puts("  bursts: ");
        print_ulong(kraken.bursts_fired);
        uart_puts("  sent: ");
        print_ulong(kraken.tx_sent);
        uart_puts("  held by gate: ");
        print_ulong(kraken.tx_held);
        uart_puts("\n  focus: ");
        const f = kraken.focused();
        if (f == 0) uart_puts("none") else print_ulong(f);
        uart_puts("\n  paths (path:queued):");
        var i: usize = 0;
        while (i < 12) : (i += 1) {
            uart_puts(" ");
            print_ulong(i);
            uart_puts(":");
            print_ulong(kraken.path_queued(i));
        }
        uart_puts("\n");
        return;
    }
    if (streq(sub.?, "focus")) {
        const ids = it.next() orelse {
            uart_puts("usage: kraken focus <id>\n");
            return;
        };
        const id: u32 = @intCast(parse_dec(ids));
        kraken.focus(id);
        uart_puts("kraken: all ticks pour into ");
        print_ulong(id);
        uart_puts("\n  law: ");
        if (mreason.domainIndex("ten-tails")) |di| {
            uart_puts(mreason.DOMAINS[di].laws[1].eq);
        }
        uart_puts("\n");
        return;
    }
    if (streq(sub.?, "unfocus")) {
        kraken.unfocus();
        uart_puts("kraken: focus released\n");
        return;
    }
    uart_puts("usage: kraken [focus <id> | unfocus]\n");
}

fn cmd_bell(args: []const u8) void {
    var it = split(args, ' ');
    const sub = it.next();
    if (sub == null or sub.?.len == 0) {
        // status: the pairs report
        uart_puts("bell: pairwise entanglement on the mesh\n");
        var any = false;
        for (bell.pairs, 0..) |p, pi| {
            if (!p.active) continue;
            any = true;
            uart_puts("  pair ");
            print_ulong(pi);
            uart_puts(": nodes ");
            print_ulong(p.a);
            uart_puts("-");
            print_ulong(p.b);
            if (p.broken) {
                uart_puts("  X-FORM BROKEN (guard fired, no fake number)\n");
            } else {
                uart_puts("  C ");
                print_ulong(@as(u32, @intFromFloat(p.c * 1000.0)));
                if (p.c < 0.5) uart_puts("  (below eta-gate: classical)");
                uart_puts("\n");
            }
        }
        if (!any) uart_puts("  no pairs - bell <a> <b> to entangle two nodes\n");
        uart_puts("  gamma milli/tick: ");
        print_ulong(bell.gamma_milli);
        uart_puts(" (provisional - Nathan's call)\n");
        if (bell.s_valid) {
            uart_puts("  CHSH S: ");
            const sm: i32 = bell.last_s_milli;
            if (sm < 0) {
                uart_puts("-");
                print_ulong(@as(u32, @intCast(-sm)));
            } else {
                print_ulong(@as(u32, @intCast(sm)));
            }
            uart_puts(if (sm < -2000 or sm > 2000) "  QUANTUM\n" else "  CLASSICAL\n");
        }
        return;
    }
    if (streq(sub.?, "refresh")) {
        const ids = it.next() orelse {
            uart_puts("usage: bell refresh <pair>\n");
            return;
        };
        bell.refresh(@intCast(parse_dec(ids)));
        uart_puts("bell: pair re-entangled to phi+\n");
        return;
    }
    if (streq(sub.?, "decay")) {
        const gs = it.next() orelse {
            uart_puts("usage: bell decay <gamma_milli_per_tick>\n");
            return;
        };
        bell.gamma_milli = @intCast(parse_dec(gs));
        uart_puts("bell: gamma set (provisional)\n");
        return;
    }
    if (streq(sub.?, "chsh")) {
        const s = bell.chsh();
        const sm: i32 = @as(i32, @intFromFloat(s * 1000.0));
        bell.last_s_milli = sm;
        bell.s_valid = true;
        uart_puts("bell: CHSH S = ");
        if (sm < 0) {
            uart_puts("-");
            print_ulong(@as(u32, @intCast(-sm)));
        } else {
            print_ulong(@as(u32, @intCast(sm)));
        }
        uart_puts(if (sm < -2000 or sm > 2000) "  QUANTUM\n" else "  CLASSICAL\n");
        return;
    }
    if (streq(sub.?, "beam")) {
        // verification shot: mesh + the burning beam, dumped as PPM
        sicore.clear(sicore.OBSIDIAN);
        mesh.render(936, 295, 125);
        bellview.render_vp(936, 295, 125);
        dump_ppm();
        return;
    }
    // bell <a> <b>: entangle two mesh nodes
    const a: usize = @intCast(parse_dec(sub.?));
    const bnode = it.next() orelse {
        uart_puts("usage: bell <a> <b> | refresh <pair> | decay <gamma> | chsh | beam\n");
        return;
    };
    const b: usize = @intCast(parse_dec(bnode));
    if (bell.makePair(a, b)) {
        uart_puts("bell: nodes ");
        print_ulong(a);
        uart_puts(" and ");
        print_ulong(b);
        uart_puts(" entangled - C 1000\n");
    } else {
        uart_puts("bell: refused (full table, same node, or node out of range)\n");
    }
}

fn dump_ppm() void {
    uart_puts("P6\n");
    print_ulong(sicore.FB_W);
    uart_putc(' ');
    print_ulong(sicore.FB_H);
    uart_puts("\n255\n");
    const ptr = sicore.fb_ptr();
    const len = sicore.fb_len();
    var i: usize = 0;
    while (i < len) : (i += 1) {
        uart_putc(ptr[i]);
    }
}

fn cmd_taskmgr() void {
    // Sample current state, render through SI Core, dump PPM
    taskmgr.sample();
    taskmgr.render();
    dump_ppm();
}

fn cmd_gpu(args: []const u8) void {
    var it = split(args, ' ');
    const sub = it.next() orelse {
        uart_puts("gpu: cube [angle]\n");
        return;
    };
    if (streq(sub, "cube")) {
        const angle_s = it.next();
        const angle: u32 = if (angle_s) |s| parse_dec(s) else 45;
        const tris = pyre.render_cube(angle);
        uart_puts("gpu: rendered ");
        print_ulong(tris);
        uart_puts(" tris\n");
        // dump framebuffer as PPM
        dump_ppm();
    } else if (streq(sub, "neural")) {
        const angle_s = it.next();
        const angle: u32 = if (angle_s) |s| parse_dec(s) else 45;
        const tris = pyre.render_cube_neural(angle);
        uart_puts("gpu: neural rendered ");
        print_ulong(tris);
        uart_puts(" tris\n");
        // dump framebuffer as PPM
        dump_ppm();
    } else if (streq(sub, "sphere")) {
        const angle_s = it.next();
        const angle: u32 = if (angle_s) |s| parse_dec(s) else 45;
        const tris = pyre.render_sphere_neural(angle);
        uart_puts("gpu: neural sphere rendered ");
        print_ulong(tris);
        uart_puts(" tris\n");
        // dump framebuffer as PPM
        dump_ppm();
    } else {
        uart_puts("gpu: cube [angle] | neural [angle] | sphere [angle]\n");
    }
}

fn cmd_sicore() void {
    uart_puts(sicore.about());
    uart_puts("\n  role: ");
    uart_puts(sicore.SI_ROLE);
    uart_puts("\n");
}

fn cmd_desktop() void {
    desktop.render();
    dump_ppm();
}

fn cmd_browser(args: []const u8) void {
    var page: []const u8 = "home";
    if (args.len > 0) page = args;
    browser.render_page(page);
    dump_ppm();
}

fn cmd_hand(args: []const u8) void {
    if (args.len == 0) {
        uart_puts("hand: ");
        uart_puts(hand.status());
        uart_puts("\n  worker task: ");
        uart_puts(hand.worker_task());
        uart_puts("\n  pointer: ");
        uart_puts(hand.pointer_state());
        if (hand.coding_active()) {
            uart_puts("\n  typing: ");
            print_ulong(hand.code_progress());
            uart_puts("% (");
            uart_puts(hand.code_domain_name());
            uart_puts(")");
        }
        uart_puts("\n");
        return;
    }
    if (streq(args, "out")) {
        uart_puts("--- hand code begin ---\n");
        uart_puts(hand.code_text());
        uart_puts("--- hand code end ---\n");
        return;
    }
    if (args.len > 5 and streq(args[0..5], "code ")) {
        if (hand.code(args[5..])) {
            trust.boost(601, 8); // the hand jumps the queue to type
            uart_puts("hand: reasoning the brief - typing ");
            uart_puts(hand.code_domain_name());
            uart_puts(" Zig\n");
        } else {
            uart_puts("hand: no resonance - nothing to type. refusal is absence.\n");
        }
        return;
    }
    hand.assign(args);
    trust.boost(601, 8); // user touched the hand — it jumps the queue
    uart_puts("hand: worker assigned '");
    uart_puts(args);
    uart_puts("'\n");
}

fn cmd_point(args: []const u8) void {
    var it = split(args, ' ');
    const xs = it.next() orelse {
        uart_puts("usage: point <x> <y>\n");
        return;
    };
    const ys = it.next() orelse {
        uart_puts("usage: point <x> <y>\n");
        return;
    };
    const x = parse_dec(xs);
    const y = parse_dec(ys);
    hand.point(@intCast(x), @intCast(y));
    trust.boost(601, 8); // pointer moved — the hand task jumps the queue
    uart_puts("pointer: moving to (");
    uart_puts(xs);
    uart_puts(", ");
    uart_puts(ys);
    uart_puts(")\n");
}

fn cmd_grab(_: []const u8) void {
    hand.grab();
    trust.boost(601, 8);
    uart_puts("pointer: grabbing\n");
}

fn cmd_release(_: []const u8) void {
    hand.release();
    trust.boost(601, 8);
    uart_puts("pointer: released\n");
}

// ---- REASON: the crew's decision layer ----
// Vera routes, Mira's gate speaks, Gaven's floor holds underneath.

fn cmd_reason(args: []const u8) void {
    if (args.len == 0) {
        uart_puts("usage: reason <brief>\n");
        return;
    }
    var p = mreason.Problem{};
    mreason.setName(&p, "brief");
    mreason.sketch(args, &p);
    const d = mreason.reason(&p);
    uart_puts("reason:\n");
    if (mreason.abstains(d)) {
        uart_puts("  domain: none (no resonance)\n");
        uart_puts("  decision: ABSTAIN - refusal is absence\n");
        return;
    }
    const dom = &mreason.DOMAINS[d.domain];
    uart_puts("  domain: ");
    uart_puts(dom.name);
    uart_puts(" (");
    print_ulong(d.score_x1000);
    uart_puts(")\n");
    var bnd: [4]mreason.Binding = undefined;
    const nb = mreason.bind(&p, dom, &bnd);
    uart_puts("  bind:");
    var i: u8 = 0;
    while (i < nb) : (i += 1) {
        uart_puts(" ");
        uart_puts(dom.roles[bnd[i].role]);
        uart_puts("=");
        uart_puts(mreason.entityName(&p, bnd[i].ent));
    }
    uart_puts("\n  laws:\n");
    for (dom.laws) |*l| {
        uart_puts("    ");
        uart_puts(l.name);
        uart_puts(" :: ");
        uart_puts(l.eq);
        uart_puts("\n");
    }
    var sbuf: [256]u8 = undefined;
    const sl = mreason.speak(d.domain, &p, bnd[0..nb], &sbuf);
    uart_puts("  speak: ");
    uart_puts(sbuf[0..sl]);
    uart_puts("\n");
    if (d.runner_up != mreason.NONE and d.runner_score > 0) {
        uart_puts("  paradox: also reads as ");
        uart_puts(mreason.domainName(d.runner_up));
        uart_puts(" (");
        print_ulong(d.runner_score);
        uart_puts(")\n");
    }
    uart_puts("  decision: proceed as ");
    uart_puts(dom.name);
    uart_puts(" (first law: ");
    uart_puts(mreason.firstLaw(d.domain));
    uart_puts(")\n");
}

const AGENT_NAMES = [_][]const u8{
    "vera", "mira", "merlin", "gaven",
    "brood-00", "brood-01", "brood-02", "brood-03",
    "paintr", "veda", "si-core-gfx", "hand", "kraken",
};

fn cmd_route(args: []const u8) void {
    if (args.len == 0) {
        uart_puts("usage: route <intent>\n");
        return;
    }
    var p = mreason.Problem{};
    mreason.setName(&p, "intent");
    mreason.sketch(args, &p);
    const d = mreason.reason(&p);
    uart_puts("vera: ");
    if (mreason.abstains(d)) {
        uart_puts("no resonance - holding. refusal is absence.\n");
        return;
    }
    // an agent named in the brief wins; otherwise the domain's affinity
    var target: []const u8 = mreason.affinity(d.domain);
    var how: []const u8 = "affinity";
    var ei: u8 = 0;
    while (ei < p.nent) : (ei += 1) {
        const en = mreason.entityName(&p, ei);
        for (AGENT_NAMES) |an| {
            if (streq(en, an)) {
                target = an;
                how = "named";
                break;
            }
        }
        if (streq(how, "named")) break;
    }
    uart_puts("routed to ");
    uart_puts(target);
    uart_puts(" via ");
    uart_puts(mreason.domainName(d.domain));
    uart_puts(" (");
    uart_puts(how);
    uart_puts(", ");
    print_ulong(d.score_x1000);
    uart_puts(")\n");
}

fn cmd_gate(args: []const u8) void {
    var it = split(args, ' ');
    const ts = it.next() orelse {
        uart_puts("usage: gate <trust> <eta>  (0-1000)\n");
        return;
    };
    const es = it.next() orelse {
        uart_puts("usage: gate <trust> <eta>  (0-1000)\n");
        return;
    };
    const trust_v = parse_dec(ts);
    const eta_v = parse_dec(es);
    // the canonical admission problem: a supplicant at the rope
    var p = mreason.Problem{};
    mreason.setName(&p, "admission");
    const supplicant = mreason.addEntity(&p, "supplicant").?;
    const rope = mreason.addEntity(&p, "rope").?;
    _ = mreason.addRelation(&p, supplicant, 0, rope); // queues_for
    _ = mreason.addRelation(&p, supplicant, 1, rope); // judged_by
    _ = mreason.addRelation(&p, supplicant, 2, rope); // held_by
    _ = mreason.addRelation(&p, supplicant, 3, rope); // passes
    const d = mreason.reason(&p);
    uart_puts("mira: the gate reasons - ");
    uart_puts(mreason.domainName(d.domain));
    uart_puts(" (");
    print_ulong(d.score_x1000);
    uart_puts(")\n");
    var ctx = mreason.LawCtx{};
    ctx.args[0] = @as(f32, @floatFromInt(trust_v)) / 1000.0;
    ctx.args[1] = @as(f32, @floatFromInt(eta_v)) / 1000.0;
    ctx.nargs = 2;
    if (!mreason.runLaw(d.domain, "admission", &ctx)) {
        uart_puts("  no admission law in this domain - the gate holds\n");
        return;
    }
    uart_puts("  law: admit(x) = trust(x) >= eta ? enter : absent\n");
    gates.verdict_changed(); // Mira's gate flashes - the gate speaks
    if (ctx.flag) {
        uart_puts("  verdict: ENTER (trust ");
        print_ulong(trust_v);
        uart_puts(" >= eta ");
        print_ulong(eta_v);
        uart_puts(")\n");
    } else {
        uart_puts("  verdict: ABSENT - the gate holds (trust ");
        print_ulong(trust_v);
        uart_puts(" < eta ");
        print_ulong(eta_v);
        uart_puts(")\n");
    }
}

// ---- Phase 10: virtio-net ----
fn cmd_net(args: []const u8) void {
    var it = split(args, ' ');
    const sub = it.next() orelse {
        uart_puts("usage: net probe | net tx\n");
        return;
    };
    if (streq(sub, "scan")) {
        uart_puts("net: mmio scan (nonzero slots):\n");
        var slot: usize = 0;
        while (slot < 32) : (slot += 1) {
            const base: usize = 0x0a000000 + slot * 0x200;
            const magic: *volatile u32 = @ptrFromInt(base);
            if (magic.* != 0) {
                const ver: *volatile u32 = @ptrFromInt(base + 4);
                const id: *volatile u32 = @ptrFromInt(base + 8);
                uart_puts("  slot ");
                print_ulong(slot);
                uart_puts(": magic 0x");
                print_hex(magic.*);
                uart_puts(" ver ");
                print_ulong(ver.*);
                uart_puts(" id ");
                print_ulong(id.*);
                uart_puts("\n");
            }
        }
        return;
    }
    if (streq(sub, "probe")) {
        uart_puts("net: probing virtio-mmio bus...\n");
        if (net.probe()) {
            const m = net.mac_addr();
            uart_puts("  virtio-net up. MAC ");
            var i: usize = 0;
            while (i < 6) : (i += 1) {
                if (i > 0) uart_putc(':');
                print_hex_byte(m[i]);
            }
            uart_puts("\n  rx/tx queues ready, RX buffers posted\n");
        } else {
            uart_puts("  no virtio-net device found\n");
        }
        return;
    }
    if (streq(sub, "tx")) {
        if (!net.link_up) {
            uart_puts("net: link down - run 'net probe' first\n");
            return;
        }
        var frame: [64]u8 = undefined;
        const flen = net.build_arp_request(&frame);
        uart_puts("net: sending broadcast ARP (");
        print_ulong(flen);
        uart_puts(" bytes)...\n");
        if (net.tx_frame(frame[0..flen])) {
            uart_puts("  TX complete - used ring advanced\n");
        } else {
            uart_puts("  TX timed out - no completion\n");
        }
        const rx = net.rx_ready();
        if (rx > 0) {
            uart_puts("  RX: ");
            print_ulong(rx);
            uart_puts(" frame(s) arrived\n");
        } else {
            uart_puts("  RX: nothing arrived (no one answered the ARP)\n");
        }
        return;
    }
    uart_puts("usage: net probe | net tx\n");
}

fn print_hex_byte(v: u8) void {
    const hi: u8 = v >> 4;
    const lo: u8 = v & 0xF;
    uart_putc(if (hi < 10) '0' + hi else 'a' + hi - 10);
    uart_putc(if (lo < 10) '0' + lo else 'a' + lo - 10);
}

// merlin: the executor. spider-mouse — the Gordon loop made visible:
// analyze (bindings) → propose (speak) → approve (Nathan's gate) → execute (first law).
// ---- Phase 9b: the rest of the crew decides through the engine ----
fn cmd_merlin(args: []const u8) void {
    if (args.len == 0) {
        uart_puts("usage: merlin <brief>\n");
        return;
    }
    var p = mreason.Problem{};
    mreason.setName(&p, "task");
    mreason.sketch(args, &p);
    const d = mreason.reason(&p);
    uart_puts("merlin:\n");
    if (mreason.abstains(d)) {
        uart_puts("  analyze: no resonance - nothing to plan. refusal is absence.\n");
        return;
    }
    const dom = &mreason.DOMAINS[d.domain];
    uart_puts("  reasoned as ");
    uart_puts(dom.name);
    uart_puts(" (");
    print_ulong(d.score_x1000);
    uart_puts(")\n");
    var bnd: [4]mreason.Binding = undefined;
    const nb = mreason.bind(&p, dom, &bnd);
    uart_puts("  analyze:");
    var i: u8 = 0;
    while (i < nb) : (i += 1) {
        uart_puts(" ");
        uart_puts(dom.roles[bnd[i].role]);
        uart_puts("=");
        uart_puts(mreason.entityName(&p, bnd[i].ent));
    }
    uart_puts("\n  propose: ");
    var sbuf: [256]u8 = undefined;
    const sl = mreason.speak(d.domain, &p, bnd[0..nb], &sbuf);
    uart_puts(sbuf[0..sl]);
    uart_puts("\n  approve: the gate is yours - say the word\n");
    uart_puts("  execute: ");
    uart_puts(mreason.firstLaw(d.domain));
    uart_puts(" :: ");
    uart_puts(dom.laws[0].eq);
    uart_puts("\n");
}

// paintr: the judge. deliberate-and-judge as a verdict —
// the winning domain's vocabulary, chosen by the engine, never a script.
const PAINTR_VERDICTS = [_][]const u8{
    "REFUSE - absence. Not everyone gets in.", // bouncer
    "SETTLE - let it find its layer.", // ocean
    "CONSOLIDATE - pour it into one path.", // ten-tails
    "WAIT - coherence is earned, not commanded.", // kuramoto
    "REFINE - through fire, then quench.", // forge
    "STRIKE - plan slow, strike fast.", // spider-mouse
};

fn cmd_paintr(args: []const u8) void {
    var it = split(args, ' ');
    const sub = it.next() orelse {
        uart_puts("usage: paintr judge <brief>\n");
        return;
    };
    if (!streq(sub, "judge")) {
        uart_puts("usage: paintr judge <brief>\n");
        return;
    }
    var rest: []const u8 = args[sub.len..];
    while (rest.len > 0 and rest[0] == ' ') rest = rest[1..];
    if (rest.len == 0) {
        uart_puts("usage: paintr judge <brief>\n");
        return;
    }
    var p = mreason.Problem{};
    mreason.setName(&p, "work");
    mreason.sketch(rest, &p);
    const d = mreason.reason(&p);
    uart_puts("paintr:\n");
    if (mreason.abstains(d)) {
        uart_puts("  verdict: HOLD - no resonance, nothing to judge.\n");
        return;
    }
    uart_puts("  reasoned as ");
    uart_puts(mreason.domainName(d.domain));
    uart_puts(" (");
    print_ulong(d.score_x1000);
    uart_puts(")\n  verdict: ");
    uart_puts(PAINTR_VERDICTS[d.domain]);
    uart_puts("\n");
}

// veda: the auditor. Every rule is a guard — she checks the decision itself:
// did it resonate, is every bound role filled, does the first law run.
fn cmd_veda(args: []const u8) void {
    var it = split(args, ' ');
    const sub = it.next() orelse {
        uart_puts("usage: veda audit <brief>\n");
        return;
    };
    if (!streq(sub, "audit")) {
        uart_puts("usage: veda audit <brief>\n");
        return;
    }
    var rest: []const u8 = args[sub.len..];
    while (rest.len > 0 and rest[0] == ' ') rest = rest[1..];
    if (rest.len == 0) {
        uart_puts("usage: veda audit <brief>\n");
        return;
    }
    var p = mreason.Problem{};
    mreason.setName(&p, "claim");
    mreason.sketch(rest, &p);
    const d = mreason.reason(&p);
    uart_puts("veda: audit\n");
    var passed: u32 = 0;
    var failed: u32 = 0;
    // guard 1: resonance — a decision with no domain is a hallucination
    if (!mreason.abstains(d)) {
        uart_puts("  [PASS] resonance: ");
        uart_puts(mreason.domainName(d.domain));
        uart_puts(" (");
        print_ulong(d.score_x1000);
        uart_puts(")\n");
        passed += 1;
    } else {
        uart_puts("  [FAIL] resonance: none - the claim stands unmapped\n");
        failed += 1;
    }
    if (!mreason.abstains(d)) {
        const dom = &mreason.DOMAINS[d.domain];
        // guard 2: binding coverage — no empty roles
        var bnd: [4]mreason.Binding = undefined;
        const nb = mreason.bind(&p, dom, &bnd);
        var covered = true;
        var i: u8 = 0;
        while (i < nb) : (i += 1) {
            if (mreason.entityName(&p, bnd[i].ent).len == 0) covered = false;
        }
        if (covered and nb > 0) {
            uart_puts("  [PASS] binding: every role filled (");
            print_ulong(nb);
            uart_puts(")\n");
            passed += 1;
        } else {
            uart_puts("  [FAIL] binding: empty roles\n");
            failed += 1;
        }
        // guard 3: the first law runs — a law that cannot run is decoration
        var ctx = mreason.LawCtx{};
        if (mreason.runLaw(d.domain, mreason.firstLaw(d.domain), &ctx)) {
            uart_puts("  [PASS] law: ");
            uart_puts(mreason.firstLaw(d.domain));
            uart_puts(" runs :: ");
            uart_puts(dom.laws[0].eq);
            uart_puts("\n");
            passed += 1;
        } else {
            uart_puts("  [FAIL] law: first law does not run\n");
            failed += 1;
        }
    }
    uart_puts("  audit: ");
    print_ulong(passed);
    uart_puts(" pass, ");
    print_ulong(failed);
    uart_puts(" fail");
    if (failed == 0) uart_puts(" - nothing passes on vibes\n") else uart_puts("\n");
}

fn cmd_peek(args: []const u8) void {
    const addr = parse_hex(args);
    if (addr == null) {
        uart_puts("usage: peek <hex addr>\n");
        return;
    }
    const ptr: *volatile u32 = @ptrFromInt(addr.?);
    uart_puts("0x");
    print_hex(addr.?);
    uart_puts(": 0x");
    print_hex(ptr.*);
    uart_puts("\n");
}

fn cmd_poke(args: []const u8) void {
    // split into addr and val
    var it = split(args, ' ');
    const addr_s = it.next() orelse {
        uart_puts("usage: poke <hex addr> <hex val>\n");
        return;
    };
    const val_s = it.next() orelse {
        uart_puts("usage: poke <hex addr> <hex val>\n");
        return;
    };
    const addr = parse_hex(addr_s) orelse {
        uart_puts("bad address\n");
        return;
    };
    const val = parse_hex(val_s) orelse {
        uart_puts("bad value\n");
        return;
    };
    const ptr: *volatile u32 = @ptrFromInt(addr);
    ptr.* = @truncate(val);
    uart_puts("poked 0x");
    print_hex(addr);
    uart_puts(" = 0x");
    print_hex(val);
    uart_puts("\n");
}

fn cmd_run(args: []const u8) void {
    const t = find_task(args) orelse {
        uart_puts("no such task\n");
        return;
    };
    if (trust.transition(t, .ready)) {
        uart_puts("task ");
        uart_puts(trust.task_name(t));
        uart_puts(" -> ready\n");
    } else {
        uart_puts("watchdog denied\n");
    }
}

fn cmd_kill(args: []const u8) void {
    const t = find_task(args) orelse {
        uart_puts("no such task\n");
        return;
    };
    t.state = .done;
    uart_puts("task ");
    uart_puts(trust.task_name(t));
    uart_puts(" killed\n");
}

fn cmd_eta(args: []const u8) void {
    var it = split(args, ' ');
    const name = it.next() orelse {
        uart_puts("usage: eta <task> <val>\n");
        return;
    };
    const val_s = it.next() orelse {
        uart_puts("usage: eta <task> <val>\n");
        return;
    };
    const t = find_task(name) orelse {
        uart_puts("no such task\n");
        return;
    };
    t.eta_x1000 = parse_dec(val_s);
    uart_puts("task ");
    uart_puts(trust.task_name(t));
    uart_puts(" eta = ");
    print_ulong(t.eta_x1000);
    uart_puts("\n");
}

fn find_task(name: []const u8) ?*trust.Task {
    for (trust.tasks[0..trust.ntasks]) |*t| {
        if (streq(trust.task_name(t), name)) return t;
    }
    return null;
}

fn parse_hex(s: []const u8) ?u64 {
    var v: u64 = 0;
    var str = s;
    if (str.len >= 2 and str[0] == '0' and (str[1] == 'x' or str[1] == 'X')) {
        str = str[2..];
    }
    if (str.len == 0) return null;
    for (str) |c| {
        v <<= 4;
        if (c >= '0' and c <= '9') {
            v |= c - '0';
        } else if (c >= 'a' and c <= 'f') {
            v |= c - 'a' + 10;
        } else if (c >= 'A' and c <= 'F') {
            v |= c - 'A' + 10;
        } else return null;
    }
    return v;
}

fn parse_dec(s: []const u8) u32 {
    var v: u32 = 0;
    for (s) |c| {
        if (c >= '0' and c <= '9') v = v * 10 + (c - '0');
    }
    return v;
}

fn print_hex(v: u64) void {
    var shift: u6 = 60;
    var started = false;
    while (true) {
        const nibble: u8 = @truncate((v >> shift) & 0xF);
        if (nibble != 0 or started or shift == 0) {
            started = true;
            uart_putc(if (nibble < 10) '0' + nibble else 'a' + nibble - 10);
        }
        if (shift == 0) break;
        shift -= 4;
    }
}

// Simple string splitter
fn split(s: []const u8, delim: u8) Splitter {
    return Splitter{ .s = s, .delim = delim, .pos = 0 };
}

const Splitter = struct {
    s: []const u8,
    delim: u8,
    pos: usize,

    fn next(self: *Splitter) ?[]const u8 {
        while (self.pos < self.s.len and self.s[self.pos] == self.delim) : (self.pos += 1) {}
        if (self.pos >= self.s.len) return null;
        const start = self.pos;
        while (self.pos < self.s.len and self.s[self.pos] != self.delim) : (self.pos += 1) {}
        return self.s[start..self.pos];
    }
};
fn cmd_help() void {
    uart_puts("commands:\n");
    uart_puts("  about    - about this kernel\n");
    uart_puts("  agents   - list the agent crew\n");
    uart_puts("  tasks    - tRust task manager status\n");
    uart_puts("  tick     - run one scheduler round\n");
    uart_puts("  watchdog - demo the eta-gate denial\n");
    uart_puts("  taskmgr  - render visual task manager (PPM)\n");
    uart_puts("  sicore   - about the graphics engine\n");
    uart_puts("  peek     - peek <hex addr>\n");
    uart_puts("  poke     - poke <hex addr> <hex val>\n");
    uart_puts("  run      - run <task>\n");
    uart_puts("  kill     - kill <task>\n");
    uart_puts("  eta      - eta <task> <val>\n");
    uart_puts("  gpu      - gpu cube [angle] | gpu neural [angle] | gpu sphere [angle] (renders, PPM dump)\n");
    uart_puts("  desktop  - render the PainTr desktop (PPM)\n");
    uart_puts("  browser  - browser <page> (renders, PPM dump)\n");
    uart_puts("  hand     - hand <task> | hand code <brief> | hand out (the hand types Zig)\n");
    uart_puts("  point    - point <x> <y> (move the pointer hand)\n");
    uart_puts("  grab     - pointer hand grabs\n");
    uart_puts("  release  - pointer hand releases\n");
    uart_puts("  reason   - reason <brief> (the crew's decision layer)\n");
    uart_puts("  route    - route <intent> (vera routes through the engine)\n");
    uart_puts("  gate     - gate <trust> <eta> (mira's gate verdict)\n");
    uart_puts("  merlin   - merlin <brief> (gordon loop through the engine)\n");
    uart_puts("  paintr   - paintr judge <brief> (the judge's verdict)\n");
    uart_puts("  veda     - veda audit <brief> (audit the decision)\n");
    uart_puts("  net      - net probe | net tx (virtio-net)\n");
    uart_puts("  help     - this help\n");
    uart_puts("  clear    - clear screen\n");
    uart_puts("  clear    - clear screen\n");
}

fn streq(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |x, y| if (x != y) return false;
    return true;
}

fn dispatch(line: []const u8) void {
    // trim leading spaces
    var l = line;
    while (l.len > 0 and l[0] == ' ') l = l[1..];
    if (l.len == 0) return;

    // split command from args
    var cmd_end: usize = 0;
    while (cmd_end < l.len and l[cmd_end] != ' ') : (cmd_end += 1) {}
    const cmd = l[0..cmd_end];
    var args = l[cmd_end..];
    while (args.len > 0 and args[0] == ' ') args = args[1..];

    if (streq(cmd, "about")) cmd_about()
    else if (streq(cmd, "agents")) cmd_agents()
    else if (streq(cmd, "tasks")) cmd_tasks()
    else if (streq(cmd, "tick")) cmd_tick()
    else if (streq(cmd, "watchdog")) cmd_watchdog()
    else if (streq(cmd, "kraken")) cmd_kraken(args)
    else if (streq(cmd, "bell")) cmd_bell(args)
    else if (streq(cmd, "taskmgr")) cmd_taskmgr()
    else if (streq(cmd, "sicore")) cmd_sicore()
    else if (streq(cmd, "gpu")) cmd_gpu(args)
    else if (streq(cmd, "desktop")) cmd_desktop()
    else if (streq(cmd, "browser")) cmd_browser(args)
    else if (streq(cmd, "hand")) cmd_hand(args)
    else if (streq(cmd, "point")) cmd_point(args)
    else if (streq(cmd, "grab")) cmd_grab(args)
    else if (streq(cmd, "release")) cmd_release(args)
    else if (streq(cmd, "reason")) cmd_reason(args)
    else if (streq(cmd, "route")) cmd_route(args)
    else if (streq(cmd, "gate")) cmd_gate(args)
    else if (streq(cmd, "merlin")) cmd_merlin(args)
    else if (streq(cmd, "paintr")) cmd_paintr(args)
    else if (streq(cmd, "veda")) cmd_veda(args)
    else if (streq(cmd, "net")) cmd_net(args)
    else if (streq(cmd, "peek")) cmd_peek(args)
    else if (streq(cmd, "poke")) cmd_poke(args)
    else if (streq(cmd, "run")) cmd_run(args)
    else if (streq(cmd, "kill")) cmd_kill(args)
    else if (streq(cmd, "eta")) cmd_eta(args)
    else if (streq(cmd, "help")) cmd_help()
    else if (streq(cmd, "clear")) uart_puts("\x1b[2J\x1b[H")
    else {
        uart_puts("unknown: ");
        uart_puts(l);
        uart_puts("\n");
    }
}

// ---- kernel main ----
export fn kernel_main() noreturn {
    init_crew();

    // Spawn agents as tRust-managed tasks
    _ = trust.spawn("vera", 101, trust.agent_contract(), null);
    _ = trust.spawn("mira", 102, trust.agent_contract(), null);
    _ = trust.spawn("merlin", 103, trust.agent_contract(), null);
    _ = trust.spawn("gaven", 104, trust.agent_contract(), null);
    _ = trust.spawn("brood-00", 201, trust.agent_contract(), null);
    _ = trust.spawn("brood-01", 202, trust.agent_contract(), null);
    _ = trust.spawn("brood-02", 203, trust.agent_contract(), null);
    _ = trust.spawn("brood-03", 204, trust.agent_contract(), null);
    _ = trust.spawn("paintr", 301, trust.gpu_contract(), null);
    _ = trust.spawn("veda", 401, trust.agent_contract(), null);
    _ = trust.spawn("si-core-gfx", 501, trust.gpu_contract(), null);
    _ = trust.spawn("hand", 601, trust.agent_contract(), null);
    _ = trust.spawn("kraken", 701, trust.agent_contract(), null);
    kraken.init();
    hand.init();
    bell.init();

    uart_puts("\n");
    uart_puts("  PoeTchi v1.0 (Zig)\n");
    uart_puts("  Bare metal. tRust watchdog online. Kraken holds the paths.\n");
    uart_puts("  (c) 2026 Nathan Brown\n");
    uart_puts("\n");
    uart_puts("poetchi> ");

    var line: [128]u8 = undefined;
    var len: usize = 0;

    while (true) {
        const c = uart_getc();
        if (c == '\r' or c == '\n') {
            uart_puts("\n");
            dispatch(line[0..len]);
            len = 0;
            uart_puts("poetchi> ");
        } else if (c == 0x7f or c == 0x08) {
            if (len > 0) {
                len -= 1;
                uart_puts("\x08 \x08");
            }
        } else if (c >= 0x20 and c < 0x7f) {
            if (len < line.len) {
                line[len] = c;
                len += 1;
                uart_putc(c);
            }
        }
    }
}

// ---- boot entry ----
// Sets up stack, enables FPU, clears BSS, jumps to kernel_main.
export fn _start() linksection(".text.boot") callconv(.Naked) noreturn {
    asm volatile (
        \\// FPU enable (CPACR_EL1)
        \\mrs x0, CurrentEL
        \\lsr x0, x0, #2
        \\cmp x0, #1
        \\b.ne 1f
        \\// EL1: enable FP/SIMD via CPACR_EL1
        \\mov x0, #(3 << 20)
        \\msr CPACR_EL1, x0
        \\1:
        \\// stack
        \\ldr x0, =_stack_top
        \\mov sp, x0
        \\// clear BSS
        \\ldr x0, =_bss_start
        \\ldr x1, =_bss_end
        \\2:
        \\cmp x0, x1
        \\b.hs 3f
        \\str xzr, [x0], #8
        \\b 2b
        \\3:
        \\bl kernel_main
        \\// hang
        \\4: wfe
        \\b 4b
    );
}
