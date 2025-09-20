extends Control


func _on_lobby_menu_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATES.LOBBY_MENU)


# We're outta here
func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
