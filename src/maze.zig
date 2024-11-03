const std = @import("std");
const types = @import("types.zig");

pub const Maze = struct {
    cells: []types.Cell,
    width: usize,
    height: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Maze {
        const cells = try allocator.alloc(types.Cell, width * height);
        for (cells) |*cell| {
            cell.* = types.Cell.init();
        }
        return Maze{
            .cells = cells,
            .width = width,
            .height = height,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Maze) void {
        self.allocator.free(self.cells);
    }

    pub fn getCell(self: *Maze, x: usize, y: usize) *types.Cell {
        return &self.cells[y * self.width + x];
    }

    pub fn reset(self: *Maze) void {
        for (self.cells) |*cell| {
            cell.* = types.Cell.init();
        }
    }
};
