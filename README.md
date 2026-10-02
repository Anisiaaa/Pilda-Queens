#Pilda Queens

A Godot 4.7 implementation of a Queens-style logic puzzle. Place skulls on an 8×8 board under multiple simultaneous constraints, with every level generated fresh and guaranteed to have exactly one solution.
About the Game

Each puzzle asks you to place exactly 8 skulls, one per row, while obeying four placement rules at once. The board is divided into 8 colored regions, and the region shapes are generated to work together with the skull positions to produce a puzzle with a single, unique solution.
Rules

    Place exactly 8 skulls — one in every row.

    No two skulls may share a row.

    No two skulls may share a column.

    No two skulls may be adjacent, including diagonally.

    No two skulls may share the same colored region.

#Controls

    Left click a cell to cycle it: Empty → X → Skull → Empty

    Right click a non-empty cell to clear it

#Win / Loss

    Win: all 8 skulls placed with every rule satisfied.

    Lose: 3 wrong skull placements. Click the board to retry the same level.

    New level: after a win, a fresh level is generated automatically.

#How Levels Are Generated

Every level is built from scratch at runtime, with two guarantees: exactly one solution, and no repeats within a session.
1. Skull layout

The generator first places 8 skulls at random, one per row, obeying the no-same-column and no-adjacency rules. If a placement dead-ends, it retries. Each successful layout defines where the solution will be — everything else is built around it.
2. Region growing

Starting from the 8 skulls, the generator grows 8 colored regions outward, one cell at a time. At every step it picks the unassigned cell with the most already-assigned neighbors, so regions always grow from the frontier rather than from isolated pockets.

Critically, after every single cell assignment, a solver runs and checks how many valid solutions the board still permits. If the count is anything other than 1, that assignment is rejected and the algorithm backtracks. This is the key step — it means every region boundary is placed with the eventual solution's uniqueness in mind, not discovered as an afterthought.

A node cap (MAX_NODES_PER_LAYOUT) keeps hard layouts from stalling the game. If a layout can't be completed within the cap, it's discarded and a fresh skull layout is tried.
3. Uniqueness verification

After a region layout is produced, a full independent solver confirms the board has exactly one solution. This is a redundant check — the growing stage already enforces it — but it's cheap and catches any edge cases in the search.
4. Freshness check

Each completed board is hashed. If the hash has been seen before in this session, the board is discarded and a new one is generated. This guarantees that consecutive levels in one play session never repeat.
Solving under constraints

The solver that runs during region growth is a row-by-row backtracking search. For each row, it tries every column and rejects a placement if it violates any of the four rules. Because all four constraints are checked at once, the search is heavily pruned — most of the 8⁸ naive placements are eliminated within a few rows, and the search returns in milliseconds even on partial boards.
#Run the Project

    Open the project folder in Godot 4.7.

    Run the main scene (gameplay_manager.tscn).

    A new level is generated and displayed immediately.

#Project Structure

    project.godot — Godot project configuration

    gameplay_manager.tscn — main scene

    scripts/gameplay_manager.gd — game flow, input, lives, win/loss handling, cell layout

    scripts/level_generator.gd — puzzle generation, region growing, uniqueness checks

    scripts/rule_validator.gd — runtime rule and conflict validation

    scripts/cell.gd — per-cell visuals, borders, and state display

    scripts/cell_state.gd — cell state enum

    scripts/life.gd — life icons and pop-and-hide animation

    textures/ — cell background, X, and skull sprite assets

