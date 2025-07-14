class_name BangBangController
extends Object

var tolerance: float = 0.01
var output_max: float = 1.0

func update(target: float, current: float) -> float:
	var error = target - current
	if abs(error) <= tolerance:
		return 0.0
	return output_max * sign(error)
