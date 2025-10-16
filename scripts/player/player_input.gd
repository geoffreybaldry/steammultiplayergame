extends Node
class_name PlayerInput

## A separate script to collect the player's input. This is quite a pleasant
## way of doing things, partly because it takes some of the weight out of the 
## main player script.
## It's also required by NetFox, which needs the input to be separate state
## from the player object itself.

# Analog input, which needs to be buffered and averaged
var input_direction: Vector2 = Vector2.ZERO
var input_direction_buf: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.ZERO
var aim_direction_buf: Vector2 = Vector2.ZERO
var sample_count: int = 0

# Binary input
var just_fired: bool = false
var just_fired_buf: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	NetworkTime.before_tick_loop.connect(_gather)
	NetworkTime.after_tick.connect(func(_dt, _t): _gather_always())


#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion:
		#aim_direction_buf += (get_viewport().get_camera_2d().get_global_mouse_position() - get_parent().global_position).normalized()
	#elif event is InputEventJoypadMotion:
		#input_direction_buf += Focus.input_get_vector("move_left", "move_right", "move_up", "move_down")
		#aim_direction_buf += Focus.input_get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	##elif event is InputEventKey and event.
#
	#sample_count += 1
	
func _process(_delta: float) -> void:
	# Input.get_vector() provides a Vector2 of maximum length 1 unit - perfect
	# for use in directions of players.
	input_direction_buf += Focus.input_get_vector("move_left", "move_right", "move_up", "move_down")
	aim_direction_buf += Focus.input_get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	sample_count += 1
	
	if Focus.input_is_action_just_pressed("fire"):
		just_fired_buf = true


func _gather():
	# Don't run if this node is in the process of being freed
	if not is_inside_tree():
		return
		
	# Only allow this player's authority to collect input
	if not is_multiplayer_authority():
		return

	# Average the buffered input
	if sample_count > 0:
		input_direction = input_direction_buf / sample_count
		aim_direction = aim_direction_buf / sample_count
	else:
		input_direction = Vector2.ZERO
		aim_direction = Vector2.ZERO
		
	# Reset input buffer
	input_direction_buf = Vector2.ZERO
	aim_direction_buf = Vector2.ZERO
	sample_count = 0
	

func _gather_always():
	just_fired = just_fired_buf
	just_fired_buf = false
