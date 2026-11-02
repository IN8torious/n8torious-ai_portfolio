// Harakiri NG — Zig build script
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .aarch64,
        .os_tag = .freestanding,
        .abi = .none,
    });
    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "harakiri-ng",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    kernel.setLinkerScript(b.path("boot/linker.ld"));
    kernel.entry = .{ .symbol_name = "_start" };

    b.installArtifact(kernel);

    // raw binary for QEMU
    const objcopy = b.addObjCopy(kernel.getEmittedBin(), .{
        .format = .bin,
    });
    const bin_install = b.addInstallBinFile(objcopy.getOutput(), "harakiri-ng.bin");
    b.getInstallStep().dependOn(&bin_install.step);
}
