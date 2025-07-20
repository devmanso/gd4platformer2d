extends CharacterBody2D

@onready var water : ColorRect = get_parent().get_node("Water")
@onready var camera : Camera2D = $Camera
@onready var hurtbox : CollisionShape2D = $Hurtbox
@onready var sprite : Sprite2D = $Sprite
@onready var damage_timer : Timer = $DamageTimer
@onready var reset_sprite_timer : Timer = $ResetSpriteTimer
@onready var dash_timer : Timer = $DashTimer
@onready var dash_particle_timer : Timer = $DashParticleTimer
@onready var dash_particle : CPUParticles2D = $DashParticle
@onready var bubble_particle : CPUParticles2D = $BubbleParticle
@onready var deathscreen : Control = $Camera/PositionController/DeathScreen
# Control node's don't inherit from Node2d, so they don't have a position
# We can get around this by making the deathscreen (a Control object)
# a child of a deathscreen_position (A node2d) object, and control the position
# through that instead. Same goes for all of the other UI element stuff
@onready var deathscreen_position : Node2D = $Camera/PositionController
@onready var restart_button_position : Node2D = $Camera/RestartButtonController

@export var health : float = 100.0
@export var hurt_color : Color = Color(1, 0, 0, 1)
@export var allow_restarts : bool = false
@export var colors : Array[Color] = [Color("#FF2DD1"), Color("4DFFBE"), 
Color.WHITE, Color("#6FE6FC"), Color("#FFFA8D"), Color("#FDB7EA"), 
Color("#FFC785"), Color("#A294F9")]
@export_range(0.0, 1.0) var acceleration : float = 0.25
@export_range(0.0, 1.0) var friction : float = 0.1

var death_message_target_xposition : float = -320.0
var menu_button_target_xpositions : float = -1104.0
var regular_color : Color = Color(1, 1, 1, 1)
var current_direction : float
var current_powerup : String = "none"
var facing_down : bool = false
var deathscreen_slidein : bool = false
var can_move : bool = true

var SPEED : float = 300.0
var JUMP_VELOCITY : float = -900.0
var DOWNFORCE : float = 1000.0
var player_scale : Vector2 = Vector2(0.5, 0.5)
var player_scale_down_squash : Vector2 = Vector2(0.6, 0.4)
var player_scale_down_squash_compressed : Vector2 = Vector2(0.7, 0.3)
var player_scale_up_squash : Vector2 = Vector2(0.4, 0.6)
var dash_speed : float = 1600.0
var dash_duration : float = 0.2
var dash_cooldown : float = 0.2
var can_dash : bool = true
var is_dashing : bool = false
var should_emit_dash_trail : bool = false

func is_in_water() -> bool:
	# check if water is in scenetree:
	if water == null:
		push_error("water (ColorRect) node not found in scene")
		return false
	elif position.y > water.get_water_level():
			return true
	else: 
		return false
		

func get_speed() -> float:
	return SPEED

func set_speed(speed : float) -> void:
	SPEED = clamp(speed, 100, 800)

func get_jump_velocity() -> float:
	return JUMP_VELOCITY

func set_jump_velocity(jump_velocity : float) -> void:
	if jump_velocity > 0:
		jump_velocity *= -1
	JUMP_VELOCITY = clamp(jump_velocity, 0, -1200)

func get_current_powerup() -> String:
	return current_powerup

func give_powerup(powerup : String) -> void:
	current_powerup = powerup

# don't use this to kill the player, use die() instead
func set_health(value : int) -> void:
	health = clamp(value, 0, 100)

func get_health() -> int:
	return health

#TODO: implement other ui and buttons for later
# might not even need this function, could use Curve's instead?
func is_menu_option_in_position(menu_option : String) -> bool:
	
	if menu_option == "death":
		if deathscreen_position.position.distance_to(Vector2(-320,-224)) < 5:
			return true
	
	return false

#TODO: implement restart and other functionality later
func die() -> void:
	camera.die()
	deathscreen.show()
	deathscreen_slidein = true

func get_direction() -> String:
	if current_direction < 0:
		return "left"
	elif current_direction > 0:
		return "right"
	else:
		return "middle"

func is_facing_down() -> bool:
	return facing_down

func rainbow() -> void:
	var rainbow_time := 0.5
	var step_time := rainbow_time / colors.size()
	for i in range(colors.size()):
		var color = colors[i]
		get_tree().create_timer(i * step_time).timeout.connect(
			func():
				sprite.self_modulate = color
		)
	# Reset to regular after rainbow finishes
	get_tree().create_timer(rainbow_time).timeout.connect(
		func():
		sprite.self_modulate = regular_color
	)

func start_dash() -> void:
	should_emit_dash_trail = true
	can_dash = false
	is_dashing = true
	dash_timer.start(dash_duration)
	dash_particle.emitting = true
	
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")
	
	if input_dir == Vector2.ZERO:
		 # No input? Dash in facing direction, default right
		#input_dir.x = sign(current_direction) if current_direction != 0 else 1
		# don't do anything if not facing directions
		pass
	input_dir = input_dir.normalized()
	velocity = input_dir * dash_speed
	rainbow()
	camera.start_shake(3)

func _ready() -> void:
	bubble_particle.emitting = false
	# set offscreen then hide, when the player dies, we'll
	# slide it back into view (where position.x = 0), and show it
	deathscreen_position.position.x = -3000
	restart_button_position.position.x = -4000
	deathscreen.hide()

func _process(delta: float) -> void:
	
	randomize()
	
	# for debug purposes! allow_restarts should be false for builds
	# or finished levels
	if Input.is_action_pressed("restart") and allow_restarts:
		get_tree().reload_current_scene()
	
	if is_in_water():
		bubble_particle.emitting = true
	else:
		bubble_particle.emitting = false
	
	if health <= 0:
		die()
	
	if deathscreen_slidein:
		# t = 0.08. 5 * 0.016 (60fps) = 0.08
		deathscreen_position.position.x = lerp(deathscreen_position.position.x, death_message_target_xposition, 5 * delta)
		# instead of having them both slide in, I want the restart button to slide in, 1 second after the deathscreen is in position
		#restart_button_position.position.x = lerp(restart_button_position.position.x, menu_button_target_xpositions, 5 * delta)
		if is_menu_option_in_position("death"):
			restart_button_position.position.x = lerp(restart_button_position.position.x, menu_button_target_xpositions, 10 * delta)

func _physics_process(delta: float) -> void:
	randomize()
	
	if get_health() == 0:
		can_move = false
	else:
		can_move = true
	
	if can_move:
		
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			facing_down = false
		
		if Input.is_action_pressed("ui_down") and !is_on_floor():
			velocity.y += DOWNFORCE * delta
			facing_down = true
		
		if is_on_floor() and abs(velocity.y) < 10 and !Input.is_action_pressed("ui_down"):
			sprite.scale = sprite.scale.lerp(player_scale, 10 * delta)
			# scale down the hurtbox too
			hurtbox.set_scale(player_scale)
		elif is_on_floor() and abs(velocity.y) < 10 and Input.is_action_pressed("ui_down"):
			sprite.scale = sprite.scale.lerp(player_scale_down_squash_compressed, 10 * delta)
			hurtbox.set_scale(player_scale_down_squash_compressed)
		else:
			if velocity.y < 0:
				sprite.scale = sprite.scale.lerp(player_scale_up_squash, 10 * delta)
				hurtbox.set_scale(player_scale_up_squash)
			else:
				sprite.scale = sprite.scale.lerp(player_scale_down_squash, 10 * delta)
				hurtbox.set_scale(player_scale_down_squash)
		
		var direction := Input.get_axis("ui_left", "ui_right")
		current_direction = direction
		if direction:
			#velocity.x = direction * SPEED
			velocity.x = lerp(velocity.x, direction * SPEED, acceleration)
		else:
			velocity.x = lerp(velocity.x, 0.0, friction)
			#velocity.x = move_toward(velocity.x, 0, SPEED)
		
		if is_on_floor():
			can_dash = true
		
		if Input.is_action_just_pressed("dash") and can_dash:
			start_dash()
		
		move_and_slide()
		
		if is_on_floor():
			should_emit_dash_trail = false
			dash_particle.emitting = false


# signal shit should go here

func _on_damage_timer_timeout() -> void:
	if is_in_water():
		set_health(health-10)
		sprite.self_modulate = hurt_color
		if get_health() != 0:
			camera.start_shake(5)
	
	print("Player HP: ", health)


func _on_reset_sprite_timer_timeout() -> void:
	if !is_in_water():
		sprite.self_modulate = regular_color

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_dash_timer_timeout() -> void:
	is_dashing = false

func _on_dash_particle_timer_timeout() -> void:
	pass
	#var index = randf_range(0, colors.size())
	#dash_circle_particle.position.y = randf_range(-20, 20)
	#dash_circle_particle.self_modulate = colors[index]
