extends Control

@onready var death_message : RichTextLabel = $DeathMessage
@export var game_over_messages : Array[String] = [":(", "You are dead!",
"Whoops...", "...", "RIP", "Game Over!", "Try Again?", "(✖╭╮✖)"]
var death_message_set : bool = false

func set_game_over_text(message : String) -> void:
	death_message.text = message

func choose_random_game_over_text() -> void:
	if !death_message_set:
		var index : int = randi_range(0, game_over_messages.size() -1)
		set_game_over_text(game_over_messages[index])
		death_message_set = true
	else:
		pass

func _ready() -> void:
	randomize()
	death_message.text = "Game Over!" # default message
