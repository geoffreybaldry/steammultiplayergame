extends Area2D
class_name Bullet

const SPEED:int = 100

# This peer_id gets synchronized by a MultiplayerSynchronizer, only on change
@export var peer_id: int = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Take a frame to allow the network to synchronize, etc, and let peer_id
	# be set.
	await get_tree().process_frame
	
	# Ensure that the player that fired the bullet is the authority
	set_multiplayer_authority(peer_id)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += transform.x * SPEED * delta

func destroy_bullet() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	Log.pr("Bullet entered body " + str(body.name))
	destroy_bullet()


func _on_timer_timeout() -> void:
	Log.pr("Bullet timed out")
	destroy_bullet()
