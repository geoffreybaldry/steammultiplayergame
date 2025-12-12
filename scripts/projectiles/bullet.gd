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
	Log.pr("Bullet from peer " + str(fired_by) + " Hit HitBox " + area.get_parent().name)
	
	# Perform a "shove" on the actor
	area.get_parent().shove(Vector2(1,0).rotated(rotation), 1000.0)
	NetworkRollback.mutate(area.get_parent())
	
	disable_projectile()
