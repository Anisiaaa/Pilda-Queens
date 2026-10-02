extends Node2D

enum GameState { PLAYING, WON, LOST }

const MAX_WRONGS := 3
const BOARD_SIZE := 8
const WIN_DELAY := 1.5

const TILE_SIZE := 100.0

const CELL_SCENE := preload("res://cell.tscn")

const LIFE_DISPLAY_SIZE := TILE_SIZE / 2.0  


@onready var rule_validator: Node = $RuleValidator
@onready var level_generator: Node = $LevelGenerator
@onready var cells_root: Node2D = $Cells
@onready var lives: Array = [$Lives/Life0, $Lives/Life1, $Lives/Life2]
@onready var overlay: Control = $UI/Overlay
@onready var overlay_label: Label = $UI/Overlay/Label

var grid_logic: Array = []
var level_regions: Array = []
var wrong_count: int = 0
var state: int = GameState.PLAYING

var _cell_nodes: Dictionary = {}

const REGION_COLORS: Array[Color] = [
	Color("4dd0e1"),  
	Color("9575cd"),  
	Color("f06292"),
	Color("e57373"),  
	Color("ffb74d"), 
	Color("dce775"), 
	Color("4db6ac"),
	Color("7986cb"),  
]

func _ready() -> void:
	print("[DIAG] _ready fired")
	_build_cells()
	_position_board()
	_setup_lives()
	_start_new_level()
	
func _position_board() -> void:
	var vp_size := get_viewport_rect().size
	var board_size := BOARD_SIZE * TILE_SIZE
	cells_root.position = Vector2(
		(vp_size.x - board_size) / 2.0,
		(vp_size.y - board_size) / 2.0
	)
	
func _setup_lives() -> void:
	var board_right := cells_root.position.x + BOARD_SIZE * TILE_SIZE
	$Lives.position = Vector2(board_right + 20, cells_root.position.y)
	for i in range(lives.size()):
		var life = lives[i]
		life.setup(LIFE_DISPLAY_SIZE)
		life.position = Vector2(i * (LIFE_DISPLAY_SIZE + 10), 0)


func _build_cells() -> void:
	_cell_nodes.clear()
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var cell := CELL_SCENE.instantiate()
			cell.grid_col = col
			cell.grid_row = row
			cell.position = Vector2(col * TILE_SIZE + TILE_SIZE / 2, row * TILE_SIZE + TILE_SIZE / 2)
			cells_root.add_child(cell)
			_cell_nodes[Vector2i(col, row)] = cell


func _start_new_level() -> void:
	level_generator.generate_full_level()
	level_regions = level_generator.level_regions

	grid_logic = []
	for r in range(BOARD_SIZE):
		var row_arr: Array = []
		for c in range(BOARD_SIZE):
			row_arr.append(CellState.EMPTY)
		grid_logic.append(row_arr)

	wrong_count = 0
	state = GameState.PLAYING
	overlay.visible = false

	for life in lives:
		life.reset()

	_apply_region_textures_to_cells()
	_apply_region_borders() 
	_refresh_all_cell_icons()
	refresh_highlights()
	
func _apply_region_textures_to_cells() -> void:
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var node = _cell_nodes.get(Vector2i(col, row))
			if node == null:
				continue
			var region_id: int = level_regions[row][col]
			if region_id < 0 or region_id >= REGION_COLORS.size():
				continue
			node.set_region_color(REGION_COLORS[region_id])


func _refresh_all_cell_icons() -> void:
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var node = _cell_nodes.get(Vector2i(col, row))
			if node:
				node.set_state(grid_logic[row][col])



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		print("[input] mouse button %d pressed" % event.button_index)
	if not (event is InputEventMouseButton and event.pressed):
		return

	if state == GameState.LOST:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			_restart_same_level()
		return

	if state == GameState.WON:
		return

	if event.button_index == MOUSE_BUTTON_LEFT:
		_handle_left_click(event)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click(event)


func _handle_left_click(event: InputEventMouseButton) -> void:
	var cell := _cell_at_mouse()
	if cell == Vector2i(-1, -1):
		return
	var col := cell.x
	var row := cell.y

	var current = grid_logic[row][col]
	var new_state: int
	match current:
		CellState.EMPTY:
			new_state = CellState.MARKED_X
		CellState.MARKED_X:
			new_state = CellState.SKULL
		_:
			new_state = CellState.EMPTY
	_set_cell(row, col, new_state)

	if new_state != CellState.SKULL:
		refresh_highlights()
		return

	refresh_highlights()
	if rule_validator.cell_has_conflict(row, col, grid_logic, level_regions):
		_on_wrong_placement()
		return

	if rule_validator.count_skulls(grid_logic) == BOARD_SIZE:
		if rule_validator.is_board_valid(grid_logic, level_regions):
			_on_win()


func _handle_right_click(event: InputEventMouseButton) -> void:
	var cell := _cell_at_mouse()
	if cell == Vector2i(-1, -1):
		return
	var col := cell.x
	var row := cell.y
	if grid_logic[row][col] == CellState.EMPTY:
		return
	_set_cell(row, col, CellState.EMPTY)
	refresh_highlights()


func _set_cell(row: int, col: int, value: int) -> void:
	grid_logic[row][col] = value
	var node = _cell_nodes.get(Vector2i(col, row))
	if node:
		node.set_state(value)


func _cell_at_mouse() -> Vector2i:
	var local := get_local_mouse_position() - cells_root.position
	print("[mouse] local = ", local)
	var col := int(floor(local.x / TILE_SIZE))
	var row := int(floor(local.y / TILE_SIZE))
	print("[mouse] col=%d row=%d" % [col, row])
	if col < 0 or col >= BOARD_SIZE or row < 0 or row >= BOARD_SIZE:
		return Vector2i(-1, -1)
	return Vector2i(col, row)


func refresh_highlights() -> void:
	for key in _cell_nodes:
		_cell_nodes[key].set_conflict(false)
	var conflicting: Array = rule_validator.get_conflicting_cells(grid_logic, level_regions)
	for cell in conflicting:
		var node = _cell_nodes.get(cell)
		if node:
			node.set_conflict(true)


func _on_wrong_placement() -> void:
	wrong_count += 1
	_animate_wrong_cells()
	if wrong_count <= MAX_WRONGS:
		lives[wrong_count - 1].pop_and_hide()

	if wrong_count >= MAX_WRONGS:
		_on_lose()


func _animate_wrong_cells() -> void:
	var conflicting: Array = rule_validator.get_conflicting_cells(grid_logic, level_regions)
	for cell in conflicting:
		var node = _cell_nodes.get(cell)
		if node:
			node.play_wrong_animation()


func _on_lose() -> void:
	state = GameState.LOST
	overlay_label.text = "You lost!"
	overlay.visible = true


func _restart_same_level() -> void:
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			grid_logic[row][col] = CellState.EMPTY
			var node = _cell_nodes.get(Vector2i(col, row))
			if node:
				node.set_state(CellState.EMPTY)

	wrong_count = 0
	state = GameState.PLAYING
	overlay.visible = false
	for life in lives:
		life.reset()
	refresh_highlights()


func _on_win() -> void:
	state = GameState.WON
	overlay_label.text = "Congrats!"
	overlay.visible = true
	await get_tree().create_timer(WIN_DELAY).timeout
	overlay.visible = false
	_start_new_level()
	
	
func _apply_region_borders() -> void:
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var node = _cell_nodes.get(Vector2i(col, row))
			if node == null:
				continue
			var r: int = level_regions[row][col]
			var top: bool = row == 0 or level_regions[row - 1][col] != r
			var bottom: bool = row == BOARD_SIZE - 1 or level_regions[row + 1][col] != r
			var left: bool = col == 0 or level_regions[row][col - 1] != r
			var right: bool = col == BOARD_SIZE - 1 or level_regions[row][col + 1] != r
			node.set_borders(top, right, bottom, left)
