const s = @import("shared.zig");
const std = @import("std");
const builtIn = @import("builtin");

const updateAndRender_t = @TypeOf(&updateAndRenderStub);
pub fn updateAndRenderStub(_: *s.GameState) callconv(.c) void {}

var curr_lib: std.DynLib = undefined;

var oldModificationTime: i96 = 0;

const LIB_SRC_DIR = "zig-out/lib/";
const EXE_SRC_DIR = "zig-out/bin/";
const LIB_DEST_DIR = "libs/";
const LIB_NAME = if (builtIn.target.os.tag == .windows) "game.dll" else "libgame.so";
const LIB_SRC = if (builtIn.target.os.tag == .windows) EXE_SRC_DIR ++ LIB_NAME else LIB_SRC_DIR ++ LIB_NAME;

const CopyFile = struct { src: []const u8, dst: []const u8 };
const FILES_TO_COPY = if (builtIn.target.os.tag == .windows)
    [_]CopyFile{
        .{ .src = EXE_SRC_DIR ++ "game.pdb", .dst = LIB_DEST_DIR ++ "game.pdb" },
        .{ .src = LIB_SRC, .dst = LIB_DEST_DIR ++ LIB_NAME },
        .{ .src = LIB_SRC_DIR ++ "game.lib", .dst = LIB_DEST_DIR ++ "game.lib" },
    }
else
    [_]CopyFile{
        .{ .src = LIB_SRC, .dst = LIB_DEST_DIR ++ LIB_NAME },
    };

pub fn tryToReload(io: std.Io, updateAndRender: *updateAndRender_t) void {
    const stat = std.Io.Dir.statFile(std.Io.Dir.cwd(), io, LIB_SRC, .{}) catch return;
    if (stat.mtime.nanoseconds > oldModificationTime) {
        reloadCode(io, true, updateAndRender) catch unreachable;
        oldModificationTime = stat.mtime.nanoseconds;
    }
}

pub fn reloadCode(io: std.Io, closeDll: bool, updateAndRender: *updateAndRender_t) !void {
    if (closeDll) curr_lib.close();

    const cwd = std.Io.Dir.cwd();

    for (FILES_TO_COPY) |paths| {
        std.Io.Dir.copyFile(cwd, paths.src, cwd, paths.dst, io, .{}) catch |err| {
            std.debug.print("****Could not copy {s} to {s}\n", .{ paths.src, paths.dst });
            return err;
        };
    }
    const out_path = LIB_DEST_DIR ++ LIB_NAME;

    curr_lib = try std.DynLib.open(out_path);
    std.debug.print("***reloaded dll: {s}\n", .{out_path});

    updateAndRender.* = curr_lib.lookup(updateAndRender_t, "updateAndRender").?;
}

pub fn createLibraryDir(io: std.Io) !void {
    const cwd = std.Io.Dir.cwd();
    var file = cwd.openDir(io, LIB_DEST_DIR, .{});

    if (file) |*f| {
        f.close(io);
    } else |_| {
        try cwd.createDir(io, LIB_DEST_DIR, .default_file);
    }
}
