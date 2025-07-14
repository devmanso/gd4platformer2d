class_name MotionPlanner2D
extends Object

var profile := TrapezoidProfile.new()
var pid := PIDController.new()

func update(target: float, current: float, delta: float) -> float:
	var desired_velocity = profile.update(target, current, delta)
	return pid.update(desired_velocity, 0.0, delta)
