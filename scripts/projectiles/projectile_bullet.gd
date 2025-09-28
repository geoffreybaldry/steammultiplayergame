extends Area2D

const SPEED:int = 250
#var velocity: Vector2
@export var peer_id: int = -1

#@onready var rollback_synchronizer: RollbackSynchronizer = $RollbackSynchronizer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Take a frame to allow the network to synchronize, etc, and let player_id
	# be set.
	await get_tree().process_frame
	
	set_multiplayer_authority(1)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
	
func _physics_process(delta: float) -> void:
	position += transform.x * SPEED * delta
