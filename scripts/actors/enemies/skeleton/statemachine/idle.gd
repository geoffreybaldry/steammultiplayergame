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
	#Log.pr("IDLE tick on tick : " + str(_tk))
	
	# If we went idle, decelerate from whatever velocity we were doing
	character_body_2d.velocity = character_body_2d.velocity.move_toward(Vector2.ZERO, character_body_2d.deceleration * _delta)
	character_body_2d._on_velocity_computed(character_body_2d.velocity)
	
	# Try to find a nearby player
	var nearby_player: Node2D = character_body_2d.find_nearby_player()
	if nearby_player:
		character_body_2d.navigation_agent_2d.set_target_position(nearby_player.global_position)
		state_machine.transition(&"CHASE")


# Called when entering the state.
func enter(_previous_state, _tk):
	Log.pr("IDLE state entered on tick : " + str(_tk))
	

# Called when exiting the state.
func exit(_next_state, _tk):
	Log.pr("IDLE state exited on tick : " + str(_tk))

# Called before entering the state. The state is only entered if this method returns true.
func can_enter(_previous_state):
	return true

# Called before displaying the state.
func display_enter(_previous_state, _tk):
	animation_player.play("skeleton_idle")

# Called before displaying a different state.
func display_exit(_next_state, _tk):
	pass
