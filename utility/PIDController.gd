class_name PIDController
extends Object

var kp: float = 1.0
var ki: float = 0.0
var kd: float = 0.0

var integral: float = 0.0
var last_error: float = 0.0
var output_min: float = -INF
var output_max: float = INF

func _init(p_kp: float = 1.0, p_ki: float = 0.0, p_kd: float = 0.0, p_output_min: float = -INF, p_output_max: float = INF) -> void:
	kp = p_kp
	ki = p_ki
	kd = p_kd
	output_min = p_output_min
	output_max = p_output_max

func reset() -> void:
	integral = 0.0
	last_error = 0.0

func update(target: float, current: float, delta: float) -> float:
	var error = target - current
	integral += error * delta
	var derivative = (error - last_error) / delta if delta > 0.0 else 0.0
	last_error = error

	var output = (kp * error) + (ki * integral) + (kd * derivative)
	return clamp(output, output_min, output_max)
