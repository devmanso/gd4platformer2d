class_name TrapezoidProfile
extends Object

var max_velocity: float = 100.0
var max_acceleration: float = 300.0
var velocity: float = 0.0

func update(target: float, current: float, delta: float) -> float:
	var error = target - current
	var desired_velocity = clamp(error / delta, -max_velocity, max_velocity)
	var accel = clamp((desired_velocity - velocity) / delta, -max_acceleration, max_acceleration)
	velocity += accel * delta
	return velocity
