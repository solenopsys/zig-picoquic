const std = @import("std");

const c_flags = [_][]const u8{
    "-std=c11",
    "-fPIC",
    "-pthread",
    "-D_GNU_SOURCE",
    "-D_DEFAULT_SOURCE",
    "-DOPENSSL_NO_ENGINE",
    "-DPTLS_WITHOUT_FUSION",
    "-DPICOQUIC_LIBRARY",
    "-DPICOTLS_USE_OPENSSL",
    "-O2",
    "-ffunction-sections",
    "-fdata-sections",
    "-fvisibility=hidden",
    "-Wno-error",
    "-fno-sanitize=undefined",
};

const picoquic_sources = [_][]const u8{
    "libs/picoquic/picoquic/bbr.c",
    "libs/picoquic/picoquic/bbr1.c",
    "libs/picoquic/picoquic/bytestream.c",
    "libs/picoquic/picoquic/cc_common.c",
    "libs/picoquic/picoquic/config.c",
    "libs/picoquic/picoquic/cubic.c",
    "libs/picoquic/picoquic/ech.c",
    "libs/picoquic/picoquic/error_names.c",
    "libs/picoquic/picoquic/fastcc.c",
    "libs/picoquic/picoquic/frames.c",
    "libs/picoquic/picoquic/intformat.c",
    "libs/picoquic/picoquic/logger.c",
    "libs/picoquic/picoquic/logwriter.c",
    "libs/picoquic/picoquic/loss_recovery.c",
    "libs/picoquic/picoquic/newreno.c",
    "libs/picoquic/picoquic/pacing.c",
    "libs/picoquic/picoquic/packet.c",
    "libs/picoquic/picoquic/paths.c",
    "libs/picoquic/picoquic/performance_log.c",
    "libs/picoquic/picoquic/picohash.c",
    "libs/picoquic/picoquic/picoquic_lb.c",
    "libs/picoquic/picoquic/picoquic_mbedtls.c",
    "libs/picoquic/picoquic/picoquic_ptls_fusion.c",
    "libs/picoquic/picoquic/picoquic_ptls_minicrypto.c",
    "libs/picoquic/picoquic/picoquic_ptls_openssl.c",
    "libs/picoquic/picoquic/picosocks.c",
    "libs/picoquic/picoquic/picosplay.c",
    "libs/picoquic/picoquic/port_blocking.c",
    "libs/picoquic/picoquic/prague.c",
    "libs/picoquic/picoquic/quicctx.c",
    "libs/picoquic/picoquic/register_all_cc_algorithms.c",
    "libs/picoquic/picoquic/sacks.c",
    "libs/picoquic/picoquic/sender.c",
    "libs/picoquic/picoquic/sim_link.c",
    "libs/picoquic/picoquic/siphash.c",
    "libs/picoquic/picoquic/sockloop.c",
    "libs/picoquic/picoquic/spinbit.c",
    "libs/picoquic/picoquic/ticket_store.c",
    "libs/picoquic/picoquic/timing.c",
    "libs/picoquic/picoquic/token_store.c",
    "libs/picoquic/picoquic/tls_api.c",
    "libs/picoquic/picoquic/transport.c",
    "libs/picoquic/picoquic/unified_log.c",
    "libs/picoquic/picoquic/util.c",
    "libs/picoquic/picoquic/winsockloop.c",
};

const picohttp_sources = [_][]const u8{
    "libs/picoquic/picohttp/democlient.c",
    "libs/picoquic/picohttp/demoserver.c",
    "libs/picoquic/picohttp/h3zero.c",
    "libs/picoquic/picohttp/h3zero_client.c",
    "libs/picoquic/picohttp/h3zero_common.c",
    "libs/picoquic/picohttp/h3zero_server.c",
    "libs/picoquic/picohttp/h3zero_uri.c",
    "libs/picoquic/picohttp/h3zero_url_template.c",
    "libs/picoquic/picohttp/picomask.c",
    "libs/picoquic/picohttp/quicperf.c",
    "libs/picoquic/picohttp/webtransport.c",
    "libs/picoquic/picohttp/wt_baton.c",
};

const loglib_sources = [_][]const u8{
    "libs/picoquic/loglib/autoqlog.c",
    "libs/picoquic/loglib/cidset.c",
    "libs/picoquic/loglib/csv.c",
    "libs/picoquic/loglib/logconvert.c",
    "libs/picoquic/loglib/logreader.c",
    "libs/picoquic/loglib/memory_log.c",
    "libs/picoquic/loglib/qlog.c",
    "libs/picoquic/loglib/svg.c",
};

const picotls_core_sources = [_][]const u8{
    "libs/picotls/lib/hpke.c",
    "libs/picotls/lib/pembase64.c",
    "libs/picotls/lib/picotls.c",
};

const picotls_minicrypto_sources = [_][]const u8{
    "libs/picotls/deps/micro-ecc/uECC.c",
    "libs/picotls/deps/cifra/src/aes.c",
    "libs/picotls/deps/cifra/src/blockwise.c",
    "libs/picotls/deps/cifra/src/chacha20.c",
    "libs/picotls/deps/cifra/src/chash.c",
    "libs/picotls/deps/cifra/src/curve25519.c",
    "libs/picotls/deps/cifra/src/drbg.c",
    "libs/picotls/deps/cifra/src/gcm.c",
    "libs/picotls/deps/cifra/src/gf128.c",
    "libs/picotls/deps/cifra/src/hmac.c",
    "libs/picotls/deps/cifra/src/modes.c",
    "libs/picotls/deps/cifra/src/poly1305.c",
    "libs/picotls/deps/cifra/src/sha256.c",
    "libs/picotls/deps/cifra/src/sha512.c",
    "libs/picotls/lib/asn1.c",
    "libs/picotls/lib/cifra.c",
    "libs/picotls/lib/cifra/aes128.c",
    "libs/picotls/lib/cifra/aes256.c",
    "libs/picotls/lib/cifra/chacha20.c",
    "libs/picotls/lib/cifra/random.c",
    "libs/picotls/lib/cifra/x25519.c",
    "libs/picotls/lib/ffx.c",
    "libs/picotls/lib/minicrypto-pem.c",
    "libs/picotls/lib/openssl.c",
    "libs/picotls/lib/ptlsbcrypt.c",
    "libs/picotls/lib/uecc.c",
};

const sample_sources = [_][]const u8{
    "libs/picoquic/sample/sample.c",
    "libs/picoquic/sample/sample_client.c",
    "libs/picoquic/sample/sample_server.c",
    "libs/picoquic/sample/sample_background.c",
};

const include_dirs = [_][]const u8{
    "libs/picoquic",
    "libs/picoquic/picoquic",
    "libs/picoquic/picohttp",
    "libs/picoquic/loglib",
    "libs/picotls/include",
    "libs/picotls/deps/cifra/src",
    "libs/picotls/deps/cifra/src/ext",
    "libs/picotls/deps/micro-ecc",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseFast });

    const pico_module = b.addModule("picoquic", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "picoquic",
        .linkage = .static,
        .root_module = pico_module,
    });

    inline for (include_dirs) |inc| {
        pico_module.addIncludePath(b.path(inc));
    }

    inline for (.{ &picoquic_sources, &picohttp_sources, &loglib_sources, &picotls_core_sources, &picotls_minicrypto_sources }) |group| {
        lib.addCSourceFiles(.{
            .files = group,
            .flags = &c_flags,
        });
    }

    inline for (include_dirs) |inc| {
        lib.addIncludePath(b.path(inc));
    }

    lib.linkLibC();
    lib.linkSystemLibrary("crypto");
    lib.linkSystemLibrary("ssl");

    switch (target.result.os.tag) {
        .linux, .freebsd, .netbsd, .dragonfly, .openbsd, .haiku, .solaris => {
            lib.linkSystemLibrary("pthread");
            lib.linkSystemLibrary("m");
            lib.linkSystemLibrary("dl");
        },
        .windows => {
            lib.linkSystemLibrary("ws2_32");
            lib.linkSystemLibrary("bcrypt");
        },
        else => {},
    }

    b.installArtifact(lib);

    const demo = b.addExecutable(.{
        .name = "picoquicdemo",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    demo.addCSourceFile(.{
        .file = b.path("libs/picoquic/picoquicfirst/picoquicdemo.c"),
        .flags = &c_flags,
    });

    inline for (include_dirs) |inc| {
        demo.addIncludePath(b.path(inc));
    }
    demo.addIncludePath(b.path("libs/picoquic/picoquicfirst"));
    demo.addIncludePath(b.path("libs/picoquic/picoquictest"));

    demo.linkLibrary(lib);
    demo.linkLibC();
    demo.linkSystemLibrary("crypto");
    demo.linkSystemLibrary("ssl");

    switch (target.result.os.tag) {
        .linux, .freebsd, .netbsd, .dragonfly, .openbsd, .haiku, .solaris => {
            demo.linkSystemLibrary("pthread");
            demo.linkSystemLibrary("m");
            demo.linkSystemLibrary("dl");
        },
        .windows => {
            demo.linkSystemLibrary("ws2_32");
            demo.linkSystemLibrary("bcrypt");
        },
        else => {},
    }

    b.installArtifact(demo);

    const sample = b.addExecutable(.{
        .name = "picoquic_sample",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });

    sample.addCSourceFiles(.{
        .files = &sample_sources,
        .flags = &c_flags,
    });

    inline for (include_dirs) |inc| {
        sample.addIncludePath(b.path(inc));
    }
    sample.addIncludePath(b.path("libs/picoquic/sample"));

    sample.linkLibrary(lib);
    sample.linkLibC();
    sample.linkSystemLibrary("crypto");
    sample.linkSystemLibrary("ssl");

    switch (target.result.os.tag) {
        .linux, .freebsd, .netbsd, .dragonfly, .openbsd, .haiku, .solaris => {
            sample.linkSystemLibrary("pthread");
            sample.linkSystemLibrary("m");
            sample.linkSystemLibrary("dl");
        },
        .windows => {
            sample.linkSystemLibrary("ws2_32");
            sample.linkSystemLibrary("bcrypt");
        },
        else => {},
    }

    b.installArtifact(sample);

    const echo = b.addExecutable(.{
        .name = "picoquic_echo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    echo.root_module.addImport("picoquic", pico_module);

    inline for (include_dirs) |inc| {
        echo.addIncludePath(b.path(inc));
    }

    echo.linkLibrary(lib);
    echo.linkLibC();
    echo.linkSystemLibrary("crypto");
    echo.linkSystemLibrary("ssl");

    switch (target.result.os.tag) {
        .linux, .freebsd, .netbsd, .dragonfly, .openbsd, .haiku, .solaris => {
            echo.linkSystemLibrary("pthread");
            echo.linkSystemLibrary("m");
            echo.linkSystemLibrary("dl");
        },
        .windows => {
            echo.linkSystemLibrary("ws2_32");
            echo.linkSystemLibrary("bcrypt");
        },
        else => {},
    }

    b.installArtifact(echo);
}
