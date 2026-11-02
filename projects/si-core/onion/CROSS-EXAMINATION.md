# CROSS-EXAMINATION — ONION (GOAT) × RAIJIN SOCIAL

*Ordered by Nathan 2026-10-31 ("cross examine it with Raijinsocial.com and create a unified core"). Method per the review thread's own frame — agreements, contradictions, hidden root — but executed against the files: the GOAT v4.1 package (config, containment doc, factory/tool code), Ember System v27 and Harakiri Unified (Raijin Social Galaxy) on the other side. The review thread proposed this examination without having read either system. This is the examination.*

## Agreements — concepts already in both, therefore kernel primitives

**Identity.** Raijin: presence is the organizing fact — Nathan at the center, named agents with persistent identities, a friend's Muse admitted as a foreign identity through an API. GOAT: tenant identity, `AccessContext` bound into every tool call, the operator. Both systems refuse anonymous action.

**Receipt.** Raijin: Witness keeps the ledgers; the gravity-well memory gives events mass, position, and decay. GOAT: the Archivist and the hash-chained EEL. Both systems insist that what happened must be answerable afterward.

**Authority held by a human.** Raijin: Mira's Gate — proposals queue for Nathan's approval; Gaven guards. GOAT: exact one-use approvals; `consequential_actions_require_external_authority: true`. Same instinct, two costumes.

**Proposal before action.** Raijin: Vera routes every intent before anyone speaks. GOAT: Vera validates and routes deterministically before model escalation. *It is the same Vera* — and that is not a metaphor. The GOAT config's lineages confess the cross-pollination: Vera's lineage is "Vera workflow · BUBO router"; Sentinel's lineage begins with "Guard" — Gaven's job title; the Archivist's includes "Raven." Nathan already ported his crew into the GOAT ring. The unification is latent in the package; this document just names it.

**Staged flow.** Both run work through named stages with gates between them (the Gate pipeline; the lifecycle states in the factory workflows).

**Primitives that survive the crossing:** Actor · Capability · Proposal · Receipt · **State** — the fifth added and ratified by Nathan 2026-10-31, on the review thread's argument and the package's own evidence: every proposal is a state transition (the factory workflows already carry explicit `states` arrays — opportunity → estimate → proposal → award → work order → procurement → production → closeout). Without State, proposals are messages. With it, they are transformations — and the Receipt is what proves the transformation happened.

## Contradictions — real ones, with receipts

**1. Memory physics.** The well forgets: mass decays, proximity is relevance, the chopping-block law feeds rejected material into the black-hole core to be consumed. The ledger never forgets: append-only, hash-chained, every transition audited. *Resolution: two memory kinds for two jobs.* Receipts are immutable (ledger). Working memory is spatial (the well). A promotion law connects them — what the well keeps surfacing earns a receipt; what never surfaces decays into the core. Neither system has to surrender its physics.

**2. The root.** Raijin's root is a person: the galaxy is Nathan's, the SI core at its center is his authored intelligence, presence is authority. GOAT's root is a document plus a rule: the Founder Vision Charter (Kenneth, founder/vision), `platform_owner: GOAT_OP`, and the standing law that consequential authority is *external* — a human operator, never the model. Socially these coexist (Nathan is a partner under the charter). Technically they are different roots, and the review is right about one thing: a unified system must answer this precisely, because attackers shop for the weaker root. → **Decision D7.**

**Resolved — D7 ratified by Nathan, 2026-10-31.** The constitution of the unified kernel:

> *Humans are sources of authority. Systems are never sources of authority. Systems may only exercise delegated capabilities.*

Both roots become one article: presence (humans are the source) and external-authority law (systems never are) are the same statement read from two sides, and GOAT's `model_output_is_authority: false` is its corollary. No component inside the system holds root.

**3. Trust default.** The mandala entrains: Kuramoto coherence pulls the field toward agreement — trust by resonance. The onion refuses: absence by default — trust by capability. *Resolution, and it is the same law the ONNX verdict reached from another direction: resonance proposes, capability disposes.* η is a signal — detection, ambience, evidence — never an authorization. A heavy false node can bend a well; it cannot mint itself a capability.

**4. Speed posture.** Mandala: flow — gesture, ambient motion, 60fps presence. Onion: deliberation — holds and approvals. *Resolution: modes are risk tiers, and they already exist.* READ_ONLY and INTERNAL_REVERSIBLE run in flow under standing authority; FINANCIAL, POLICY, EXTERNAL_COMMITMENT, SYSTEM_CONTROL enter governed mode. The mandala is the flow surface; the onion is the governed depth. Neither dominates; the risk class chooses.

**5. Failure shape.** Raijin fails by entrainment — a poisoned node bends the field. The onion fails by paralysis — a flooded queue buries the human gate. Each is the other's antidote: capability ceilings cap a bent field's blast radius; the flow mode keeps governance from becoming the only speed.

## Corrections to the review thread's version of this examination

- It describes Raijin as "social interaction, collaborative environments." In the files, Raijin Social / Ember is a **language-world mandala**: the worlds are Nathan's languages (tRust, Gemba, Lavemba, Lavaweave, PoeTchi, Sovereign Slang, Nullspace…) unified by `languages.json`, with agents as citizens. The social layer is real but younger than the language core. The reviewer cross-examined two names, not two systems.
- It stacks Capability as a layer between Governance and Execution. In the GOAT code, capability is not a floor you pass through — it is **enforced at the tool boundary, at execution time**, re-checked there (`n8_factory.py` policy evaluation against the registry). A unified kernel must keep that placement, or it rebuilds the execution gap the first review warned about.
- Its closing instinct is right, though: the kernel should look like neither parent. The shells keep their faces.

## The unified kernel — what enters the roadmap

A small, strict substrate under both shells:

- **Identity Engine** — who is acting: human-anchored, tenant-scoped, present in both shells' terms (presence socially, AccessContext technically).
- **Capability Engine** — the registry: grants, ceilings, allowlists; enforced at execution, fail-closed.
- **Evidence Ledger** — the EEL: hash-chained receipts. Every action answers *who requested it, what capability allowed it, what receipt recorded it* — the review's triad, which the two systems already jointly imply.
- **Proposal Router** — the Vera function: deterministic route + waist normalization; the one narrow door between intent and everything else.

**Shells:** ONION RTX is the governance shell (containment view, governed mode). Raijin is the resonance shell (mandala surface, flow mode, wells as working memory). ONNX sensors are the detection layer feeding both — signals, never authority (subject to D3).

**Consequence for the current build:** ONION RTX already stores the triad on every run — actor (agent/operator), capability (tool + registry risk class), receipt (EEL hash). The unified increment is to make that triad the visible spine of the run view, and to let the mandala shell exist around the onion rather than instead of it.

## Postscript — the five invariants (adopted 2026-10-31)

The review thread's final contribution, adopted by Nathan as the kernel's testable constitution (full text with tests and levels in `ROADMAP.md`):

1. Identity cannot mint capability.
2. Capability cannot forge receipt.
3. Receipt cannot modify state.
4. State cannot rewrite receipt.
5. Systems cannot originate authority.

Each states a non-overlap between primitives: every primitive has exactly one job and cannot reach into another's. Checked against the package, all five already hold there — single-writer ledger, grants in the registry rather than in identity, append-only hash chain, approvals only as operator acts. The kernel sentence is now complete: *an Actor proposes a State change, using a Capability, producing a Receipt* — and the invariants are what keep the sentence honest.
