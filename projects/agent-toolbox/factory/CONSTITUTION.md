# THE CONSTITUTION

One page of law that every agent, factory, and build in this pack obeys.

## The sentence

> **An Actor proposes a State change, using a Capability, producing a
> Receipt.**

## The five primitives

- **Actor** — anything that can propose: a human, an agent, a process.
- **Capability** — a specific, named permission to affect the world.
  Capabilities are held, delegated, and revoked; they are never implied.
- **Proposal** — a typed request to change State using a Capability.
  A proposal is a typed object, or it is nothing.
- **Receipt** — the immutable record that a decision happened.
- **State** — the world as it is, changed only through this machine.

## The law above all laws (D7)

> **Humans are sources of authority. Systems are never sources of
> authority. Systems may only exercise delegated capabilities.**

## The five invariants

1. **Identity cannot mint capability.** Being someone — even being the
   system itself — grants nothing.
2. **Capability cannot forge receipt.** Holding a permission does not
   let you write history.
3. **Receipt cannot modify state.** The record of a thing is not the
   thing; the ledger never reaches back into the world.
4. **State cannot rewrite receipt.** What happened stays happened;
   the chain is tamper-evident (and the kernel proves it with a tamper
   test you can run).
5. **Systems cannot originate authority.** (= D7, restated as an
   invariant because everything depends on it.)

## The five services

Identity · Capability · Proposal · State · Receipt. A kernel that
implements exactly these five, and nothing else, can host any crew in
this pack. Hosts are pluggable. The constitution stays.

## Field law (notes and forces)

Objects inside the core may exert *influence* — mass counted from their
receipts, force counted from formulas. Influence moves trajectories
only. It never executes, vetoes, or approves. There is no Authority
Note: a note cannot create an approval path. That refusal is D7 applied
to the field, and it is permanent.

*Implementation: `assets/kernel/si-kernel.js` — run its tests.*
