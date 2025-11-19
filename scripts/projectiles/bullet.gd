extends Projectile
class_name Bullet

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	
	audio_stream_player_2d.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#super(delta)
	#
#
#func _physics_process(delta: float) -> void:
	#super(delta)
	#
	#position += transform.x * speed * delta


func _tick(delta, _t) -> void:
	position += transform.x * speed * delta

	# Skip collisions for a single tick, no more
	#is_first_tick = false
	
func _on_body_entered(_body: Node2D) -> void:
	remove_projectile()


func _on_timer_timeout() -> void:
	remove_projectile()


func _on_hurt_box_area_entered(area: Area2D) -> void:
	Log.pr("Bullet from peer " + str(fired_by) + " Hit HitBox " + area.get_parent().name)
	remove_projectile()
