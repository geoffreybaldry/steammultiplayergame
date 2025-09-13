extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Log.pr("game_level_1 loaded")
	
	SteamNetwork.player_loaded.rpc()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	pass # Replace with function body.
