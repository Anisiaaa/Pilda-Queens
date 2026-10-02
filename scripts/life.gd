extends Sprite2D

const SKULL_TEXTURE := preload("res://textures/skull_icon.png")

var _base_scale: Vector2 = Vector2.ONE


func setup(display_size: float) -> void:
	texture = SKULL_TEXTURE
	_base_scale = Vector2(
		display_size / SKULL_TEXTURE.get_width(),
		display_size / SKULL_TEXTURE.get_height()
	)
	scale = _base_scale
	modulate = Color(1, 1, 1, 1)


func reset() -> void:
	visible = true
	scale = _base_scale
	modulate = Color(1, 1, 1, 1)


func pop_and_hide() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", _base_scale * 1.4, 0.12)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(_hide)


func _hide() -> void:
	visible = false
