# N8TORIOUS AGENT TOOLBOX

**Build your own agent factory from working parts.**

This pack contains the complete agent system of N8torious AI: the crew
roster with a detail sheet for every agent, the constitutional kernel the
crew runs on, the Gate protocol that keeps a human in charge, the Pain
agent-system source, and the full machine-readable spec corpus (79 import
files). It is not a framework download. It is a working factory's parts,
laws, and blueprints, packaged so you can stand up your own.

## The one idea

An agent factory is a crew of small, independent agents with simple
contracts between them, governed by a constitution instead of a boss:

- **No central orchestrator.** Agents propose; they do not command.
- **Humans are sources of authority. Systems never are.** A system may
  only exercise capabilities a human delegated to it. (This is Law D7,
  and it is not negotiable inside the pack.)
- **Every action leaves a receipt.** The ledger is hash-chained and
  tamper-evident. If it isn't in the ledger, it didn't happen.
- **Refusal is absence.** A denied thing is not shown disabled or
  explained at length. It is simply not there.

## What's inside

| Path | What it is |
|---|---|
| `ROSTER.md` | Every agent in the system, one line each, core crew first |
| `agents/` | Detail sheets: what each agent does, its contract, its law |
| `factory/CONSTITUTION.md` | The five primitives and five invariants everything obeys |
| `factory/THE-GATE.md` | The proposal lifecycle: route → triage → guard → audit → approve → execute → receipt |
| `factory/FACTORY-BLUEPRINT.md` | Step-by-step: stand up your own factory from these parts |
| `factory/AGENT-TEMPLATE.md` | Blank agent spec — fill it in to mint a new agent |
| `factory/LEDGER.md` | The receipt format and hash chain, exactly as implemented |
| `assets/kernel/` | `si-kernel.js` — the constitutional runtime in code, with tests |
| `assets/pain-system/` | The Pain agent system (Python): resonance core, thought factory, synthesizer |
| `assets/corvus.c` | Corvus, the long-memory agent, as a C source |
| `assets/specs/` | The full spec corpus: 79 `import://` JSON specs + the master index |

## Quickstart

1. Read `factory/CONSTITUTION.md` (one page). Everything else follows it.
2. Load `assets/kernel/si-kernel.js` and run its tests
   (`assets/kernel/test-kernel.mjs`) to watch a proposal move through the
   decision machine.
3. Copy `factory/AGENT-TEMPLATE.md` and define your first four agents:
   a **router**, a **gate**, an **executor**, a **ledger-keeper**. Those
   four are a factory. Everything else is growth.
4. Wire them through the Gate protocol (`factory/THE-GATE.md`) and let
   the receipts accumulate.

## Provenance

Designed and built by Nathan Brown / N8torious AI (Akron, Ohio) across
the Star System, Harakiri, and Raijin lines of work, 2026. The crew
names, laws, and specs are his. See `LICENSE.md` for use terms.
