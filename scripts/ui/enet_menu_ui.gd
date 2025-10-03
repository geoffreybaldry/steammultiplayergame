extends Control


func _on_host_button_pressed() -> void:
	# Start multiplayer_peer networking
	Network.create_enet_network()


func _on_join_button_pressed() -> void:
	Network.join_enet_network()


func _on_start_game_button_pressed() -> void:
	Levels.goto_scene.rpc("res://scenes/levels/test_level.tscn")


func _on_main_menu_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATES.MAIN_MENU)
