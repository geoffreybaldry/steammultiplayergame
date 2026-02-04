@tool
extends RewindableState

@export var character_body_2d: CharacterBody2D
@export var player_input: PlayerInput
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
	
	# Decelerate from whatever velocity we were doing before entering IDLE state
	character_body_2d.velocity = character_body_2d.velocity.move_toward(Vector2.ZERO, character_body_2d.deceleration)
	character_body_2d.update_velocity(character_body_2d.velocity)

	# If we are applying input movement, transition to walk state
	if player_input.input_direction != Vector2.ZERO:
		state_machine.transition(&"WALK")


# Called when entering the state.
func enter(_previous_state, _tk):
	pass
	#Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "IDLE state (enter) on tick : " + str(_tk))
	
	
# Called when exiting the state.
func exit(_next_state, _tk):
	pass
	#Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "IDLE state (exit) on tick : " + str(_tk))
	

# Called before entering the state. The state is only entered if this method returns true.
func can_enter(_previous_state):
	return true

# Called before displaying the state.
func display_enter(_previous_state, _tk):
	#Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "IDLE state (display_enter) on tick : " + str(_tk))
	character_body_2d.state_label.text = "IDLE"
	animation_player.speed_scale = 1.0 # Default
	animation_player.play("player_animations/player_idle" + "_" + character_body_2d.PLAYER_COLORS.keys()[character_body_2d.player_color].to_lower())

# Called before displaying a different state.
func display_exit(_next_state, _tk):
	pass
	#Log.pr("[" + str(multiplayer.get_unique_id()) + "]" + " " + "IDLE state (display_exit) on tick : " + str(_tk))
