extends Control


signal lobby_menu_button_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_lobby_menu_button_pressed() -> void:
	lobby_menu_button_pressed.emit()


# We're outta here
func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
