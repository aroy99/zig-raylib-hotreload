const s = @import("shared.zig");
const std = @import("std");
const builtIn = @import("builtin");

const updateAndRender_t = @TypeOf(&updateAndRenderStub);
pub fn updateAndRenderStub(_: *s.GameState) callconv(.C) void {}

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
        .{ .src = EXE_SRC_DIR ++ "game.pdb", .dst = LIB_DEST_DIR ++ "game.pdb" },
        .{ .src = EXE_SRC_DIR ++ LIB_NAME, .dst = LIB_DEST_DIR ++ LIB_NAME },
        .{ .src = LIB_SRC_DIR ++ "game.lib", .dst = LIB_DEST_DIR ++ "game.lib" },
    }
else
    [_]CopyFile{
        .{ .src = LIB_SRC_DIR ++ LIB_NAME, .dst = LIB_DEST_DIR ++ LIB_NAME },
    };

pub fn tryToReload(updateAndRender: *updateAndRender_t) void {
    shouldReload += 1;
    if (shouldReload > RELOADTIME) {
        reloadCode(true, updateAndRender) catch unreachable;
        shouldReload = 0;
    }
}

pub fn reloadCode(closeDll: bool, updateAndRender: *updateAndRender_t) !void {
    if (closeDll) curr_lib.close();

    for (FILES_TO_COPY) |paths| {
        try std.fs.Dir.copyFile(std.fs.cwd(), paths.src, std.fs.cwd(), paths.dst, .{});
    }
    const out_path = LIB_DEST_DIR ++ LIB_NAME;

    curr_lib = try std.DynLib.open(out_path);
    std.debug.print("***reloaded dll: {s}\n", .{out_path});

    updateAndRender.* = curr_lib.lookup(updateAndRender_t, "updateAndRender").?;
}
