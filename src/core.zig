const r = @import("raylib");
const s = @import("shared.zig");
const std = @import("std");

const MAX_FRAME_SPEED: u16 = 15;
const MIN_FRAME_SPEED: u16 = 1;

pub export fn updateAndRender(gs: *s.GameState) void {
    gs.framesCounter += 1;
    if (gs.framesCounter >= @divFloor(s.TARGET_FRAME_RATE, gs.framesSpeed)) {
        gs.framesCounter = 0;
        gs.currentFrame += 1;

        if (gs.currentFrame > 5) {
            gs.currentFrame = 0;
        }

        gs.frameRec.x = @as(f32, @floatFromInt(gs.currentFrame * @divFloor(gs.scarfy.width, s.NUM_FRAMES)));
    }

    // Control frames speed
    if (r.isKeyPressed(r.KeyboardKey.right)) {
        gs.framesSpeed += 1;
    } else if (r.isKeyPressed(r.KeyboardKey.left)) {
        gs.framesSpeed -= 1;
    }

    if (gs.framesSpeed > MAX_FRAME_SPEED) {
        gs.framesSpeed = MAX_FRAME_SPEED;
    } else if (gs.framesSpeed < MIN_FRAME_SPEED) {
        gs.framesSpeed = MIN_FRAME_SPEED;
    }

    r.beginDrawing();
    defer r.endDrawing();
    {
        r.clearBackground(r.Color.ray_white);

        r.drawTexture(gs.scarfy, 15, 40, r.Color.white);
        r.drawRectangleLines(15, 40, gs.scarfy.width, gs.scarfy.height, r.Color.lime);
        r.drawRectangleLines(15 + @as(i32, @intFromFloat(gs.frameRec.x)), 40 + @as(i32, @intFromFloat(gs.frameRec.y)), @as(i32, @intFromFloat(gs.frameRec.width)), @as(i32, @intFromFloat(gs.frameRec.height)), r.Color.red);

        r.drawText("Frame Speed: ", 165, 210, 10, r.Color.dark_gray);
        r.drawText(r.textFormat("%02i FPS", .{gs.framesSpeed}), 575, 210, 10, r.Color.dark_gray);
        r.drawText("Hot reloading now works!", 290, 240, 10, r.Color.dark_gray);

        var i: i32 = 0;
        while (i < MAX_FRAME_SPEED) : (i += 1) {
            if (i < gs.framesSpeed) {
                r.drawRectangle(250 + 21 * i, 205, 20, 20, r.Color.red);
            }
            r.drawRectangleLines(250 + 21 * i, 205, 20, 20, r.Color.maroon);
        }

        r.drawTextureRec(gs.scarfy, gs.frameRec, gs.position, r.Color.white); // Draw part of the texture
    }
}
