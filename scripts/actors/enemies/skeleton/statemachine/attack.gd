@tool
extends RewindableState

@export var character_body_2d: CharacterBody2D
@export var animation_player: AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Called for every rollback tick the state is active.
func tick(_delta, _tk, _is_fresh):
	Log.pr("ATTACK tick on tick : " + str(_tk))


# Called when entering the state.
func enter(_previous_state, _tk):
	Log.pr("ATTACK state entered on tick : " + str(_tk))
	

# Called when exiting the state.
func exit(_next_state, _tk):
	Log.pr("ATTACK state exited on tick : " + str(_tk))

# Called before entering the state. The state is only entered if this method returns true.
func can_enter(_previous_state):
	return true

# Called before displaying the state.
func display_enter(_previous_state, _tk):
	pass
	#animation_player.play("skeleton_attack")

# Called before displaying a different state.
func display_exit(_next_state, _tk):
	pass
