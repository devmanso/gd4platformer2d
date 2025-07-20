extends Control

@onready var death_message : RichTextLabel = $DeathMessage
@export var game_over_messages : Array[String] = [":(", "You are dead!",
"Whoops...", "...", "RIP"]

func set_game_over_text(message : String) -> void:
	death_message.text = message

func choose_random_game_over_text() -> void:
	var index : int = randi_range(0, game_over_messages.size())
	set_game_over_text(game_over_messages[index])

func _ready() -> void:
	randomize()
	death_message.text = "Game Over!" # default message
