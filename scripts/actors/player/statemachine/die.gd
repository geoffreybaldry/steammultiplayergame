@tool
extends RewindableState

@export var character_body_2d: CharacterBody2D
@export var animation_player: AnimationPlayer

var restart_tick: int = INF
var restart_cooldown_ticks: int = 60 # 2 seconds at 30TPS

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Called for every rollback tick the state is active.
func tick(_delta, _tk, _is_fresh):
	character_body_2d.is_dying = false
	
	# Check if it's time to restart
	if _tk >= restart_tick:
		restart_tick = INF
		Events.game_events.player_died.emit(character_body_2d.peer_id)
		state_machine.transition(&"IDLE")

# Called when entering the state.
func enter(_previous_state, _tk):
	Log.pr("DIE state entered on tick : " + str(_tk))
	restart_tick = _tk + restart_cooldown_ticks
	
	
# Called when exiting the state.
func exit(_next_state, _tk):
	Log.pr("DIE state exited on tick : " + str(_tk))

# Called before entering the state. The state is only entered if this method returns true.
func can_enter(_previous_state):
	return true

# Called before displaying the state.
func display_enter(_previous_state, _tk):
	character_body_2d.state_label.text = "DIE"
	animation_player.speed_scale = 1.0 # Default
	animation_player.play("player_animations/player_die" + "_" + character_body_2d.PLAYER_COLORS.keys()[character_body_2d.player_color].to_lower())
	
# Called before displaying a different state.
func display_exit(_next_state, _tk):
	pass
