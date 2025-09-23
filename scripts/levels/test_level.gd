extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Let the Network know that we have loaded the level
	SteamNetwork.player_loaded.rpc()

func _process(delta: float) -> void:
	pass
