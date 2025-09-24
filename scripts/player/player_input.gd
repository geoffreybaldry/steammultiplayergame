extends Node

## A separate script to collect the player's input. This is quite a pleasant
## way of doing things. Partly because it takes some of the weight out of the 
## main player script.

# Exporting this var makes it easily selectable in the PlayerInputSynchronizer
@export var input_direction: Vector2
@export var aim_direction: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Only allow this player's authority to perform actions
	if not is_multiplayer_authority():
		return
	
	# Input.get_vector provides a Vector2 of maximum length 1 unit - perfect
	# for use in directions of players.
	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	aim_direction = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
