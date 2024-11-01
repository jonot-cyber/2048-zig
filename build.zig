const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const gba_img = b.addExecutable(.{
        .name = "gbaimg",
        .root_source_file = b.path("tools/gbaimg.zig"),
        .optimize = optimize,
        .target = b.standardTargetOptions(.{}),
        .link_libc = true,
    });

    const target2 = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{
            .explicit = &std.Target.arm.cpu.arm7tdmi,
        },
        .os_tag = .freestanding,
        .abi = .eabi,
    });
    const elf = b.addExecutable(.{
        .name = "zig.elf",
        .root_source_file = b.path("src/main.zig"),
        .target = target2,
        .optimize = optimize,
        .single_threaded = true,
        .link_libc = false,
        .linkage = .static,
        .omit_frame_pointer = optimize == .ReleaseSmall,
        .use_lld = true,
    });
    elf.addAssemblyFile(b.path("src/start.s"));
    elf.setLinkerScript(b.path("src/link.ld"));

    const gba_img_run_tiles = b.addRunArtifact(gba_img);
    gba_img_run_tiles.addFileArg(b.path("assets/tiles.png"));
    const output_tiles = gba_img_run_tiles.addOutputFileArg("tiles.zig");
    gba_img_run_tiles.addArg("32");
    elf.root_module.addAnonymousImport("tiles", .{
        .root_source_file = output_tiles,
    });

    const gba_img_run_bg = b.addRunArtifact(gba_img);
    gba_img_run_bg.addFileArg(b.path("assets/bg.png"));
    const output_bg = gba_img_run_bg.addOutputFileArg("bg.zig");

    gba_img_run_bg.addArg("8");
    elf.root_module.addAnonymousImport("bg", .{
        .root_source_file = output_bg,
    });
    b.installArtifact(elf);

    _ = b.addInstallArtifact(elf, .{});

    const obj_copy = b.addObjCopy(elf.getEmittedBin(), .{
        .format = .bin,
    });
    obj_copy.step.dependOn(&elf.step);

    const copy_bin = b.addInstallBinFile(obj_copy.getOutput(), "2048.gba");
    b.default_step.dependOn(&copy_bin.step);

    // Add a run step
    const run_step_command = b.addSystemCommand(&.{"mgba-qt"});
    run_step_command.addFileArg(obj_copy.getOutput());
    run_step_command.step.dependOn(&obj_copy.step);

    const run_step = b.step("run", "Run in an emulator");
    run_step.dependOn(&run_step_command.step);
}
