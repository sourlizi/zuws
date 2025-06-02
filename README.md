# zuws

Opinionated zig bindings for [`uWebsockets`](https://github.com/uNetworking/uWebSockets). Now with SSL support through boringssl.

# Installation

`zuws` is available using the `zig fetch` command.

```sh
zig fetch --save git+https://github.com/sourlizi/zuws
```

To add it to your project, after running the command above add the following to your `build.zig` file:

```zig
const zuws = b.dependency("zuws", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("zuws", zuws.module("zuws"));
```

> [!NOTE]
> You can disable the default debug logs by passing `.debug_logs = false` as an option.

## Using the C bindings

You can import the C bindings directly instead of the `zuws` wrapper by using the following:

```zig
exe.root_module.addImport("uws", zuws.module("uws"));
```

# Usage

```zig
const uws = @import("zuws");
const App = uws.App;
const Request = uws.Request;
const Response = uws.Response;

pub fn main() !void {
    const app: App = try .init();
    defer app.deinit();

    try app.get("/hello", hello)
        .listen(3000, null);
}

fn hello(res: *Response, req: *Request) void {
    _ = req;
    const str = "Hello World!\n";
    res.end(str, false);
}
```


```zig
const uws = @import("zuws");
const App = uws.App;
const Request = uws.Request;
const Response = uws.Response;

pub fn main() !void {
    const app: App = try .initSSL(.{
        .cert_file_name = "path/to/cert.pem",
        .key_file_name = "path/to/key.pem",
        .passphrase = "your_passphrase", // Optional, if your key is encrypted
    });
    defer app.deinit();

    try app.get("/hello", hello)
        .listen(3000, null);
}

fn hello(res: *Response, req: *Request) void {
    _ = req;
    const str = "Hello World!\n";
    res.end(str, false);
}
```

# Grouping

Grouping is not something provided by uws itself and instead is an abstraction we provide to aid developers.

The grouping API has a `comptime` and a `runtime` variant, most of the time you will want to use the `comptime` variant, but for the rare cases where adding routes at runtime dynamically is needed the functionality is there.

## Creating groups at `comptime`

```zig
const app: App = try .init();
defer app.deinit();

const my_group = App.Group.initComptime("/v1")
    .get("/example", someHandler);

// This will create the following route:
// /v1/example
app.comptimeGroup(my_group);
```

## Creating groups at `runtime`

```zig
const app: App = try .init();
defer app.deinit();

var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
const allocator = gpa.allocator();

var my_group = App.Group.init(allocator, "/v1");
try my_group.get("/example", someHandler);

// This will create the following route:
// /v1/example
try app.group(my_group);

// We highly recommend you deinit the group
// after you don't need it anymore
my_group.deinit();


```

## Combining groups together

We provide 2 different ways of combining groups together.

### Grouping

```zig
const app: App = try .init();
defer app.deinit();

const api = App.Group.initComptime("/api");
const v1 = App.Group.initComptime("/v1")
    .get("/example", someHandler);

_ = api.group(v1);

// This will create the following route:
// /api/v1/example
app.comptimeGroup(api);
```

### Merging

```zig
const app: App = try .init();
defer app.deinit();

const v1 = App.Group.initComptime("/v1")
    .get("/example", someHandler);
const v2 = App.Group.initComptime("/v2");

_ = v2.merge(v1);

// This will create the following route:
// /v2/example
app.comptimeGroup(v2);
```

# Running the Examples

To run the provided examples in `zuws` you can clone the repository (don't forget to initialize the submodules), and run the following command:

```zsh
zig build example -- <example-name>
```

You can also generate the assembly of a specific example using the following:

```zsh
zig build example-asm -- <example-name>
```
