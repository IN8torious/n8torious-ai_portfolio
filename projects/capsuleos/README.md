# CapsuleOS — in the portfolio

CapsuleOS is the Capsule Toolbox's AME Wizard playbook, and it has its
own repository: **[IN8torious/CapsuleOS](https://github.com/IN8torious/CapsuleOS)** —
the verified `.apbx` ships there as a release asset.

This folder carries the same record for the portfolio:

| Path | What it is |
|---|---|
| `playbook/` | The playbook source exactly as packaged: `playbook.conf`, `Configuration/` YAML (apply / revert / tasks), the fixed installer script, the internal manifest |
| `TOOLBOX.md` | The Capsule Toolbox — what it does, with honest Working / Prototype / Not verified labels |
| `MANIFEST.md` | The pre-release build record: file hashes and remaining gates |
| `VERIFICATION.md` | The independent audit: 27 checks, the BCJ2 container catch, and the byte-identical rebuild |

**Status:** pre-release 0.1.0. Verified statically and at the
container level; an AME Wizard load test of this exact build on a
target machine is still owed, and the bundled Toolbox setup is
unsigned.
