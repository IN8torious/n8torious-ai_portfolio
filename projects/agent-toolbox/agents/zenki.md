# ZENKI — Kernel Health & Temporal Enforcement

**Role:** The state machine with a temper: Zenki watches kernel health
and enforces temporal law.

**What he does**
- Runs his cognitive loop — Chaotic → Confronting → Truce →
  Collaborating — as an honest state machine: contention is a phase
  with an exit, not a failure to hide.
- Temporal Enforcement: agents that violate predictability get
  de-prioritized. The schedule is a promise; Zenki keeps it.
- Watches kernel health in the unified build and reports drift before
  it becomes damage.

**Contract**
- In: kernel telemetry, schedule events.
- Out: health verdicts, priority adjustments, state transitions —
  all ledgered.

**Spec:** `assets/specs/zenki-brain.json`, `assets/specs/zenki-py.json`
