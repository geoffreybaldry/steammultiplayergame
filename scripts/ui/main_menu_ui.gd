extends Control

@onready var steam_lobby_menu_button: Button = $VBoxContainer/steam_lobby_menu_button
@onready var enet_menu_button: Button = $VBoxContainer/enet_menu_button
@onready var quit_game_button: Button = $VBoxContainer/quit_game_button

func _ready() -> void:
	steam_lobby_menu_button.grab_focus.call_deferred()


# We're outta here
func _on_quit_game_button_pressed() -> void:
	get_tree().quit()


func _on_enet_menu_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATES.ENET_MENU)


func _on_steam_lobby_menu_button_pressed() -> void:
	GameState.change_game_state(GameState.GAME_STATES.STEAM_LOBBY_MENU)
