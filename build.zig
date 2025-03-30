const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const config_options = b.addOptions();
    const debug_logs = b.option(bool, "debug_logs", "Whether to enable debug logs for route creation.") orelse (optimize == .Debug);

    config_options.addOption(bool, "debug_logs", debug_logs);

    var arena = std.heap.ArenaAllocator.init(b.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

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
    uSockets.addCSourceFiles(.{
        .root = b.path("uWebSockets/uSockets/src/"),
        .files = &[_][]const u8{
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
        },
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
    const uWS_c_module = uWS_c.createModule();

    const zuws = b.addModule("zuws", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    zuws.addOptions("config", config_options);
    zuws.addImport("uws", uWS_c_module);
    zuws.linkLibrary(uWebSockets);
    const libzuws = b.addLibrary(.{
        .name = "zuws",
        .linkage = .static,
        .root_module = zuws,
    });
    b.installArtifact(libzuws);

    var main_files: std.ArrayListUnmanaged(struct {
        dir: []const u8,
        path: []const u8,
    }) = .empty;

    var dir = try std.fs.cwd().openDir(".", .{ .iterate = true });
    var walker = try dir.walk(b.allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file and std.mem.eql(u8, entry.basename, "main.zig")) {
            const parent_dir = std.fs.path.dirname(entry.path) orelse continue;

            try main_files.append(allocator, .{
                .dir = try b.allocator.dupe(u8, parent_dir),
                .path = try b.allocator.dupe(u8, entry.path),
            });
        }
    }

    for (main_files.items) |main| {
        const exe_name = std.fs.path.basename(main.dir);
        const exe = b.addExecutable(.{
            .name = exe_name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(main.path),
                .target = target,
                .optimize = optimize,
            }),
        });

        exe.root_module.addOptions("config", config_options);
        exe.root_module.addImport("uws", uWS_c_module);
        exe.root_module.addImport("zuws", zuws);
        b.installArtifact(exe);

        // Create a run step
        const exe_install = b.addInstallArtifact(exe, .{});
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(&exe_install.step);

        const run_description = try std.fmt.allocPrint(allocator, "Run the {s} example", .{exe_name});
        const run_step = b.step(exe_name, run_description);
        run_step.dependOn(&run_cmd.step);

        const asm_description = try std.fmt.allocPrint(allocator, "Emit the {s} example ASM file", .{exe_name});
        const asm_step_name = try std.fmt.allocPrint(allocator, "{s}-asm", .{exe_name});
        const asm_step = b.step(asm_step_name, asm_description);
        const awf = b.addWriteFiles();
        awf.step.dependOn(b.getInstallStep());
        // Path is relative to the cache dir in which it *would've* been placed in
        _ = awf.addCopyFile(exe.getEmittedAsm(), "../../../main.asm");
        asm_step.dependOn(&awf.step);
    }
}
