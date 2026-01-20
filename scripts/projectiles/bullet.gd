extends Projectile
class_name Bullet

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	

func _tick(delta, _t) -> void:
	super(delta, _t)
	
	
func _rollback_tick(_delta, _tk, _is_fresh: bool):
	super(_delta, _tk, _is_fresh)
	
	if is_disabled:
		return
	
	position += transform.x * speed * _delta
	#Events.error_messages.error_message.emit("Doing something on rollback tick " + str(_tk), 2)
	# Check if our hurtbox collided with any hitboxes
	var collisions = hurt_box.get_overlapping_areas()
	if collisions:
		# Dish out damage to any of those hitbox owners
		for collider in collisions:
			var actor = collider.get_parent()
			if actor.has_method("damage"):
				#Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Sending some damage on rollback tick " + str(_tk))
				actor.damage(1.0)
				is_disabled = true
				# If the actor is shovable, then shove them too
				#if actor.has_method("shove"):
					#actor.shove(Vector2(1,0).rotated(rotation), shove_force)
				
				NetworkRollback.mutate(actor)
	else:
		is_disabled = false


func _after_tick_loop():
	if is_disabled:
		disable_projectile()
	
	
func _on_body_entered(_body: Node2D) -> void:
	disable_projectile()
