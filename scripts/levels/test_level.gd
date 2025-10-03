extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Let the Network Server know that we have loaded the level
	Network.player_loaded.rpc_id(1)

func _process(_delta: float) -> void:
	pass
