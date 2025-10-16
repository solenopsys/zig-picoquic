const std = @import("std");

pub const c = @cImport({
    @cInclude("picoquic.h");
    @cInclude("picoquic_utils.h");
    @cInclude("picoquic_packet_loop.h");
    @cInclude("picoquic_bbr.h");
    @cInclude("picosocks.h");
});

pub const Error = error{
    CreateFailed,
    ConnectionFailed,
    SendFailed,
    PacketLoopFailed,
};

const ALPN = &[_:0]u8{ 'p', 'i', 'c', 'o', 'e', 'c', 'h', 'o', 0 };

const ServerCallbackContext = struct {
    allocator: std.mem.Allocator,
};

fn serverStreamCallback(
    cnx: ?*c.picoquic_cnx_t,
    stream_id: u64,
    bytes: [*c]u8,
    length: usize,
    fin_or_event: c.picoquic_call_back_event_t,
    _: ?*anyopaque,
    _: ?*anyopaque,
) callconv(.c) c_int {
    const conn = cnx orelse return 0;
    switch (fin_or_event) {
        c.picoquic_callback_stream_data,
        c.picoquic_callback_stream_fin,
        => {
            if (length > 0) {
                const rc = c.picoquic_add_to_stream(conn, stream_id, bytes, length, if (fin_or_event == c.picoquic_callback_stream_fin) 1 else 0);
                if (rc != 0) return @as(c_int, rc);
            }
        },
        else => {},
    }
    return 0;
}

fn serverLoopCallback(
    _: ?*c.picoquic_quic_t,
    cb_mode: c.picoquic_packet_loop_cb_enum,
    _: ?*anyopaque,
    _: ?*anyopaque,
) callconv(.c) c_int {
    return switch (cb_mode) {
        c.picoquic_packet_loop_ready => 0,
        c.picoquic_packet_loop_after_receive => 0,
        c.picoquic_packet_loop_after_send => 0,
        c.picoquic_packet_loop_port_update => 0,
        c.picoquic_packet_loop_time_check => 0,
        c.picoquic_packet_loop_system_call_duration => 0,
        c.picoquic_packet_loop_wake_up => 0,
        c.picoquic_packet_loop_alt_port => 0,
        else => 0,
    };
}

pub fn startEchoServer(allocator: std.mem.Allocator, port: u16, cert_path: []const u8, key_path: []const u8) !void {
    var reset_seed: [c.PICOQUIC_RESET_SECRET_SIZE]u8 = undefined;
    @memset(&reset_seed, 0);

    const cert_z = try allocator.dupeZ(u8, cert_path);
    defer allocator.free(cert_z);
    const key_z = try allocator.dupeZ(u8, key_path);
    defer allocator.free(key_z);

    const ctx = ServerCallbackContext{ .allocator = allocator };

    const now = c.picoquic_current_time();
    const quic = c.picoquic_create(
        8,
        cert_z.ptr,
        key_z.ptr,
        null,
        ALPN,
        serverStreamCallback,
        @constCast(&ctx),
        null,
        null,
        &reset_seed,
        now,
        null,
        null,
        null,
        0,
    ) orelse return Error.CreateFailed;
    defer c.picoquic_free(quic);

    c.picoquic_set_default_congestion_algorithm(quic, c.picoquic_bbr_algorithm);

    var params = c.picoquic_packet_loop_param_t{
        .local_port = port,
        .local_af = 0,
        .dest_if = 0,
        .socket_buffer_size = 0,
        .do_not_use_gso = 0,
        .extra_socket_required = 0,
        .prefer_extra_socket = 0,
        .simulate_eio = 0,
        .send_length_max = 0,
    };

    const rc = c.picoquic_packet_loop_v2(quic, &params, serverLoopCallback, @constCast(&ctx));
    if (rc != 0 and rc != @as(c_int, c.PICOQUIC_NO_ERROR_TERMINATE_PACKET_LOOP)) {
        return Error.PacketLoopFailed;
    }
}

const ClientState = struct {
    allocator: std.mem.Allocator,
    message: []const u8,
    sent: bool = false,
    finished: bool = false,
    response: []u8,
    response_len: usize,

    fn init(allocator: std.mem.Allocator, message: []const u8) !ClientState {
        return .{
            .allocator = allocator,
            .message = message,
            .response = try allocator.alloc(u8, 4096),
            .response_len = 0,
        };
    }

    fn deinit(self: *ClientState) void {
        self.allocator.free(self.response);
    }
};

fn clientStreamCallback(
    cnx: ?*c.picoquic_cnx_t,
    stream_id: u64,
    bytes: [*c]u8,
    length: usize,
    fin_or_event: c.picoquic_call_back_event_t,
    callback_ctx: ?*anyopaque,
    _: ?*anyopaque,
) callconv(.c) c_int {
    const state_ptr: *ClientState = @alignCast(@ptrCast(callback_ctx.?));
    switch (fin_or_event) {
        c.picoquic_callback_prepare_to_send => {
            if (!state_ptr.sent) {
                const rc = c.picoquic_add_to_stream(cnx, stream_id, state_ptr.message.ptr, state_ptr.message.len, 1);
                if (rc != 0) return @as(c_int, rc);
                state_ptr.sent = true;
            }
        },
        c.picoquic_callback_stream_data,
        c.picoquic_callback_stream_fin,
        => {
            if (length > 0) {
                const slice = bytes[0..length];
                // Copy data to response buffer
                if (state_ptr.response_len + length > state_ptr.response.len) {
                    return @as(c_int, c.PICOQUIC_ERROR_MEMORY);
                }
                @memcpy(state_ptr.response[state_ptr.response_len..][0..length], slice);
                state_ptr.response_len += length;
            }
            if (fin_or_event == c.picoquic_callback_stream_fin) {
                state_ptr.finished = true;
            }
        },
        c.picoquic_callback_close,
        c.picoquic_callback_stop_sending,
        => {
            state_ptr.finished = true;
        },
        else => {},
    }
    return 0;
}

fn clientLoopCallback(
    _: ?*c.picoquic_quic_t,
    cb_mode: c.picoquic_packet_loop_cb_enum,
    callback_ctx: ?*anyopaque,
    _: ?*anyopaque,
) callconv(.c) c_int {
    const state_ptr: *ClientState = @alignCast(@ptrCast(callback_ctx.?));
    return switch (cb_mode) {
        c.picoquic_packet_loop_after_receive,
        c.picoquic_packet_loop_after_send,
        => if (state_ptr.finished) @as(c_int, c.PICOQUIC_NO_ERROR_TERMINATE_PACKET_LOOP) else 0,
        else => 0,
    };
}

pub fn runEchoClient(
    allocator: std.mem.Allocator,
    host: []const u8,
    port: u16,
    message: []const u8,
) ![]u8 {
    var state = try ClientState.init(allocator, message);
    defer state.deinit();

    var reset_seed: [c.PICOQUIC_RESET_SECRET_SIZE]u8 = undefined;
    @memset(&reset_seed, 0);

    const host_z = try allocator.dupeZ(u8, host);
    defer allocator.free(host_z);

    const now = c.picoquic_current_time();
    const quic = c.picoquic_create(
        1,
        null,
        null,
        null,
        ALPN,
        clientStreamCallback,
        @as(*anyopaque, @ptrCast(&state)),
        null,
        null,
        &reset_seed,
        now,
        null,
        null,
        null,
        0,
    ) orelse return Error.CreateFailed;
    defer c.picoquic_free(quic);

    c.picoquic_set_default_congestion_algorithm(quic, c.picoquic_bbr_algorithm);

    var server_address: c.sockaddr_storage = undefined;
    var is_name: c_int = 0;
    const port_c = std.math.cast(c_int, port) orelse return Error.ConnectionFailed;
    var get_addr_rc = c.picoquic_get_server_address(host_z.ptr, port_c, &server_address, &is_name);
    if (get_addr_rc != 0) return Error.ConnectionFailed;

    const server_addr_ptr = @as(*c.sockaddr, @ptrCast(&server_address));

    const cnx = c.picoquic_create_cnx(
        quic,
        c.picoquic_null_connection_id,
        c.picoquic_null_connection_id,
        server_addr_ptr,
        now,
        0,
        host_z.ptr,
        ALPN,
        1,
    ) orelse return Error.ConnectionFailed;

    c.picoquic_set_callback(cnx, clientStreamCallback, @as(*anyopaque, @ptrCast(&state)));

    get_addr_rc = c.picoquic_start_client_cnx(cnx);
    if (get_addr_rc != 0) return Error.ConnectionFailed;

    const mark_rc = c.picoquic_mark_active_stream(cnx, 0, 1, @as(*anyopaque, @ptrCast(&state)));
    if (mark_rc != 0) return Error.SendFailed;

    var params = c.picoquic_packet_loop_param_t{
        .local_port = 0,
        .local_af = server_address.ss_family,
        .dest_if = 0,
        .socket_buffer_size = 0,
        .do_not_use_gso = 0,
        .extra_socket_required = 0,
        .prefer_extra_socket = 0,
        .simulate_eio = 0,
        .send_length_max = 0,
    };

    const loop_rc = c.picoquic_packet_loop_v2(quic, &params, clientLoopCallback, @as(*anyopaque, @ptrCast(&state)));
    if (loop_rc != 0 and loop_rc != @as(c_int, c.PICOQUIC_NO_ERROR_TERMINATE_PACKET_LOOP)) {
        return Error.PacketLoopFailed;
    }

    return try allocator.dupe(u8, state.response[0..state.response_len]);
}
