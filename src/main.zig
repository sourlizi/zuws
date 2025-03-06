const std = @import("std");
const App = @import("./App.zig");
const Request = @import("./Request.zig");
const Response = @import("./Response.zig");
const WebSocket = @import("./WebSocket.zig");

const c = @import("uws");

pub fn main() !void {
    const app = try App.init();
    defer app.deinit();

    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    const cmp = App.Group.initComptime("/comptime")
        .get("/hi", hello);
    const cmp1 = App.Group.initComptime("/v1")
        .get("/yo", hello);
    _ = cmp.group(cmp1)
        .merge(cmp1);

    _ = app.comptimeGroup(cmp);

    var r1 = App.Group.init(allocator, "/v1");
    try r1.get("/yo", rawHello);
    var r2 = App.Group.init(allocator, "/runtime");
    try r2.get("/hi", rawHello);
    try r2.group(r1);
    try r2.merge(r1);
    r1.deinit();

    try app.group(&r2);

    // List needs to be manually de initialized at runtime
    // `defer` only runs when the scope ends
    // but as this is main, the scope will never end while the app is running
    r2.deinit();

    try app.ws("/ws", .{
        // zig fmt: off
            .upgrade = on_upgrade,
            .open = on_open,
            .message = on_message,
            .dropped = on_message,
            .drain = on_drain,
            .ping = on_ping,
            .pong = on_pong,
            .close = on_close,
            .subscription = on_subscription,
        })
        // zig fmt: on
        .get("/get", hello)
        .get("/get/:id", hello2)
        .listen(3001, null);
}

fn corked(res: Response) void {
    const str = "Hello World!\n";
    res.end(str, false);
}

fn hello(res: *Response, req: *Request) void {
    _ = req;
    res.cork(corked);
}

fn rawHello(rawRes: ?*c.struct_uws_res_s, rawReq: ?*c.struct_uws_req_s) callconv(.c) void {
    var res = Response{ .ptr = rawRes orelse return };
    _ = rawReq;
    const str = "Hello World!\n";
    res.end(str, false);
}

fn hello2(res: *Response, req: *Request) void {
    const method = req.getMethod() catch unreachable;
    std.debug.print("{any}\n", .{method});
    std.debug.print("{s}\n", .{req.getParameter(0)});
    const str = "Hello World!\n";
    res.end(str, false);
}

fn on_upgrade(res: *Response, req: *Request) void {
    std.debug.print("Upgrade: {any} | {any}\n", .{ res, req });
}
fn on_open(ws: *WebSocket) void {
    std.debug.print("Open: {any}\n", .{ws});
    _ = ws.subscribe("NonsensicalTest");
}
fn on_message(ws: *WebSocket, message: [:0]const u8, opcode: WebSocket.Opcode) void {
    std.debug.print("Message: {any} | {any} | {any}\n", .{ ws, message, opcode });
    _ = ws.send("UwU", .TEXT);
}
fn on_drain(ws: *WebSocket) void {
    std.debug.print("Drain: {any}\n", .{ws});
}
fn on_ping(ws: *WebSocket, message: [:0]const u8) void {
    std.debug.print("Ping: {any} | {any}\n", .{ ws, message });
}
fn on_pong(ws: *WebSocket, message: [:0]const u8) void {
    std.debug.print("Pong: {any} | {any}\n", .{ ws, message });
}
fn on_close(ws: *WebSocket, code: i32, message: [:0]const u8) void {
    std.debug.print("Close: {any} | {any} | {any}\n", .{ ws, code, message });
}
fn on_subscription(ws: *WebSocket, topic: [:0]const u8, newNumberOfSubscribers: i32, oldNumberOfSubscribers: i32) void {
    std.debug.print("Subscription: {any} | {any} | {any} | {any}\n", .{ ws, topic, newNumberOfSubscribers, oldNumberOfSubscribers });
}
