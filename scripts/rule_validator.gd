extends Node

const BOARD_SIZE := 8
const SKULL := 2


func count_skulls(grid_logic: Array) -> int:
	var n := 0
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			if grid_logic[row][col] == SKULL:
				n += 1
	return n


func cell_has_conflict(row: int, col: int, grid_logic: Array, level_regions: Array) -> bool:
	if grid_logic[row][col] != SKULL:
		return false
	var my_region: int = level_regions[row][col]
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			if r == row and c == col:
				continue
			if grid_logic[r][c] != SKULL:
				continue
			if r == row or c == col:
				return true
			if level_regions[r][c] == my_region:
				return true
			if abs(r - row) <= 1 and abs(c - col) <= 1:
				return true
	return false


func get_conflicting_cells(grid_logic: Array, level_regions: Array) -> Array:
	var marked: Dictionary = {}
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			if grid_logic[row][col] != SKULL:
				continue
			if not cell_has_conflict(row, col, grid_logic, level_regions):
				continue
			var region: int = level_regions[row][col]
			for i in range(BOARD_SIZE):
				marked[Vector2i(i, row)] = true
				marked[Vector2i(col, i)] = true
			for r in range(BOARD_SIZE):
				for c in range(BOARD_SIZE):
					if level_regions[r][c] == region:
						marked[Vector2i(c, r)] = true
	return marked.keys()


func is_board_valid(grid_logic: Array, level_regions: Array) -> bool:
	var skull_count := 0
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			if grid_logic[row][col] == SKULL:
				skull_count += 1
				if cell_has_conflict(row, col, grid_logic, level_regions):
					return false
	return skull_count == BOARD_SIZE
