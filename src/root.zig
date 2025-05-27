pub const App = @import("./App.zig");
pub const Request = @import("./Request.zig");
pub const Response = @import("./Response.zig");
pub const WebSocket = @import("./WebSocket.zig");

/// A uSocket
pub const Socket = opaque {};

pub const SSL = enum {
    ssl,
    none,
};
