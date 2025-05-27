const c = @import("uws");
const std = @import("std");
const App = @import("./App.zig");

const Request = @This();

ptr: *c.uws_req_s,

pub fn getUrl(res: *const Request) []const u8 {
    var temp: [*:0]const u8 = undefined;
    const len = c.uws_req_get_url(res.ptr, @ptrCast(&temp));
    return temp[0..len];
}

pub fn getFullUrl(res: *const Request) []const u8 {
    var temp: [*:0]const u8 = undefined;
    const len = c.uws_req_get_full_url(res.ptr, @ptrCast(&temp));
    return temp[0..len];
}

pub fn getMethod(res: *const Request) !App.Method {
    const method = @constCast(res.getCaseSensitiveMethod());

    for (method) |*char| {
        char.* = std.ascii.toUpper(char.*);
    }

    return std.meta.stringToEnum(App.Method, method) orelse error.UnknownMethod;
}

pub fn getCaseSensitiveMethod(res: *const Request) []const u8 {
    var temp: [*:0]const u8 = undefined;
    const len = c.uws_req_get_case_sensitive_method(res.ptr, @ptrCast(&temp));
    return temp[0..len];
}

pub fn getHeader(res: *const Request, lowerCaseHeader: []const u8) []const u8 {
    var temp: [*:0]const u8 = undefined;
    const len = c.uws_req_get_header(res.ptr, lowerCaseHeader.ptr, lowerCaseHeader.len, @ptrCast(&temp));
    return temp[0..len];
}

pub fn getQueryParam(res: *const Request, name: []const u8) []const u8 {
    var temp: [*:0]const u8 = undefined;
    const len = c.uws_req_get_query(res.ptr, name.ptr, name.len, @ptrCast(&temp));
    return temp[0..len];
}

pub fn getParameter(res: *const Request, index: u16) []const u8 {
    var temp: [*:0]const u8 = undefined;
    const len = c.uws_req_get_parameter_index(res.ptr, @as(c_ushort, index), @ptrCast(&temp));
    return temp[0..len];
}
