# FACTORY BLUEPRINT — Build Your Own Agent Factory

A factory is a crew + a constitution + a gate + a ledger. Build it in
this order; each step is small and testable before the next begins.

## Step 0 — Adopt the constitution

Copy `CONSTITUTION.md` into your project and mean it. Especially D7:
the human is the source of authority. If your design needs a system to
originate authority "just this once," the design is wrong, not the law.

## Step 1 — Stand up the kernel

`assets/kernel/si-kernel.js` is a complete constitutional runtime:
five services, a decision machine, a hash-chained ledger, and a test
suite that includes a tamper test (invariant 4, proven in code).
Run the tests before you change a line:

```
node assets/kernel/test-kernel.mjs
```

Your crew registers as agent manifests: `{ id, name, capabilities[] }`,
plus the legal state transitions for your domain.

## Step 2 — Mint the first four agents

A factory needs exactly four roles to be a factory. Use
`AGENT-TEMPLATE.md` and the sheets in `agents/` as worked examples:

1. **Router** (Vera's seat) — classifies intent, publishes reasons,
   holds no other capability.
2. **Gate** (Mira's seat) — triages proposals, queues for the human,
   speaks the answers.
3. **Executor** (Merlin's seat) — analyze → propose → approve →
   execute; never self-approves.
4. **Ledger-keeper** (Witness's seat) — append-only receipts,
   hash-chained (`LEDGER.md`).

## Step 3 — Add the guards before you add power

In this order, as your factory earns them:

5. **Sentinel** (Gaven's seat) — the η gate; refusal as absence;
   absolute safety veto.
6. **Auditor** (Veda's seat) — falsifiable checks only; PASS/REPAIR.
7. **Repair hand** (Rapheal's seat) — fixes what the auditor flags.
8. **Memory** (Corvus's seat) — patterns over the ledger; the factory
   starts getting smarter.

Then grow by need: a coordinator (HiveMind), a maker (PainTr), a
consolidated heavy lifter (Kraken), personal/session agents (Kami),
automation (Genki), health & time (Zenki).

## Step 4 — Run the loop

Wire every agent through the Gate protocol (`THE-GATE.md`). Deliberate
design decisions as a micro-agent circle — positions, challenges,
convergence, preserved dissent — and save the record. Queues wait
silently; the human batch-approves; receipts accumulate.

## Working standards (learned the hard way, included free)

- **Loud stubs.** A stub announces itself as a stub. Silent fakes are
  how factories rot.
- **A test that cannot fail is a painting, not a test.**
- **Real math or no claim.** If a number is on the tin, the equation is
  in the box.
- **One file, one build line.** No parallel variants drifting apart.
- **Polish ships with the feature.** "Later" is where quality goes to
  die.
