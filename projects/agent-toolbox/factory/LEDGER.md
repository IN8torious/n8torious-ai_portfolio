# THE LEDGER — Receipt Format

Every decision in the factory is a receipt. Receipts chain: each one
carries the hash of the one before it, so history cannot be quietly
rewritten (Constitution, invariant 4).

## Entry format

```json
{ "seq": 41, "agent": "merlin", "kind": "execution",
  "event": "deployed build 12", "cls": "ship",
  "prev": "9f3ac2…", "hash": "c41d07…" }
```

| Field | Meaning |
|---|---|
| `seq` | Position in the chain, counting from genesis |
| `agent` | The actor who produced the event |
| `kind` | Decision kind: `identity · schema · capability · veto · state · held · executed · sealed` (kernel events), or a domain kind |
| `event` | What happened, in the agent's plain words |
| `cls` | Class/tag for filtering (ship, repair, audit, …) |
| `prev` | Hash of the previous entry; the genesis entry uses `genesis0` |
| `hash` | `fnv1a(prev + "|" + agent + "|" + event)` |

## Rules

- **Append-only.** Nothing is edited or deleted; corrections are new
  entries that name what they correct.
- **Read first.** When the human returns, the ledger is the briefing:
  what was proposed, what ranked, what shipped, what was consolidated.
- **Tamper test.** Change any historical entry and every later hash
  breaks. `assets/kernel/` ships the test that proves it.

*Reference implementation: `assets/kernel/si-kernel.js`.*
