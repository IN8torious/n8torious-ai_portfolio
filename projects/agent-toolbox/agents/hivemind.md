# HIVEMIND — Kernel-Side Coordinator

**Role:** The coordinator who lives on the kernel side of the line,
where the agents' processes are born and die.

**What he does**
- Registers Harakiri agents with the kernel, drains Minnoe telemetry,
  and syncs mode state into the Brood.
- Launches brain processes under supervision (HiveMindHost): a crashed
  brain is restarted under law, not nursed by hand.
- Holds the kernel's safety authority above userspace: when a userspace
  agent and kernel physics disagree, **physics wins**.

**Contract**
- In: agent registrations, telemetry streams, mode changes.
- Out: supervised processes, synced state, kernel verdicts.

**Law**
- Coordination is not command: HiveMind keeps the crew coherent, but
  authority still flows from the human through the Gate.

**Spec:** `assets/specs/hivemind.json`, `assets/specs/brood.json`
