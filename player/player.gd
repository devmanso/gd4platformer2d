extends CharacterBody2D

@onready var cursor : Node2D = $Cursor
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
@onready var deathscreen_position : Node2D = $Camera/PositionController
@onready var restart_button_position : Node2D = $Camera/RestartButtonController
@onready var restart_button : Button = $Camera/RestartButtonController/RestartButton
@onready var debug_ui_controller : Node2D = $DebugUIController
@onready var fps_display : RichTextLabel = $DebugUIController/FPSLabel

@export var push_force : float = 50.0
@export var health : float = 100.0
@export var hurt_color : Color = Color(1, 0, 0, 1)
@export var allow_restarts : bool = false
@export var colors : Array[Color] = [Color("#FF2DD1"), Color("4DFFBE"), 
Color.WHITE, Color("#6FE6FC"), Color("#FFFA8D"), Color("#FDB7EA"), 
Color("#FFC785"), Color("#A294F9")]
@export_range(0.0, 1.0) var acceleration : float = 0.25
@export_range(0.0, 1.0) var friction : float = 0.1
@export_range(200.0, 1600.0) var joystick_speed : float = 1200
@export_range(0.1, 0.5) var deadzone : float = 0.1
@export_range(1.0, 5.0) var fling : float = 1.5

var death_message_target_xposition : float = -320.0
var menu_button_target_xpositions : float = -1104.0
var regular_color : Color = Color(1, 1, 1, 1)
var current_direction : float
var current_powerup : String = "none"
var facing_down : bool = false
var deathscreen_slidein : bool = false
var can_move : bool = true

var SPEED : float = 650.0
var JUMP_VELOCITY : float = -900.0
var DOWNFORCE : float = 1000.0
var player_scale : Vector2 = Vector2(0.5, 0.5)
var player_scale_down_squash : Vector2 = Vector2(0.6, 0.4)
var player_scale_down_squash_compressed : Vector2 = Vector2(0.7, 0.3)
var player_scale_up_squash : Vector2 = Vector2(0.4, 0.6)
var dash_speed : float = 1400.0
var dash_duration : float = 0.2
var dash_cooldown : float = 0.2
var can_dash : bool = true
var is_dashing : bool = false
var should_emit_dash_trail : bool = false
var dead : bool = false
var show_cursor : bool = false
var wall_slide_gravity_multiplier : float = 0.3
var wall_jump_horizontal_force : float = 500.0
var wall_coyote_time : float = 0.12
var wall_coyote_timer : float = 0.0
var last_wall_direction : float = 0.0   # -1 = left wall, 1 = right wall
var is_wall_sliding : bool = false

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

func set_health(value : int) -> void:
	health = clamp(value, 0, 100)

func get_health() -> int:
	return health

func is_menu_option_in_position(menu_option : String) -> bool:
	if menu_option == "death":
		if deathscreen_position.position.distance_to(Vector2(-320,-224)) < 5:
			return true
	return false

func die() -> void:
	deathscreen.choose_random_game_over_text()
	camera.die()
	deathscreen.show()
	dash_particle.emitting = false
	bubble_particle.emitting = false
	dead = true

func get_direction() -> String:
	if current_direction < 0:
		return "left"
	elif current_direction > 0:
		return "right"
	else:
		return "middle"

func is_facing_down() -> bool:
	return facing_down

func get_wall_direction() -> float:
	# Returns which wall we're touching: -1 left, 1 right, 0 none
	if is_on_wall_only():
		var wall_normal = get_wall_normal()
		return -sign(wall_normal.x)   # normal points away from wall, so negate
	return 0.0

func rainbow() -> void:
	var rainbow_time := 0.5
	var step_time := rainbow_time / colors.size()
	for i in range(colors.size()):
		var color = colors[i]
		get_tree().create_timer(i * step_time).timeout.connect(
			func():
				sprite.self_modulate = color
		)
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
		input_dir.x = current_direction if current_direction != 0 else 1.0
		
	input_dir = input_dir.normalized()
	var plat_velo = get_platform_velocity()
	velocity = (input_dir * dash_speed) + (plat_velo * fling)
	rainbow()
	camera.start_shake(3)

func _ready() -> void:
	randomize()
	bubble_particle.emitting = false
	deathscreen.hide()
	cursor.hide()

func _process(delta: float) -> void:
	
	fps_display.text = str(Engine.get_frames_per_second()) + " FPS"
	
	if Input.is_action_just_pressed("ui_cancel"):
		show_cursor = !show_cursor
	
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if show_cursor or dead else Input.MOUSE_MODE_HIDDEN
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var joystick_input = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	
	if joystick_input.length() > deadzone:
		cursor.set_cursor_position(cursor.get_position() + joystick_input * joystick_speed * delta)
		camera.set_target_position(cursor.position)
	else:
		cursor.set_cursor_position(get_local_mouse_position())
		camera.set_target_position(cursor.position)
	
	if Input.is_action_pressed("restart") and allow_restarts:
		get_tree().reload_current_scene()
	
	if health <= 0:
		die()
	
	if dead:
		restart_button_position.show()
	else:
		deathscreen_position.hide()
		restart_button_position.hide()

func _physics_process(delta: float) -> void:
	can_move = get_health() != 0
	
	if can_move:
		var wall_dir := get_wall_direction()
		
		# Track wall coyote time — briefly remember the last wall after leaving it
		if wall_dir != 0.0:
			last_wall_direction = wall_dir
			wall_coyote_timer = wall_coyote_time
		elif wall_coyote_timer > 0:
			wall_coyote_timer -= delta
		
		# Determine if we're wall sliding: airborne, pressing into a wall, moving downward
		is_wall_sliding = (
			not is_on_floor()
			and (wall_dir != 0.0 or wall_coyote_timer > 0.0)
			and velocity.y > 0
			and Input.get_axis("ui_left", "ui_right") != 0.0
		)
			
		if not is_on_floor():
			if is_wall_sliding:
				velocity += get_gravity() * wall_slide_gravity_multiplier * delta
				velocity.y = min(velocity.y, 200.0)  # cap slide speed
			else:
				velocity += get_gravity() * delta
			
# Jump: floor jump or wall jump
		if Input.is_action_just_pressed("ui_accept"):
			if is_on_floor():
				var plat_velo = get_platform_velocity()
				velocity.y = JUMP_VELOCITY
				velocity.x += plat_velo.x
				if plat_velo.y < 0:
					velocity.y += plat_velo.y
				facing_down = false
			elif is_wall_sliding or wall_coyote_timer > 0.0:
				# Wall jump: kick away from the wall
				velocity.y = JUMP_VELOCITY
				velocity.x = -last_wall_direction * wall_jump_horizontal_force
				facing_down = false
				can_dash = true              # reward the wall jump with a fresh dash
				wall_coyote_timer = 0.0     # consume coyote window
				is_wall_sliding = false
		
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
			velocity.x = lerp(velocity.x, direction * SPEED, acceleration)
		else:
			velocity.x = lerp(velocity.x, 0.0, friction)
		
		if is_on_floor():
			can_dash = true
		
		if Input.is_action_just_pressed("dash") and can_dash:
			start_dash()
		
		move_and_slide()
		
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# Check if the object we hit is a RigidBody2D
			if collider is RigidBody2D:
				# Calculate push direction (away from the collision point)
				# Using negative normal points directly into the object
				var push_direction : Vector2 = -collision.get_normal()
				
				# don't want to change push_force every frame because it will
				# exponentially grow out of control
				var final_push : float = push_force
				
				if is_dashing:
					final_push *=3
				
				# Apply the impulse to the central point of the ball
				# We multiply by push_force, and optionally factor in player speed
				collider.apply_central_impulse(push_direction * final_push)
				#collider.apply_central_force(-collision.get_normal() * push_force * 60.0)
				
		
		if is_on_floor():
			should_emit_dash_trail = false
			dash_particle.emitting = false

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_dash_timer_timeout() -> void:
	is_dashing = false

func _on_dash_particle_timer_timeout() -> void:
	pass
