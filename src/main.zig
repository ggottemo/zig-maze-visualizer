const std = @import("std");
const r = @cImport({
    @cInclude("raylib.h");
});
const MazeVisualizer = @import("visualizer.zig").MazeVisualizer;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var visualizer = try MazeVisualizer.init(allocator, 20, 15);
    defer visualizer.deinit();

    const window_width = 960;
    const window_height = 640;

    r.InitWindow(window_width, window_height, "Maze Visualizer");
    r.SetTargetFPS(60);
    defer r.CloseWindow();

    while (!r.WindowShouldClose()) {
        visualizer.update();

        r.BeginDrawing();
        r.ClearBackground(r.WHITE);
        visualizer.draw();
        r.EndDrawing();
    }
}
