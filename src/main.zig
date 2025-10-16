const std = @import("std");
const pico = @import("lib.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args_iter = try std.process.argsWithAllocator(allocator);
    defer args_iter.deinit();

    _ = args_iter.next(); // skip executable name

    const mode = args_iter.next() orelse {
        return usage();
    };

    if (std.mem.eql(u8, mode, "server")) {
        const port_arg = args_iter.next() orelse {
            return usage();
        };
        const port = try std.fmt.parseInt(u16, port_arg, 10);
        const cert = args_iter.next() orelse "libs/picoquic/certs/cert.pem";
        const key = args_iter.next() orelse "libs/picoquic/certs/key.pem";

        std.log.info("Starting echo server on port {d}", .{port});
        try pico.startEchoServer(allocator, port, cert, key);
    } else if (std.mem.eql(u8, mode, "client")) {
        const host = args_iter.next() orelse return usage();
        const port_arg = args_iter.next() orelse return usage();
        const port = try std.fmt.parseInt(u16, port_arg, 10);
        const message = args_iter.next() orelse return usage();

        std.log.info("Connecting to {s}:{d}", .{ host, port });
        const response = try pico.runEchoClient(allocator, host, port, message);
        defer allocator.free(response);
        std.log.info("Server replied: \"{s}\"", .{response});
    } else {
        return usage();
    }
}

fn usage() !void {
    std.debug.print(
        \\Usage:
        \\  picoquic_echo server <port> [cert_path key_path]
        \\  picoquic_echo client <host> <port> <message>
        \\
        \\Defaults use the test certificates shipped with picoquic.
        \\
    , .{});
    return error.InvalidUsage;
}
