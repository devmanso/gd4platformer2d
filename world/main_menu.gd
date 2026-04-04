extends Node2D

@onready var play_button_position : Node2D = $PlayButtonPositionController
@onready var play_button : Button = $PlayButtonPositionController/Play

var screen_width : int
var screen_height : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	screen_width = get_viewport().get_visible_rect().size.x
	screen_height = get_viewport().get_visible_rect().size.y
	play_button_position.position = Vector2(screen_width/2, screen_height/2)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://world.tscn")
