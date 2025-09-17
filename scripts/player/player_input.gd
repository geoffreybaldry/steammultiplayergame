extends Node

# Exporting this var makes it easily selectable in the PlayerInputSynchronizer
@export var input_direction: Vector2 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Only allow this player's authority to perform actions
	if not is_multiplayer_authority():
		return
		
	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
