extends Node2D

@onready var cursor_image : Sprite2D = $CursorImage

@export var range : float = 800

var joystick_speed : float = 400.0
var deadzone : float = .1

func get_cursor_position() -> Vector2:
	return position

func get_cursor_global_position() -> Vector2:
	return global_position

func set_cursor_position(cursor_position : Vector2) -> void:
	var clamped = Vector2(
		clamp(cursor_position.x, -range, range),
		clamp(cursor_position.y, -range, range)
	)
	position = clamped

func set_cursor_global_position(global_cursor_position : Vector2) -> void:
	var clamped = Vector2(
		clamp(global_cursor_position.x, -range, range),
		clamp(global_cursor_position.y, -range, range)
	)
	global_position = clamped
