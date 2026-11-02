#!/usr/bin/env python3
"""Run the Harakiri NG kernel under QEMU on your laptop.
Pure stdlib — needs only python3 and qemu-system-aarch64 installed.

Usage:
  python3 run_harakiri.py            boot, run the demo scene, save desktop.bmp
  python3 run_harakiri.py --shell    interactive kernel REPL (Ctrl+C quits)

Install QEMU first (Pengwin/WSL):
  sudo apt update && sudo apt install -y qemu-system-arm
"""
import os
import struct
import subprocess
import sys

BIN = "harakiri-ng.bin"
W, H = 1280, 720
MARKER = b"P6\n1280 720\n255\n"


def save_bmp(raw, path):
    """W*H*3 raw RGB bytes -> 24-bit BMP (opens natively on Windows)."""
    row = W * 3
    pad = (4 - row % 4) % 4
    px = bytearray()
    for y in range(H - 1, -1, -1):
        off = y * row
        r = raw[off:off + row]
        bgr = bytearray(row)
        bgr[0::3] = r[2::3]
        bgr[1::3] = r[1::3]
        bgr[2::3] = r[0::3]
        px += bgr + b"\x00" * pad
    hdr = struct.pack("<2sIHHI", b"BM", 54 + len(px), 0, 0, 54)
    dib = struct.pack("<IiiHHIIiiII", 40, W, H, 1, 24, 0, len(px), 0, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(hdr + dib + px)


def qemu_cmd():
    return ["qemu-system-aarch64", "-M", "virt", "-cpu", "cortex-a72",
            "-kernel", BIN, "-serial", "stdio", "-display", "none"]


def demo():
    cmds = ["tick"] * 25 + ["point 1216 452", "grab"] + ["tick"] * 5 + ["desktop"]
    try:
        p = subprocess.run(qemu_cmd(), input=("\n".join(cmds) + "\n").encode(),
                           capture_output=True, timeout=180)
    except FileNotFoundError:
        print("qemu-system-aarch64 not found. Install it:")
        print("  sudo apt update && sudo apt install -y qemu-system-arm")
        sys.exit(1)
    data = p.stdout
    i = data.find(MARKER)
    if i < 0:
        print("No frame captured. Kernel said:")
        print(data[:600].decode("utf-8", "replace"))
        sys.exit(1)
    px = data[i + len(MARKER):i + len(MARKER) + W * H * 3]
    save_bmp(px, "desktop.bmp")
    print("Saved desktop.bmp — open it and behold.")


def shell():
    try:
        os.execvp("qemu-system-aarch64", qemu_cmd())
    except FileNotFoundError:
        print("qemu-system-aarch64 not found. Install it:")
        print("  sudo apt update && sudo apt install -y qemu-system-arm")
        sys.exit(1)


if __name__ == "__main__":
    if not os.path.exists(BIN):
        print(f"Put {BIN} in this folder first (grab it from Drive: Harakiri Builds).")
        sys.exit(1)
    if "--shell" in sys.argv:
        shell()
    else:
        demo()
