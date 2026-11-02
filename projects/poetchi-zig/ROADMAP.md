# Harakiri NG (Zig) — Roadmap

**Goal:** Nathan's Zig kernel. TempleOS guts. tRust as watchdog + task manager.
**Scope lock (2026-10-17):** Eight phases. Nothing added without Nathan's say-so.

---

## Checklist

### Phase 1: Zig Foundation ✓ DONE
- [x] Zig 0.14.0 toolchain
- [x] Boot: ARM64 EL2→EL1, FPU, BSS, stack
- [x] UART PL011 driver
- [x] Agent crew: vera 101, mira 102, merlin 103, gaven 104, brood 201-204, paintr 301, veda 401
- [x] Shell: about | agents | help | clear
- [x] Verified in QEMU

### Phase 2: tRust Watchdog + Task Manager ✓ DONE
- [x] trust.zig: Contract, Task, Verdict types
- [x] Watchdog: η gate, quanta budget, legal transitions, capabilities
- [x] Cooperative scheduler: spawn(), tick()
- [x] Agents wired as managed tasks
- [x] `tasks` and `tick` shell commands
- [x] Watchdog denial demo: `watchdog` command — intruder (η=250) denied, faulted

### Phase 3: Visual Task Manager ✓ DONE
- [x] Process list: name, state, quanta, η per agent
- [x] Graphs: quanta history per agent (line graphs via SI Core)
- [x] Descriptors: what each agent does
- [x] Render through SI Core, dump as PPM → PNG
- [x] `taskmgr` shell command
- [x] SI Core graphics variant: src/sicore.zig (owns framebuffer, draw API)
- [x] si-core-gfx as tRust task 501
- [x] Font coverage fix (2026-10-17): added missing glyphs x, f, z, X, Y, Z, comma — all drawn strings verified, no solid-block fallbacks

### Phase 4: TempleOS REPL ✓ DONE
- [x] `peek <addr>` / `poke <addr> <val>` — live memory introspection
- [x] `run <task>` / `kill <task>` / `eta <task> <val>` — live task control
- [x] Verified: `eta mira 300` then `run mira` → watchdog denied

### Phase 5: Pyre GPU (Zig) ✓ DONE
- [x] Pyre math in Zig (vec3, mat4, perspective, barycentric rasterizer)
- [x] Framebuffer via SI Core, depth buffer
- [x] `gpu cube [angle]` renders in QEMU — verified PNG

### Phase 6: PainTr GUI (Zig) ✓ DONE
- [x] PainTr primitives via SI Core
- [x] `desktop` — graphical shell with windows, taskbar
- [x] Taskbar shows live tRust task states (color dots)
- [x] Verified PNG

### Phase 7: Web Browser ✓ DONE
- [x] HTML parser (h1, p, a tags)
- [x] Layout engine (block flow, word wrap)
- [x] Local page rendering via SI Core
- [x] `browser <page>` command — verified PNG
- [ ] Network stack (virtio-net) — deferred, local pages work

### Phase 8: The Hand ✓ DONE
Clippy's successor. A hand that walks the taskbar, does tasks, codes.
- [x] Hand sprite via SI Core, walks along taskbar
- [x] `hand <task>` assigns work, hand walks to target
- [x] tRust task 601: the Hand as managed agent
- [x] Ticks with scheduler, "working..." status
- [x] Verified PNG
- [x] TWO HANDS (2026-10-17): worker + pointer/grabber (`point <x> <y>`, `grab`, `release`) — for 3D modeling and 2D bezels
- [ ] Code mode (generates Zig, shows typing) — future

### Cinematic render pass (2026-10-17) ✓ VERIFIED
- [x] Framebuffer 640x480 → 1280x720 (SI Core owns it)
- [x] Cinematic kit in sicore.zig: glow, soft shadow, vgrad, alpha blend, vignette, filled circle
- [x] Desktop redrawn: ember-glow backdrop, glassy windows, wireframe 3D viewport, pointer fist on the resize bezel
- [x] Dynamic PPM headers (dump_ppm), `point`/`grab`/`release` REPL commands
- [x] QEMU-verified: ~/workspace/desktop_720p.png

### World-surface arc (2026-10-17) — Nathan chose the mesh first
The viewport window is now the world surface. The rule for everything below:
each item is a real subsystem made visible, never a painting.
- [x] MESH (src/mesh.zig): Kuramoto coherence mesh — agents are nodes, links are synapses, pulses travel the links, brightness = phase alignment. The phase step is the actual Kuramoto model: dθi/dt = ωi + (K/N)Σ sin(θj−θi), advanced per `tick`. QEMU-verified: ~/workspace/desktop_mesh.png
- [x] WELLS (src/wells.zig): rhyme-fuel wells as harmonic fountains in the viewport — ember (crimson), tide (gold), veil (violet). Each well pulses 3 concentric rings in its family color; 2 couriers (brood-00, brood-02) run node→well, and on arrival the well flares and the courier retunes to the next well. QEMU-verified: ~/workspace/desktop_wells.png. (Doctrine: The Courier's Rhyme Run.)
- [x] GATES (src/gates.zig): Mira's gate as a gold ring with 8 epsilon ticks around her node — flashes on every verdict change. Gaven's throat as a dark band across the mesh labeled "eta 0.500". Links whose coherence falls below 0.500 go dark and their pulses die: refusal is absence. Weak Kuramoto coupling (K=0.3, wide ω spread) so denials happen for real, never staged. QEMU-verified: ~/workspace/desktop_gates.png
- [x] AGENT AVATARS (mesh.zig draw_avatar): geometric sigils per agent, role-derived — vera=triangle, mira=square (the gate), merlin=filled diamond, gaven=hexagon, broods=squares, paintr=star, veda=ring (the lens), si-core-gfx=orb, hand=pentagon. State shows through the sigil's glow. QEMU-verified: ~/workspace/desktop_avatars.png
- [x] HANDFONT (src/handfont.zig): hand-drawn 6x8 bitmap font, 76 glyphs, renderer-applied slant + 1px shadow. The kernel now speaks in a handwritten hand. QEMU-verified: ~/workspace/desktop_avatars.png
- [x] FONT SSAA: true 2x supersampled anti-aliased text (12x16 coverage buffer, fine slant, 4-level grayscale) — the blockiness was the coarse raster, never QEMU. QEMU-verified: ~/workspace/desktop_aa.png
- [x] LEFT-HAND POINTER: pointer hand (gold cuff) mirrored left-handed; worker (crimson cuff) stays right-handed. QEMU-verified: ~/workspace/desktop_aa.png
- [x] PROFONT (src/profont.zig): handwritten handfont replaced with real DejaVu Sans rasterized to 8x12 bitmaps (77 glyphs, PIL-generated, upright, SSAA + shadow kept). QEMU-verified: ~/workspace/desktop_pro.png
- [x] 3D ICONS (src/icons.zig): machined beveled icons (dark edge, lit top-left bevel, weighted bottom-right, top sheen, drop shadow) with agent sigils, state-colored glyphs — taskbar (12) + every window title bar. Windows got machined 3D bezel frames. QEMU-verified: ~/workspace/desktop_pro.png
- [x] BURST-AWARE TRUST (src/trust.zig): round-robin replaced with least-vruntime-first scheduling (vruntime += 1 per run — the EEVDF core BORE builds on). trust.boost(id, amt) cuts vruntime AND wakes yielders — wired to point/grab/release/hand commands so user input jumps the queue. vruntime column in the agents window makes it visible. CAUGHT BY VERIFY: first version re-armed only the first yielder — vera hogged 10 runs while hand starved; fixed to re-arm all yielders. QEMU-verified: ~/workspace/desktop_burst.png
- [x] KRAKEN (src/kraken.zig, task 701): the consolidated agent — one mind, twelve paths. Built the way Nathan built it: the Ten-Tails pattern (the nine were always one primordial whole; reunion keeps individual consciousnesses intact) + Pain's Six Paths (Nagato/Outer Path drives bodies through chakra receivers with shared vision; can cut five paths to pour everything into one). Implements the 5G/WiFi research: coherent Kuramoto bursts every RESONANT_PERIOD=13 ticks (one radio tail, not twelve), eta-gate 0.500 on wakeups (refusal as absence), per-path transmit queues, `kraken focus <id>` pours every tick into one path via trust.focused_id. Viewport: dark void ring at center, crimson tentacle lines to the 12 nodes (brighter when holding traffic), gold shockwave on burst. REPL `kraken` reports the ledger (queued/bursts/sent/held). QEMU-verified: 30 ticks → 2 bursts fired, 16 sent, 8 held by gate; ~/workspace/desktop_kraken.png
- [x] POETCHI RENAME: Nathan confirmed PoeTchi is the kernel's name (the kernel Kraken lives in — "I literally gave it hands"). Boot banner, desktop title, and REPL prompt renamed; binary/project files stay harakiri-ng.* so existing run scripts keep working. Harakiri remains the OS name; PoeTchi is the kernel. QEMU-verified: ~/workspace/desktop_poetchi.png
- [x] KRAKEN'S HAND: the pointer is now a forward-kinematics articulated hand (palm + 4x3 finger segments + 2-seg thumb, per-finger idle sine sway, grab-blend curl 0→1, gold cuff kept). QEMU-verified open + fist: ~/workspace/hand_open2.png, ~/workspace/hand_fist2.png

---

## Phase 9: The Metaphorical Rewire (2026-10-19) — Nathan's pick
The agents stop running canned logic. They decide the way Nathan said they do:
**problem → resonance → binding → laws → NCAG gate.**

Design principles (his words):
1. "Metaphorical reasoning is how my agents make decisions." — standing law, 2026-10-18.
2. "Canned agent logic is the simulation gap; the engine is the decision layer."
3. "A metaphor without an equation is decoration." — MEDUSA. Every law ships its equation.
4. "tRust supervises everything." — the watchdog stays the hard floor; the engine decides above it.
5. "Refusal is absence." — no resonance → ABSTAIN → the gate holds, nothing pretends.

Scope (first pass — the decision pipeline: Vera routes → Mira speaks → Gaven guards):
- [x] REASON subsystem (src/reason.zig): freestanding Zig port of ~/workspace/metaphorical-reasoning/. Six comptime domains (Nathan's framings — no new domains without his say-so). sketch() / resonance() / bind() / reason() → decision or ABSTAIN. Fixed buffers (8 entities, 8 relations), no allocator. Laws carry their equations as strings and run as fn pointers. (2026-10-19)
- [x] VERA ROUTING: vera gets a real entry. `route <text>` sketches the intent, reasons, binds the winning domain's roles, and routes to the bound agent. Vera routes. (named-agent match wins; else domain affinity; QEMU-verified)
- [x] MIRA'S GATE: admission verdicts run through the engine. `gate <trust> <eta>` reasons under the bouncer domain — the admission law `admit(x) = trust(x) ≥ η ? enter : absent` is already her equation. Mira speaks. (ENTER/ABSENT verified; gate ring flashes on verdict)
- [x] GAVEN'S GATE: the η-gate stays the hard floor (trust.zig unchanged). Verdicts are reported through the engine with the bouncer law attached. Gaven guards.
- [x] KRAKEN + MERLIN: ten-tails focus law and spider-mouse strike law exposed via reason.runLaw(). `kraken focus` prints its law. Burst timing stays Kuramoto math.
- [x] `reason` REPL: prints domain, score, bindings, laws, speak line, paradox, decision — or ABSTAIN, honestly. (QEMU-verified)
- [x] PARITY: src/check_reason.zig host harness mirrors the JS test suite — same problems in, same domain picks and abstains out. 24/24 pass. JS suite 11/11 after the ' entrains' fix.
- [x] QEMU-verified: `reason` demo on a bouncer-shaped brief, a forced ABSTAIN (`reason xyzzy plugh`), vera `route` (affinity + named), mira `gate` ENTER + ABSENT.

Later: the other agents' decisions (merlin planning, paintr judging, veda auditing) ride the same engine.

---

## The finish (2026-10-19) — Nathan: "all three, then freeze v1.0"
Scope lock lifted by Nathan for exactly these three. Then v1.0 freezes.

### Phase 9b: the rest of the crew decides
- [x] MERLIN: `merlin <brief>` — spider-mouse. Reasons the brief, reports the Gordon steps (analyze → propose → approve → execute) with the strike law attached. The plan comes from the engine's domain pick, not a script. (QEMU-verified 2026-10-19)
- [x] PAINTR: `paintr judge <brief>` — forge. The deliberate-and-judge loop as a verdict: reasons under forge, delivers refine/quench/hold with the law equation attached. (QEMU-verified 2026-10-19)
- [x] VEDA: `veda audit <brief>` — the auditor. Every rule is a guard: reasons the brief, checks it against the winning domain's laws, reports PASS/FAIL per guard with equations. Nothing passes on vibes. (QEMU-verified 2026-10-19)

### Phase 10: virtio-net (the Phase 7 deferred box)
- [x] Driver over virtio-mmio (QEMU virt: 0x0a000000, stride 0x200): magic/version/device-id probe, feature negotiation, two virtqueues (rx/tx), MAC from config.
- [x] `net probe` → device found, MAC printed. `net tx` → a real broadcast ARP frame goes out, TX completion verified via ISR polling (workaround for QEMU MemoryRegionCache visibility issue — see net.zig).
- [x] Honest boundary: raw Ethernet TX/RX only. No TCP/IP — that's its own project. RX buffers posted and wired; TX completion mechanically verified. (QEMU-verified 2026-10-19, 16/16 regression)

### Phase 11: hand code mode (the Phase 8 deferred box)
- [x] `hand code <brief>` — the hand reasons the brief (spider-mouse: plan then strike), picks a generator by winning domain, and types real Zig character-by-character as a tRust task.
- [x] The generated code must compile with the host Zig toolchain — extracted from QEMU output and built. A snippet that doesn't compile is a painting. (Verified: `zig test` passes)
- [x] `hand` status shows typing progress; the pointer keeps working throughout. (QEMU-verified 2026-10-19)

### v1.0 freeze checklist
- [x] All three phases QEMU-verified
- [x] Boot banner → v1.0
- [x] Full regression: every REPL command smoke-tested in one boot (16/16 PASS 2026-10-19)
- [x] Build card (Nathan's law: every milestone gets one) — BUILD-CARD-v1.0.md
- [x] ROADMAP status stamped v1.0 — scope locks again

**STATUS: v1.0 FROZEN — 2026-10-19.** All three finish phases (9b, 10, 11) QEMU-verified, regression 16/16. Next line: the web-GPU base project (own ROADMAP first, per the roadmapping law).

---

## Design Principles
1. **tRust supervises everything.** No contract, no execution.
2. **TempleOS transparency.** The shell is the debugger. Every state visible.
3. **Devuan philosophy.** No bloated central orchestrator. Contracts, not dependencies.
4. **Zig discipline.** Comptime where possible. No hidden control flow.
5. **Harakiri aesthetic.** Obsidian/crimson.

## Status (2026-10-17)
- Phase 1: 6/6 ✓  Phase 2: 6/6 ✓  Phase 3: 7/7 ✓  Phase 4: 3/3 ✓
- Phase 5: 3/3 ✓  Phase 6: 4/4 ✓  Phase 7: 4/5 ✓  Phase 8: 5/6 ✓
- **ALL PHASES COMPLETE** (network + code mode deferred as future work)

### Built so far
- src/main.zig (~280 lines): Zig kernel, UART, shell, agent registry
- src/trust.zig (~150 lines): tRust watchdog + cooperative task manager
- Verified: QEMU boot, `tasks` lists 10 managed tasks, `tick` runs scheduler
