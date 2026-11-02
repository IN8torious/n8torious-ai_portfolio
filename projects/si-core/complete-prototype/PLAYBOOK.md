# SI CORE — PLAYBOOK BUNDLE

Packed 2026-10-31 by Nathan's order: *"zip it with my agent schematics and
agents — this is going directly into a playbook."*

This bundle is the complete SI Core system as it stands tonight: the build,
the law it runs on, the schematics it was derived from, the agents that crew
it, and the source material it reuses. Drop it into the playbook as one unit.

## Contents

| Path | What it is |
|---|---|
| `index.html` | **SI CORE · COMPLETE** — the build. The Ball (geodesic lattice, five primitive nodes, ten language worlds) + gaze readouts + free orbit on gaze + agent motes + musicode individuals + field notes under P2.8-A. One file, no dependencies beyond CDN libraries. |
| `kernel/si-kernel.js` | The shared kernel — the one source of law every lens inlines (Identity · Capability · Proposal · State · Receipt). |
| `kernel/test-kernel.mjs` | The kernel's node proofs. |
| `build/` | How `index.html` is composed: `assemble.py` (extracts the verified Ball sections, inserts the layers) + `layers.js` (braille helix, musicode, gold dust, furnace embers), `freeorbit.js` (agent motes, free orbit on gaze, pinch-owns-radius), `music.js` (music on hover), `field.js` (field notes, P2.8-A host counting), `sources-card.html`. |
| `schematics/ROADMAP.md` | The master roadmap — constitution, invariants, force law (P2.8 + the P2.8-A field-notes amendment), phases, open decisions. |
| `schematics/ROADMAP-PROTOTYPE.md` | The complete prototype's own goal posts (G0–G7). |
| `schematics/CROSS-EXAMINATION-UNIFIED.md` | The GOAT onion × Raijin cross-examination that defined the unified kernel. |
| `schematics/CROSS-EXAMINATION-PROTOTYPE.md` | Cross-examination II — the six reuse sources examined against the canonical Raijin build; what was adopted, mapped, and refused. |
| `schematics/n8_factory_config.json` | The factory schematic: eight agents with names, authority, purpose, lineage — verbatim from the GOAT Core v4.1 variation. |
| `agents/crew-manifest.json` | The kernel crew as shipped in the build (extracted verbatim from AGENT_DEFS at pack time): ids, names, capability grants. |
| `agents/prodigy/` | The complete GOAT Core v4.1 "Prodigy" source tree (182 files) — the agents' runtime, docs, and the Founder Vision Charter, **untouched** (charter md5 f9efba2449e7e5e6c32334a8e1d7580b; Kenneth Monday retains founder/vision authority; Nathan holds partner engineering authority; this is an engineering variation, not an official GOAT/OP release). |
| `sources/` | The six reuse sources, original filenames: component-description CSV, braille-helix, altaminac (musicode), alchemy (Truth Engine), darctix-core, thesis (Physics of Emotional Weight). |

## The law (from the roadmap, verbatim in force)

- Kernel sentence: *an Actor proposes a State change, using a Capability,
  producing a Receipt.*
- **D7:** Humans are sources of authority. Systems are never sources of
  authority. Systems may only exercise delegated capabilities.
- Five invariants: (1) Identity cannot mint capability. (2) Capability cannot
  forge receipt. (3) Receipt cannot modify state. (4) State cannot rewrite
  receipt. (5) Systems cannot originate authority.
- Forces govern trajectory, law governs outcome. Every force is a countable
  formula. P2.8-A: field notes exert real force — mass = receipts authored by
  lineage, radius = 2.2 + 0.25 × mass, host counts, kernel adds; Observation +
  Creative push, Contradiction drags, Receipt anchors. An Authority Note is
  refused: no artifact creates an approval path.

## Apply

1. Serve or open `index.html` — the whole system is the one file.
2. The kernel is inlined and hash-identical across lenses; to amend the law,
   edit `kernel/si-kernel.js`, run `kernel/test-kernel.mjs`, re-inline.
3. To rebuild the prototype from parts: `python3 build/assemble.py` beside
   the Ball source, then re-earn the proofs (nothing is inherited).

## Proof status at pack time (honest)

- Kernel node tests: **ALL PASS** (24 checks incl. the P2.8-A field terms and
  the no-field regression).
- Ball lens on the amended kernel: battery **ALL PASS** (36 checks).
- Unified (Onion) lens: hard-math **25/25 PASS**. Its UI battery stalled on
  the first run in the latest pass — file diff proves the kernel amendment is
  not the cause (nothing outside `forcesFor` changed; the Onion never calls
  it); a live diagnostic is running and the package re-issues if it finds a
  build fault.
- Complete prototype battery: field live-fire proven (a real run's kernel
  parts carried field push). The final confirmation run — including the
  pinch-owns-radius proofs for the mobile zoom fix Nathan reported from his
  Edge — was in flight at pack time; verdict follows this package, and the
  package re-issues if any check fails.
- Device verdicts remain Nathan's: audibility of the notes, pinch feel, and
  the polished look on the Edge OLED.
