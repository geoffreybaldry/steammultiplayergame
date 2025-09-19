extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_multiplayer_lobby_button_pressed() -> void:
	pass
	#Levels.goto_scene()


# We're outta here
func _on_quit_game_button_pressed() -> void:
	get_tree().quit()
