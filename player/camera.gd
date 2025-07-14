extends Camera2D

@export var deadzone: float = 100
@export var shake_strength: float = 0.0
@export var shake_decay: float = 5.0

var is_dead: bool = false

func _process(delta):
	# --- Camera shake ---
	randomize()
	if shake_strength > 0:
		offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_strength
		shake_strength = max(shake_strength - shake_decay * delta, 0)
	else:
		offset = Vector2.ZERO
	# --- Look-ahead ---
	if not is_dead and Input.is_action_pressed("look"):
		var target = get_local_mouse_position()
		if target.length() < deadzone:
			position = Vector2.ZERO
		else:
			position = target.normalized() * (target.length() - deadzone) * 0.5
	else:
		# Reset camera to player center when not looking ahead
		
		position = Vector2.ZERO

func start_shake(strength: float) -> void:
	shake_strength = strength

# because the menu/ui elements are children of the camera, we have to reset
# the position of the camera to (0,0) so that the ui looks normal, only call 
# this when the player dies
func die() -> void:
	is_dead = true
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	# I tried 3 different things to try to get the camera to reset.
	# Not a single one of them worked, but the 2 lines of code above did.
	# I didn't delete this because I think it could be useful later
	#position_smoothing_speed = 100
	#set_anchor_mode(Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT)
	#position_smoothing_enabled = false
	position = Vector2.ZERO
