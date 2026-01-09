const r = @import("raylib");

pub const TARGET_FRAME_RATE: u16 = 144;
pub const NUM_FRAMES: u16 = 6;

pub const GameState = struct {
    scarfy: r.Texture = undefined,
    position: r.Vector2 = undefined,

    currentFrame: u16 = 0,

    framesCounter: u16 = 0,
    framesSpeed: u16 = 8,

    frameRec: r.Rectangle = undefined,

    pub fn init(self: *GameState, screenWidth: i32, screenHeight: i32, title: [:0]const u8) void {
        r.initWindow(screenWidth, screenHeight, title);

        self.scarfy = r.loadTexture("res/scarfy.png") catch unreachable;

        self.position = r.Vector2.init(350.0, 280.0);
        self.frameRec = r.Rectangle.init(0.0, 0.0, @as(f32, @floatFromInt(self.scarfy.width)) / @as(f32, @floatFromInt(NUM_FRAMES)), @as(f32, @floatFromInt(self.scarfy.height)));

        r.setTargetFPS(TARGET_FRAME_RATE);
    }

    pub fn deinit(self: *GameState) void {
        r.unloadTexture(self.scarfy);
        r.closeWindow();
    }
};

pub fn shouldClose() bool {
    return r.windowShouldClose();
}
