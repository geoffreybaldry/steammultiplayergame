@tool
extends RewindableState

@export var character_body_2d: CharacterBody2D
@export var animation_player: AnimationPlayer
@export var navigation_agent_2d: NavigationAgent2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Called for every rollback tick the state is active.
func tick(_delta, _tk, _is_fresh):
	#Log.pr("CHASE tick on tick : " + str(_tk))
	
	if character_body_2d.is_dying:
		state_machine.transition(&"DIE")
	
	# Update the location of nearby player if there is one
	var nearby_player: Node2D = character_body_2d.find_nearby_player()
	if nearby_player:
		# Attack, if they are within range
		if nearby_player.global_position.distance_to(character_body_2d.global_position) <= character_body_2d.attack_range:
			state_machine.transition(&"ATTACK")
			
		character_body_2d.navigation_agent_2d.set_target_position(nearby_player.global_position)
	
	# If we entered the CHASE state we must have a target position to move towards
	# Path navigation logic
	var next_path_position: Vector2 = navigation_agent_2d.get_next_path_position()
	var target_vector: Vector2 = character_body_2d.global_position.direction_to(next_path_position).normalized() * character_body_2d.max_speed
	character_body_2d.velocity = character_body_2d.velocity.move_toward(target_vector, character_body_2d.acceleration * _delta) 
	
	if navigation_agent_2d.avoidance_enabled:
		navigation_agent_2d.set_velocity(character_body_2d.velocity)
	else:
		character_body_2d._on_velocity_computed(character_body_2d.velocity)
		
	if navigation_agent_2d.is_navigation_finished():
		state_machine.transition(&"IDLE")


# Called when entering the state.
func enter(_previous_state, _tk):
	Log.pr("CHASE state entered on tick : " + str(_tk))
	

# Called when exiting the state.
func exit(_next_state, _tk):
	Log.pr("CHASE state exited on tick : " + str(_tk))

# Called before entering the state. The state is only entered if this method returns true.
func can_enter(_previous_state):
	return true

# Called before displaying the state.
func display_enter(_previous_state, _tk):
	character_body_2d.state_label.text = "CHASE"
	animation_player.play("skeleton_walk")

# Called before displaying a different state.
func display_exit(_next_state, _tk):
	pass
