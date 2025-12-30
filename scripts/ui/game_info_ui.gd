extends Control

@onready var game_state_label: Label = $HBoxContainer/game_state_label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	game_state_label.text = "GameState: : " + GameState.GAME_STATES.keys()[GameState.current_game_state]
