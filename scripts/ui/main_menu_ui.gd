extends Control

@onready var lobby_menu_button: Button = $VBoxContainer/lobby_menu_button
@onready var quit_game_button: Button = $VBoxContainer/quit_game_button

func _ready() -> void:
	lobby_menu_button.grab_focus.call_deferred()
	

func _on_lobby_menu_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATES.LOBBY_MENU)


# We're outta here
func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
