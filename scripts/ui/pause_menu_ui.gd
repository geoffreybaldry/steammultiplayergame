extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if GameState.current_game_state != GameState.GAME_STATES.PLAYING and GameState.current_game_state != GameState.GAME_STATES.PAUSED:
		return
		
	if Input.is_action_just_pressed("options") or Input.is_action_just_pressed("escape"):
		if GameState.current_game_state == GameState.GAME_STATES.PAUSED:
			GameState.change_game_state(GameState.GAME_STATES.PLAYING)
		else:
			GameState.change_game_state(GameState.GAME_STATES.PAUSED)


func _on_resume_game_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATES.PLAYING)


func _on_exit_game_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATES.MAIN_MENU)
