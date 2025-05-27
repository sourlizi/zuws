const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const config_options = b.addOptions();
    const debug_logs = b.option(bool, "debug_logs", "Whether to enable debug logs for route creation.") orelse (optimize == .Debug);

    config_options.addOption(bool, "debug_logs", debug_logs);

    const libuv_dep = b.dependency("libuv", .{
        .target = target,
        .optimize = optimize,
    });

    const zlib_dep = b.dependency("zlib", .{
        .target = target,
        .optimize = optimize,
    });

    const boringssl_dep = b.dependency("boringssl", .{
        .target = target,
        .optimize = optimize,
    });

    const usockets_dep = b.dependency("uSockets", .{});
    const uwebsockets_dep = b.dependency("uWebSockets", .{});

    const uSockets = b.addLibrary(.{
        .name = "uSockets",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .link_libcpp = target.result.abi != .msvc,
        }),
    });

    uSockets.linkLibrary(zlib_dep.artifact("z"));
    uSockets.linkLibrary(libuv_dep.artifact("uv"));
    const ssl = boringssl_dep.artifact("ssl");
    uSockets.linkLibrary(ssl);
    uSockets.installLibraryHeaders(ssl);
    uSockets.addIncludePath(usockets_dep.path("src"));
    uSockets.installHeader(usockets_dep.path("src/libusockets.h"), "libusockets.h");
    uSockets.addCSourceFiles(.{
        .root = usockets_dep.path("src"),
        .files = &.{
            "bsd.c",
            "context.c",
            "loop.c",
            "quic.c",
            "socket.c",
            "udp.c",
            "crypto/openssl.c",
            "eventing/epoll_kqueue.c",
            "eventing/gcd.c",
            "eventing/libuv.c",
            "io_uring/io_context.c",
            "io_uring/io_loop.c",
            "io_uring/io_socket.c",
        },
        .flags = &.{
            "-DLIBUS_USE_OPENSSL=1",
            "-DWIN32_LEAN_AND_MEAN",
        },
    });
    uSockets.addCSourceFiles(.{
        .root = usockets_dep.path("src"),
        .files = &.{
            "crypto/sni_tree.cpp",
        },
        .flags = &.{ "-std=c++17", "-DLIBUS_USE_OPENSSL=1" },
        .language = .cpp,
    });
    b.installArtifact(uSockets);

    const uWebSockets = b.addLibrary(.{
        .name = "uWebSockets",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    uWebSockets.installHeadersDirectory(uwebsockets_dep.path("src/"), "", .{});
    uWebSockets.linkLibCpp();
    uWebSockets.linkLibrary(uSockets);
    uWebSockets.linkLibrary(zlib_dep.artifact("z"));
    uWebSockets.addIncludePath(uwebsockets_dep.path("src"));
    uWebSockets.addCSourceFiles(.{
        .root = b.path("bindings/"),
        .files = &.{ "uws.cpp", "app_raw.cpp", "app_ssl.cpp" },
    });
    b.installArtifact(uWebSockets);

    const uws = b.addTranslateC(.{
        .root_source_file = b.path("bindings/uws.h"),
        .target = target,
        .optimize = optimize,
    });

    const uws_module = uws.addModule("uws");

    const zuws = b.addModule("zuws", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    zuws.addOptions("config", config_options);
    zuws.addImport("uws", uws_module);
    zuws.linkLibrary(uWebSockets);
    const libzuws = b.addLibrary(.{
        .name = "zuws",
        .linkage = .static,
        .root_module = zuws,
    });
    b.installArtifact(libzuws);

    const examples: []const []const u8 = &.{
        "hello-world",
        "hello-world-ssl",
        "versioning",
        "ws-server",
    };

    inline for (examples) |example_name| {
        try addExample(b, example_name, target, optimize, uws_module, zuws);
    }
}

fn addExample(
    b: *std.Build,
    example_name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    uws_module: *std.Build.Module,
    zuws: *std.Build.Module,
) !void {
    const path = try std.fmt.allocPrint(b.allocator, "examples/{s}/main.zig", .{example_name});

    const exe = b.addExecutable(.{
        .name = example_name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(path),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("uws", uws_module);
    exe.root_module.addImport("zuws", zuws);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.setCwd(b.path("."));

    const example_step = b.step(
        try std.fmt.allocPrint(b.allocator, "example-{s}", .{example_name}),
        try std.fmt.allocPrint(b.allocator, "Run the {s} example", .{example_name}),
    );
    example_step.dependOn(&run_cmd.step);

    const example_assembly_step = b.step(
        try std.fmt.allocPrint(b.allocator, "example-{s}-asm", .{example_name}),
        try std.fmt.allocPrint(b.allocator, "Emit the {s} example ASM file", .{example_name}),
    );

    const asm_description = try std.fmt.allocPrint(b.allocator, "Emit the {s} example ASM file", .{example_name});
    const asm_step_name = try std.fmt.allocPrint(b.allocator, "{s}-asm", .{example_name});
    const asm_step = b.step(asm_step_name, asm_description);
    const awf = b.addUpdateSourceFiles();
    awf.step.dependOn(b.getInstallStep());
    awf.addCopyFileToSource(exe.getEmittedAsm(), "main.asm");
    asm_step.dependOn(&awf.step);
    example_assembly_step.dependOn(asm_step);
}
