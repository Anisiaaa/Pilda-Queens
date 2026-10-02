extends Node2D

@export var grid_col: int
@export var grid_row: int

const CELL_BG_TEXTURE := preload("res://textures/cell_bg.png")
const X_TEXTURE := preload("res://textures/x_icon.png")
const SKULL_TEXTURE := preload("res://textures/skull_icon.png")

const TILE_SIZE := 100.0
const BORDER_THICKNESS := 3.0

@onready var background: Sprite2D = $Background
@onready var x_icon: Sprite2D = $XIcon
@onready var skull_icon: Sprite2D = $SkullIcon
@onready var conflict_highlight: ColorRect = $ConflictHighlight
@onready var border_top: ColorRect = $BorderTop
@onready var border_right: ColorRect = $BorderRight
@onready var border_bottom: ColorRect = $BorderBottom
@onready var border_left: ColorRect = $BorderLeft

var current_state: int = 0


func _ready() -> void:
	background.texture = CELL_BG_TEXTURE
	x_icon.texture = X_TEXTURE
	skull_icon.texture = SKULL_TEXTURE
	x_icon.visible = false
	skull_icon.visible = false
	conflict_highlight.visible = false
	_setup_borders()


func _setup_borders() -> void:
	var half := TILE_SIZE / 2.0
	var t := BORDER_THICKNESS
	var length := 100.0                 
	var offset := (TILE_SIZE - length) / 2.0 

	border_top.position = Vector2(-half + offset, -half)
	border_top.size = Vector2(length, t)

	border_right.position = Vector2(half - t, -half + offset)
	border_right.size = Vector2(t, length)

	border_bottom.position = Vector2(-half + offset, half - t)
	border_bottom.size = Vector2(length, t)

	border_left.position = Vector2(-half, -half + offset)
	border_left.size = Vector2(t, length)

	border_top.visible = false
	border_right.visible = false
	border_bottom.visible = false
	border_left.visible = false


func set_region_color(c: Color) -> void:
	background.modulate = c


func set_borders(top: bool, right: bool, bottom: bool, left: bool) -> void:
	border_top.visible = top
	border_right.visible = right
	border_bottom.visible = bottom
	border_left.visible = left


func set_state(new_state: int) -> void:
	current_state = new_state
	x_icon.visible = (new_state == 1)
	skull_icon.visible = (new_state == 2)


func set_conflict(is_conflicting: bool) -> void:
	conflict_highlight.visible = is_conflicting


func play_wrong_animation() -> void:
	var start_x := position.x
	var tween := create_tween()
	tween.tween_property(self, "position:x", start_x + 6, 0.05)
	tween.tween_property(self, "position:x", start_x - 6, 0.05)
	tween.tween_property(self, "position:x", start_x, 0.05)
