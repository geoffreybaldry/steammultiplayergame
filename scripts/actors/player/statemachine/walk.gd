@tool
extends RewindableState

@export var character_body_2d: CharacterBody2D
@export var player_input: PlayerInput
@export var animation_player: AnimationPlayer
@export var audio_stream_player_2d: AudioStreamPlayer2D

var audio_footsteps = [
	preload("res://assets/audio/effects/footsteps/footstep_concrete_000.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_001.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_002.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_003.ogg"),
	preload("res://assets/audio/effects/footsteps/footstep_concrete_004.ogg"),
]

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
		
	var target_velocity = player_input.input_direction * character_body_2d.max_speed
	character_body_2d.velocity = character_body_2d.velocity.move_toward(target_velocity, character_body_2d.acceleration) 

	character_body_2d.update_velocity(character_body_2d.velocity)
	
	if player_input.input_direction == Vector2.ZERO:
		state_machine.transition(&"IDLE")

	animation_player.speed_scale = clampf(character_body_2d.velocity.length() / character_body_2d.max_speed, 0.2, 1.0)
	animation_player.play("player_animations/player_walk" + "_" + character_body_2d.PLAYER_COLORS.keys()[character_body_2d.player_color].to_lower())

# Called when entering the state.
func enter(_previous_state, _tk):
	Log.pr("WALK state entered on tick : " + str(_tk))
	

# Called when exiting the state.
func exit(_next_state, _tk):
	Log.pr("WALK state exited on tick : " + str(_tk))


# Called before entering the state. The state is only entered if this method returns true.
func can_enter(_previous_state):
	return player_input.input_direction != Vector2.ZERO


# Called before displaying the state.
func display_enter(_previous_state, _tk):
	character_body_2d.state_label.text = "WALK"


# Called before displaying a different state.
func display_exit(_next_state, _tk):
	pass


func footstep_audio() -> void:
	audio_stream_player_2d.stream = audio_footsteps.pick_random()
	audio_stream_player_2d.pitch_scale = randf_range(0.8, 1.2)
	audio_stream_player_2d.play()
