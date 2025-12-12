const std = @import("std");
const build_utils = @import("build_utils.zig");

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

fn buildForTarget(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    artifacts_dir: []const u8,
    hashes: *std.StringHashMap([]const u8),
    json_step: *build_utils.WriteJsonStep,
) void {
    const target_str = build_utils.getTargetString(target);
    const lib_name = build_utils.getLibName(std.heap.page_allocator, "picoquic", target_str);

    const lib = b.addLibrary(.{
        .name = lib_name,
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    inline for (include_dirs) |inc| {
        lib.root_module.addIncludePath(b.path(inc));
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

    const install = b.addInstallArtifact(lib, .{});

    const hash_step = build_utils.HashAndMoveStep.create(
        b,
        lib_name,
        target_str,
        artifacts_dir,
        hashes,
    );
    hash_step.step.dependOn(&install.step);

    json_step.step.dependOn(&hash_step.step);
}

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const artifacts_dir = "../../artifacts/libs";
    const json_path = "current.json";

    const build_all = b.option(bool, "all", "Build for all supported targets") orelse false;

    if (build_all) {
        const hashes = build_utils.createHashMap(b);
        const json_step = build_utils.WriteJsonStep.create(b, hashes, json_path);

        for (build_utils.supported_targets) |query| {
            const target = b.resolveTargetQuery(query);
            buildForTarget(b, target, optimize, artifacts_dir, hashes, json_step);
        }

        b.default_step.dependOn(&json_step.step);
    } else {
        const target = b.standardTargetOptions(.{});

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
    }
}
