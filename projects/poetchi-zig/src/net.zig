// PoeTchi — virtio-net driver (Phase 10)
// Raw Ethernet over virtio-mmio on QEMU's virt machine.
// No TCP/IP — that's its own project. This is the driver: device discovery,
// feature negotiation, virtqueues, TX with completion, RX buffers posted.
// MMU is off in this kernel, so static buffers are identity-mapped.
// Nathan Brown, 2026.

const std = @import("std");

// ---- virtio-mmio layout (QEMU virt: base 0x0a000000, stride 0x200, 32 slots) ----
const MMIO_BASE: usize = 0x0a000000;
const MMIO_STRIDE: usize = 0x200;
const MMIO_SLOTS: usize = 32;

const R_MAGIC: usize = 0x000;
const R_VERSION: usize = 0x004;
const R_DEVICE_ID: usize = 0x008;
const R_DEV_FEAT: usize = 0x010;
const R_DEV_FEAT_SEL: usize = 0x014;
const R_DRV_FEAT: usize = 0x020;
const R_DRV_FEAT_SEL: usize = 0x024;
const R_QUEUE_SEL: usize = 0x030;
const R_QUEUE_NUM_MAX: usize = 0x034;
const R_QUEUE_NUM: usize = 0x038;
const R_QUEUE_READY: usize = 0x044;
const R_QUEUE_NOTIFY: usize = 0x050;
const R_INT_STATUS: usize = 0x060;
const R_INT_ACK: usize = 0x064;
const R_STATUS: usize = 0x070;
const R_Q_DESC_LO: usize = 0x080;
const R_Q_DESC_HI: usize = 0x084;
const R_Q_DRV_LO: usize = 0x090;
const R_Q_DRV_HI: usize = 0x094;
const R_Q_DEV_LO: usize = 0x0a0;
const R_Q_DEV_HI: usize = 0x0a4;
const R_CONFIG: usize = 0x100;

const MAGIC: u32 = 0x74726976; // "triv"
const DEV_NET: u32 = 1;

const ST_ACK: u32 = 1;
const ST_DRIVER: u32 = 2;
const ST_DRIVER_OK: u32 = 4;
const ST_FEATURES_OK: u32 = 8;
const ST_FAILED: u32 = 128;

const F_MAC: u32 = 5; // VIRTIO_NET_F_MAC
const F_VERSION_1: u32 = 32; // VIRTIO_F_VERSION_1

const DESC_F_WRITE: u16 = 2;

const QSIZE: usize = 64;
const VNET_HDR_LEN: usize = 10; // sizeof(virtio_net_hdr): required TX prefix

// ---- virtqueue structures ----
const Desc = packed struct {
    addr: u64,
    len: u32,
    flags: u16,
    next: u16,
};

const Avail = struct {
    flags: u16 = 0,
    idx: u16 = 0,
    ring: [QSIZE]u16 = [_]u16{0} ** QSIZE,
    used_event: u16 = 0,
};

const UsedElem = packed struct {
    id: u32,
    len: u32,
};

const Used = struct {
    flags: u16 = 0,
    idx: u16 = 0,
    ring: [QSIZE]UsedElem = [_]UsedElem{.{ .id = 0, .len = 0 }} ** QSIZE,
    avail_event: u16 = 0,
};

const Queue = struct {
    desc: [QSIZE]Desc = [_]Desc{.{ .addr = 0, .len = 0, .flags = 0, .next = 0 }} ** QSIZE,
    avail: Avail = .{},
    used: Used = .{},
    last_used: u16 = 0,
};

var rx_q: Queue = .{};
var tx_q: Queue = .{};
var rx_bufs: [QSIZE][2048]u8 = [_][2048]u8{[_]u8{0} ** 2048} ** QSIZE;
var tx_buf: [2048]u8 = [_]u8{0} ** 2048;

var mmio_base: usize = 0;
var have_mac: bool = false;
var mac: [6]u8 = [_]u8{0} ** 6;
pub var link_up: bool = false;

fn reg(off: usize) *volatile u32 {
    return @ptrFromInt(mmio_base + off);
}

fn reg_read(off: usize) u32 {
    return reg(off).*;
}

fn reg_write(off: usize, v: u32) void {
    reg(off).* = v;
}

// find a virtio-net device on the mmio bus
fn find_device() bool {
    var slot: usize = 0;
    while (slot < MMIO_SLOTS) : (slot += 1) {
        const base = MMIO_BASE + slot * MMIO_STRIDE;
        const magic: *volatile u32 = @ptrFromInt(base + R_MAGIC);
        if (magic.* != MAGIC) continue;
        const ver: *volatile u32 = @ptrFromInt(base + R_VERSION);
        if (ver.* != 2) continue;
        const id: *volatile u32 = @ptrFromInt(base + R_DEVICE_ID);
        if (id.* != DEV_NET) continue;
        mmio_base = base;
        return true;
    }
    return false;
}

fn queue_setup(qsel: u32, q: *Queue) bool {
    reg_write(R_QUEUE_SEL, qsel);
    const max = reg_read(R_QUEUE_NUM_MAX);
    if (max == 0) return false;
    const n: u32 = if (max < QSIZE) max else QSIZE;
    reg_write(R_QUEUE_NUM, n);
    const desc_addr = @intFromPtr(&q.desc);
    const drv_addr = @intFromPtr(&q.avail);
    const dev_addr = @intFromPtr(&q.used);
    reg_write(R_Q_DESC_LO, @truncate(desc_addr));
    reg_write(R_Q_DESC_HI, @truncate(desc_addr >> 32));
    reg_write(R_Q_DRV_LO, @truncate(drv_addr));
    reg_write(R_Q_DRV_HI, @truncate(drv_addr >> 32));
    reg_write(R_Q_DEV_LO, @truncate(dev_addr));
    reg_write(R_Q_DEV_HI, @truncate(dev_addr >> 32));
    reg_write(R_QUEUE_READY, 1);
    return true;
}

fn read_mac() void {
    if (!have_mac) {
        // no F_MAC: fall back to a locally-administered address
        mac = [_]u8{ 0x02, 0x4e, 0x61, 0x74, 0x68, 0x61 }; // 02:"Nathan"
        return;
    }
    var i: usize = 0;
    while (i < 6) : (i += 1) {
        const p: *volatile u8 = @ptrFromInt(mmio_base + R_CONFIG + i);
        mac[i] = p.*;
    }
}

// post RX buffers so the device has somewhere to put incoming frames
fn rx_post_all() void {
    reg_write(R_QUEUE_SEL, 0);
    var i: usize = 0;
    while (i < QSIZE) : (i += 1) {
        rx_q.desc[i] = .{ .addr = @intFromPtr(&rx_bufs[i]), .len = 2048, .flags = DESC_F_WRITE, .next = 0 };
        rx_q.avail.ring[i] = @intCast(i);
    }
    rx_q.avail.idx = QSIZE;
    reg_write(R_QUEUE_NOTIFY, 0);
}

// probe + init the device. true = link up.
pub fn probe() bool {
    link_up = false;
    if (!find_device()) return false;

    reg_write(R_STATUS, 0); // reset
    const s = reg_read(R_STATUS);
    reg_write(R_STATUS, s | ST_ACK);
    reg_write(R_STATUS, reg_read(R_STATUS) | ST_DRIVER);

    // features: we want the MAC (bit 5) and VERSION_1 (bit 32)
    reg_write(R_DEV_FEAT_SEL, 0);
    const feat_lo = reg_read(R_DEV_FEAT);
    have_mac = (feat_lo & (@as(u32, 1) << F_MAC)) != 0;
    reg_write(R_DRV_FEAT_SEL, 0);
    // sel 0 covers bits 0..31: MAC lives here
    reg_write(R_DRV_FEAT, if (have_mac) (@as(u32, 1) << F_MAC) else 0);
    reg_write(R_DRV_FEAT_SEL, 1);
    reg_write(R_DRV_FEAT, 1 << 0); // bit 32 = VERSION_1
    reg_write(R_STATUS, reg_read(R_STATUS) | ST_FEATURES_OK);
    if ((reg_read(R_STATUS) & ST_FEATURES_OK) == 0) {
        reg_write(R_STATUS, reg_read(R_STATUS) | ST_FAILED);
        return false;
    }

    read_mac();
    if (!queue_setup(0, &rx_q)) return false;
    if (!queue_setup(1, &tx_q)) return false;
    rx_post_all();

    reg_write(R_STATUS, reg_read(R_STATUS) | ST_DRIVER_OK);
    link_up = true;
    return true;
}

pub fn mac_addr() [6]u8 {
    return mac;
}

// transmit one raw Ethernet frame; waits for the used-ring completion.
// Prepends the 10-byte virtio_net_hdr QEMU's virtio-net TX path requires.
pub fn tx_frame(frame: []const u8) bool {
    if (!link_up) return false;
    if (frame.len == 0 or frame.len + VNET_HDR_LEN > tx_buf.len) return false;
    @memset(tx_buf[0..VNET_HDR_LEN], 0); // virtio_net_hdr: no flags, no GSO
    @memcpy(tx_buf[VNET_HDR_LEN..][0..frame.len], frame);
    const total: u32 = @intCast(VNET_HDR_LEN + frame.len);

    reg_write(R_QUEUE_SEL, 1);
    tx_q.desc[0] = .{ .addr = @intFromPtr(&tx_buf), .len = total, .flags = 0, .next = 0 };
    const ai = tx_q.avail.idx;
    tx_q.avail.ring[ai % QSIZE] = 0;
    tx_q.avail.idx = ai +% 1;
    // make sure the descriptor/avail writes are visible before notify.
    // MMU off: still need a CPU barrier — AArch64 may reorder stores.
    asm volatile ("dmb sy" ::: "memory");
    reg_write(R_QUEUE_NOTIFY, 1);

    // poll for completion via the ISR (interrupt status register).
    // WORKAROUND: polling the used.idx in guest RAM is unreliable because
    // QEMU's MemoryRegionCache writes may not be visible to the guest CPU
    // (cache coherency issue with TCG). The ISR is an MMIO register, so
    // reads go through the MMIO path and are always coherent.
    // Bit 0 = used buffer notification (TX complete).
    // Clear any stale interrupt first, then wait for the new one.
    reg_write(R_INT_ACK, 0x1);
    var spins: u32 = 0;
    while ((reg_read(R_INT_STATUS) & 0x1) == 0) : (spins += 1) {
        if (spins > 200000000) return false;
    }
    reg_write(R_INT_ACK, 0x1); // acknowledge
    // Update our tracking from the used ring (best-effort; may be stale
    // due to the cache issue, but we know TX completed via the ISR).
    const used_idx: *volatile u16 = @ptrFromInt(@intFromPtr(&tx_q.used.idx));
    tx_q.last_used = used_idx.*;
    return true;
}

// how many RX frames have completed (best-effort; nothing may arrive)
pub fn rx_ready() u16 {
    if (!link_up) return 0;
    const used_idx: *const volatile u16 = @ptrFromInt(@intFromPtr(&rx_q.used.idx));
    return used_idx.* -% rx_q.last_used;
}

// build a broadcast ARP request for the QEMU user-net gateway.
pub fn build_arp_request(out: []u8) usize {
    if (out.len < 60) return 0;
    @memset(out[0..60], 0);
    // dst: broadcast
    @memset(out[0..6], 0xff);
    // src: our MAC
    @memcpy(out[6..12], mac[0..6]);
    // ethertype: ARP
    out[12] = 0x08;
    out[13] = 0x06;
    // htype ethernet, ptype IPv4, hlen 6, plen 4, oper request
    out[14] = 0x00;
    out[15] = 0x01;
    out[16] = 0x08;
    out[17] = 0x00;
    out[18] = 6;
    out[19] = 4;
    out[20] = 0x00;
    out[21] = 0x01;
    // sha: our MAC
    @memcpy(out[22..28], mac[0..6]);
    // spa: 10.0.2.15 (QEMU user-net guest address)
    out[28] = 10;
    out[29] = 0;
    out[30] = 2;
    out[31] = 15;
    // tha: zeros (30..36 already zero)
    // tpa: 10.0.2.2 (gateway)
    out[38] = 10;
    out[39] = 0;
    out[40] = 2;
    out[41] = 2;
    return 60;
}
