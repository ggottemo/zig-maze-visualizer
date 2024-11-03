# RayZig - Maze Generation & Pathfinding Visualization

A maze generation and pathfinding visualization project built with Zig and Raylib. This project demonstrates various maze generation algorithms and pathfinding techniques in an interactive visual environment.

## Features

- Multiple maze generation algorithms:
  - Recursive Backtracker
  - Prim's Algorithm
  - Binary Tree Algorithm
- Multiple pathfinding algorithms:
  - Depth-First Search
  - Breadth-First Search
  - A* Search
- Interactive start/end point placement
- Real-time visualization of generation and solving
- Clean, modular Zig codebase

## Getting Started

1. Clone the project:
```bash
git clone https://github.com/yourusername/RayZig.git
```

2. Update the Raylib submodule:
```bash
git submodule update --init
```

3. Build and run:
```bash
zig build run
```

## Project Structure

- `src/main.zig` - Entry point and window management
- `src/types.zig` - Core type definitions and constants
- `src/maze.zig` - Maze data structure
- `src/button.zig` - UI button component
- `src/visualizer.zig` - Main visualization and algorithm logic

## Usage

1. Select a maze generation algorithm using the top buttons
2. Click "Generate Maze" to create a new maze
3. Set start and end points by clicking the respective buttons and then clicking cells in the maze
4. Select a pathfinding algorithm
5. Click "Solve Maze" to visualize the pathfinding process
6. Use "Reset" to start over

## Requirements

- Zig 0.11.0 or later
- Raylib (included as submodule)

## Building from Source

The project uses Zig's build system. No additional setup is required beyond having Zig installed and initializing the Raylib submodule.

## Contributing

Feel free to open issues or submit pull requests with improvements or bug fixes.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on the RayZig template by ipinzi
- Uses Raylib for graphics rendering