# PoeTchi v1.0 — FROZEN

**Harakiri NG Zig kernel · 2026-10-19 · Status: ✅ SHIPPED**

## What shipped

- **Phase 9b — the rest of the crew decides.** `merlin <brief>` runs the Gordon loop (analyze → propose → approve → execute) through the metaphorical reasoning engine. `paintr judge <brief>` delivers forge verdicts. `veda audit <brief>` checks every brief against the winning domain's laws — PASS/FAIL with equations, nothing on vibes.
- **Phase 10 — virtio-net.** Modern virtio-mmio driver on QEMU's virt board: probe, feature negotiation (F_MAC + VERSION_1), split rx/tx virtqueues, MAC 52:54:00:12:34:56 from config. `net tx` sends a real broadcast ARP and verifies completion. Raw Ethernet only — no TCP/IP (that's its own project).
- **Phase 11 — hand code mode.** `hand code <brief>` reasons the brief, picks a generator by winning domain (6 templates), and types real Zig character-by-character as a tRust task. `hand out` dumps it; the extracted code compiles and its test passes on the host toolchain.
- **Boot banner → "PoeTchi v1.0 (Zig)"**, about → "Harakiri NG v1.0 (Zig)".

## The TX completion bug (the hard part)

TX transmits and QEMU completes the descriptor, but polling the used.idx in guest RAM never sees the update — QEMU's `MemoryRegionCache` writes aren't coherently visible to the guest CPU under TCG. Proven via QMP `x-query-virtio-queue-status`: QEMU's `used-idx` advances to 1 while guest RAM still reads 0. **Fix:** `tx_frame` polls the `INTERRUPT_STATUS` MMIO register (bit 0) instead of guest RAM — MMIO reads are always coherent. Documented in `src/net.zig`.

## Verified

- Full v1.0 regression (`v10_regression.sh`): **16/16 PASS** — banner, watchdog, reason (bouncer + abstain), route, gate ENTER + ABSENT, merlin, paintr, veda, hand typing + dump, net probe, net tx, kraken focus law, hand-typed code compiles + tests green.
- Parity harness `check_reason.zig`: 24/24 vs the JS metaphorical-reasoning engine.
- QEMU invocation for virtio-net: `-global virtio-mmio.force-legacy=false -global virtio-mmio.ioeventfd=false -netdev user,id=n0 -device virtio-net-device,netdev=n0`.

## Next

Kernel as the base for the **web GPU** (Pyre rasterizer + neural BRDF already compile to wasm32-wasi). Needs its own ROADMAP.md before code.
