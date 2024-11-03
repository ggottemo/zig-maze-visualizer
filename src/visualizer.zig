const std = @import("std");
const r = @cImport({
    @cInclude("raylib.h");
});
const types = @import("types.zig");
const Button = @import("button.zig").Button;
const Maze = @import("maze.zig").Maze;

pub const MazeVisualizer = struct {
    maze: Maze,
    settings: types.Settings,
    state: types.ProgramState = .idle,
    current_generator: types.GeneratorType = .recursive_backtracker,
    current_solver: types.SolverType = .depth_first,
    generator_stack: std.ArrayList(@Vector(2, usize)),
    solver_queue: std.ArrayList(@Vector(2, usize)),
    solution_path: std.ArrayList(@Vector(2, usize)),
    buttons: []const Button,
    allocator: std.mem.Allocator,
    start_pos: ?@Vector(2, usize) = null,
    end_pos: ?@Vector(2, usize) = null,
    parent_map: std.AutoHashMap(@Vector(2, usize), @Vector(2, usize)),

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !*MazeVisualizer {
        const self = try allocator.create(MazeVisualizer);

        const buttons = [_]Button{
            .{
                .rect = .{ .x = 10, .y = 10, .width = 150, .height = 40 },
                .text = "Recursive Backtracker",
                .action = setRecursiveBacktracker,
            },
            .{
                .rect = .{ .x = 170, .y = 10, .width = 150, .height = 40 },
                .text = "Prim's Algorithm",
                .action = setPrimsAlgorithm,
            },
            .{
                .rect = .{ .x = 330, .y = 10, .width = 150, .height = 40 },
                .text = "Binary Tree",
                .action = setBinaryTree,
            },
            .{
                .rect = .{ .x = 10, .y = 60, .width = 150, .height = 40 },
                .text = "Generate Maze",
                .action = startGeneration,
            },
            .{
                .rect = .{ .x = 170, .y = 60, .width = 150, .height = 40 },
                .text = "Solve Maze",
                .action = startSolving,
            },
            .{
                .rect = .{ .x = 330, .y = 60, .width = 150, .height = 40 },
                .text = "Reset",
                .action = reset,
            },
            .{
                .rect = .{ .x = 10, .y = 110, .width = 150, .height = 40 },
                .text = "Depth First Search",
                .action = setDepthFirstSearch,
            },
            .{
                .rect = .{ .x = 170, .y = 110, .width = 150, .height = 40 },
                .text = "Breadth First Search",
                .action = setBreadthFirstSearch,
            },
            .{
                .rect = .{ .x = 330, .y = 110, .width = 150, .height = 40 },
                .text = "A* Search",
                .action = setAStarSearch,
            },
            .{
                .rect = .{ .x = 490, .y = 60, .width = 150, .height = 40 },
                .text = "Set Start",
                .action = startSettingStart,
            },
            .{
                .rect = .{ .x = 490, .y = 110, .width = 150, .height = 40 },
                .text = "Set End",
                .action = startSettingEnd,
            },
        };

        self.* = .{
            .maze = try Maze.init(allocator, width, height),
            .settings = types.Settings{},
            .generator_stack = std.ArrayList(@Vector(2, usize)).init(allocator),
            .solver_queue = std.ArrayList(@Vector(2, usize)).init(allocator),
            .solution_path = std.ArrayList(@Vector(2, usize)).init(allocator),
            .buttons = &buttons,
            .allocator = allocator,
            .parent_map = std.AutoHashMap(@Vector(2, usize), @Vector(2, usize)).init(allocator),
            .state = .idle,
            .current_generator = .recursive_backtracker,
            .current_solver = .depth_first,
            .start_pos = null,
            .end_pos = null,
        };

        return self;
    }

    pub fn deinit(self: *MazeVisualizer) void {
        self.maze.deinit();
        self.generator_stack.deinit();
        self.solver_queue.deinit();
        self.solution_path.deinit();
        self.parent_map.deinit();
        self.allocator.destroy(self);
    }

    pub fn setRecursiveBacktracker(self: *MazeVisualizer) void {
        if (self.state == .idle) self.current_generator = .recursive_backtracker;
    }

    pub fn setPrimsAlgorithm(self: *MazeVisualizer) void {
        if (self.state == .idle) self.current_generator = .prims;
    }

    pub fn setBinaryTree(self: *MazeVisualizer) void {
        if (self.state == .idle) self.current_generator = .binary_tree;
    }

    pub fn setDepthFirstSearch(self: *MazeVisualizer) void {
        if (self.state == .generated or self.state == .solved) self.current_solver = .depth_first;
    }

    pub fn setBreadthFirstSearch(self: *MazeVisualizer) void {
        if (self.state == .generated or self.state == .solved) self.current_solver = .breadth_first;
    }

    pub fn setAStarSearch(self: *MazeVisualizer) void {
        if (self.state == .generated or self.state == .solved) self.current_solver = .a_star;
    }

    pub fn startGeneration(self: *MazeVisualizer) void {
        if (self.state == .idle) {
            std.debug.print("Starting generation with {}\n", .{self.current_generator});
            self.reset();
            self.state = .generating;
            self.initializeGeneration();
        }
    }

    pub fn startSolving(self: *MazeVisualizer) void {
        if (self.state == .generated or self.state == .solved) {
            self.clearSolution();
            self.state = .solving;
            self.initializeSolver();
        }
    }

    pub fn startSettingStart(self: *MazeVisualizer) void {
        if (self.state == .idle or self.state == .generated or self.state == .solved) {
            self.state = .setting_start;
        }
    }

    pub fn startSettingEnd(self: *MazeVisualizer) void {
        if (self.state == .idle or self.state == .generated or self.state == .solved) {
            self.state = .setting_end;
        }
    }

    pub fn reset(self: *MazeVisualizer) void {
        self.maze.reset();
        self.generator_stack.clearRetainingCapacity();
        self.solver_queue.clearRetainingCapacity();
        self.solution_path.clearRetainingCapacity();
        self.parent_map.clearRetainingCapacity();
        self.state = .idle;
        self.start_pos = null;
        self.end_pos = null;
    }

    pub fn clearSolution(self: *MazeVisualizer) void {
        var y: usize = 0;
        while (y < self.maze.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.maze.width) : (x += 1) {
                const cell = self.maze.getCell(x, y);
                cell.path = false;
                cell.current = false;
                cell.visited = false;
            }
        }
        self.solution_path.clearRetainingCapacity();
        self.parent_map.clearRetainingCapacity();
    }

    fn initializeGeneration(self: *MazeVisualizer) void {
        self.generator_stack.clearRetainingCapacity();

        switch (self.current_generator) {
            .recursive_backtracker => {
                self.generator_stack.append(.{ 0, 0 }) catch return;
                self.maze.getCell(0, 0).visited = true;
                self.maze.getCell(0, 0).current = true;
            },
            .prims => {
                const start_x = 0;
                const start_y = 0;
                self.maze.getCell(start_x, start_y).visited = true;
                self.maze.getCell(start_x, start_y).current = true;

                for (types.DIRECTIONS) |dir| {
                    const new_x = @as(i32, @intCast(start_x)) + dir.dx;
                    const new_y = @as(i32, @intCast(start_y)) + dir.dy;
                    if (new_x >= 0 and new_x < @as(i32, @intCast(self.maze.width)) and
                        new_y >= 0 and new_y < @as(i32, @intCast(self.maze.height)))
                    {
                        self.generator_stack.append(.{ @intCast(new_x), @intCast(new_y) }) catch return;
                    }
                }
            },
            .binary_tree => {
                self.generator_stack.append(.{ 0, 0 }) catch return;
            },
        }
    }

    fn initializeSolver(self: *MazeVisualizer) void {
        if (self.start_pos == null or self.end_pos == null) {
            std.debug.print("Start or end position not set!\n", .{});
            self.state = .generated;
            return;
        }

        self.solver_queue.clearRetainingCapacity();
        self.solution_path.clearRetainingCapacity();
        self.parent_map.clearRetainingCapacity();

        // Reset visited and path flags
        var y: usize = 0;
        while (y < self.maze.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.maze.width) : (x += 1) {
                const cell = self.maze.getCell(x, y);
                cell.visited = false;
                cell.path = false;
                cell.current = false;
            }
        }

        const start = self.start_pos.?;
        self.solver_queue.append(start) catch return;
        self.maze.getCell(start[0], start[1]).visited = true;
        self.maze.getCell(start[0], start[1]).current = true;
    }

    fn stepGeneration(self: *MazeVisualizer) void {
        if (self.state != .generating) return;

        switch (self.current_generator) {
            .recursive_backtracker => self.stepRecursiveBacktracker(),
            .prims => self.stepPrims(),
            .binary_tree => self.stepBinaryTree(),
        }
    }

    fn stepRecursiveBacktracker(self: *MazeVisualizer) void {
        if (self.generator_stack.items.len == 0) {
            std.debug.print("Generation complete\n", .{});
            self.state = .generated;
            return;
        }

        const current = self.generator_stack.items[self.generator_stack.items.len - 1];
        const x = current[0];
        const y = current[1];

        std.debug.print("Processing cell ({}, {})\n", .{ x, y });

        // Clear current marker from previous cell
        self.maze.getCell(x, y).current = false;

        var unvisited_neighbors = std.ArrayList(types.Direction).init(self.allocator);
        defer unvisited_neighbors.deinit();

        // Check all neighbors
        for (types.DIRECTIONS) |dir| {
            const new_x = @as(i32, @intCast(x)) + dir.dx;
            const new_y = @as(i32, @intCast(y)) + dir.dy;

            if (new_x >= 0 and new_x < @as(i32, @intCast(self.maze.width)) and
                new_y >= 0 and new_y < @as(i32, @intCast(self.maze.height)))
            {
                const neighbor = self.maze.getCell(@intCast(new_x), @intCast(new_y));
                if (!neighbor.visited) {
                    unvisited_neighbors.append(dir) catch continue;
                }
            }
        }

        if (unvisited_neighbors.items.len > 0) {
            // Choose random unvisited neighbor
            var prng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
            const dir = unvisited_neighbors.items[prng.random().intRangeAtMost(usize, 0, unvisited_neighbors.items.len - 1)];
            const new_x = @as(usize, @intCast(@as(i32, @intCast(x)) + dir.dx));
            const new_y = @as(usize, @intCast(@as(i32, @intCast(y)) + dir.dy));

            std.debug.print("Carving wall between ({}, {}) and ({}, {})\n", .{ x, y, new_x, new_y });

            // Remove walls between current cell and chosen cell
            self.maze.getCell(x, y).walls[dir.wall_index] = false;
            self.maze.getCell(new_x, new_y).walls[dir.opposite_wall] = false;

            // Mark new cell as visited and current
            self.maze.getCell(new_x, new_y).visited = true;
            self.maze.getCell(new_x, new_y).current = true;

            self.generator_stack.append(.{ new_x, new_y }) catch return;
        } else {
            _ = self.generator_stack.pop();
            if (self.generator_stack.items.len > 0) {
                const next = self.generator_stack.items[self.generator_stack.items.len - 1];
                self.maze.getCell(next[0], next[1]).current = true;
            }
        }
    }

    fn stepPrims(self: *MazeVisualizer) void {
        if (self.generator_stack.items.len == 0) {
            self.state = .generated;
            return;
        }

        var prng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
        const rand_idx = prng.random().intRangeAtMost(usize, 0, self.generator_stack.items.len - 1);
        const current = self.generator_stack.items[rand_idx];
        _ = self.generator_stack.swapRemove(rand_idx);

        if (self.maze.getCell(current[0], current[1]).visited) return;

        // Find visited neighbors
        var visited_neighbors = std.ArrayList(types.Direction).init(self.allocator);
        defer visited_neighbors.deinit();

        for (types.DIRECTIONS) |dir| {
            const new_x = @as(i32, @intCast(current[0])) + dir.dx;
            const new_y = @as(i32, @intCast(current[1])) + dir.dy;

            if (new_x >= 0 and new_x < @as(i32, @intCast(self.maze.width)) and
                new_y >= 0 and new_y < @as(i32, @intCast(self.maze.height)))
            {
                const neighbor = self.maze.getCell(@intCast(new_x), @intCast(new_y));
                if (neighbor.visited) {
                    visited_neighbors.append(dir) catch continue;
                }
            }
        }

        if (visited_neighbors.items.len > 0) {
            var prng2 = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
            const dir = visited_neighbors.items[prng2.random().intRangeAtMost(usize, 0, visited_neighbors.items.len - 1)];

            // Connect to chosen visited neighbor
            self.maze.getCell(current[0], current[1]).walls[dir.wall_index] = false;
            const neighbor_x = @as(usize, @intCast(@as(i32, @intCast(current[0])) + dir.dx));
            const neighbor_y = @as(usize, @intCast(@as(i32, @intCast(current[1])) + dir.dy));
            self.maze.getCell(neighbor_x, neighbor_y).walls[dir.opposite_wall] = false;

            // Mark current cell as visited
            self.maze.getCell(current[0], current[1]).visited = true;
            self.maze.getCell(current[0], current[1]).current = true;

            // Add unvisited neighbors to frontier
            for (types.DIRECTIONS) |new_dir| {
                const new_x = @as(i32, @intCast(current[0])) + new_dir.dx;
                const new_y = @as(i32, @intCast(current[1])) + new_dir.dy;

                if (new_x >= 0 and new_x < @as(i32, @intCast(self.maze.width)) and
                    new_y >= 0 and new_y < @as(i32, @intCast(self.maze.height)))
                {
                    const neighbor = self.maze.getCell(@intCast(new_x), @intCast(new_y));
                    if (!neighbor.visited) {
                        self.generator_stack.append(.{ @intCast(new_x), @intCast(new_y) }) catch continue;
                    }
                }
            }
        }
    }

    fn stepBinaryTree(self: *MazeVisualizer) void {
        const current = self.generator_stack.items[0];
        const x = current[0];
        const y = current[1];

        self.maze.getCell(x, y).visited = true;
        self.maze.getCell(x, y).current = true;

        // For binary tree, we only carve north or east
        var possible_dirs = std.ArrayList(types.Direction).init(self.allocator);
        defer possible_dirs.deinit();

        // Check north
        if (y > 0) {
            possible_dirs.append(types.DIRECTIONS[0]) catch {};
        }
        // Check east
        if (x < self.maze.width - 1) {
            possible_dirs.append(types.DIRECTIONS[1]) catch {};
        }

        if (possible_dirs.items.len > 0) {
            var prng = std.rand.DefaultPrng.init(@intCast(std.time.timestamp()));
            const dir = possible_dirs.items[prng.random().intRangeAtMost(usize, 0, possible_dirs.items.len - 1)];

            const new_x = @as(usize, @intCast(@as(i32, @intCast(x)) + dir.dx));
            const new_y = @as(usize, @intCast(@as(i32, @intCast(y)) + dir.dy));

            self.maze.getCell(x, y).walls[dir.wall_index] = false;
            self.maze.getCell(new_x, new_y).walls[dir.opposite_wall] = false;
        }

        // Move to next cell
        if (x < self.maze.width - 1) {
            self.generator_stack.items[0] = .{ x + 1, y };
        } else if (y < self.maze.height - 1) {
            self.generator_stack.items[0] = .{ 0, y + 1 };
        } else {
            self.state = .generated;
            return;
        }

        // Clear current marker from previous cell
        self.maze.getCell(x, y).current = false;
    }

    fn stepSolver(self: *MazeVisualizer) void {
        if (self.state != .solving or self.start_pos == null or self.end_pos == null) return;

        switch (self.current_solver) {
            .depth_first => self.stepDepthFirstSearch(),
            .breadth_first => self.stepBreadthFirstSearch(),
            .a_star => self.stepAStarSearch(),
        }
    }

    fn reconstructPath(self: *MazeVisualizer, end_pos: @Vector(2, usize)) !void {
        var current = end_pos;
        while (self.parent_map.get(current)) |parent| {
            self.maze.getCell(current[0], current[1]).path = true;
            try self.solution_path.append(current);
            current = parent;
        }
        // Don't forget to mark the start position
        self.maze.getCell(current[0], current[1]).path = true;
        try self.solution_path.append(current);
    }

    fn manhattanDistance(a: @Vector(2, usize), b: @Vector(2, usize)) usize {
        const dx = if (a[0] > b[0]) a[0] - b[0] else b[0] - a[0];
        const dy = if (a[1] > b[1]) a[1] - b[1] else b[1] - a[1];
        return dx + dy;
    }

    fn getGScore(self: *MazeVisualizer, pos: @Vector(2, usize)) usize {
        var steps: usize = 0;
        var current = pos;
        while (self.parent_map.get(current)) |parent| {
            steps += 1;
            current = parent;
        }
        return steps;
    }

    fn stepDepthFirstSearch(self: *MazeVisualizer) void {
        if (self.solver_queue.items.len == 0) {
            self.state = .solved;
            return;
        }

        const current = self.solver_queue.items[self.solver_queue.items.len - 1];
        const x = current[0];
        const y = current[1];

        self.maze.getCell(x, y).current = false;

        if (x == self.end_pos.?[0] and y == self.end_pos.?[1]) {
            self.reconstructPath(current) catch {};
            self.state = .solved;
            return;
        }

        var unvisited_neighbors = std.ArrayList(types.Direction).init(self.allocator);
        defer unvisited_neighbors.deinit();

        for (types.DIRECTIONS) |dir| {
            const new_x = @as(i32, @intCast(x)) + dir.dx;
            const new_y = @as(i32, @intCast(y)) + dir.dy;

            if (new_x >= 0 and new_x < @as(i32, @intCast(self.maze.width)) and
                new_y >= 0 and new_y < @as(i32, @intCast(self.maze.height)))
            {
                const current_cell = self.maze.getCell(x, y);
                const neighbor = self.maze.getCell(@intCast(new_x), @intCast(new_y));

                if (!neighbor.visited and !current_cell.walls[dir.wall_index]) {
                    unvisited_neighbors.append(dir) catch continue;
                }
            }
        }

        if (unvisited_neighbors.items.len > 0) {
            const dir = unvisited_neighbors.items[0];
            const new_x = @as(usize, @intCast(@as(i32, @intCast(x)) + dir.dx));
            const new_y = @as(usize, @intCast(@as(i32, @intCast(y)) + dir.dy));

            self.maze.getCell(new_x, new_y).visited = true;
            self.maze.getCell(new_x, new_y).current = true;

            const new_pos = @Vector(2, usize){ new_x, new_y };
            self.parent_map.put(new_pos, current) catch {};
            self.solver_queue.append(new_pos) catch return;
        } else {
            _ = self.solver_queue.pop();
            if (self.solver_queue.items.len > 0) {
                const next = self.solver_queue.items[self.solver_queue.items.len - 1];
                self.maze.getCell(next[0], next[1]).current = true;
            }
        }
    }

    fn stepBreadthFirstSearch(self: *MazeVisualizer) void {
        if (self.solver_queue.items.len == 0) {
            self.state = .solved;
            return;
        }

        const current = self.solver_queue.orderedRemove(0);
        const x = current[0];
        const y = current[1];

        self.maze.getCell(x, y).current = false;

        if (x == self.end_pos.?[0] and y == self.end_pos.?[1]) {
            self.reconstructPath(current) catch {};
            self.state = .solved;
            return;
        }

        for (types.DIRECTIONS) |dir| {
            const new_x = @as(i32, @intCast(x)) + dir.dx;
            const new_y = @as(i32, @intCast(y)) + dir.dy;

            if (new_x >= 0 and new_x < @as(i32, @intCast(self.maze.width)) and
                new_y >= 0 and new_y < @as(i32, @intCast(self.maze.height)))
            {
                const current_cell = self.maze.getCell(x, y);
                const neighbor = self.maze.getCell(@intCast(new_x), @intCast(new_y));

                if (!neighbor.visited and !current_cell.walls[dir.wall_index]) {
                    neighbor.visited = true;
                    neighbor.current = true;
                    const new_pos = @Vector(2, usize){ @intCast(new_x), @intCast(new_y) };
                    self.parent_map.put(new_pos, current) catch continue;
                    self.solver_queue.append(new_pos) catch continue;
                }
            }
        }
    }

    fn stepAStarSearch(self: *MazeVisualizer) void {
        if (self.solver_queue.items.len == 0) {
            self.state = .solved;
            return;
        }

        var min_f_score: usize = std.math.maxInt(usize);
        var min_index: usize = 0;
        const end_pos = self.end_pos.?;

        for (self.solver_queue.items, 0..) |pos, i| {
            const g_score = self.getGScore(pos);
            const h_score = manhattanDistance(pos, end_pos);
            const f_score = g_score + h_score;

            if (f_score < min_f_score) {
                min_f_score = f_score;
                min_index = i;
            }
        }

        const current = self.solver_queue.orderedRemove(min_index);
        self.maze.getCell(current[0], current[1]).current = false;

        if (current[0] == end_pos[0] and current[1] == end_pos[1]) {
            self.reconstructPath(end_pos) catch {};
            self.state = .solved;
            return;
        }

        for (types.DIRECTIONS) |dir| {
            const new_x = @as(i32, @intCast(current[0])) + dir.dx;
            const new_y = @as(i32, @intCast(current[1])) + dir.dy;

            if (new_x >= 0 and new_x < @as(i32, @intCast(self.maze.width)) and
                new_y >= 0 and new_y < @as(i32, @intCast(self.maze.height)))
            {
                const current_cell = self.maze.getCell(current[0], current[1]);
                const neighbor = self.maze.getCell(@intCast(new_x), @intCast(new_y));

                if (!neighbor.visited and !current_cell.walls[dir.wall_index]) {
                    neighbor.visited = true;
                    neighbor.current = true;
                    const new_pos = @Vector(2, usize){ @intCast(new_x), @intCast(new_y) };
                    self.parent_map.put(new_pos, current) catch continue;
                    self.solver_queue.append(new_pos) catch continue;
                }
            }
        }
    }

    pub fn handleMouseClick(self: *MazeVisualizer) void {
        const mouse_pos = r.GetMousePosition();
        const total_width = @as(i32, @intCast(self.maze.width)) * self.settings.cell_size;
        const total_height = @as(i32, @intCast(self.maze.height)) * self.settings.cell_size;
        const start_x = @divTrunc(r.GetScreenWidth() - total_width, 2);
        const start_y = @divTrunc(r.GetScreenHeight() - total_height, 2) + 80; // Offset for buttons

        if (mouse_pos.x < @as(f32, @floatFromInt(start_x)) or
            mouse_pos.y < @as(f32, @floatFromInt(start_y)) or
            mouse_pos.x >= @as(f32, @floatFromInt(start_x + total_width)) or
            mouse_pos.y >= @as(f32, @floatFromInt(start_y + total_height)))
        {
            return;
        }

        const grid_x = @as(usize, @intFromFloat(@floor((mouse_pos.x - @as(f32, @floatFromInt(start_x))) / @as(f32, @floatFromInt(self.settings.cell_size)))));
        const grid_y = @as(usize, @intFromFloat(@floor((mouse_pos.y - @as(f32, @floatFromInt(start_y))) / @as(f32, @floatFromInt(self.settings.cell_size)))));

        if (grid_x < self.maze.width and grid_y < self.maze.height) {
            switch (self.state) {
                .setting_start => {
                    if (self.start_pos) |old_start| {
                        self.maze.getCell(old_start[0], old_start[1]).is_start = false;
                    }
                    self.start_pos = .{ grid_x, grid_y };
                    self.maze.getCell(grid_x, grid_y).is_start = true;
                    self.state = .generated;
                },
                .setting_end => {
                    if (self.end_pos) |old_end| {
                        self.maze.getCell(old_end[0], old_end[1]).is_end = false;
                    }
                    self.end_pos = .{ grid_x, grid_y };
                    self.maze.getCell(grid_x, grid_y).is_end = true;
                    self.state = .generated;
                },
                else => {},
            }
        }
    }

    pub fn update(self: *MazeVisualizer) void {
        for (self.buttons) |*button| {
            if (button.isClicked()) {
                std.debug.print("Button clicked: {s}\n", .{button.text});
                button.action(self);
            }
        }

        if (r.IsMouseButtonPressed(r.MOUSE_BUTTON_LEFT)) {
            self.handleMouseClick();
        }

        if (self.state == .generating) {
            self.stepGeneration();
        } else if (self.state == .solving) {
            self.stepSolver();
        }
    }

    pub fn draw(self: *MazeVisualizer) void {
        // Draw buttons
        for (self.buttons) |*button| {
            const active = switch (self.state) {
                .idle => true,
                .setting_start => true,
                .setting_end => true,
                .generating => false,
                .generated => true,
                .solving => false,
                .solved => true,
            };
            button.draw(active);
        }

        // Draw maze
        const total_width = @as(i32, @intCast(self.maze.width)) * self.settings.cell_size;
        const total_height = @as(i32, @intCast(self.maze.height)) * self.settings.cell_size;
        const start_x = @divTrunc(r.GetScreenWidth() - total_width, 2);
        const start_y = @divTrunc(r.GetScreenHeight() - total_height, 2) + 80; // Offset for buttons

        var y: usize = 0;
        while (y < self.maze.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.maze.width) : (x += 1) {
                const cell = self.maze.getCell(x, y);
                const cell_x = start_x + @as(i32, @intCast(x)) * self.settings.cell_size;
                const cell_y = start_y + @as(i32, @intCast(y)) * self.settings.cell_size;

                // Draw cell background
                var cell_color = r.WHITE;
                if (cell.visited) cell_color = r.LIGHTGRAY;
                if (cell.path) cell_color = r.GREEN;
                if (cell.current) cell_color = r.YELLOW;
                if (cell.is_start) cell_color = r.BLUE;
                if (cell.is_end) cell_color = r.RED;

                r.DrawRectangle(
                    cell_x,
                    cell_y,
                    self.settings.cell_size,
                    self.settings.cell_size,
                    cell_color,
                );

                // Draw walls
                if (cell.walls[0]) { // top
                    r.DrawLineEx(
                        .{ .x = @as(f32, @floatFromInt(cell_x)), .y = @as(f32, @floatFromInt(cell_y)) },
                        .{ .x = @as(f32, @floatFromInt(cell_x + self.settings.cell_size)), .y = @as(f32, @floatFromInt(cell_y)) },
                        @as(f32, @floatFromInt(self.settings.wall_thickness)),
                        r.BLACK,
                    );
                }
                if (cell.walls[1]) { // right
                    r.DrawLineEx(
                        .{ .x = @as(f32, @floatFromInt(cell_x + self.settings.cell_size)), .y = @as(f32, @floatFromInt(cell_y)) },
                        .{ .x = @as(f32, @floatFromInt(cell_x + self.settings.cell_size)), .y = @as(f32, @floatFromInt(cell_y + self.settings.cell_size)) },
                        @as(f32, @floatFromInt(self.settings.wall_thickness)),
                        r.BLACK,
                    );
                }
                if (cell.walls[2]) { // bottom
                    r.DrawLineEx(
                        .{ .x = @as(f32, @floatFromInt(cell_x)), .y = @as(f32, @floatFromInt(cell_y + self.settings.cell_size)) },
                        .{ .x = @as(f32, @floatFromInt(cell_x + self.settings.cell_size)), .y = @as(f32, @floatFromInt(cell_y + self.settings.cell_size)) },
                        @as(f32, @floatFromInt(self.settings.wall_thickness)),
                        r.BLACK,
                    );
                }
                if (cell.walls[3]) { // left
                    r.DrawLineEx(
                        .{ .x = @as(f32, @floatFromInt(cell_x)), .y = @as(f32, @floatFromInt(cell_y)) },
                        .{ .x = @as(f32, @floatFromInt(cell_x)), .y = @as(f32, @floatFromInt(cell_y + self.settings.cell_size)) },
                        @as(f32, @floatFromInt(self.settings.wall_thickness)),
                        r.BLACK,
                    );
                }
            }
        }

        // Draw hover highlight for setting start/end positions
        if (self.state == .setting_start or self.state == .setting_end) {
            const mouse_pos = r.GetMousePosition();
            if (mouse_pos.x >= @as(f32, @floatFromInt(start_x)) and
                mouse_pos.y >= @as(f32, @floatFromInt(start_y)) and
                mouse_pos.x < @as(f32, @floatFromInt(start_x + total_width)) and
                mouse_pos.y < @as(f32, @floatFromInt(start_y + total_height)))
            {
                const grid_x = @as(usize, @intFromFloat(@floor((mouse_pos.x - @as(f32, @floatFromInt(start_x))) / @as(f32, @floatFromInt(self.settings.cell_size)))));
                const grid_y = @as(usize, @intFromFloat(@floor((mouse_pos.y - @as(f32, @floatFromInt(start_y))) / @as(f32, @floatFromInt(self.settings.cell_size)))));

                if (grid_x < self.maze.width and grid_y < self.maze.height) {
                    const highlight_x = start_x + @as(i32, @intCast(grid_x)) * self.settings.cell_size;
                    const highlight_y = start_y + @as(i32, @intCast(grid_y)) * self.settings.cell_size;
                    const highlight_color = if (self.state == .setting_start) r.BLUE else r.RED;

                    r.DrawRectangleLinesEx(
                        .{
                            .x = @as(f32, @floatFromInt(highlight_x)),
                            .y = @as(f32, @floatFromInt(highlight_y)),
                            .width = @as(f32, @floatFromInt(self.settings.cell_size)),
                            .height = @as(f32, @floatFromInt(self.settings.cell_size)),
                        },
                        3,
                        highlight_color,
                    );
                }
            }
        }
    }
};

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
