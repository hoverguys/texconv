const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zigimg = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });

    const module = b.addModule("texconv", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    module.addImport("zigimg", zigimg.module("zigimg"));

    const exe = b.addExecutable(.{
        .name = "texconv",
        .root_module = module,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Testing
    const tex_unit_tests = b.addTest(.{
        .root_module = b.addModule("texconv", .{
            .root_source_file = b.path("src/elf.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_tex_unit_tests = b.addRunArtifact(tex_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tex_unit_tests.step);
}
