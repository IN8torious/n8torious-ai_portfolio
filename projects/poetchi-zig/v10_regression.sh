#!/bin/bash
# Harakiri NG v1.0 freeze regression.
# Boots the kernel in QEMU, runs every REPL command once, extracts the
# hand-typed code and compiles it. A failure anywhere fails the freeze.
set -u
cd "$(dirname "$0")"
ZIG="$HOME/workspace/tools/zig-linux-x86_64-0.14.0/zig"
BIN="zig-out/bin/harakiri-ng.bin"
LOG="/tmp/v10_regression.log"

{
echo "about"; sleep 0.5
echo "agents"; sleep 0.5
echo "tasks"; sleep 0.5
echo "tick"; sleep 0.5
echo "watchdog"; sleep 0.5
echo "reason the tasks queues for the cpu"; sleep 0.5
echo "reason xyzzy plugh"; sleep 0.5
echo "route the ore heated by the fire melts into alloy"; sleep 0.5
echo "gate 900 500"; sleep 0.5
echo "gate 250 500"; sleep 0.5
echo "merlin the ore heated by the fire melts into alloy"; sleep 0.5
echo "paintr judge the supplicant queues for the rope"; sleep 0.5
echo "veda audit the tasks queues for the cpu"; sleep 0.5
echo "hand code the supplicant queues for the rope judged by the list"; sleep 0.5
for i in $(seq 1 80); do echo "tick"; sleep 0.05; done
echo "hand"; sleep 0.5
echo "hand out"; sleep 1
echo "net probe"; sleep 1
echo "net tx"; sleep 6
echo "kraken focus 3"; sleep 0.5
echo "kraken"; sleep 0.5
} | timeout 120 qemu-system-aarch64 -M virt -cpu cortex-a57 -m 128M -nographic -kernel "$BIN" -global virtio-mmio.force-legacy=false -global virtio-mmio.ioeventfd=false -netdev user,id=n0 -device virtio-net-device,netdev=n0 2>/dev/null > "$LOG"

echo "== transcript: $(wc -l < "$LOG") lines =="
checks=0; fails=0
expect() { # $1 = grep pattern, $2 = label
  checks=$((checks+1))
  if grep -q -- "$1" "$LOG"; then echo "PASS: $2";
  else echo "FAIL: $2"; fails=$((fails+1)); fi
}
expect "PoeTchi v1.0" "boot banner v1.0"
expect "watchdog holds" "watchdog demo"
expect "domain: bouncer" "reason bouncer"
expect "ABSTAIN" "reason abstain"
expect "vera: routed to" "vera route"
expect "verdict: ENTER" "gate enter"
expect "verdict: ABSENT" "gate absent"
expect "merlin:" "merlin plans"
expect "paintr:" "paintr judges"
expect "veda: audit" "veda audits"
expect "typing" "hand typing status"
expect "--- hand code begin ---" "hand code dump"
expect "virtio-net up" "net probe"
expect "TX complete" "net tx"
expect "law: power(path_k)" "kraken focus law"

# the hand's typed code must compile: extract and build it
awk '/--- hand code begin ---/{f=1;next}/--- hand code end ---/{f=0}f' "$LOG" > /tmp/hand_code.zig
if [ -s /tmp/hand_code.zig ]; then
  if "$ZIG" test /tmp/hand_code.zig 2>&1 | tail -2; then
    checks=$((checks+1)); echo "PASS: hand-typed code compiles and passes"
  else
    checks=$((checks+1)); fails=$((fails+1)); echo "FAIL: hand-typed code does not compile"
  fi
else
  checks=$((checks+1)); fails=$((fails+1)); echo "FAIL: no code extracted"
fi

echo "== $checks checks, $fails failures =="
exit $fails
