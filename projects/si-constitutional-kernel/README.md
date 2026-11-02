# SI KERNEL — the shared constitutional runtime

One source of law for every lens (Onion, Rose, and any future shell).

`si-kernel.js` is the only place the constitution is implemented: the five
services (Identity · Capability · Proposal · State · Receipt), the decision
machine, the hash-chained ledger, the forces formulas, and constitutional
health. It renders nothing, imports nothing, and knows nothing about
geometry, worlds, languages, or sensors — hosts inject those as data
(agent manifests, legal transitions) at construction.

## The contract

- `new Kernel({ agents: [{id, name, capabilities[]}], legal: [[from,to],...] })`
- `K.propose(input)` — the router. Unknown fields are stripped and reported;
  a proposal is a typed object or it is nothing.
- `K.next(proposal, eta)` — advances one constitutional decision and returns
  its event: `identity · schema · capability · veto · state · held ·
  executed · sealed`. The lens animates events; the kernel decides them.
- `K.approve(id)` / `K.deny(id)` — operator acts; the only source of
  authority in the system (D7).
- `K.forcesFor(p, eta)` — momentum / opposition / net from the published
  formulas (roadmap P2.8). Forces govern the trajectory; law governs the
  outcome. There is no execution probability anywhere in this file.
- `K.health()` — one real ratio per primitive; Receipt is chain truth.
- `K.ledger` — entries `{seq, agent, kind, event, cls, prev, hash}`,
  `hash = fnv1a(prev|agent|event)`, genesis prev `genesis0`. This format is
  canonical: two independent suites recompute it from outside the page.

## How lenses consume it

Deliverables stay single self-contained HTML files, so the kernel is
**inlined at build time**, never hand-copied:

```
node build.mjs ../unified-core/index.html ../flower-lens/index.html
```

`build.mjs` strips the `export` keywords, splices the source between the
`SI KERNEL` markers in each lens, and verifies the inlined body's sha256
matches the source's. If they ever differ, the build refuses. Edit the law
here, rebuild, and every lens moves together.

## Tests

```
node test-kernel.mjs   # 18 checks: lifecycle, veto, illegal transition,
                       # hold/approve/deny, smuggle strip, forces formula,
                       # health ratios, ledger tamper/restore
```

The lenses carry their own browser batteries on top (stage geometry,
crossings, sky==ledger invariant, Kuramoto recomputation, tamper tests
against the live ledger).
