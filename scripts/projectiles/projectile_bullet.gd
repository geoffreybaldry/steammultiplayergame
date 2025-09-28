extends Area2D


var velocity: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Take a frame to allow the network to synchronize, etc, and let player_id
	# be set.
	#await get_tree().process_frame
	
	# Ensure that the server/host is the autohority over the player node
	set_multiplayer_authority(1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
