const c = @import("uws");
const Request = @import("./Request.zig");

const Response = @This();

ptr: *c.uws_res_s,
ssl: @import("root.zig").SSL = .none,

pub fn close(res: *const Response) void {
    switch (res.ssl) {
        .ssl => c.uws_res_close_ssl(res.ptr),
        .none => c.uws_res_close(res.ptr),
    }
}

pub fn end(res: *const Response, data: []const u8, close_connection: bool) void {
    switch (res.ssl) {
        .ssl => c.uws_res_end_ssl(res.ptr, data.ptr, data.len, close_connection),
        .none => c.uws_res_end(res.ptr, data.ptr, data.len, close_connection),
    }
}

pub fn cork(res: *const Response, callback: fn (Response) void) void {
    const callbackWrapper = struct {
        fn cW(uws_res: ?*const c.uws_res_t) callconv(.c) void {
            callback(Response{ .ptr = @constCast(uws_res) orelse return });
        }
    }.cW;
    switch (res.ssl) {
        .ssl => c.uws_res_cork_ssl(res.ptr, callbackWrapper),
        .none => c.uws_res_cork(res.ptr, callbackWrapper),
    }
}

pub fn pause(res: *const Response) void {
    switch (res.ssl) {
        .ssl => c.uws_res_pause_ssl(res.ptr),
        .none => c.uws_res_pause(res.ptr),
    }
}

pub fn restart(res: *const Response) void {
    switch (res.ssl) {
        .ssl => c.uws_res_resume_ssl(res.ptr),
        .none => c.uws_res_resume(res.ptr),
    }
}

pub fn writeContinue(res: *const Response) void {
    switch (res.ssl) {
        .ssl => c.uws_res_write_continue_ssl(res.ptr),
        .none => c.uws_res_write_continue(res.ptr),
    }
}

pub fn writeStatus(res: *const Response, status: []const u8) void {
    switch (res.ssl) {
        .ssl => c.uws_res_write_status_ssl(res.ptr, status, status.len),
        .none => c.uws_res_write_status(res.ptr, status, status.len),
    }
}

pub fn writeHeader(res: *const Response, key: []const u8, value: []const u8) void {
    switch (res.ssl) {
        .ssl => c.uws_res_write_header_ssl(res.ptr, key, key.len, value, value.len),
        .none => c.uws_res_write_header(res.ptr, key, key.len, value, value.len),
    }
}

pub fn writeHeaderInt(res: *const Response, key: []const u8, value: u64) void {
    switch (res.ssl) {
        .ssl => c.uws_res_write_header_int_ssl(res.ptr, key, key.len, value),
        .none => c.uws_res_write_header_int(res.ptr, key, key.len, value),
    }
}

pub fn endWithoutBody(res: *const Response, close_connection: bool) void {
    switch (res.ssl) {
        .ssl => c.uws_res_end_without_body_ssl(res.ptr, close_connection),
        .none => c.uws_res_end_without_body(res.ptr, close_connection),
    }
}

pub fn write(res: *const Response, data: []const u8) bool {
    return switch (res.ssl) {
        .ssl => c.uws_res_write_ssl(res.ptr, data, data.len),
        .none => c.uws_res_write(res.ptr, data, data.len),
    };
}

pub fn overrideWriteOffset(res: *const Response, offset: u64) void {
    switch (res.ssl) {
        .ssl => c.uws_res_override_write_offset_ssl(res.ptr, offset),
        .none => c.uws_res_override_write_offset(res.ptr, offset),
    }
}

pub fn hasResponded(res: *const Response) bool {
    return switch (res.ssl) {
        .ssl => c.uws_res_has_responded_ssl(res.ptr),
        .none => c.uws_res_has_responded(res.ptr),
    };
}

// TODO: Look into implementing wrappers for these
pub fn onWritable(res: *const Response, handler: c.uws_res_on_writable_handler) void {
    switch (res.ssl) {
        .ssl => c.uws_res_on_writable_ssl(res.ptr, handler),
        .none => c.uws_res_on_writable(res.ptr, handler),
    }
}

pub fn onAborted(res: *const Response, handler: c.uws_res_on_aborted_handler) void {
    switch (res.ssl) {
        .ssl => c.uws_res_on_aborted_ssl(res.ptr, handler),
        .none => c.uws_res_on_aborted(res.ptr, handler),
    }
}

pub fn onData(res: *const Response, handler: c.uws_res_on_data_handler) void {
    switch (res.ssl) {
        .ssl => c.uws_res_on_data_ssl(res.ptr, handler),
        .none => c.uws_res_on_data(res.ptr, handler),
    }
}

pub fn upgrade(
    res: *const Response,
    req: *const Request,
    ws: ?*c.uws_socket_context_t,
) void {
    var ws_key: ?[*:0]const u8 = null;
    var ws_protocol: ?[*:0]const u8 = null;
    var ws_extensions: ?[*:0]const u8 = null;
    const ws_key_len = c.uws_req_get_header(req.ptr, "sec-websocket-key", 17, @ptrCast(&ws_key));
    const ws_protocol_len = c.uws_req_get_header(req.ptr, "sec-websocket-protocol", 22, @ptrCast(&ws_protocol));
    const ws_extensions_len = c.uws_req_get_header(req.ptr, "sec-websocket-extensions", 24, @ptrCast(&ws_extensions));

    switch (res.ssl) {
        .ssl => c.uws_res_upgrade_ssl(
            res.ptr,
            null,
            ws_key.?,
            ws_key_len,
            ws_protocol.?,
            ws_protocol_len,
            ws_extensions.?,
            ws_extensions_len,
            ws,
        ),
        .none => c.uws_res_upgrade(
            res.ptr,
            null,
            ws_key,
            ws_key_len,
            ws_protocol.?,
            ws_protocol_len,
            ws_extensions.?,
            ws_extensions_len,
            ws,
        ),
    }
}

pub fn tryEnd(res: *const Response, data: []const u8, totalSize: u64, close_connection: bool) c.uws_try_end_result_t {
    return switch (res.ssl) {
        .ssl => c.uws_res_try_end_ssl(res.ptr, data, data.len, totalSize, close_connection),
        .none => c.uws_res_try_end(res.ptr, data, data.len, totalSize, close_connection),
    };
}

pub fn getWriteOffset(res: *const Response) u64 {
    return switch (res.ssl) {
        .ssl => c.uws_res_get_write_offset_ssl(res.ptr),
        .none => c.uws_res_get_write_offset(res.ptr),
    };
}

pub fn getRemoteAddress(res: *const Response) [:0]const u8 {
    var temp: [*:0]const u8 = undefined;
    const len = switch (res.ssl) {
        .ssl => c.uws_res_get_remote_address_ssl(res.ptr, &temp),
        .none => c.uws_res_get_remote_address(res.ptr, &temp),
    };
    return temp[0..len :0];
}

pub fn getRemoteAddressAsText(res: *const Response) [:0]const u8 {
    var temp: [*:0]const u8 = undefined;
    const len = switch (res.ssl) {
        .ssl => c.uws_res_get_remote_address_as_text_ssl(res.ptr, &temp),
        .none => c.uws_res_get_remote_address_as_text(res.ptr, &temp),
    };
    return temp[0..len :0];
}
