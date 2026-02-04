extends Projectile
class_name Bullet



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	

func _tick(delta, _t) -> void:
	super(delta, _t)


# This is an inputless RBS - remember this function will probably not run at
# all on clients/peers, and only on the server.
func _rollback_tick(_delta, _tk, _is_fresh: bool):
	position += transform.x * speed * _delta
	
	# Check if our hurtbox collided with any hitboxes
	var collisions = hurt_box.get_overlapping_areas()
	if collisions:
		#did_hit = true
		# Dish out damage to any of those hitbox owners
		for collider in collisions:
			var actor = collider.get_parent()
			if actor.has_method("damage"):
				Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Sending some damage on tick " + str(NetworkTime.tick) + " and rollback tick " + str(_tk))
				actor.damage(1.0)
				is_disabled = true
				if actor.has_method("shove"): # If the actor is shovable, then shove them too
					actor.shove(Vector2(1,0).rotated(rotation), shove_force)
				#NetworkRollback.mutate(actor)
				#NetworkRollback.mutate(self)
	else:
		#did_hit = false
		is_disabled = false


func _after_tick_loop():
	if is_disabled:
		disable_projectile()
	#if did_hit:
		#audio_stream_player_2d.play()
		#did_hit = false
	
func _on_body_entered(_body: Node2D) -> void:
	audio_stream_player_2d.play()
	disable_projectile()
