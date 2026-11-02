// Harakiri NG — tRust watchdog + task manager
// tRust: Nathan's type-constraint language, now the kernel's supervisor.
// Every task carries a type contract. The watchdog enforces it.
// Nathan Brown, 2026.

// A task contract: what tRust knows about a task.
pub const Contract = struct {
    // Resource bounds
    max_quanta: u32,        // max work units per scheduling round
    max_stack: u32,         // max stack bytes

    // Gate thresholds
    min_eta: u32,           // minimum η × 1000 to run (Gaven's gate: 500)

    // Allowed state transitions (bitmask of legal target states)
    // bit N = may transition TO state N
    legal_targets: u8,

    // Capabilities: what this task may touch
    can_uart: bool,
    can_gpu: bool,
    can_spawn: bool,
};

// Task states (matches TempleOS cooperative model)
pub const TaskState = enum(u8) {
    idle = 0,
    ready = 1,
    running = 2,
    yielding = 3,
    blocked = 4,
    done = 5,
    faulted = 6,  // watchdog killed it
};

// A managed task
pub const Task = struct {
    id: u32,
    name: [16]u8,
    state: TaskState,
    contract: Contract,
    quanta_used: u32,
    eta_x1000: u32,
    // Burst-aware scheduling: virtual runtime. Least vruntime runs first;
    // vruntime += 1 per run. boost() subtracts — interactive work jumps
    // the queue, and the boost decays naturally as the task runs.
    // (The EEVDF core that BORE builds its burst penalties on.)
    vruntime: u64,
    // Cooperative: task yields back here
    // (function pointer set by task owner)
    entry: ?*const fn (*Task) void,
};

// ---- Watchdog verdicts ----
pub const Verdict = enum {
    allow,      // contract satisfied, task may run
    deny_eta,   // η below threshold — Gaven's gate holds
    deny_quanta,// exceeded work budget
    deny_state, // illegal state transition
    deny_cap,   // capability not granted
};

// The watchdog: checks a task's contract before it runs.
pub fn inspect(task: *const Task, want_state: TaskState) Verdict {
    // η gate
    if (task.eta_x1000 < task.contract.min_eta) {
        return .deny_eta;
    }
    // quanta budget
    if (task.quanta_used >= task.contract.max_quanta) {
        return .deny_quanta;
    }
    // legal transition?
    const bit: u8 = @as(u8, 1) << @as(u3, @truncate(@intFromEnum(want_state)));
    if (task.contract.legal_targets & bit == 0) {
        return .deny_state;
    }
    return .allow;
}

// Attempt a state transition through the watchdog.
pub fn transition(task: *Task, to: TaskState) bool {
    const v = inspect(task, to);
    if (v != .allow) {
        task.state = .faulted;
        return false;
    }
    task.state = to;
    return true;
}

// ---- Task manager: cooperative scheduler ----
// TempleOS-style: tasks yield, watchdog picks next.

pub const MAX_TASKS: usize = 16;
pub var tasks: [MAX_TASKS]Task = undefined;
pub var ntasks: usize = 0;

// Focus: when nonzero, only the focused task is eligible — Kraken pouring
// every tick into one path (Pain cut five paths to focus the sixth).
pub var focused_id: u32 = 0;

pub fn spawn(name: []const u8, id: u32, contract: Contract, entry: ?*const fn (*Task) void) ?*Task {
    if (ntasks >= MAX_TASKS) return null;
    var t = &tasks[ntasks];
    t.id = id;
    t.state = .idle;
    t.contract = contract;
    t.quanta_used = 0;
    t.eta_x1000 = 972;
    t.vruntime = 0;
    t.entry = entry;
    @memset(&t.name, 0);
    const n = @min(name.len, 15);
    @memcpy(t.name[0..n], name[0..n]);
    ntasks += 1;
    return t;
}

// Interactive boost: user input cuts a task's virtual runtime so it runs
// sooner, and wakes it if it was yielding — a woken interactive task jumps
// the queue. BORE's lesson — bursty interactive work first; the cut decays
// naturally as the task runs (vruntime += 1 per run).
pub fn boost(id: u32, amount: u64) void {
    for (tasks[0..ntasks]) |*t| {
        if (t.id == id) {
            t.vruntime = t.vruntime -| amount;
            if (t.state == .yielding) t.state = .ready;
            return;
        }
    }
}

// One scheduler tick: run the eligible task with the lowest virtual runtime,
// watchdog-gate it, run it. Least-attained-service — a task that hogs ticks
// accumulates vruntime and waits; a task that idles stays low and gets prompt
// service when it wakes. That IS burst awareness.
pub fn tick() void {
    if (ntasks == 0) return;
    var tried: usize = 0;
    while (tried < ntasks) : (tried += 1) {
        var best: ?*Task = null;
        for (tasks[0..ntasks]) |*t| {
            if (t.state != .ready and t.state != .idle) continue;
            if (focused_id != 0 and t.id != focused_id) continue; // Kraken's focus
            if (best == null or t.vruntime < best.?.vruntime) best = t;
        }
        const t = best orelse break;
        if (transition(t, .running)) {
            if (t.entry) |run| run(t);
            // Task should have yielded; if still running, force yield
            if (t.state == .running) {
                _ = transition(t, .yielding);
            }
            t.quanta_used += 1;
            t.vruntime += 1;
            return;
        }
        // watchdog denied — transition() faulted it, so the next scan skips it
    }
    // nobody runnable: re-arm every yielder so the rotation stays fair.
    // (Re-arming only the first yielder starves the rest — verified 2026-10-17.)
    for (tasks[0..ntasks]) |*t| {
        if (t.state == .yielding) t.state = .ready;
    }
}

pub fn task_name(t: *const Task) []const u8 {
    var len: usize = 0;
    while (len < 16 and t.name[len] != 0) : (len += 1) {}
    return t.name[0..len];
}

pub fn verdict_name(v: Verdict) []const u8 {
    return switch (v) {
        .allow => "allow",
        .deny_eta => "deny (eta)",
        .deny_quanta => "deny (quanta)",
        .deny_state => "deny (state)",
        .deny_cap => "deny (capability)",
    };
}

// Default contracts for the agent crew
pub fn agent_contract() Contract {
    return Contract{
        .max_quanta = 1000,
        .max_stack = 8192,
        .min_eta = 500, // Gaven's gate
        .legal_targets = (1 << 1) | (1 << 2) | (1 << 3) | (1 << 5), // ready, running, yielding, done
        .can_uart = true,
        .can_gpu = false,
        .can_spawn = false,
    };
}

pub fn gpu_contract() Contract {
    var c = agent_contract();
    c.can_gpu = true;
    c.max_quanta = 5000; // GPU work is heavier
    return c;
}
