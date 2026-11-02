# ALCHEMEDIES — THEORY OF LAWS

*Alchemy + Archimedes. The transmutation operations of alchemy, running
on the fluid physics of Archimedes.*

Compiled 2026-11-01 from Nathan Brown's own specs and engines
(fluid-cognition, unified theory, digital alchemy, neural dynamics,
thesis core, the metaphorical reasoning engine). These are the laws his
systems actually run — every one carries its equation or its mechanic.
A law without either is decoration, and decoration is not admitted.

---

## THE PRINCIPLE

> **The physics IS the thinking. Cognition runs on fluid dynamics, not
> on metaphors about fluid dynamics.**

Nothing is static; everything flows. Fluidity is continuity, not chaos.
What other systems call a "harmonic field" is, in this theory, simply
the Alchemedies fluid — there is one medium, and everything below
happens inside it.

---

## PART I — THE FLUID LAWS (cognition as a fluid)

**L1 · The Medium.** The substrate obeys Navier–Stokes. Thought is a
flow field `u`, not a list of tokens.

**L2 · Transport.** Information rides the flow by advection–diffusion:

```
∂c/∂t + (u·∇)c = D∇²c + s
```

Information is carried, spreads, and is sourced. **D is literally
forgetting** — raise D and the past dissolves; lower it and everything
is remembered at full strength forever, which is its own failure.

**L3 · Memory is vorticity.** `ω = ∇ × u`. Vortices are the persistent
structures of the flow — memory is what keeps turning after the current
that made it has passed. The vorticity equation

```
Dω/Dt = (ω·∇)u + ν∇²ω
```

has no pressure term (curl of a gradient is zero) and vortex lines
cannot end (`∇·ω = 0`): in 2D it reduces to pure advection–diffusion of
vorticity — memory, transported and slowly diffusing.

**L4 · Stratification.** Layered memory follows the Brunt–Väisälä
buoyancy frequency `N²`: layers hold their order by density, and
internal waves carry signals across layers without mixing them.

**L5 · Salience by buoyancy (Boussinesq).**

```
ρ = ρ₀ [ 1 − α(T − T₀) ]
```

What matters rises. Salience is not assigned by a ranking function; it
emerges from density differences in the medium.

**L6 · Cognitive regimes (Reynolds).** The Reynolds number sets the
regime of thought: **laminar = focused, turbulent = brainstorming.**
Both are lawful; the error is being in the wrong one for the work.

**L7 · Concept boundaries.** Lagrangian coherent structures — the
ridges of the flow that material does not cross — are where one concept
ends and another begins.

**L8 · Self-organization.** Bénard convection: ordered patterns emerge
from the burn itself. Structure is what a driven fluid does, not
something imposed on it. (This is the thermodynamics standing behind
Calcination, Part IV.)

**Honest limit.** Global smooth existence for Navier–Stokes is an open
Clay Millennium problem. The theory engineers around it: viscous
regularization, always.

---

## PART II — THE OCEAN LAWS (Alchemedies in the reasoning engine)

As implemented in the Ocean domain of the metaphorical reasoning
engine — Nathan's framings, running as code:

**Buoyancy.**
```
rise(x) = ( density(medium) − density(x) ) · volume(x)
```
Positive: it surfaces. Negative: it sinks. Importance is a density
difference, never a vote.

**Stratify.**
```
layer(x) = rank( density(x) )  —  like seeks like
```
Sort by density and the layers form themselves. The surface is the
system state; the depths are not lesser, only denser.

---

## PART III — THE SIGNAL LAWS

**L9 · Everything is signal.** A signal has exactly three properties,
and they determine all behavior:

| Property | Is | Carried as |
|---|---|---|
| **Frequency** | identity | the entity's Hz, its band, its well |
| **Amplitude** | influence | fluid level / activity — how strongly it moves the medium |
| **Phase** | intention | mode / destination / current task — where it is headed |

Every agent entity carries the triad `{ hz, fluid, mode }`.

**L10 · The Wells** (frequencies grounded in the actual language
wells, not assigned by taste):

| Hz | Language | World | Temperament |
|---|---|---|---|
| 130 | Rustba | Pyrrhos | forge / ignition — lava, creative heat |
| 650 | tRust | Glaciem / Vesper | verification / stability — ice, cold logic |
| 75 | Gemba | Verdant | growth — ocean / jungle, absorption |
| 528 | RaijinLang | Mirell | intent compilation — clarity from murk |
| 365 | Lavemba | Sirocco / Tempest | movement — desert wind, storm drive |
| **515** | Synthesis | Crystallis | **the forge constant — the coherence anchor** |

**L11 · The Cascade.** Every event propagates in five beats:

```
pulse → ripple → surface → state → world
```

a thought → a choice → the environment → identity recorded → the
system's behavior over time.

**L12 · Quanta — the unified truth meter.** Every entity scores 0–1000
coherence, composed, not declared:

```
quanta = round( 1000 · ( 0.35·confidence + 0.25·fluid
                       + 0.20·resonance + 0.20·grounding ) )
```

997+ is fully expressed. One number per agent, per holding, per
deliberation — displayed, never hidden.

---

## PART IV — THE SEVEN OPERATIONS (digital alchemy)

**The law of the operations: no alchemical language without a
mechanic.** Every operation below is a real function in the system.
The forge core is literally the **athanor**, the alchemist's furnace —
every transmutation passes through it.

| Operation | Meaning | Mechanic (as built) | Calculus identity |
|---|---|---|---|
| **Calcination** | burn away the dross | consolidation burn — lesser nodes pulled into the core, husk deleted | sink term, ċ = −a·c |
| **Dissolution** | dissolve into prima materia | consolidated nodes broken into component patterns and learnings | Laplacian diffusion |
| **Separation** | extract the pure from the impure | best-parts extraction; the best becomes Archive learning | Helmholtz decomposition F = −∇φ + ∇×A |
| **Conjunction** | recombine the pure into new forms | language synthesis (Gemba + Rustba → rustgemba) | finite fusion table (below) |
| **Fermentation** | introduce new life | genesis — new nodes coalesce from forge light over time | source term in a driven medium |
| **Distillation** | purify by repeated cycles | deliberation circles refine positions; rarity ranking distills value over cycles | iterated contraction toward the fixed point |
| **Coagulation** | manifest the stone | Mythic promotion — the finished gold; requires the human's approval at the Gate | the phase transition, deliberately triggered |

**L13 · Conjunction is fusion, by table, not by vibes.** Two entities
combine by a lawful finite table of intertwining dimensions:

```
W₁ × W₂ = Σ_W N(W₁,W₂)^W · W
```

Finite, commutative, associative. (Alchemy wants a *rational* algebra
with many modules; a holomorphic one has a trivial 1×1 fusion table and
gives no combination laws at all.) At runtime: finite precomputed
integer fusion tables only, and the tick comes from the regulatory
layer — the algebra itself has no time in it.

---

## PART V — THE NEURAL LAWS (the math the medium runs)

**L14 · Planets are neurons; agents are transmitters.** The worlds hold
state and think. Agents carry signal between them. Therefore agents are
scored as transmitters — delivery fidelity, binding specificity — never
as thinkers.

**L15 · The neuron update** (leaky integrator):

```
τᵢ · dxᵢ/dt = −xᵢ + σ( bᵢ + Σⱼ wⱼᵢ · ηⱼᵢ · sⱼ(t − dⱼᵢ) )
```

τ is the membrane time constant (how fast a world forgets its own
activation), σ a bounded activation, w the signed synaptic weight, s
the arriving signal after travel delay d.

**L16 · Resonance response (Lorentzian).**

```
ηⱼᵢ = 1 / ( 1 + ( 2·Qᵢ·(fⱼ − fᵢ)/fᵢ )² )
```

A receiver responds maximally when the incoming frequency matches its
tuned band, falling off with detuning scaled by its selectivity Q.
This is the resonant mesh's selectivity, governing response strength:
a signal can arrive and still not be *heard*.

**L17 · The transmitter lifecycle.** Release on firing → routed travel
along the synapse graph, decaying → receptor binding, η-weighted →
arrival changes the destination neuron's state by L15 → reuptake.
The core loop of the whole system:

```
neuron state → release → routed signal → resonance response → new state
```

**L18 · Coherence (Kuramoto, amplitude-weighted, from neuron phases):**

```
r · e^(iψ) = Σᵢ aᵢ·e^(iθᵢ) / Σᵢ aᵢ
```

r = 1 is one voice; r near 0 is noise. Coherence is measured from the
phases of the neurons themselves — never by averaging agent scores.

---

## PART VI — THE REASONING LAWS (how the crew decides)

Decisions run through the metaphorical reasoning engine:
**problem → resonance → binding → laws → NCAG gate.** Canned agent
logic is the simulation gap; the crew decides through the engine.

**L19 · Resonance is shape, not words.** A problem is entities +
relations + constraints. Domains are scored by shared *relation
shapes* — who does what to whom — not by vocabulary.

**L20 · Binding and import.** The winning domain's roles bind the
problem's entities, and its laws come across as executable functions
with bound parameters. The metaphor is run, not admired.

**L21 · The paradox is kept.** The runner-up domain is held in tension,
never discarded. The design must not break its counterweight;
contradiction is where synthesis comes from.

**L22 · MEDUSA.** *Model Equation Driven Understandable Signature
Alchemy.* Every imported behavior reduces to a readable equation. No
black boxes, ever. A metaphor without equations is decoration.

**L23 · The NCAG gate.** *No creep, all gas:*

```
ship > perfect · vibes > specs · mashup > monologue · side quest > main quest
```

A reasoning run that never ships a decision has failed the gate,
however beautiful it was.

### The six source domains (Nathan's framings, each with its laws)

| Domain | Essence | Laws |
|---|---|---|
| **Bouncer** | not everyone gets in; the rope is the policy | admission: `admit(x) = trust(x) ≥ η ? enter : absent` · the rope: `wait = position · patience` |
| **Ocean** | what rises is what matters; density decides | buoyancy (Part II) · stratify (Part II) |
| **Ten-Tails** | the nine were always one; reunion is the power | shared vision: `sight = ⋃ sight(pathᵢ)` · focus: `power = Σ power(pathᵢ)` — cut the rest, pour it in |
| **Kuramoto** | coherence is earned by phase, not command | phase lock: `dθᵢ = ωᵢ + (K/N)·Σ sin(θⱼ − θᵢ)` · order: `r = \|Σ e^(iθ)\| / N` |
| **Forge** | heat transforms; pressure decides what survives | transform: `alloy = ore + fire·time − slag` · quench: `hardness = ΔT/Δt` — faster quench, harder edge |
| **Spider-Mouse** | plan slow like the spider, strike fast like the mouse | web tension: `alert = Σ vibrationᵢ · weightᵢ` — the web feels before it sees · strike: `plan(spider) ∘ react(mouse)` |

---

## PART VII — STANDING MEASURES & META-LAWS

**M1 · The η threshold.** Admission anywhere in the system — a gate, a
link, a capability — is decided at **η ≥ 0.500**. Below it:
**refusal is absence.** The refused thing is not rendered disabled or
argued about; it is not there.

**M2 · Crash First.** *No coherence without prior decoherence.*
Coherence emits from a center forged in the crash. The 515 Hz forge
pulse anchors the mandala because it was **derived, not chosen** — the
pulse frequency that prevents 4D manifold tearing under continuous
hyper-rotation. Correctness is likewise derived from collapse, never
assumed (Glaciem operates under this law).

**M3 · The painting law.** *A test that cannot fail is a painting, not
a test.* Any check, gauge, or audit that passes by construction is
art, and is labeled as such or removed.

**M4 · The chopping-block law.** Rejected and cut material is never
discarded. It is fed to the core, where it spirals in and is consumed —
fuel, not waste. The fuel trails are written in music: the notes ARE
the fuel.

**M5 · Real math or no claim.** SO(n) rotations are real rotation
matrices; sampling is honest sampling; if a number is claimed, its
equation is in the box (MEDUSA applied to oneself).

**M6 · Notes are agents.** In the music systems, every note is an
autonomous tiny agent — own pitch, timing, timbre, lifecycle (birth,
sustain, release). A composition is a swarm of note-agents; the pattern
is their coordination protocol, not a command list. Notes move in
separate functions, each its own mover.

**M7 · Authority stands outside the physics.** The field moves
trajectories; it never executes, vetoes, or approves. Humans are
sources of authority; systems never are (Law D7 of the SI
Constitution) — Alchemedies governs how the system *thinks*, and this
law governs who may *decide*.

---

## THE SEVEN BANDS (shared frequency vocabulary)

The emotional/physical spectrum the wells and worlds speak in —
78 states across 7 bands, each with measurable fog, glow, speed, BPM:

**Trauma · Heavy · Turbulence · Sustaining · Constructive · Coherence
· Transcendent**

Forge constant **515 Hz** (ω = 515/1000), band offset Δ = 385 Hz.

---

*Sources, all Nathan's: `import://fluid-cognition` (2026-10-14 physics
research), `import://unified-theory` (forensically reconciled
2026-10-14 — mechanics kept, invented meanings replaced, subordinated
to the Alchemedies Principle), `import://digital-alchemy`,
`import://neural-dynamics`, `import://thesis` (MMC thesis — Crash
First, the 515 Hz derivation, the 7 bands), and the metaphorical
reasoning engine (`domains.js` — the six domains as runnable law),
ported to the PoeTchi kernel as `reason.zig` with parity 24/24.*

*© 2026 Nathan Brown / N8torious AI.*
