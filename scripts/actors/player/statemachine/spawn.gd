@tool
extends RewindableState

@export var character_body_2d: CharacterBody2D
@export var player_input: PlayerInput
@export var animation_player: AnimationPlayer
@export var tick_interpolator: TickInterpolator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Called for every rollback tick the state is active.
func tick(_delta, _tk, _is_fresh):
	check_spawn(_tk) 		# Check if the player needs to spawn

# Called when entering the state.
func enter(_previous_state, _tk):
	Log.pr("SPAWN state entered on tick : " + str(_tk))

# Called when exiting the state.
func exit(_next_state, _tk):
	Log.pr("SPAWN state exited on tick : " + str(_tk))

# Called before entering the state. The state is only entered if this method returns true.
func can_enter(_previous_state):
	return true

# Called before displaying the state.
func display_enter(_previous_state, _tk):
	character_body_2d.state_label.text = "SPAWN"
	animation_player.speed_scale = 1.0 # Default
	animation_player.play("player_animations/player_idle" + "_" + character_body_2d.PLAYER_COLORS.keys()[character_body_2d.player_color].to_lower())

# Called before displaying a different state.
func display_exit(_next_state, _tk):
	tick_interpolator.teleport()


func check_spawn(_tk) -> void:
	if _tk == character_body_2d.spawn_tick:
		character_body_2d.global_position = character_body_2d.spawn_position
		#character_body_2d.did_spawn = true
		character_body_2d.health = character_body_2d.max_health
		character_body_2d.is_player_enabled = true
		if player_input.is_multiplayer_authority():
			character_body_2d.grab_pcam()
		state_machine.transition(&"IDLE")
	else:
		pass
		#character_body_2d.did_spawn = false
