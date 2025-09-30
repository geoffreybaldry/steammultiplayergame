extends Area2D
class_name ProjectileBullet

const SPEED:int = 100

@export var peer_id: int = -1

var fired_by: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkTime.on_tick.connect(_tick)


func _tick(delta, _t):
	position += transform.x * SPEED * delta


func remove_projectile() -> void:
	queue_free()
	NetworkTime.on_tick.disconnect(_tick)


func _on_body_entered(body: Node2D) -> void:
	Log.pr("Projectile entered body : " + str(body.name))
	if body.is_in_group("enemies"):
		Log.pr("Peer ID " + str(fired_by.peer_id) + " shot an enemy!")
		# TBD - award points to the player
	
	remove_projectile()


func _on_area_entered(area: Area2D) -> void:
	Log.pr("Projectile entered area : " + str(area.name))
	remove_projectile()


func _on_timer_timeout() -> void:
	Log.pr("Projectile timed out after not colliding.")
	remove_projectile()
