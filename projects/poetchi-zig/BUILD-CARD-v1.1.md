# PoeTchi — BUILD CARD v1.1 (transforms unification)

2026-10-31 · Nathan's order: "improve and then upload my full zig kernel to
google drive." v1.0 stays frozen as a release; v1.1 is a behavior-preserving
source improvement on top of it, proven below. The boot banner still reads
PoeTchi v1.0 — behavior is v1.0's; only the source is cleaner and truer.

## The improvement

**Transforms unification** — the last open refactor from the 2026-10-19
list. `mesh.zig` and `wells.zig` each carried an identical hand-rolled
`project()` with 4-decimal trig literals (0.8776, 0.4794, 0.9394, 0.3429).
Both now call one shared projection:

- `pyre.zig` gains `Mat4.rot_x` (same column-major pattern as `rot_y`) and
  the shared orbit projection: `ORBIT_VIEW = rot_x(0.35) · rot_y(0.5)` +
  `project_orbit()` — real `@cos`/`@sin`, one place to fix, no literals.
- `mesh.zig` / `wells.zig`: `project()` is now a one-line delegate to
  `pyre.project_orbit`. Call sites untouched.

## Proof

- **Full clean build**: `zig build` from an empty `zig-out` —
  `harakiri-ng` (1,816,720 B) + `harakiri-ng.bin` (531,200 B), zero errors.
- **New parity harness** `src/check_project.zig`: old formula vs the Mat4
  composition over 4,913 points × 3 scales = **19,652 checks, 0 fail**.
  Max rotated-coordinate deviation **0.000086** — exactly the old literals'
  rounding error, nothing else. Max screen deviation 1 px (an
  `@intFromFloat` truncation edge at the largest scale; individual dots
  only, visually indistinguishable, mathematically explained).
- **Host harnesses re-run after the change**: `check_reason` **24 pass,
  0 fail**; `check_bell` **13/13 green**; `check_neural` runs clean.
- **QEMU regression (`v10_regression.sh`, 16 checks): NOT re-run** — QEMU
  is not installed in this VM, and a claim needs the run. The refactor is
  confined to the viewport projection (no REPL, agent, net, or hand-code
  paths touched), and the freeze script stands ready on any QEMU machine:
  `./v10_regression.sh` against this tree. Recorded here as owed, not as
  passed.

## Still open (Nathan's calls, untouched)

- **Specular term** — Blinn-Phong direct vs neural-only: his decision,
  recorded 2026-10-19, still his.
- Kernoid OS (AIRX-DESIGN.md) remains design-complete and dormant; the
  device hunt is parked by his order.

## Archive

`poetchi-zig-kernel-v1.1.zip` — the full tree (src incl. the new harness,
boot, build.zig, roadmaps, both build cards, regression script, fresh
binaries), excluding `.zig-cache` and `__pycache__`. Uploaded to Google
Drive (Harakiri Builds folder) 2026-10-31.
