const r = @cImport({
    @cInclude("raylib.h");
});

pub const Button = struct {
    rect: r.Rectangle,
    text: []const u8,
    action: *const fn (*@import("visualizer.zig").MazeVisualizer) void,

    pub fn draw(self: *const Button, active: bool) void {
        const color = if (active) r.DARKGRAY else r.GRAY;
        r.DrawRectangleRec(self.rect, color);
        r.DrawRectangleLinesEx(self.rect, 2, r.BLACK);

        const font_size = 20;
        const text_width = r.MeasureText(self.text.ptr, font_size);
        const text_x = @as(i32, @intFromFloat(self.rect.x + (self.rect.width - @as(f32, @floatFromInt(text_width))) / 2));
        const text_y = @as(i32, @intFromFloat(self.rect.y + (self.rect.height - @as(f32, @floatFromInt(font_size))) / 2));

        r.DrawText(self.text.ptr, text_x, text_y, font_size, r.BLACK);
    }

    pub fn isClicked(self: *const Button) bool {
        const mouse_pos = r.GetMousePosition();
        return r.CheckCollisionPointRec(mouse_pos, self.rect) and r.IsMouseButtonPressed(r.MOUSE_BUTTON_LEFT);
    }
};
