extends StaticBody2D

@onready var sprite = $Sprite2D

@export var pass_through := false

func _process(delta: float) -> void:
	update_collision_type()
	if pass_through:
		sprite.hide()
	else:
		sprite.show()

func update_collision_type():
	if pass_through:
		# Put the block on the Pass-Through World layer
		set_collision_layer_value(1, false)
		set_collision_layer_value(4, true)
		# Only collide with players
		set_collision_mask_value(2, true)
		set_collision_mask_value(3, false)
	else:
		# Put the block on the Normal World layer
		set_collision_layer_value(1, true)
		set_collision_layer_value(4, false)
		# Collide with players and projectiles
		set_collision_mask_value(2, true)
		set_collision_mask_value(3, true)
