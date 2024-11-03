const std = @import("std");
const raySdk = @import("raylib/src/build.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create the modules
    const types_module = b.createModule(.{
        .root_source_file = b.path("src/types.zig"),
    });

    const button_module = b.createModule(.{
        .root_source_file = b.path("src/button.zig"),
        .imports = &.{
            .{ .name = "types", .module = types_module },
        },
    });

    const maze_module = b.createModule(.{
        .root_source_file = b.path("src/maze.zig"),
        .imports = &.{
            .{ .name = "types", .module = types_module },
        },
    });

    const visualizer_module = b.createModule(.{
        .root_source_file = b.path("src/visualizer.zig"),
        .imports = &.{
            .{ .name = "types", .module = types_module },
            .{ .name = "button", .module = button_module },
            .{ .name = "maze", .module = maze_module },
        },
    });

    // Create the executable
    const exe = b.addExecutable(.{
        .name = "MazeVisualizer",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add the modules to the executable
    exe.root_module.addImport("types", types_module);
    exe.root_module.addImport("button", button_module);
    exe.root_module.addImport("maze", maze_module);
    exe.root_module.addImport("visualizer", visualizer_module);

    // Add Raylib
    const raylib = try raySdk.addRaylib(b, target, optimize, .{
        .shared = false,
    });
    exe.linkLibrary(raylib);

    // Install and create run step
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the maze visualizer");
    run_step.dependOn(&run_cmd.step);
}
