const std = @import("std");
const builtIn = @import("builtin");
const s = @import("shared.zig");

var updateAndRender: *const fn (*s.GameState) void = &updateAndRenderStub;

const updateAndRender_t = @TypeOf(updateAndRender);

var curr_lib: std.DynLib = undefined;

var shouldReload: u16 = 0;
const RELOADTIME = 144;

const LIB_SRC_DIR = "zig-out/lib/";
const EXE_SRC_DIR = "zig-out/bin/";
const LIB_DEST_DIR = "libs/";
const LIB_NAME = if (builtIn.target.os.tag == .windows) "game.dll" else "libgame.so";

const CopyFile = struct { src: []const u8, dst: []const u8 };
const FILES_TO_COPY = if (builtIn.target.os.tag == .windows)
    [_]CopyFile{
        .{ .src = EXE_SRC_DIR ++ "/game.pdb", .dst = LIB_DEST_DIR ++ "/game.pdb" },
        .{ .src = EXE_SRC_DIR ++ LIB_NAME, .dst = LIB_DEST_DIR ++ LIB_NAME },
        .{ .src = LIB_SRC_DIR ++ "/game.lib", .dst = LIB_DEST_DIR ++ "/game.lib" },
    }
else
    [_]CopyFile{
        .{ .src = LIB_SRC_DIR ++ LIB_NAME, .dst = LIB_DEST_DIR ++ LIB_NAME },
        .{ .src = LIB_SRC_DIR ++ "/game.lib", .dst = LIB_DEST_DIR ++ "/game.lib" },
    };

pub fn main() !void {
    const screenWidth = 800;
    const screenHeight = 450;

    try reloadCode(false);

    var gameState = s.GameState{};

    gameState.init(screenWidth, screenHeight, "hot reload test");
    defer gameState.deinit();

    while (!s.shouldClose()) {
        shouldReload += 1;
        if (shouldReload > RELOADTIME) {
            reloadCode(true) catch unreachable;
            shouldReload = 0;
        }

        updateAndRender(&gameState);
    }
}

fn reloadCode(closeDll: bool) !void {
    if (closeDll) curr_lib.close();

    for (FILES_TO_COPY) |paths| {
        try std.fs.Dir.copyFile(std.fs.cwd(), paths.src, std.fs.cwd(), paths.dst, .{});
    }
    const out_path = LIB_DEST_DIR ++ LIB_NAME;

    curr_lib = try std.DynLib.open(out_path);
    std.debug.print("***reloaded dll: {s}\n", .{out_path});

    updateAndRender = curr_lib.lookup(updateAndRender_t, "updateAndRender").?;
}

fn updateAndRenderStub(_: *s.GameState) void {}
