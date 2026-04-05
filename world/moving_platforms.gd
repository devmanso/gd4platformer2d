extends Node2D

@export_group("Settings")
@export var offset: Vector2 = Vector2(200, 0) # How far it moves from start
@export var duration: float = 2.0             # Time to reach destination
@export var idle_time: float = 0.5           # Wait time at each end

@onready var platform: AnimatableBody2D = $Platform

func _ready() -> void:
	start_tween()

func start_tween() -> void:
	# Calculate the two points
	var start_pos = platform.position
	var end_pos = platform.position + offset
	
	var tween = create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	# Move to Target
	tween.tween_property(platform, "position", end_pos, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(idle_time)
	
	# Move back to Start
	tween.tween_property(platform, "position", start_pos, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(idle_time)
