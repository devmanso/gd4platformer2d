extends ColorRect

@export var rise_speed : float = 20
@export var enabled : bool = false

func get_water_level() -> float:
	return position.y

func set_water_level(yposition : float) -> void:
	position.y = yposition

func set_rise_speed(speed : float) -> void:
	clamp(rise_speed, 20, 120)

func get_rise_speed() -> float:
	return rise_speed

func _process(delta: float) -> void:
	if enabled:
		position.y -= rise_speed *delta
