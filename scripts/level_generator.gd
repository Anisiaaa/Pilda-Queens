extends Node

const REGION_CAP := 20
const BOARD_SIZE := 8
const SKULL_COUNT := 8
const SOLUTION_LIMIT := 2
const MAX_ATTEMPTS := 200
const MAX_NODES_PER_LAYOUT := 500

var level_regions: Array = []
var winning_skulls: Array = []
var region_sizes: Array = []
var solution_count: int = 0

var seen_hashes: Dictionary = {}


var nodes_this_layout: int = 0
var aborted_this_layout: bool = false


func generate_full_level() -> void:
	print("[gen] --- generate_full_level START ---")
	var skull_fails := 0
	var region_fails := 0
	var uniqueness_fails := 0
	var freshness_fails := 0

	for attempt in range(MAX_ATTEMPTS):
		print("[gen] attempt %d: calling generate_winning_skulls" % attempt)
		if not generate_winning_skulls():
			skull_fails += 1
			print("[gen] attempt %d: skull gen FAILED" % attempt)
			continue

		print("[gen] attempt %d: skulls OK, calling generate_regions_from_skulls" % attempt)
		if not generate_regions_from_skulls():
			region_fails += 1
			print("[gen] attempt %d: region gen FAILED (nodes=%d, aborted=%s)" % [attempt, nodes_this_layout, aborted_this_layout])
			continue

		print("[gen] attempt %d: regions OK, calling count_solutions" % attempt)
		var sols := count_solutions()
		print("[gen] attempt %d: count_solutions returned %d" % [attempt, sols])
		if sols != 1:
			uniqueness_fails += 1
			continue

		var h := hash_board()
		if seen_hashes.has(h):
			freshness_fails += 1
			continue
		seen_hashes[h] = true
		print("[gen] attempt %d: SUCCESS" % attempt)
		return

	print("=== FAILED after %d attempts ===" % MAX_ATTEMPTS)
	print("skull_fails: %d" % skull_fails)
	print("region_fails: %d" % region_fails)
	print("uniqueness_fails: %d" % uniqueness_fails)
	print("freshness_fails: %d" % freshness_fails)
	push_error("Failed to generate a unique fresh level after %d attempts" % MAX_ATTEMPTS)


func hash_board() -> int:
	var s := ""
	for row in level_regions:
		for v in row:
			s += str(v) + ","
		s += "|"
	return s.hash()


func generate_winning_skulls() -> bool:
	winning_skulls.clear()
	var available_cols = [0, 1, 2, 3, 4, 5, 6, 7]
	for row in range(BOARD_SIZE):
		var current_choices = available_cols.duplicate()
		current_choices.shuffle()
		var placed_successfully = false
		for col in current_choices:
			if is_skull_placement_safe(row, col, winning_skulls):
				winning_skulls.append(Vector2i(col, row))
				available_cols.erase(col)
				placed_successfully = true
				break
		if not placed_successfully:
			winning_skulls.clear()
			return false
	return true


func is_skull_placement_safe(new_row: int, new_col: int, placed: Array) -> bool:
	for skull in placed:
		if abs(skull.x - new_col) <= 1 and abs(skull.y - new_row) <= 1:
			return false
	return true


func generate_regions_from_skulls() -> bool:
	print("  [regions] start")
	nodes_this_layout = 0
	aborted_this_layout = false

	level_regions.clear()
	for i in range(BOARD_SIZE):
		level_regions.append([])
		for j in range(BOARD_SIZE):
			level_regions[i].append(-1)

	region_sizes.clear()
	for i in range(SKULL_COUNT):
		region_sizes.append(1)

	var id: int = 0
	for skull in winning_skulls:
		level_regions[skull.y][skull.x] = id
		id += 1

	var unassigned: Array = []
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			if level_regions[y][x] == -1:
				unassigned.append(Vector2i(x, y))
	unassigned.shuffle()

	print("  [regions] unassigned count: %d, calling _assign_cells" % unassigned.size())
	var ok := _assign_cells(unassigned, 0)
	print("  [regions] _assign_cells returned %s (nodes=%d, aborted=%s)" % [ok, nodes_this_layout, aborted_this_layout])
	return ok


func _assign_cells(unassigned: Array, idx: int) -> bool:
	nodes_this_layout += 1
	if nodes_this_layout > MAX_NODES_PER_LAYOUT:
		aborted_this_layout = true
		return false

	if idx >= unassigned.size():
		return true

	
	var best_cell: Vector2i = Vector2i(-1, -1)
	var best_candidates: Array = []
	for i in range(idx, unassigned.size()):
		var c: Vector2i = unassigned[i]
		var cands = colored_neighbor_regions(c)
		cands = cands.filter(func(r): return region_sizes[r] < REGION_CAP)
		if cands.size() > best_candidates.size():
			best_cell = c
			best_candidates = cands
			if best_candidates.size() >= 4:
				break


	if best_cell == Vector2i(-1, -1):
		return false

	
	var chosen_idx := unassigned.find(best_cell)
	var tmp = unassigned[idx]
	unassigned[idx] = best_cell
	unassigned[chosen_idx] = tmp

	best_candidates.shuffle()

	for r in best_candidates:
		level_regions[best_cell.y][best_cell.x] = r
		region_sizes[r] += 1

		if _count_restricted_solutions() == 1:
			if _assign_cells(unassigned, idx + 1):
				return true

		level_regions[best_cell.y][best_cell.x] = -1
		region_sizes[r] -= 1

	return false


func _count_restricted_solutions() -> int:
	solution_count = 0
	_place_skull_restricted(0, [])
	return solution_count


func _place_skull_restricted(row: int, placed: Array) -> void:
	if solution_count >= SOLUTION_LIMIT:
		return
	if row == 8:
		if placed.size() == SKULL_COUNT:
			solution_count += 1
		return
	for col in range(8):
		if level_regions[row][col] == -1:
			continue
		if _is_solver_placement_safe(row, col, placed):
			placed.append(Vector2i(col, row))
			_place_skull_restricted(row + 1, placed)
			placed.pop_back()


func neighbors(cell: Vector2i) -> Array:
	return [
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 0),
		cell + Vector2i(0, 1),
		cell + Vector2i(0, -1),
	]


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < BOARD_SIZE and cell.y >= 0 and cell.y < BOARD_SIZE


func colored_neighbor_regions(cell: Vector2i) -> Array:
	var result: Array = []
	for n in neighbors(cell):
		if in_bounds(n) and level_regions[n.y][n.x] != -1:
			var r: int = level_regions[n.y][n.x]
			if not result.has(r):
				result.append(r)
	return result


func count_solutions() -> int:
	solution_count = 0
	_place_skull_in_row(0, [])
	return solution_count


func _place_skull_in_row(row: int, placed: Array) -> void:
	if solution_count >= SOLUTION_LIMIT:
		return
	if row == 8:
		if placed.size() == SKULL_COUNT:
			solution_count += 1
		return
	for col in range(8):
		if _is_solver_placement_safe(row, col, placed):
			placed.append(Vector2i(col, row))
			_place_skull_in_row(row + 1, placed)
			placed.pop_back()


func _is_solver_placement_safe(row: int, col: int, placed: Array) -> bool:
	for skull in placed:
		if skull.x == col:
			return false
		if abs(skull.x - col) <= 1 and abs(skull.y - row) <= 1:
			return false

	var my_region: int = level_regions[row][col]
	for skull in placed:
		if level_regions[skull.y][skull.x] == my_region:
			return false

	return true
