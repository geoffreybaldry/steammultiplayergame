extends Area2D
class_name Bullet

const SPEED:int = 100

# This peer_id gets synchronized by a MultiplayerSynchronizer, only on change
@export var peer_id: int = -1

@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Take a frame to allow the network to synchronize, etc, and let peer_id
	# be set.
	await get_tree().process_frame
	
	# Ensure that the player that fired the bullet is the authority
	set_multiplayer_authority(peer_id)
	
	NetworkTime.on_tick.connect(_tick)
	
	if is_multiplayer_authority():
		area_entered.connect(_on_area_entered)
		body_entered.connect(_on_body_entered)
		timer.timeout.connect(_on_timer_timeout)


# Tick instead of _physics_process (means it can't rollback, I guess, though).
func _tick(delta, _t) -> void:
	position += transform.x * SPEED * delta


func destroy_bullet() -> void:
	queue_free()
	NetworkTime.on_tick.disconnect(_tick)


func _on_body_entered(body: Node2D) -> void:
	Log.pr("Bullet entered body " + str(body.name))
	destroy_bullet()


func _on_area_entered(area: Area2D) -> void:
	Log.pr("Bullet entered area " + str(area.name))
	

func _on_timer_timeout() -> void:
	Log.pr("Bullet timed out")
	destroy_bullet()
