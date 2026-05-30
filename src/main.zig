const std = @import("std");
const s = @import("shared.zig");
const hotReload = @import("config").hotReload;
const rd = if (hotReload) @import("hotreload.zig") else undefined;

var updateAndRender: *const fn (*s.GameState) callconv(.c) void =
    if (hotReload) rd.updateAndRenderStub else @import("core.zig").updateAndRender;

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    const screenWidth = 800;
    const screenHeight = 450;

    if (hotReload) {
        try rd.createLibraryDir(io);
        try rd.reloadCode(io, false, &updateAndRender);
    }

    var gameState = s.GameState{};

    gameState.init(screenWidth, screenHeight, "hot reload test");
    defer gameState.deinit();

    while (!s.shouldClose()) {
        if (hotReload) {
            rd.tryToReload(io, &updateAndRender);
        }

        updateAndRender(&gameState);
    }
}
