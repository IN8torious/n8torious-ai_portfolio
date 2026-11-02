# KERNOID OS ON THE AIR X — KERNEL DESIGN
*Design only. Roadmap before code (Nathan's law, 2026-10-17). Checkboxes mean VERIFIED, nothing else.*
*Target: MANGMI Air X · The kernel is PoeTchi · The OS is **Kernoid OS** (renamed from Harakiri, 2026-10-30) · Project tree stays `harakiri-ng` — history keeps its names.*

---

## THE POINT (Nathan's question, 2026-10-30 — answered in the doc so it survives)

Not speed. If the goal were faster games, stock firmware already does that job and changing it would be pointless. The point:

1. **It is his.** Stock answers to the vendor and to Google — it reports, it updates on their schedule, it can be altered or abandoned remotely. Kernoid answers to Nathan. Sovereignty is the product; performance is a side effect.
2. **It runs what stock cannot.** The crew lives in this kernel — sync, reason, admit, the whole table. No stock firmware anywhere runs his agents as kernel organs. The comparison was never Kernoid vs stock at stock's job; stock cannot do this job at all.
3. **A user can understand it.** The whole system fits in §0's twenty-one words. Stock is thousands of packages nobody can enumerate.
4. **It outlives the vendor.** When MANGMI stops updating the Air X, stock rots in place. Kernoid rides mainline, which is maintained indefinitely.
5. **It moves.** The agnostic design means the crew survives this device. Stock dies with the hardware; Kernoid changes Ports.

---

## 0. NAMES — AGNOSTIC (rename pass, 2026-10-30)

*Working names are single plain function words — bound to nothing: no job titles, no metaphor, no gender, no platform, no project flavor. The name is the contract; any implementer can hold it. (First pass used job titles — Router, Approver, Conductor — still metaphors, replaced here. The original names are kept once, so nothing is lost. Strike any line and it gets struck here too.)*

**Agents**
| Name | Before | Actually does |
|---|---|---|
| **route** | Vera | Routes every intent before anything else moves |
| **voice** | Mira | Speaks for the system; every proposal queues at her desk — nothing reaches Nathan unqueued, nothing ships unapproved |
| **act** | Merlin | Carries out approved work: analyze → propose → approve → execute |
| **veto** | Gaven | Admission and the security veto; refusal is absence. *His given name stays — veto is the work name.* |
| **audit** | Veda | Checks finished work against its ticket; every rule is a guard |
| **record** | Witness | Writes the ledger; nothing runs on memory |
| **paint** | PainTr | Paints the images, builds the 3D models (the tool itself still ships as PainTr) |
| **index** | HiveMind | Keeps the roll: who is awake, who holds what, telemetry in, mode sync out |
| **sync** | Kraken | One mind over the twelve paths; keeps them in coherence as a single creature |

**Processes**
| Name | Before | Actually does |
|---|---|---|
| **work** | Brood | The execution pool that does the lifting |
| **plan** | Spider mode | Slow, deliberate planning |
| **react** | Mouse mode | Fast reaction, no deliberation |
| **pace** | burst scheduler | Paces wakeups in coherent Kuramoto bursts (13-tick law) |
| **admit** | the η-gate | η ≥ 0.500, or the answer is absence |
| **queue** | Mira's Gate | The human-facing queue at voice's desk |
| **review** | THE GATE pipeline | Route → sample → coherence → audit → admission → speak → record |
| **reason** | the reasoning engine | Resonance → binding → laws → verdict |
| **signal** | vibe resonance | Symbol messages (♪⚠✓…) between paths |
| **sense** | Minnoe drain | The senses reporting in |
| **bridge** | Sovereign Agent Layer | Userspace I/O only — no processing lives here |
| **watch** | tRust watchdog | The hard floor. Already plain; unchanged in every way that matters |

REPL verbs were already this shape — `reason`, `route`, `admit` — the table now matches them.

---

## 0.5 THE AGNOSTIC LAW (Nathan, 2026-10-30)

**The crew knows nothing about the chip.** sync, the twelve paths, reason, pace, admit, signal — none of them may name a SoC, a register, a bus, or a vendor. Everything hardware-shaped lives behind one seam:

**THE PORT** — the only layer allowed to touch metal. Its contract, the same on every platform:
boot handoff (device tree / firmware tables → normalized boot info) · console in/out · block read/write · a scanout surface ("no display" is a valid answer) · normalized input events (axes, buttons) · power report (battery, thermal) · a timer tick · radio power.

Ports so far: **Port #0 = QEMU virt** (PoeTchi v1.0 already ran there — the core has survived one port, which is the proof this law is real) · **Port #1 = the Air X** (SM6115; Stage 1 implements the Port over mainline Linux services — DRM, input, power — Stage 2 over bare metal, *same crew code above the seam*) · future ports (the Edge's Dimensity, the laptop's x86) are new Ports, never crew changes.

The failure mode has a name: **coupling creep** — a platform fact leaking above the seam "just this once." The M1 acceptance test greps for it (§5). If a design choice only works on SM6115, it is a Port feature or it is wrong.

---

## 0.75 TWO STANDING REQUIREMENTS (Nathan, 2026-10-30)

**1. A user can understand it.** The §0 table is not internal jargon — it is page one of the user manual. Every name a user might meet (on screen, in the ledger, in a refusal) is one plain word plus one plain line saying what it does; if a user can't say what a part does from that, the name or the part is wrong. One subtlety, stated plainly: **admit refuses by absence between processes — but people are not processes.** A user who hits a refusal gets a sentence from voice saying what was refused and why, in the table's words. Silence is a mechanism, never an interface.

**2. Faster than it was.** "It" is PoeTchi v1.0 under QEMU, and the claim gets numbers or it doesn't get made (MEDUSA):
- The baseline is captured, not remembered: three timings from v1.0 in QEMU — route→verdict latency on the REPL, coherence settle time after a cold start, wakeup cost per burst — recorded in this doc before M2 is judged.
- The speed is expected from named causes, in this order: native silicon instead of TCG emulation (the big one); the crew on kernel threads, no process/syscall toll on the hot path; fixed buffers, no allocator, no jitter; the react fast lane bypassing reason entirely; pace coalescing twelve wakeups into one tail.
- Placement is a Port concern expressed in agnostic words: the Port reports fast cores and slow cores; sync and reason get the fast ones, sense and signal live on the slow ones. No cluster names above the seam.

**The stock-firmware comparison (Nathan's question, 2026-10-30).** Against stock Android on this same device, Kernoid is expected to win where weight is the cost — cold boot to usable, time-to-first-input, our interface's latency, idle drain, free RAM on a 4 GB device — because stock pays for a full Android stack, vendor services, and telemetry that we simply do not run. It is NOT expected to win where proprietary tuning is the cost: peak 3D/emulation FPS on vendor Adreno blobs, camera ISP, hardware video encode. Those are recorded as hostile tests, not assumed victories. The comparison is run on both firmwares, same device, same title where applicable — numbers in this doc, or the claim doesn't ship.

---

## 1. THE METAL (what we are designing for)

| Part | Truth | Confidence |
|---|---|---|
| SoC | Qualcomm Snapdragon 662 = **SM6115**, ARM64 | Verified (ROCKNIX wiki) |
| CPU | 4× Kryo Gold (Cortex-A73) @ 2.0 GHz + 4× Kryo Silver (Cortex-A53) @ 1.8 GHz — big.LITTLE | Platform-known |
| GPU | Adreno 610 — **Freedreno** GL + **Turnip** Vulkan in the open stack | Verified (ROCKNIX wiki) |
| Kernel base | **Mainline Linux** — SM6115 upstream is alive: MDSS/DPU display nodes, GPU nodes, Venus codec all landed upstream through 2026 | Verified (upstream DTS logs) |
| RAM / storage | 4 GB LPDDR4X / 64 GB eMMC + microSD (128 GB Amazon Basics A2, on hand) | Listing-known |
| Screen | 5.5″ 1080×1920 DSI panel | Listing-known — **panel init sequence: verify on device** |
| Input | 2 hall sticks, full gamepad set, stick LEDs, Vol/Power | Listing-known — **GPIO map: verify on device** |
| Radios | WiFi/BT onboard (chip ID on SD662 designs is usually WCN3990-class) | **Verify on device** |
| Boot | ROCKNIX ABL on the eMMC; kernel + DTB load from the microSD | Verified (ROCKNIX wiki) |

**Design consequence:** for the first time, the hardware is *documented by a living upstream platform*. We are not reverse-engineering a locked phone. The device tree is the map, and M0 (below) is reading the map off the real device — every sensor is a claim until the device itself reports it.

## 2. THE SHAPE — STAGED, WITH A GATE

The freestanding PoeTchi v1.0 (Zig, QEMU-verified, frozen) proved the agent architecture. The Air X is where it meets silicon. Two ways in:

**Stage 1 — our own mainline kernel, Kernoid as a subsystem of it (Nathan's call, 2026-10-30).**
Not ROCKNIX's kernel with our module in it — *our* tree: upstream mainline from kernel.org, our config, the Kernoid subsystem carried as our patchset, built by us. The shape has precedent in the phone line (the GKI build: `CONFIG_HARAKIRI=y`, the agent stack live on boot, `/proc/harakiri` answering) — the difference is that this time the whole tree is ours, not a vendor's. ROCKNIX's role shrinks to three honest things: the ABL (the bootloader — firmware, like any boot ROM; it loads our kernel and gets no say in what it is), a *reference* (their DT and config are the hardware map we read at M0 — research, not dependence), and the run sheet that gets the card booting. Display/storage/radios come from upstream drivers in our tree. Stage 1 spends our effort on what is ours — and what is ours now includes the kernel itself.

**Stage 2 — the freestanding gate.**
Once the agent layer is proven on silicon (coherence measured, REPL answering, display driven), PoeTchi NG may go bare-metal on the same hardware: the ABL hands us a DTB and a load address; the upstream DT becomes our hardware manual. Stage 2 is a *decision gate*, not a promise — it opens only if Stage 1's measurements say the agent layer deserves its own kernel, and Nathan witnesses the first bare-metal boot.

**Why staged:** a freestanding-first build spends months re-solving the DSI panel and the eMMC before a single agent wakes up. Staged puts sync on real silicon in the first month and keeps every Stage-1 artifact (DT overlays, ABI, the reasoning core) reusable in Stage 2.

## 3. THE STACK (top to bottom)

```
        ┌───────────────────────────────────────────────┐
        │  KERNOID OS (the face)                         │
        │  poetchi> REPL · PainTr canvas · the Hands     │
        ├───────────────────────────────────────────────┤
        │  THE BRIDGE (userspace I/O only)               │
        │  route = inputs · voice = the surface          │
        │  act = approved work · veto = admission        │
        ├───────────────────────────────────────────────┤
        │  SYNC (in-kernel, CONFIG_KERNOID=y)  │
        │  12 paths as kernel threads · index keeps the roll     │
        │  reason core (Zig, no allocator) · /proc ABI     │
        ├───────────────────────────────────────────────┤
        │  THE PORT (the only layer that touches metal)  │
        │  boot · console · block · scanout · input ·    │
        │  power · tick · radio — one contract, any chip │
        ├───────────────────────────────────────────────┤
        │  tRUST WATCHDOG (the hard floor, untouched)    │
        ├───────────────────────────────────────────────┤
        │  OUR MAINLINE KERNEL (upstream + our patchset) │
        │  DRM/KMS + Freedreno · eMMC/SD · input · power │
        │  ROCKNIX ABL boots it — and has no say in it   │
        └───────────────────────────────────────────────┘
```

**sync (in-kernel).** Twelve paths, one mind — the v1.0 topology carried over unchanged: work is the execution fabric, plan drafts / react reacts (the old Spider/Mouse loop), index keeps the roll. Kernel threads, not processes: the agents are the kernel's own organs, per the standing correction that made the Bridge a bridge (agents handle the processing; userspace is I/O).

**The scheduler discipline (MEDUSA — every behavior an equation).**
- Path phases entrain by Kuramoto: `θ̇ᵢ = ωᵢ + (K/N)·Σⱼ sin(θⱼ − θᵢ)`; coherence `η = |Σ e^{iθ}| / N` is *measured*, never painted.
- **pace:** wakeups fire in coherent bursts on the resonant period (13-tick law from v1.0) — one power/radio tail for the whole crew, not twelve.
- **admit:** a wakeup request with η < 0.500 is refused *by absence* — nothing happens, and the nothing is the answer (veto's law).
- Battery and thermal state are inputs to ω: a hot or hungry device slows the crew's natural frequencies instead of cooking itself. Resource effects are explicit (Rustba's law) — no path may spend power it cannot name.

**reason.** `reason.zig` ports as-is: freestanding, fixed buffers, no allocator — it was *built* for a kernel context. Same six comptime domains, same REPL verbs (`reason`, `route`, `admit`), same parity harness — the JS engine stays the reference, and the harness must still pass 24/24 on the port. A test that cannot fail is a painting: the harness keeps its trap cases.

**The ABI.** `/proc/kernoid/` — one file per organ: `ledger` (Witness), `coherence` (live η + per-path phase), `paths` (the roll), `admission` (verdicts). The REPL (`poetchi>`) talks over serial first, SSH second, on-screen third (PainTr canvas, §4). No binary ioctls until a file-based interface proves too slow — files are inspectable, and inspectable wins while we're learning the hardware.

## 4. DISPLAY & INPUT — THE HANDS GET A BODY

- **Scanout:** mainline DRM/KMS owns the panel. We do not write a DSI driver in Stage 1.
- **Renderer:** **Pyre** (Nathan's software GPU — barycentric rasterizer, QEMU-verified on BUBO bare metal) renders into a DRM dumb buffer. Freedreno/Turnip stay available, but Pyre is the sovereign path: our pixels, our math.
- **Surface:** PainTr canvas on Pyre (the standing plan: rasterizer → canvas → widgets → compositor). First screen: the boot banner + `poetchi>` REPL, obsidian/crimson.
- **Input:** the left stick + buttons are the **pointer Hand** (point / grab / release — for the canvas and, later, meshes); the right side is the **worker Hand** (task execution, confirm/deny). The two-Hands doctrine from the desktop line, with physical sticks under them.
- **signal:** inter-path signals carry symbols (♪⚠✓…) — in the ledger and on the canvas, compact and language-agnostic, as designed.

## 5. MILESTONES (each with a test that can fail)

- [ ] **M0 — Inventory.** Stock ROCKNIX boots from our card (run sheet). Harvest the device's own report: DT dump, `dmesg`, cpuinfo, DRM/input device lists — **plus the EL2 question: is `/dev/kvm` there, and what does dmesg say about KVM?** That one answer decides whether PoeTchi can run as a guest kernel over our Linux underlay (Nathan's arrangement, 2026-10-30) or falls back to the subsystem shape. *Fail condition: any §1 "verify on device" item contradicts the table and the design doesn't get amended.*
- [ ] **M1 — Our kernel builds and boots.** Our tree (upstream mainline + SM6115 + the kernoid patchset), our config, built with an aarch64 cross toolchain, booted via the ABL. Dev userspace only (decision 3); the kernel is ours end to end. *Fail: boot hangs, panel dark, the SD root doesn't mount, or any part of ROCKNIX's kernel turns out to be load-bearing.* **Agnostic check:** the crew core (sync, paths, reason) compiles with zero SM6115/Qualcomm identifiers in it — grep is the test, and it can fail.
- [ ] **M2 — sync wakes.** `CONFIG_KERNOID=y`: sync + 12 paths registered, `/proc/kernoid/coherence` returns live numbers, REPL answers `reason` on the real device. Parity harness 24/24 against the JS reference. The §0.75 baseline timings (captured from v1.0 under QEMU) are beaten on all three measures, and the Air X numbers are written next to them. *Fail: η flatlines at 0 or 1 (painted, not measured), any harness case regresses, or any baseline timing is not beaten.*
- [ ] **M3 — The discipline is measured.** Burst wakeups counted; battery draw with gate on vs off over a fixed workload. *Fail: the η-gate shows no measurable power effect — then the law is wrong on silicon and we say so.*
- [ ] **M4 — The face.** Pyre renders the boot banner + REPL to the panel via DRM; the pointer Hand moves a cursor with the left stick; grab moves a window edge. *Fail: tearing-free 30 fps on the banner scene not reached, or input latency is visible.*
- [ ] **M5 — The crew works.** A full loop on device: route takes a spoken/typed intent → plan drafts → act executes a real task (e.g. a paint render) → audit checks it → veto admits or refuses → voice surfaces it → record ledgers it. *Fail: any step faked, stubbed silently, or done by hand.*
- [ ] **GATE — Stage 2 decision.** Nathan reviews M0–M5 measurements and decides: freestanding PoeTchi NG on this silicon, or Kernoid-on-mainline is the product. *First bare-metal boot, if it ever happens, is Nathan's to witness.*

## 6. DECISIONS (Nathan's — the design does not guess these)

1. **Base strategy:** DECIDED 2026-10-30 — staged, and Stage 1's Linux is **our own mainline tree** (upstream + our config + the kernoid patchset), not ROCKNIX's kernel. The freestanding question waits at the Stage 2 gate, unchanged.
2. **Build host:** the laptop (Windows + WSL2 or a Linux partition) vs this VM with a userspace aarch64 toolchain installed under `~/workspace`. (No cross toolchain exists on this VM today — standing gap, noted honestly.)
3. **Userspace for Stage 1:** ROCKNIX's own rootfs as the dev host (fast start, games included) vs a minimal custom rootfs from the beginning (cleaner, slower start).
4. **First peripheral:** display-first (the face, M4 early) vs serial/SSH-first (the organs, screen later).

## 7. RISKS, STATED PLAINLY

- **Panel init** is the classic Qualcomm-handheld swamp, and it is now *our* swamp: our tree needs the Air X's panel in its DT. Mainline has the MDSS/DPU; ROCKNIX's DT is the reference map — M0 tells us what we're actually holding.
- **The ABL's kernel format** (image type, DTB handling, size limits) constrains M1 packaging — learned at M0/M1, not before.
- **WiFi firmware** may need blobs extracted from the stock Android — legal for his own device, and the run sheet's backup discipline covers the ABL; a full stock backup at M0 is cheap insurance.
- **Coupling creep** (§0.5) is the slow risk: every shortcut that hard-codes this device makes the next Port a rewrite. The grep test is cheap; run it at every milestone.
- **4 GB RAM** is the lab's ceiling: the crew is small and fixed-buffer by design, so this is a constraint we already live by, not a new threat.

---
*Sources: ROCKNIX Air X device page (kernel/drivers/boot flow); upstream SM6115 DTS activity through 2026 (MDSS, GPU, Venus); PoeTchi v1.0 freeze record (BUILD-CARD-v1.0) for the agent topology and laws.*
