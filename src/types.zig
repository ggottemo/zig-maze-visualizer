const std = @import("std");
const r = @cImport({
    @cInclude("raylib.h");
});

pub const Cell = struct {
    walls: [4]bool, // top, right, bottom, left
    visited: bool,
    path: bool, // used for visualization of solution path
    current: bool, // marks current cell being processed
    is_start: bool = false,
    is_end: bool = false,

    pub fn init() Cell {
        return Cell{
            .walls = [4]bool{ true, true, true, true },
            .visited = false,
            .path = false,
            .current = false,
            .is_start = false,
            .is_end = false,
        };
    }
};

pub const Direction = struct {
    dx: i32,
    dy: i32,
    wall_index: usize,
    opposite_wall: usize,
};

pub const DIRECTIONS = [_]Direction{
    .{ .dx = 0, .dy = -1, .wall_index = 0, .opposite_wall = 2 }, // top
    .{ .dx = 1, .dy = 0, .wall_index = 1, .opposite_wall = 3 }, // right
    .{ .dx = 0, .dy = 1, .wall_index = 2, .opposite_wall = 0 }, // bottom
    .{ .dx = -1, .dy = 0, .wall_index = 3, .opposite_wall = 1 }, // left
};

pub const GeneratorType = enum {
    recursive_backtracker,
    prims,
    binary_tree,
};

pub const SolverType = enum {
    depth_first,
    breadth_first,
    a_star,
};

pub const ProgramState = enum {
    idle,
    generating,
    generated,
    setting_start,
    setting_end,
    solving,
    solved,
};

pub const Settings = struct {
    cell_size: i32 = 30,
    wall_thickness: i32 = 2,
};
