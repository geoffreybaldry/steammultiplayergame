extends Projectile
class_name Bullet

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	

func _tick(delta, _t) -> void:
	position += transform.x * speed * delta
	
	
func _on_body_entered(_body: Node2D) -> void:
	disable_projectile()


func _on_hurt_box_area_entered(area: Area2D) -> void:
	#if not is_multiplayer_authority():
		#return

	Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Bullet from peer " + str(fired_by) + " Hit HitBox " + area.get_parent().name + " on tick " + str(NetworkTime.tick))

	# Perform a "shove" on the actor
	var actor: Node2D = area.get_parent()
	actor.shove(Vector2(1,0).rotated(rotation), shove_force)
	#actor.damage(1.0)
	
	actor.damage(1.0, NetworkTime.tick)
	NetworkRollback.mutate(actor) # Is this doing anything?
	
	disable_projectile()
