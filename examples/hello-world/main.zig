const zuws = @import("zuws");
const App = zuws.App;
const Request = zuws.Request;
const Response = zuws.Response;

pub fn main() !void {
    // you can obtain these through mkcert or similar tools for testing locally.
    // Use mkcert -install to install the CA, then mkcert localhost to generate the certs.
    const app: App = try .initSSL(.{
        .key_file_name = "localhost-key.pem",
        .cert_file_name = "localhost.pem",
    });
    defer app.deinit();

    _ = app.get("/*", hello);

    try app.listen(3000, null);
}

fn hello(res: *Response, req: *Request) void {
    _ = req;
    res.end("Hello World!\n", false);
}
