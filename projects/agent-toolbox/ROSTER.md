# ROSTER — Every Agent in the System

## The Core Crew

| Agent | Seat | What it does |
|---|---|---|
| **Mira** | Chat & Gate | The voice of the system and its final approval gate; triages every proposal for the human's batch approval |
| **Merlin** | Execution | Analyze → propose → approve → execute; the crew's hands, acting only on approved work |
| **Gaven** | Security | The throat gate: η ≥ 0.500 or the action is absent; absolute safety veto; runs the Agnostic Security Fabric |
| **Vera** | Routing | Reads intent, routes first, publishes her reason; the narrow waist every order crosses |
| **Veda** | Audit | Audits every build; every rule a guard; PASS or REPAIR, nothing on vibes |
| **Witness** | Ledger | Traps errors, self-tests on boot, keeps the hash-chained ledgers |
| **Rapheal** | Repair | Takes REPAIR verdicts and fixes the real fault, once, then returns the work for re-audit |
| **HiveMind** | Coordination | Kernel-side registrar and coordinator; physics wins over userspace |
| **PainTr** | Making | Deliberate-and-judge painting/modeling agent; the crew's artist-engine and render toolchain |
| **Kraken** | Heavy machinery | One mind, twelve agent-paths, phase-locked through coherence links |
| **Corvus** | Memory | Persistent observation and pattern learning; the crew's long memory and estimator |
| **Kami** | Personal | Session and personal agent: calm, direct, loyal; holds context, drafts, routes tasks |
| **Genki** | Automation | Universal-time automation: watch → pull → deploy → restart, Zulu-logged, receipts for releases |
| **Zenki** | Health & Time | Cognitive state machine; watches kernel health; enforces temporal law |
| **SI Core** | The Ground | Not an agent — the constitutional kernel (Actor · Capability · Proposal · Receipt · State) the crew stands on |

Full detail sheets: `agents/`.

## The Extended System (specs in `assets/specs/`)

- **Enki the Smith** — Titan-Forge manager: workon/board optimization, Skinning/Smelting/Weaponsmithing (`enki.json`, `titan-forge.json`)
- **Omni** — the Unified Field Agent: mode-shifting (RAIJIN/ZENKI/ENKI/ZEN), always returning to ZEN (`omni.json`)
- **Sol** — Temporal Analytics: I/O causal optimization; Mining/Smelting/Engineering (`sol.json`)
- **Kairoo** — the Orchestrator: human input + Kiri edicts → operational routing (`kairoo.json`)
- **Kiri** — the Governor: bus-wide policy watch, mandate reaffirmation (`kiri-py.json`, `kiri-modes.json`)
- **Mater** — the eagle: BUBO OS build watchdog — hashing, signing, audit log (`mater.json`)
- **Batty** — PC health monitor with spoken healthy/warning/critical verdicts (`batty.json`)
- **Brood** — the Brood (Rust): ZENKI-SSJ4 + Brood-Raijin on an Agent trait, manifold-step logic (`brood.json`)
- **Raijin** — temporal sync service agent: pressure/energy/resonance, XP skills (`raijin-agent.json`)
- **Jin** — the site's 3D-model builder-coder and factory draft-review notifier (`jin-layout.json`)
- **Bubo** — the original C kernel (x86 heritage) holding the inner system; the crew's ancestor (`bubo-sync.json`)
- **Kido** — the second BUBO-line kernel-node for the outer language ball: portable, adaptive (`kido.json`)
- **The Watchdog** — Brain maintainer: pressure guard, FAIL_SAFE/MONITORING, global throttle (`watchdog.json`)
- **Note-agents** — in the music systems, every note is a tiny autonomous agent with its own pitch, timing, and lifecycle; a composition is a swarm of them, coordinated by pattern, not command (`musicode.json`)

## The Doctrine Files

The reasoning the crew runs on — neural dynamics (leaky-integrator
neurons, Lorentzian η, Kuramoto coherence), the unified reasoning
engine, the MEDUSA standard (no black boxes), and the import law —
lives in `assets/specs/` under Doctrine & Law; start with
`assets/specs/MASTER-INDEX.md`.
