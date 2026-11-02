// Host-side parity check: the Zig REASON port must agree with the JS engine.
// Mirrors ~/workspace/metaphorical-reasoning/test.js + the entrains fix probe.
// A test that cannot fail is a painting.
const reason = @import("reason.zig");
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

fn eq(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

// the scheduler problem, hand-built exactly like the JS test
fn schedulerProblem(p: *reason.Problem) void {
    reason.setName(p, "scheduler");
    const tasks = reason.addEntity(p, "tasks").?;
    const cpu = reason.addEntity(p, "cpu").?;
    _ = reason.addRelation(p, tasks, 0, cpu); // queues_for
    _ = reason.addRelation(p, tasks, 1, cpu); // judged_by
    _ = reason.addRelation(p, tasks, 2, cpu); // held_by
    _ = reason.addRelation(p, tasks, 3, cpu); // passes
}

pub fn main() !void {
    // 1. resonance picks the structurally right domain
    var sp = reason.Problem{};
    schedulerProblem(&sp);
    const d = reason.reason(&sp);
    t("bouncer wins for admission-shaped problem", d.domain == 0);
    t("bouncer score is 800 on 4-of-5 relation overlap", d.score_x1000 == 800);

    // 2. laws execute and mean what they say
    var ctx = reason.LawCtx{};
    ctx.args[0] = 0.9;
    ctx.args[1] = 0.5;
    ctx.nargs = 2;
    t("admission law found", reason.runLaw(0, "admission", &ctx));
    t("admission law admits above eta", ctx.flag == true);
    ctx.args[0] = 0.1;
    _ = reason.runLaw(0, "admission", &ctx);
    t("admission law refuses below eta - refusal is absence", ctx.flag == false);

    var oc = reason.LawCtx{};
    oc.args[0] = 0.1;
    oc.args[1] = 0.1;
    oc.args[2] = 0.1;
    oc.nargs = 3;
    t("kuramoto order law found", reason.runLaw(3, "order", &oc));
    t("kuramoto order of locked phases > 0.99", oc.result > 0.99);
    oc.args[0] = 0;
    oc.args[1] = 2.1;
    oc.args[2] = 4.2;
    _ = reason.runLaw(3, "order", &oc);
    t("kuramoto order of scattered phases < 0.5", oc.result < 0.5);

    // 3. binding maps entities onto roles - never invents entities
    var bnd: [4]reason.Binding = undefined;
    const nb = reason.bind(&sp, &reason.DOMAINS[0], &bnd);
    t("binding covers every entity it was given", nb == 2);
    t("binding crowd=tasks", bnd[0].role == 0 and eq(reason.entityName(&sp, bnd[0].ent), "tasks"));
    t("binding rope=cpu", bnd[1].role == 1 and eq(reason.entityName(&sp, bnd[1].ent), "cpu"));

    // 4. abstention is honest
    var empty = reason.Problem{};
    reason.setName(&empty, "void");
    const de = reason.reason(&empty);
    t("no resonance -> abstains, never hallucinates", reason.abstains(de));

    // 5. every law carries its equation
    var all_eq = true;
    for (&reason.DOMAINS) |*dom| {
        for (dom.laws) |*l| {
            if (l.eq.len == 0) all_eq = false;
        }
    }
    t("all laws have equations", all_eq);

    // 6. NCAG gate: a resonant run ships a decision with its first law
    t("resonant run first law is admission", eq(reason.firstLaw(d.domain), "admission"));

    // 7. sketch parity with the JS engine
    var sk = reason.Problem{};
    reason.setName(&sk, "brief");
    reason.sketch("the tasks queues for the cpu and are judged by the list", &sk);
    t("sketch finds 4 entities", sk.nent == 4);
    t("sketch entity 0 is tasks", eq(reason.entityName(&sk, 0), "tasks"));
    t("sketch entity 1 is queues", eq(reason.entityName(&sk, 1), "queues"));
    t("sketch entity 2 is judged", eq(reason.entityName(&sk, 2), "judged"));
    t("sketch entity 3 is list", eq(reason.entityName(&sk, 3), "list"));
    t("sketch finds 2 relations", sk.nrel == 2);
    t("sketch rel 0 is tasks -queues_for-> queues", sk.rels[0].s == 0 and sk.rels[0].v == 0 and sk.rels[0].o == 1);
    t("sketch rel 1 is queues -judged_by-> judged", sk.rels[1].s == 1 and sk.rels[1].v == 1 and sk.rels[1].o == 2);

    // 8. the entrains fix carried over: couples_with + entrains -> kuramoto 500
    var ep = reason.Problem{};
    reason.setName(&ep, "sync");
    const nodes = reason.addEntity(&ep, "nodes").?;
    _ = reason.addRelation(&ep, nodes, 15, nodes); // couples_with
    _ = reason.addRelation(&ep, nodes, 18, nodes); // entrains
    const ed = reason.reason(&ep);
    t("entrains fix: kuramoto wins", ed.domain == 3);
    t("entrains fix: score is 500", ed.score_x1000 == 500);

    std.debug.print("\n{d} pass, {d} fail\n", .{ pass, fail });
    if (fail > 0) std.process.exit(1);
}
