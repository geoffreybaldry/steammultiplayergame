extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Let the Network Server know that we have loaded the level
	Levels.player_loaded.rpc_id(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
