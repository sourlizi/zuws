const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const config_options = b.addOptions();
    const debug_logs = b.option(bool, "debug_logs", "Whether to enable debug logs for route creation.") orelse (optimize == .Debug);

    config_options.addOption(bool, "debug_logs", debug_logs);

    const uSockets = b.addLibrary(.{
        .name = "uSockets",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    uSockets.linkSystemLibrary("zlib");

    uSockets.addIncludePath(b.path("uWebSockets/uSockets/src"));
    uSockets.installHeader(b.path("uWebSockets/uSockets/src/libusockets.h"), "libusockets.h");

    const uSocketsSourceFiles = &[_][]const u8{
        "bsd.c",
        "context.c",
        "loop.c",
        "quic.c",
        "socket.c",
        "udp.c",
        "crypto/sni_tree.cpp",
        "eventing/epoll_kqueue.c",
        "eventing/gcd.c",
        "eventing/libuv.c",
        "io_uring/io_context.c",
        "io_uring/io_loop.c",
        "io_uring/io_socket.c",
    };

    uSockets.addCSourceFiles(.{
        .root = b.path("uWebSockets/uSockets/src/"),
        .files = uSocketsSourceFiles,
        .flags = &.{"-DLIBUS_NO_SSL"},
    });

    const uWebSockets = b.addLibrary(.{
        .name = "uWebSockets",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    uWebSockets.linkLibCpp();
    uWebSockets.linkLibrary(uSockets);
    uWebSockets.addCSourceFiles(.{
        .root = b.path("bindings/"),
        .files = &.{"uws.cpp"},
    });

    b.installArtifact(uWebSockets);

    const uWS_c = b.addTranslateC(.{
        .root_source_file = b.path("bindings/uws.h"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zuws",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addOptions("config", config_options);
    exe.root_module.addImport("uws", uWS_c.createModule());
    exe.linkLibrary(uWebSockets);
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    run_exe.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_exe.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_exe.step);

    const zuws = b.addModule("zuws", .{
        .root_source_file = b.path("src/uws.zig"),
    });

    zuws.addOptions("config", config_options);
    zuws.addImport("uws", uWS_c.createModule());
    zuws.linkLibrary(uWebSockets);

    const asm_step = b.step("asm", "Emit assembly file");
    const awf = b.addWriteFiles();
    awf.step.dependOn(b.getInstallStep());
    // Path is relative to the cache dir in which it *would've* been placed in
    _ = awf.addCopyFile(exe.getEmittedAsm(), "../../../main.asm");
    asm_step.dependOn(&awf.step);

    const check = b.step("check", "Check if zuws compiles");
    const exe_check = b.addExecutable(.{
        .name = "zuws",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_check.root_module.addImport("uws", uWS_c.createModule());
    exe_check.linkLibrary(uWebSockets);
    check.dependOn(&exe_check.step);
}
