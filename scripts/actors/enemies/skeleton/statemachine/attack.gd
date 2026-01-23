@tool
extends RewindableState

@export var character_body_2d: CharacterBody2D
@export var animation_player: AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Called for every rollback tick the state is active.
func tick(_delta, _tk, _is_fresh):
	if character_body_2d.is_dying:
		state_machine.transition(&"DIE")
	
	# Perform ATTACK, which is currently stand still, lol.
	Events.error_messages.error_message.emit("Attack!", 1.0)
	
	# Check if our hurtbox collided with any hitboxes
	var collisions = character_body_2d.hurt_box.get_overlapping_areas()
	if collisions:
		# Dish out damage to any of those hitbox owners
		for collider in collisions:
			var actor = collider.get_parent()
			if actor.has_method("damage"):
				Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "Sending some damage on tick " + str(NetworkTime.tick) + " and rollback tick " + str(_tk))
				actor.damage(1.0)
				if actor.has_method("shove"): # If the actor is shovable, then shove them too
					pass # let's get back to this...
					#actor.shove(Vector2(1,0).rotated(rotation), shove_force)
				NetworkRollback.mutate(actor)
	
	character_body_2d.last_attack_tick = _tk
	
	# After attacking, go back to IDLE, which can then go back to chase
	state_machine.transition(&"IDLE")


# Called when entering the state.
func enter(_previous_state, _tk):
	Log.pr("ATTACK state entered on tick : " + str(_tk))
	

# Called when exiting the state.
func exit(_next_state, _tk):
	Log.pr("ATTACK state exited on tick : " + str(_tk))

# Called before entering the state. The state is only entered if this method returns true.
func can_enter(_previous_state):
	return NetworkTime.tick > character_body_2d.last_attack_tick + character_body_2d.attack_cooldown_ticks

# Called before displaying the state.
func display_enter(_previous_state, _tk):
	character_body_2d.state_label.text = "ATTACK"
	#animation_player.play("skeleton_attack") # Doesn't exist yet

# Called before displaying a different state.
func display_exit(_next_state, _tk):
	pass
